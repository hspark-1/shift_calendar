// ignore_for_file: non_constant_identifier_names

import 'package:flutter/services.dart';
import 'package:naver_login_flutter/naver_login_flutter.dart';

import '../../../../core/network/api_exception.dart';

/// 네이버 네이티브 SDK 호출 경계
abstract interface class NaverLoginSdk {
  Future<NaverLoginResult> logIn();
  Future<NaverToken> getCurrentAccessToken();
  Future<NaverLoginResult> logOut();
  Future<NaverLoginResult> logOutAndDeleteToken();
}

/// 실제 네이버 네이티브 SDK 구현
class NativeNaverLoginSdk implements NaverLoginSdk {
  @override
  Future<NaverLoginResult> logIn() {
    return FlutterNaverLogin.logIn();
  }

  @override
  Future<NaverToken> getCurrentAccessToken() {
    return FlutterNaverLogin.getCurrentAccessToken();
  }

  @override
  Future<NaverLoginResult> logOut() {
    return FlutterNaverLogin.logOut();
  }

  @override
  Future<NaverLoginResult> logOutAndDeleteToken() {
    return FlutterNaverLogin.logOutAndDeleteToken();
  }
}

/// 네이버 네이티브 로그인 서비스
///
/// iOS는 네이버 앱을 우선 사용하고, 앱이 설치되지 않은 경우에만
/// SDK의 인앱 브라우저로 대체합니다. Android의 인증 화면 선택 역시
/// 네이버 공식 SDK가 처리합니다.
class NaverLoginService {
  final NaverLoginSdk _naver_login_sdk;

  NaverLoginService({NaverLoginSdk? naver_login_sdk})
    : _naver_login_sdk = naver_login_sdk ?? NativeNaverLoginSdk();

  /// 네이버 SDK에서 발급한 Access Token을 반환합니다.
  Future<String> loginWithNaver() async {
    try {
      final login_result = await _naver_login_sdk.logIn();

      switch (login_result.status) {
        case NaverLoginStatus.loggedIn:
          var access_token = login_result.accessToken?.accessToken.trim();
          if (access_token == null || access_token.isEmpty) {
            final current_token = await _naver_login_sdk
                .getCurrentAccessToken();
            access_token = current_token.accessToken.trim();
          }
          if (access_token.isEmpty) {
            throw ApiException(
              code: 'NAVER_TOKEN_UNAVAILABLE',
              message: '네이버 로그인 정보를 받지 못했습니다. 다시 로그인해주세요.',
            );
          }
          return access_token;
        case NaverLoginStatus.loggedOut:
          throw _loginError('cancelled');
        case NaverLoginStatus.error:
          throw _loginError(login_result.errorMessage);
      }
    } on ApiException {
      rethrow;
    } on PlatformException catch (error) {
      throw _loginError(error.message, native_code: error.code);
    } catch (_) {
      throw _loginError(null);
    }
  }

  // SDK는 native code를 보존하지 않고 오류 문자열만 반환할 수도 있다.
  // 분류에만 사용하며 URL/토큰/네이티브 진단 원문은 UI에 전달하지 않는다.
  ApiException _loginError(String? raw_message, {String? native_code}) {
    final message = raw_message?.trim().toLowerCase() ?? '';
    final code = native_code?.toLowerCase() ?? '';
    if (message.contains('cancel') || code.contains('cancel')) {
      return ApiException(
        code: 'NAVER_LOGIN_CANCELLED',
        message: '네이버 로그인이 취소되었습니다.',
      );
    }
    final is_url_network_error =
        message.contains('nsurlerrordomain') &&
        RegExp(r'code\s*=\s*-(1001|1003|1004|1005|1009)\b').hasMatch(message);
    if (is_url_network_error ||
        message.startsWith('network error') ||
        code.contains('network')) {
      return ApiException(
        code: 'NAVER_NETWORK_ERROR',
        message: '네이버에 연결할 수 없습니다. 네트워크 상태를 확인한 후 다시 시도해주세요.',
      );
    }
    return ApiException(
      code: 'NAVER_LOGIN_FAILED',
      message: '네이버 로그인에 실패했습니다. 다시 시도해주세요.',
    );
  }

  /// 네이버 SDK에 저장된 로컬 로그인 상태를 해제합니다.
  Future<void> logout() async {
    await _naver_login_sdk.logOut();
  }

  /// 회원 탈퇴 전 네이버 앱 연결과 SDK 토큰을 해제한다.
  Future<void> disconnect() async {
    final current_token = await _naver_login_sdk.getCurrentAccessToken();
    if (current_token.accessToken.trim().isEmpty) return;

    final result = await _naver_login_sdk.logOutAndDeleteToken();
    if (result.status == NaverLoginStatus.error) {
      final error_message = result.errorMessage?.trim();
      throw Exception(
        error_message == null || error_message.isEmpty
            ? '네이버 계정 연결 해제에 실패했습니다.'
            : '네이버 계정 연결 해제에 실패했습니다: $error_message',
      );
    }
  }
}
