// ignore_for_file: non_constant_identifier_names

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart'
    show OAuthToken;
import 'package:shift_mate/core/services/token_service.dart';
import 'package:shift_mate/core/network/api_exception.dart';
import 'package:shift_mate/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:shift_mate/features/auth/data/models/apple_auth_models.dart';
import 'package:shift_mate/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:shift_mate/features/auth/data/services/apple_login_service.dart';
import 'package:shift_mate/features/auth/data/services/google_login_service.dart';
import 'package:shift_mate/features/auth/data/services/naver_login_service.dart';
import 'package:shift_mate/features/auth/domain/entities/user.dart';

class _FakeAuthRemoteDataSource extends AuthRemoteDataSource {
  _FakeAuthRemoteDataSource() : super(Dio());

  AppleLoginPlatform? challenge_platform;
  AppleLoginCredential? login_credential;
  String? google_id_token;
  Object? google_login_error;
  String? kakao_access_token;
  int kakao_logout_count = 0;
  int delete_account_count = 0;
  Object? delete_account_error;

  final challenge = const AppleAuthChallenge(
    nonce: 'server-nonce',
    state: 'signed-state',
    client_id: 'com.hspark.shiftmate',
  );

  final response = AuthResponse(
    user: const User(
      id: 'apple-user-id',
      email: 'user@example.com',
      name: 'Apple 사용자',
      apple_id: 'apple-subject',
      google_id: 'google-subject',
    ),
    access_token: 'app-access-token',
    refresh_token: 'app-refresh-token',
    expires_at: DateTime.utc(2026, 8, 7),
    requires_profile_setup: true,
  );

  @override
  Future<OAuthToken> loginWithKakaoSdk() async {
    return OAuthToken(
      'kakao-sdk-access-token',
      DateTime.utc(2026, 8, 17),
      'kakao-sdk-refresh-token',
      DateTime.utc(2026, 9, 17),
      const ['account_email', 'profile_nickname'],
    );
  }

  @override
  Future<AuthResponse> loginWithKakaoToken(String kakaoAccessToken) async {
    kakao_access_token = kakaoAccessToken;
    return response;
  }

  @override
  Future<AppleAuthChallenge> createAppleChallenge(
    AppleLoginPlatform platform,
  ) async {
    challenge_platform = platform;
    return challenge;
  }

  @override
  Future<AuthResponse> loginWithApple(AppleLoginCredential credential) async {
    login_credential = credential;
    return response;
  }

  @override
  Future<AuthResponse> loginWithGoogleIdToken(String googleIdToken) async {
    google_id_token = googleIdToken;
    final current_error = google_login_error;
    if (current_error != null) throw current_error;
    return response;
  }

  @override
  Future<void> logoutKakao() async {
    kakao_logout_count += 1;
  }

  @override
  Future<void> deleteAccount() async {
    delete_account_count += 1;
    final current_error = delete_account_error;
    if (current_error != null) throw current_error;
  }
}

class _FakeAppleLoginService extends AppleLoginService {
  AppleAuthChallenge? received_challenge;

  final result = const AppleLoginCredential(
    platform: AppleLoginPlatform.ios,
    authorization_code: 'authorization-code',
    identity_token: 'identity-token',
    state: 'signed-state',
    nonce: 'server-nonce',
  );

  @override
  AppleLoginPlatform get platform => AppleLoginPlatform.ios;

  @override
  Future<AppleLoginCredential> loginWithApple(
    AppleAuthChallenge challenge,
  ) async {
    received_challenge = challenge;
    return result;
  }
}

class _FakeTokenService extends TokenService {
  String? access_token;
  String? refresh_token;
  DateTime? expires_at;
  int save_count = 0;
  int clear_count = 0;

  @override
  Future<void> saveTokens({
    required String access_token,
    required String refresh_token,
    required DateTime expires_at,
  }) async {
    save_count += 1;
    this.access_token = access_token;
    this.refresh_token = refresh_token;
    this.expires_at = expires_at;
  }

  @override
  Future<String?> getRefreshToken() async => null;

  @override
  Future<void> clearTokens() async {
    clear_count += 1;
  }
}

class _FakeGoogleLoginService extends GoogleLoginService {
  String id_token = 'google-id-token';
  Object? login_error;
  int login_count = 0;
  int logout_count = 0;
  int disconnect_count = 0;

  @override
  Future<String> loginWithGoogle() async {
    login_count += 1;
    final current_error = login_error;
    if (current_error != null) throw current_error;
    return id_token;
  }

  @override
  Future<void> logout() async {
    logout_count += 1;
  }

  @override
  Future<void> disconnect() async {
    disconnect_count += 1;
  }
}

class _FakeNaverLoginService extends NaverLoginService {
  int logout_count = 0;
  int disconnect_count = 0;

  @override
  Future<void> logout() async {
    logout_count += 1;
  }

  @override
  Future<void> disconnect() async {
    disconnect_count += 1;
  }
}

void main() {
  test('카카오 SDK Access Token을 서버에 전달한 뒤 앱 JWT를 저장한다', () async {
    final remote_data_source = _FakeAuthRemoteDataSource();
    final token_service = _FakeTokenService();
    final repository = AuthRepositoryImpl(remote_data_source, token_service);

    final response = await repository.loginWithKakao();

    expect(remote_data_source.kakao_access_token, 'kakao-sdk-access-token');
    expect(response.access_token, 'app-access-token');
    expect(token_service.save_count, 1);
    expect(token_service.access_token, 'app-access-token');
    expect(token_service.refresh_token, 'app-refresh-token');
  });

  test('Apple challenge, SDK, 서버 검증 후 앱 JWT를 저장한다', () async {
    final remote_data_source = _FakeAuthRemoteDataSource();
    final apple_login_service = _FakeAppleLoginService();
    final token_service = _FakeTokenService();
    final repository = AuthRepositoryImpl(
      remote_data_source,
      token_service,
      apple_login_service: apple_login_service,
    );

    final response = await repository.loginWithApple();

    expect(remote_data_source.challenge_platform, AppleLoginPlatform.ios);
    expect(
      apple_login_service.received_challenge,
      same(remote_data_source.challenge),
    );
    expect(
      remote_data_source.login_credential,
      same(apple_login_service.result),
    );
    expect(response.user.apple_id, 'apple-subject');
    expect(token_service.access_token, 'app-access-token');
    expect(token_service.refresh_token, 'app-refresh-token');
    expect(token_service.expires_at, DateTime.utc(2026, 8, 7));
  });

  test('Google ID Token 서버 검증 성공 후에만 앱 JWT를 저장한다', () async {
    final remote_data_source = _FakeAuthRemoteDataSource();
    final google_login_service = _FakeGoogleLoginService();
    final token_service = _FakeTokenService();
    final repository = AuthRepositoryImpl(
      remote_data_source,
      token_service,
      google_login_service: google_login_service,
    );

    final response = await repository.loginWithGoogle();

    expect(google_login_service.login_count, 1);
    expect(remote_data_source.google_id_token, 'google-id-token');
    expect(response.user.google_id, 'google-subject');
    expect(token_service.save_count, 1);
    expect(token_service.access_token, 'app-access-token');
    expect(token_service.refresh_token, 'app-refresh-token');
  });

  test('Google 서버 토큰 교환 실패 시 JWT를 저장하지 않고 Google 세션을 정리한다', () async {
    final remote_data_source = _FakeAuthRemoteDataSource()
      ..google_login_error = Exception('서버 검증 실패');
    final google_login_service = _FakeGoogleLoginService();
    final token_service = _FakeTokenService();
    final repository = AuthRepositoryImpl(
      remote_data_source,
      token_service,
      google_login_service: google_login_service,
    );

    await expectLater(
      repository.loginWithGoogle(),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('서버 검증 실패'),
        ),
      ),
    );

    expect(token_service.save_count, 0);
    expect(google_login_service.logout_count, 1);
  });

  test('앱 로그아웃은 Google 로컬 세션과 앱 JWT를 함께 정리한다', () async {
    final remote_data_source = _FakeAuthRemoteDataSource();
    final google_login_service = _FakeGoogleLoginService();
    final naver_login_service = _FakeNaverLoginService();
    final token_service = _FakeTokenService();
    final repository = AuthRepositoryImpl(
      remote_data_source,
      token_service,
      google_login_service: google_login_service,
      naver_login_service: naver_login_service,
    );

    await repository.logout();

    expect(remote_data_source.kakao_logout_count, 1);
    expect(naver_login_service.logout_count, 1);
    expect(google_login_service.logout_count, 1);
    expect(token_service.clear_count, 1);
  });

  test('Google·Naver 연결 해제 후 탈퇴 API를 접수하고 로컬 세션을 정리한다', () async {
    final remote_data_source = _FakeAuthRemoteDataSource();
    final google_login_service = _FakeGoogleLoginService();
    final naver_login_service = _FakeNaverLoginService();
    final token_service = _FakeTokenService();
    final repository = AuthRepositoryImpl(
      remote_data_source,
      token_service,
      google_login_service: google_login_service,
      naver_login_service: naver_login_service,
    );

    await repository.deleteAccount(remote_data_source.response.user);

    expect(google_login_service.disconnect_count, 1);
    expect(naver_login_service.disconnect_count, 1);
    expect(remote_data_source.delete_account_count, 1);
    expect(remote_data_source.kakao_logout_count, 1);
    expect(naver_login_service.logout_count, 1);
    expect(google_login_service.logout_count, 1);
    expect(token_service.clear_count, 1);
  });

  test('재인증 필요 오류에서는 앱 JWT와 인증 상태를 유지한다', () async {
    final remote_data_source = _FakeAuthRemoteDataSource()
      ..delete_account_error = ApiException(
        code: 'REAUTHENTICATION_REQUIRED',
        message: '다시 로그인해주세요.',
        statusCode: 403,
      );
    final token_service = _FakeTokenService();
    final repository = AuthRepositoryImpl(
      remote_data_source,
      token_service,
      google_login_service: _FakeGoogleLoginService(),
      naver_login_service: _FakeNaverLoginService(),
    );

    await expectLater(
      repository.deleteAccount(remote_data_source.response.user),
      throwsA(
        isA<ApiException>().having(
          (error) => error.code,
          'code',
          'REAUTHENTICATION_REQUIRED',
        ),
      ),
    );

    expect(token_service.clear_count, 0);
  });

  test('이미 탈퇴 처리 중이면 로컬 세션을 정리한다', () async {
    final remote_data_source = _FakeAuthRemoteDataSource()
      ..delete_account_error = ApiException(
        code: 'ACCOUNT_DELETION_IN_PROGRESS',
        message: '회원 탈퇴가 처리 중입니다.',
        statusCode: 409,
      );
    final token_service = _FakeTokenService();
    final repository = AuthRepositoryImpl(
      remote_data_source,
      token_service,
      google_login_service: _FakeGoogleLoginService(),
      naver_login_service: _FakeNaverLoginService(),
    );

    await expectLater(
      repository.deleteAccount(remote_data_source.response.user),
      throwsA(isA<ApiException>()),
    );

    expect(token_service.clear_count, 1);
  });
}
