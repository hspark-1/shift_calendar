// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/features/auth/data/models/apple_auth_models.dart';
import 'package:shift_mate/features/auth/data/services/apple_login_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class _FakeAppleSignInSdk implements AppleSignInSdk {
  bool available = true;
  AuthorizationCredentialAppleID credential =
      const AuthorizationCredentialAppleID(
        userIdentifier: 'apple-user-id',
        givenName: '길동',
        familyName: '홍',
        authorizationCode: 'authorization-code',
        email: 'user@example.com',
        identityToken: 'identity-token',
        state: 'signed-state',
      );
  SignInWithAppleException? exception;
  bool never_complete = false;
  List<AppleIDAuthorizationScopes>? captured_scopes;
  WebAuthenticationOptions? captured_web_options;
  String? captured_nonce;
  String? captured_state;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<AuthorizationCredentialAppleID> getAppleIDCredential({
    required List<AppleIDAuthorizationScopes> scopes,
    WebAuthenticationOptions? webAuthenticationOptions,
    String? nonce,
    String? state,
  }) async {
    captured_scopes = scopes;
    captured_web_options = webAuthenticationOptions;
    captured_nonce = nonce;
    captured_state = state;
    final current_exception = exception;
    if (current_exception != null) throw current_exception;
    if (never_complete) {
      return Completer<AuthorizationCredentialAppleID>().future;
    }
    return credential;
  }
}

const _ios_challenge = AppleAuthChallenge(
  nonce: 'server-nonce',
  state: 'signed-state',
  client_id: 'com.hspark.shiftmate',
);

void main() {
  group('AppleLoginService', () {
    test('iOS에서 nonce/state를 SDK에 전달하고 서버 요청 값을 반환한다', () async {
      final sdk = _FakeAppleSignInSdk();
      final service = AppleLoginService(
        apple_sign_in_sdk: sdk,
        target_platform: TargetPlatform.iOS,
      );

      final result = await service.loginWithApple(_ios_challenge);

      expect(service.platform, AppleLoginPlatform.ios);
      expect(sdk.captured_nonce, 'server-nonce');
      expect(sdk.captured_state, 'signed-state');
      expect(sdk.captured_web_options, isNull);
      expect(sdk.captured_scopes, contains(AppleIDAuthorizationScopes.email));
      expect(
        sdk.captured_scopes,
        contains(AppleIDAuthorizationScopes.fullName),
      );
      expect(result.authorization_code, 'authorization-code');
      expect(result.identity_token, 'identity-token');
      expect(result.given_name, '길동');
      expect(result.family_name, '홍');
    });

    test('Android에서 서버가 준 Service ID와 HTTPS callback을 사용한다', () async {
      final sdk = _FakeAppleSignInSdk();
      final service = AppleLoginService(
        apple_sign_in_sdk: sdk,
        target_platform: TargetPlatform.android,
      );
      final challenge = AppleAuthChallenge(
        nonce: 'server-nonce',
        state: 'signed-state',
        client_id: 'com.hspark.shiftmate.android',
        redirect_uri: Uri.parse(
          'https://stage-api.shiftmate.co.kr/api/v1/auth/apple/callback',
        ),
      );

      final result = await service.loginWithApple(challenge);

      expect(result.platform, AppleLoginPlatform.android);
      expect(
        sdk.captured_web_options?.clientId,
        'com.hspark.shiftmate.android',
      );
      expect(
        sdk.captured_web_options?.redirectUri,
        Uri.parse(
          'https://stage-api.shiftmate.co.kr/api/v1/auth/apple/callback',
        ),
      );
    });

    test('서버 challenge와 다른 state는 서버 요청 전에 거부한다', () async {
      final sdk = _FakeAppleSignInSdk()
        ..credential = const AuthorizationCredentialAppleID(
          userIdentifier: 'apple-user-id',
          givenName: null,
          familyName: null,
          authorizationCode: 'authorization-code',
          email: null,
          identityToken: 'identity-token',
          state: 'different-state',
        );
      final service = AppleLoginService(
        apple_sign_in_sdk: sdk,
        target_platform: TargetPlatform.iOS,
      );

      expect(
        () => service.loginWithApple(_ios_challenge),
        throwsA(isA<AppleLoginSecurityException>()),
      );
    });

    test('사용자 취소를 별도 취소 예외로 변환한다', () async {
      final sdk = _FakeAppleSignInSdk()
        ..exception = const SignInWithAppleAuthorizationException(
          code: AuthorizationErrorCode.canceled,
          message: 'cancelled',
        );
      final service = AppleLoginService(
        apple_sign_in_sdk: sdk,
        target_platform: TargetPlatform.iOS,
      );

      expect(
        () => service.loginWithApple(_ios_challenge),
        throwsA(isA<AppleLoginCanceledException>()),
      );
    });

    test('지원되지 않는 기기에서는 Apple 인증 화면을 열지 않는다', () async {
      final sdk = _FakeAppleSignInSdk()..available = false;
      final service = AppleLoginService(
        apple_sign_in_sdk: sdk,
        target_platform: TargetPlatform.iOS,
      );

      expect(
        () => service.loginWithApple(_ios_challenge),
        throwsA(isA<AppleLoginUnavailableException>()),
      );
    });

    test('Android 브라우저가 복귀하지 않으면 제한시간 후 재시도 오류를 반환한다', () async {
      final sdk = _FakeAppleSignInSdk()..never_complete = true;
      final service = AppleLoginService(
        apple_sign_in_sdk: sdk,
        target_platform: TargetPlatform.android,
        android_login_timeout: const Duration(milliseconds: 1),
      );
      final challenge = AppleAuthChallenge(
        nonce: 'server-nonce',
        state: 'signed-state',
        client_id: 'com.hspark.shiftmate.android',
        redirect_uri: Uri.parse(
          'https://stage-api.shiftmate.co.kr/api/v1/auth/apple/callback',
        ),
      );

      expect(
        () => service.loginWithApple(challenge),
        throwsA(
          isA<AppleLoginUnavailableException>().having(
            (error) => error.message,
            'message',
            contains('시간이 만료'),
          ),
        ),
      );
    });
  });
}
