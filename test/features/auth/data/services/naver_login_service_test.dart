// ignore_for_file: non_constant_identifier_names

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naver_login_flutter/naver_login_flutter.dart';
import 'package:shift_mate/features/auth/data/services/naver_login_service.dart';

class _FakeNaverLoginSdk implements NaverLoginSdk {
  NaverLoginResult login_result = NaverLoginResult(
    status: NaverLoginStatus.loggedOut,
  );
  NaverToken current_token = NaverToken.empty();
  PlatformException? login_exception;
  bool logout_called = false;

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
  });
}
