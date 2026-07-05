import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';

/// 네이버 로그인 서비스
/// 웹뷰를 사용하되, 네이버 앱이 설치되어 있으면 웹뷰에서 자동으로 네이버 앱으로 리디렉션됨
class NaverLoginService {
  /// 네이버 OAuth 인증 URL 생성
  String _buildAuthUrl() {
    final clientId = AppConstants.naver_client_id;
    final redirectUri = AppConstants.naver_redirect_uri;

    // 클라이언트 ID 검증
    if (clientId.isEmpty) {
      throw Exception(
        '네이버 클라이언트 ID가 설정되지 않았습니다.\n'
        '실행 방법: flutter run --dart-define=NAVER_CLIENT_ID=실제키값',
      );
    }

    final encodedRedirectUri = Uri.encodeComponent(redirectUri);
    final state = DateTime.now().millisecondsSinceEpoch.toString();

    final authUrl =
        'https://nid.naver.com/oauth2.0/authorize?'
        'response_type=token&'
        'client_id=$clientId&'
        'redirect_uri=$encodedRedirectUri&'
        'state=$state';

    return authUrl;
  }

  /// 네이버 로그인
  /// 웹뷰를 사용하되, 네이버 앱이 설치되어 있으면 웹뷰에서 자동으로 네이버 앱으로 리디렉션됨
  /// 네이버 앱에서 로그인 후 redirect_uri로 리디렉션되면 앱이 깨어나서 처리
  Future<String> loginWithNaver(BuildContext context) async {
    final authUrl = _buildAuthUrl();
    final redirectUri = AppConstants.naver_redirect_uri;

    // 웹뷰를 사용하되, 네이버 앱이 설치되어 있으면 웹뷰에서 자동으로 네이버 앱으로 리디렉션됨
    // 네이버 앱에서 로그인 후 redirect_uri로 리디렉션되면 앱이 깨어나면서 URL이 전달됨
    return await _loginWithWebView(context, authUrl, redirectUri);
  }

  /// 네이버 로그인 (웹뷰 방식)
  /// 웹뷰를 통해 네이버 OAuth 인증을 처리하고 access_token을 반환
  Future<String> _loginWithWebView(
    BuildContext context,
    String authUrl,
    String redirectUri,
  ) async {
    final completer = Completer<String>();

    // 웹뷰 다이얼로그 표시
    await showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _NaverLoginWebView(
          authUrl: authUrl,
          redirectUri: redirectUri,
          onSuccess: (accessToken) {
            Navigator.of(dialogContext).pop();
            completer.complete(accessToken);
          },
          onError: (error) {
            Navigator.of(dialogContext).pop();
            completer.completeError(error);
          },
        );
      },
    );

    return completer.future;
  }
}

/// 네이버 로그인 웹뷰 위젯
class _NaverLoginWebView extends StatefulWidget {
  final String authUrl;
  final String redirectUri;
  final Function(String accessToken) onSuccess;
  final Function(String error) onError;

  const _NaverLoginWebView({
    required this.authUrl,
    required this.redirectUri,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<_NaverLoginWebView> createState() => _NaverLoginWebViewState();
}

class _NaverLoginWebViewState extends State<_NaverLoginWebView> {
  bool _is_loading = true;
  InAppWebViewController? _webViewController;

  /// Redirect URI와 URL을 대소문자 구분 없이 비교
  bool _isRedirectUri(String url) {
    // 대소문자 구분 없이 비교 (네이버가 소문자로 변환해서 보낼 수 있음)
    return url.toLowerCase().startsWith(widget.redirectUri.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('네이버 로그인'),
        leading: CupertinoNavigationBarBackButton(
          onPressed: () {
            widget.onError('사용자가 취소했습니다.');
          },
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.authUrl)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                useHybridComposition: true,
                // 네이버 앱으로 리디렉션 허용
                supportMultipleWindows: false,
                javaScriptCanOpenWindowsAutomatically: false,
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              onLoadStart: (controller, url) {
                setState(() {
                  _is_loading = true;
                });

                final urlString = url.toString();

                // Redirect URI로 리디렉션되었는지 확인 (대소문자 구분 없이)
                if (_isRedirectUri(urlString)) {
                  // fragment가 포함된 전체 URL 가져오기
                  _checkRedirect(urlString);
                }
              },
              onLoadStop: (controller, url) async {
                setState(() {
                  _is_loading = false;
                });

                final urlString = url.toString();

                // Redirect URI로 리디렉션되었는지 확인 (대소문자 구분 없이)
                if (_isRedirectUri(urlString)) {
                  // JavaScript를 사용하여 fragment 읽기
                  await _checkRedirect(urlString);
                }
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final url = navigationAction.request.url.toString();

                // Redirect URI로 리디렉션되었는지 확인 (대소문자 구분 없이)
                if (_isRedirectUri(url)) {
                  // fragment가 포함된 전체 URL 처리
                  await _checkRedirect(url);
                  return NavigationActionPolicy.CANCEL;
                }

                // 네이버 앱 URL 스킴으로의 리디렉션 허용
                if (url.startsWith('naversearchapp://') ||
                    url.startsWith('naversearchthirdlogin://')) {
                  // 외부 앱(네이버 앱)으로 이동 허용
                  try {
                    final uri = Uri.parse(url);
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                    // 네이버 앱으로 이동했으므로 웹뷰는 닫지 않고 대기
                    // 네이버 앱에서 로그인 후 redirect_uri로 리디렉션되면 앱이 깨어남
                    return NavigationActionPolicy.CANCEL;
                  } catch (e) {
                    // 네이버 앱 열기 실패 시 계속 진행
                    return NavigationActionPolicy.ALLOW;
                  }
                }

                return NavigationActionPolicy.ALLOW;
              },
              onReceivedError: (controller, request, error) {
                final failedUrl = request.url.toString();

                // 커스텀 URL 스킴(redirect URI)로의 리디렉션은 정상 동작
                // 웹뷰는 커스텀 URL 스킴을 로드할 수 없지만, shouldOverrideUrlLoading에서 처리됨
                if (_isRedirectUri(failedUrl)) {
                  // shouldOverrideUrlLoading에서 이미 처리되므로 오류 무시
                  return;
                }

                // 실제 네트워크 오류만 처리
                if (error.type == WebResourceErrorType.HOST_LOOKUP ||
                    error.type == WebResourceErrorType.UNKNOWN) {
                  widget.onError(
                    '네트워크 오류가 발생했습니다.\n'
                    '네이버 클라이언트 ID와 Redirect URI 설정을 확인해주세요.',
                  );
                } else {
                  widget.onError('네트워크 오류가 발생했습니다: ${error.description}');
                }
              },
            ),
            if (_is_loading) const Center(child: CupertinoActivityIndicator()),
          ],
        ),
      ),
    );
  }

  /// Redirect URI 확인 및 fragment에서 access_token 추출
  Future<void> _checkRedirect(String url) async {
    try {
      // 커스텀 URL 스킴의 경우 웹뷰가 로드하지 못하므로 JavaScript도 실행되지 않음
      // shouldOverrideUrlLoading에서 받은 URL에 이미 fragment가 포함되어 있음
      // 따라서 바로 URL 파싱 진행
      if (url.contains('#')) {
        _handleRedirect(url);
        return;
      }

      // fragment가 없는 경우에만 JavaScript 시도 (일반적인 경우는 거의 없음)
      if (_webViewController != null) {
        try {
          final fullUrl = await _webViewController!.evaluateJavascript(
            source: 'window.location.href',
          );

          if (fullUrl != null && fullUrl.toString().isNotEmpty) {
            _handleRedirect(fullUrl.toString());
            return;
          }
        } catch (e) {
          print(e);
        }
      }

      // 모든 방법 실패 시 원본 URL 파싱 시도
      _handleRedirect(url);
    } catch (e) {
      widget.onError('인증 처리 중 오류가 발생했습니다: $e');
    }
  }

  /// Redirect URI에서 access_token 추출
  void _handleRedirect(String url) {
    try {
      // 커스텀 URL 스킴의 경우 Uri.parse()가 fragment를 제대로 파싱하지 못할 수 있음
      // 직접 문자열에서 # 이후 부분 추출
      String fragment = '';

      if (url.contains('#')) {
        final hashIndex = url.indexOf('#');
        if (hashIndex != -1 && hashIndex < url.length - 1) {
          fragment = url.substring(hashIndex + 1);
        }
      }

      // fragment가 여전히 비어있으면 Uri.parse() 시도
      if (fragment.isEmpty) {
        try {
          final uri = Uri.parse(url);
          fragment = uri.fragment;
        } catch (e) {
          print(e);
        }
      }

      if (fragment.isEmpty) {
        widget.onError('인증에 실패했습니다. Redirect URI를 확인해주세요.');
        return;
      }

      // fragment에서 파라미터 파싱
      final params = Uri.splitQueryString(fragment);
      final accessToken = params['access_token'];
      final error = params['error'];
      final errorDescription = params['error_description'];

      if (error != null) {
        widget.onError(errorDescription ?? error);
        return;
      }

      if (accessToken == null || accessToken.isEmpty) {
        widget.onError('access_token을 받지 못했습니다.');
        return;
      }

      widget.onSuccess(accessToken);
    } catch (e) {
      widget.onError('인증 처리 중 오류가 발생했습니다: $e');
    }
  }
}
