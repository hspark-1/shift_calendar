// ignore_for_file: non_constant_identifier_names

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naver_login_flutter/naver_login_flutter.dart';
import 'package:shift_mate/features/auth/data/services/naver_login_service.dart';
import 'package:shift_mate/core/network/api_exception.dart';

class _FakeNaverLoginSdk implements NaverLoginSdk {
  NaverLoginResult login_result = NaverLoginResult(
    status: NaverLoginStatus.loggedOut,
  );
  NaverToken current_token = NaverToken.empty();
  PlatformException? login_exception;
  bool logout_called = false;
  bool disconnect_called = false;
  NaverLoginResult disconnect_result = NaverLoginResult(
    status: NaverLoginStatus.loggedOut,
  );

  @override
  Future<NaverLoginResult> logIn() async {
    final exception = login_exception;
    if (exception != null) {
      throw exception;
    }
    return login_result;
  }

  @override
  Future<NaverToken> getCurrentAccessToken() async {
    return current_token;
  }

  @override
  Future<NaverLoginResult> logOut() async {
    logout_called = true;
    return NaverLoginResult(status: NaverLoginStatus.loggedOut);
  }

  @override
  Future<NaverLoginResult> logOutAndDeleteToken() async {
    disconnect_called = true;
    return disconnect_result;
  }
}

NaverToken _token(String access_token) {
  return NaverToken(
    accessToken: access_token,
    refreshToken: 'refresh-token',
    expiresAt: DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
    tokenType: 'bearer',
  );
}

void main() {
  group('NaverLoginService', () {
    final network_error =
        'Network error. Detailed error description: URLSession internal error. Error Domain=NSURLErrorDomain Code=-1005 "The network connection was lost." NSURLFailingURLStringKey=https://nid.naver.com/oauth2.0/token';

    test('SDK 연결 유실은 네트워크 안내로 변환한다', () async {
      final sdk = _FakeNaverLoginSdk()
        ..login_result = NaverLoginResult(
          status: NaverLoginStatus.error,
          errorMessage: network_error,
        );
      await expectLater(
        NaverLoginService(naver_login_sdk: sdk).loginWithNaver(),
        throwsA(
          isA<ApiException>()
              .having((error) => error.code, 'code', 'NAVER_NETWORK_ERROR')
              .having((error) => error.message, 'message', contains('다시 시도'))
              .having(
                (error) => error.message,
                'no native details',
                isNot(contains('NSURLErrorDomain')),
              )
              .having(
                (error) => error.message,
                'no URL',
                isNot(contains('https://')),
              ),
        ),
      );
    });

    test('PlatformException 연결 유실도 동일한 네트워크 오류다', () async {
      final sdk = _FakeNaverLoginSdk()
        ..login_exception = PlatformException(
          code: 'NAVER_LOGIN_ERROR',
          message: network_error,
        );
      await expectLater(
        NaverLoginService(naver_login_sdk: sdk).loginWithNaver(),
        throwsA(
          isA<ApiException>().having(
            (error) => error.code,
            'code',
            'NAVER_NETWORK_ERROR',
          ),
        ),
      );
    });

    for (final message in [
      'private native diagnostic access_token=secret',
      '',
      null,
    ]) {
      test(
        'SDK의 알 수 없는 오류는 안전한 로그인 안내다: ${message == null
            ? 'null'
            : message.isEmpty
            ? 'empty'
            : 'unknown'}',
        () async {
          final sdk = _FakeNaverLoginSdk()
            ..login_result = NaverLoginResult(
              status: NaverLoginStatus.error,
              errorMessage: message,
            );
          await expectLater(
            NaverLoginService(naver_login_sdk: sdk).loginWithNaver(),
            throwsA(
              isA<ApiException>()
                  .having((error) => error.code, 'code', 'NAVER_LOGIN_FAILED')
                  .having(
                    (error) => error.message,
                    'message',
                    '네이버 로그인에 실패했습니다. 다시 시도해주세요.',
                  ),
            ),
          );
        },
      );
    }

    test('네이티브 결과의 사용자 취소도 취소로 분류한다', () async {
      final sdk = _FakeNaverLoginSdk()
        ..login_result = NaverLoginResult(
          status: NaverLoginStatus.error,
          errorMessage: 'Login cancelled by user',
        );
      await expectLater(
        NaverLoginService(naver_login_sdk: sdk).loginWithNaver(),
        throwsA(
          isA<ApiException>().having(
            (error) => error.code,
            'code',
            'NAVER_LOGIN_CANCELLED',
          ),
        ),
      );
    });

    test('토큰이 없으면 안전한 토큰 미수신 오류를 반환한다', () async {
      final sdk = _FakeNaverLoginSdk()
        ..login_result = NaverLoginResult(status: NaverLoginStatus.loggedIn);
      await expectLater(
        NaverLoginService(naver_login_sdk: sdk).loginWithNaver(),
        throwsA(
          isA<ApiException>().having(
            (error) => error.code,
            'code',
            'NAVER_TOKEN_UNAVAILABLE',
          ),
        ),
      );
    });

    test('로그인 결과에 포함된 Access Token을 반환한다', () async {
      final sdk = _FakeNaverLoginSdk()
        ..login_result = NaverLoginResult(
          status: NaverLoginStatus.loggedIn,
          accessToken: _token('login-access-token'),
        );
      final service = NaverLoginService(naver_login_sdk: sdk);

      final access_token = await service.loginWithNaver();

      expect(access_token, 'login-access-token');
    });

    test('Android 로그인 결과에 토큰이 없으면 현재 Access Token을 조회한다', () async {
      final sdk = _FakeNaverLoginSdk()
        ..login_result = NaverLoginResult(status: NaverLoginStatus.loggedIn)
        ..current_token = _token('current-access-token');
      final service = NaverLoginService(naver_login_sdk: sdk);

      final access_token = await service.loginWithNaver();

      expect(access_token, 'current-access-token');
    });

    test('사용자가 로그인을 닫으면 취소 오류를 반환한다', () async {
      final sdk = _FakeNaverLoginSdk();
      final service = NaverLoginService(naver_login_sdk: sdk);

      expect(
        service.loginWithNaver,
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('취소'),
          ),
        ),
      );
    });

    test('네이티브 취소 오류를 사용자용 취소 메시지로 변환한다', () async {
      final sdk = _FakeNaverLoginSdk()
        ..login_exception = PlatformException(
          code: 'NAVER_LOGIN_ERROR',
          message: 'Login cancelled by user',
        );
      final service = NaverLoginService(naver_login_sdk: sdk);

      expect(
        service.loginWithNaver,
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('취소'),
          ),
        ),
      );
    });

    test('로그아웃을 네이버 네이티브 SDK에 위임한다', () async {
      final sdk = _FakeNaverLoginSdk();
      final service = NaverLoginService(naver_login_sdk: sdk);

      await service.logout();

      expect(sdk.logout_called, isTrue);
    });

    test('회원 탈퇴용 토큰 삭제를 네이버 SDK에 위임한다', () async {
      final sdk = _FakeNaverLoginSdk()
        ..current_token = _token('naver-access-token');
      final service = NaverLoginService(naver_login_sdk: sdk);

      await service.disconnect();

      expect(sdk.disconnect_called, isTrue);
    });

    test('네이버 연결 해제 실패를 탈퇴 요청 전에 전달한다', () async {
      final sdk = _FakeNaverLoginSdk()
        ..current_token = _token('naver-access-token')
        ..disconnect_result = NaverLoginResult(
          status: NaverLoginStatus.error,
          errorMessage: '연결 해제 실패',
        );
      final service = NaverLoginService(naver_login_sdk: sdk);

      await expectLater(
        service.disconnect(),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('연결 해제 실패'),
          ),
        ),
      );
    });

    test('네이버 로컬 토큰이 없으면 연결 해제를 건너뛴다', () async {
      final sdk = _FakeNaverLoginSdk();
      final service = NaverLoginService(naver_login_sdk: sdk);

      await service.disconnect();

      expect(sdk.disconnect_called, isFalse);
    });
  });
}
