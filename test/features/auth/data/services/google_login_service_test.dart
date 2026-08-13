// ignore_for_file: non_constant_identifier_names

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shift_mate/features/auth/data/services/google_login_service.dart';

class _FakeGoogleSignInSdk implements GoogleSignInSdk {
  int initialize_count = 0;
  int authenticate_count = 0;
  int sign_out_count = 0;
  int disconnect_count = 0;
  String? client_id;
  String? server_client_id;
  bool supports_authenticate = true;
  String? id_token = 'google-id-token';
  Object? initialize_error;
  Object? authenticate_error;

  @override
  Future<void> initialize({String? clientId, String? serverClientId}) async {
    initialize_count += 1;
    client_id = clientId;
    server_client_id = serverClientId;
    final current_error = initialize_error;
    if (current_error != null) throw current_error;
  }

  @override
  bool supportsAuthenticate() => supports_authenticate;

  @override
  Future<String?> authenticateAndGetIdToken() async {
    authenticate_count += 1;
    final current_error = authenticate_error;
    if (current_error != null) throw current_error;
    return id_token;
  }

  @override
  Future<void> signOut() async {
    sign_out_count += 1;
  }

  @override
  Future<void> disconnect() async {
    disconnect_count += 1;
  }
}

void main() {
  group('GoogleLoginService', () {
    test('Android는 serverClientId를 전달하고 ID Token을 반환한다', () async {
      final sdk = _FakeGoogleSignInSdk();
      final service = GoogleLoginService(
        google_sign_in_sdk: sdk,
        target_platform: TargetPlatform.android,
        server_client_id: 'server-client-id',
      );

      final id_token = await service.loginWithGoogle();

      expect(id_token, 'google-id-token');
      expect(sdk.initialize_count, 1);
      expect(sdk.client_id, isNull);
      expect(sdk.server_client_id, 'server-client-id');
      expect(sdk.authenticate_count, 1);
    });

    test('iOS는 iOS clientId와 serverClientId를 모두 전달한다', () async {
      final sdk = _FakeGoogleSignInSdk();
      final service = GoogleLoginService(
        google_sign_in_sdk: sdk,
        target_platform: TargetPlatform.iOS,
        ios_client_id: 'ios-client-id',
        server_client_id: 'server-client-id',
      );

      await service.loginWithGoogle();

      expect(sdk.client_id, 'ios-client-id');
      expect(sdk.server_client_id, 'server-client-id');
    });

    test('로그인과 로그아웃을 반복해도 SDK는 정확히 한 번 초기화한다', () async {
      final sdk = _FakeGoogleSignInSdk();
      final service = GoogleLoginService(
        google_sign_in_sdk: sdk,
        target_platform: TargetPlatform.android,
        server_client_id: 'server-client-id',
      );

      await service.loginWithGoogle();
      await service.loginWithGoogle();
      await service.logout();

      expect(sdk.initialize_count, 1);
      expect(sdk.authenticate_count, 2);
      expect(sdk.sign_out_count, 1);
    });

    test('회원 탈퇴용 연결 해제를 Google SDK에 위임한다', () async {
      final sdk = _FakeGoogleSignInSdk();
      final service = GoogleLoginService(
        google_sign_in_sdk: sdk,
        target_platform: TargetPlatform.android,
        server_client_id: 'server-client-id',
      );

      await service.disconnect();

      expect(sdk.initialize_count, 1);
      expect(sdk.disconnect_count, 1);
    });

    test('ID Token이 없으면 사용자용 오류로 변환한다', () async {
      final sdk = _FakeGoogleSignInSdk()..id_token = '  ';
      final service = GoogleLoginService(
        google_sign_in_sdk: sdk,
        target_platform: TargetPlatform.android,
        server_client_id: 'server-client-id',
      );

      expect(
        service.loginWithGoogle,
        throwsA(
          isA<GoogleLoginUnavailableException>().having(
            (error) => error.message,
            'message',
            contains('ID Token'),
          ),
        ),
      );
    });

    test('사용자 취소는 별도 예외로 변환한다', () async {
      final sdk = _FakeGoogleSignInSdk()
        ..authenticate_error = const GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
        );
      final service = GoogleLoginService(
        google_sign_in_sdk: sdk,
        target_platform: TargetPlatform.android,
        server_client_id: 'server-client-id',
      );

      expect(
        service.loginWithGoogle,
        throwsA(isA<GoogleLoginCanceledException>()),
      );
    });

    test('SDK 설정 오류는 credential을 노출하지 않는 사용자용 오류로 변환한다', () async {
      final sdk = _FakeGoogleSignInSdk()
        ..initialize_error = const GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
          description: 'secret-client-configuration',
        );
      final service = GoogleLoginService(
        google_sign_in_sdk: sdk,
        target_platform: TargetPlatform.iOS,
        ios_client_id: 'ios-client-id',
        server_client_id: 'server-client-id',
      );

      await expectLater(
        service.loginWithGoogle(),
        throwsA(
          isA<GoogleLoginUnavailableException>()
              .having(
                (error) => error.message,
                'message',
                contains('설정이 올바르지 않습니다'),
              )
              .having(
                (error) => error.message,
                'message',
                isNot(contains('secret-client-configuration')),
              ),
        ),
      );
    });

    test('필수 client ID가 없으면 SDK를 호출하지 않고 설정 오류를 반환한다', () async {
      final sdk = _FakeGoogleSignInSdk();
      final service = GoogleLoginService(
        google_sign_in_sdk: sdk,
        target_platform: TargetPlatform.iOS,
        server_client_id: 'server-client-id',
      );

      expect(
        service.loginWithGoogle,
        throwsA(isA<GoogleLoginUnavailableException>()),
      );
      expect(sdk.initialize_count, 0);
      expect(sdk.authenticate_count, 0);
    });
  });
}
