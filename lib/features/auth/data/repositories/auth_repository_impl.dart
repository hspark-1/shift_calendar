// ignore_for_file: non_constant_identifier_names

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/token_service.dart';
import '../../../../core/push/installation_id_service.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/profile_image_upload.dart';
import '../datasources/auth_remote_datasource.dart';
import '../services/apple_login_service.dart';
import '../services/google_login_service.dart';
import '../services/naver_login_service.dart';

/// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDatasource = ref.watch(authRemoteDataSourceProvider);
  final tokenService = ref.watch(tokenServiceProvider);
  final installation_id_service = ref.watch(installationIdServiceProvider);
  return AuthRepositoryImpl(
    remoteDatasource,
    tokenService,
    installation_id_service: installation_id_service,
  );
});

/// 인증 Repository 인터페이스
abstract class AuthRepository {
  /// 카카오 로그인 (SDK + 서버 인증)
  Future<AuthResponse> loginWithKakao();

  /// 네이버 로그인 (네이티브 SDK + 서버 인증)
  Future<AuthResponse> loginWithNaver();

  /// Google 로그인 (ID Token + 서버 인증)
  Future<AuthResponse> loginWithGoogle();

  /// Apple 로그인 (challenge + SDK + 서버 인증)
  Future<AuthResponse> loginWithApple();

  /// 토큰 갱신
  Future<AuthToken> refreshToken();

  /// 프로필 조회
  Future<User> getProfile();

  /// 프로필 수정
  Future<User> updateProfile({
    String? name,
    String? timezone,
    String? profile_image_url,
    String? phone,
    String? job_type,
    String? workplace,
  });

  /// 신규 가입 필수·선택 프로필을 원자적으로 저장하고 완료 처리
  Future<User> completeProfile({
    required String name,
    required String timezone,
    required String phone,
    ProfileImageUpload? profile_image,
    String? job_type,
    String? workplace,
  });

  /// 로그아웃
  Future<void> logout();

  /// 회원 탈퇴 접수
  Future<void> deleteAccount(User user);

  /// 토큰 유효성 확인
  Future<bool> isLoggedIn();

  /// 저장된 Access Token 조회
  Future<String?> getAccessToken();
}

/// 인증 Repository 구현체
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote_datasource;
  final TokenService _token_service;
  final NaverLoginService _naver_login_service;
  final GoogleLoginService _google_login_service;
  final AppleLoginService _apple_login_service;
  final InstallationIdService _installation_id_service;

  AuthRepositoryImpl(
    this._remote_datasource,
    this._token_service, {
    NaverLoginService? naver_login_service,
    GoogleLoginService? google_login_service,
    AppleLoginService? apple_login_service,
    InstallationIdService? installation_id_service,
  }) : _naver_login_service = naver_login_service ?? NaverLoginService(),
       _google_login_service = google_login_service ?? GoogleLoginService(),
       _apple_login_service = apple_login_service ?? AppleLoginService(),
       _installation_id_service =
           installation_id_service ?? InstallationIdService();

  @override
  Future<AuthResponse> loginWithKakao() async {
    // 1. 카카오 SDK 로그인
    final kakaoToken = await _remote_datasource.loginWithKakaoSdk();

    // 2. 서버 인증
    final authResponse = await _remote_datasource.loginWithKakaoToken(
      kakaoToken.accessToken,
    );

    // 3. 토큰 저장
    await _token_service.saveTokens(
      access_token: authResponse.access_token,
      refresh_token: authResponse.refresh_token,
      expires_at: authResponse.expires_at,
    );

    return authResponse;
  }

  @override
  Future<AuthResponse> loginWithNaver() async {
    // 1. 네이버 네이티브 SDK 로그인
    final naverAccessToken = await _naver_login_service.loginWithNaver();

    // 2. 서버 인증
    final authResponse = await _remote_datasource.loginWithNaverToken(
      naverAccessToken,
    );

    // 3. 토큰 저장
    await _token_service.saveTokens(
      access_token: authResponse.access_token,
      refresh_token: authResponse.refresh_token,
      expires_at: authResponse.expires_at,
    );

    return authResponse;
  }

  @override
  Future<AuthResponse> loginWithGoogle() async {
    // 1. Google SDK에서 서버 audience용 ID Token을 가져온다.
    final google_id_token = await _google_login_service.loginWithGoogle();

    try {
      // 2. 서버가 ID Token을 검증하고 앱 세션을 발급한다.
      final authResponse = await _remote_datasource.loginWithGoogleIdToken(
        google_id_token,
      );

      // 3. 서버 인증 성공 후에만 앱 JWT를 저장한다.
      await _token_service.saveTokens(
        access_token: authResponse.access_token,
        refresh_token: authResponse.refresh_token,
        expires_at: authResponse.expires_at,
      );

      return authResponse;
    } catch (_) {
      try {
        await _google_login_service.logout();
      } catch (_) {
        // 서버 교환 실패가 원본 오류이며 Google 로컬 정리 실패로 덮어쓰지 않는다.
      }
      rethrow;
    }
  }

  @override
  Future<AuthResponse> loginWithApple() async {
    // 1. 서버가 플랫폼별 client ID와 일회성 nonce/state를 확정한다.
    final challenge = await _remote_datasource.createAppleChallenge(
      _apple_login_service.platform,
    );

    // 2. Apple 네이티브/웹 인증 결과를 challenge와 대조한다.
    final credential = await _apple_login_service.loginWithApple(challenge);

    // 3. 서버가 Apple code/token을 검증하고 앱 세션을 발급한다.
    final authResponse = await _remote_datasource.loginWithApple(credential);

    await _token_service.saveTokens(
      access_token: authResponse.access_token,
      refresh_token: authResponse.refresh_token,
      expires_at: authResponse.expires_at,
    );

    return authResponse;
  }

  @override
  Future<AuthToken> refreshToken() async {
    final refreshToken = await _token_service.getRefreshToken();
    if (refreshToken == null) {
      throw Exception('Refresh token이 없습니다.');
    }

    final newToken = await _remote_datasource.refreshToken(refreshToken);

    // 새 토큰 저장
    await _token_service.saveTokens(
      access_token: newToken.access_token,
      refresh_token: newToken.refresh_token,
      expires_at: newToken.expires_at,
    );

    return newToken;
  }

  @override
  Future<User> getProfile() async {
    return await _remote_datasource.getProfile();
  }

  @override
  Future<User> updateProfile({
    String? name,
    String? timezone,
    String? profile_image_url,
    String? phone,
    String? job_type,
    String? workplace,
  }) async {
    return await _remote_datasource.updateProfile(
      name: name,
      timezone: timezone,
      profile_image_url: profile_image_url,
      phone: phone,
      job_type: job_type,
      workplace: workplace,
    );
  }

  @override
  Future<User> completeProfile({
    required String name,
    required String timezone,
    required String phone,
    ProfileImageUpload? profile_image,
    String? job_type,
    String? workplace,
  }) async {
    return await _remote_datasource.completeProfile(
      name: name,
      timezone: timezone,
      phone: phone,
      profile_image: profile_image,
      job_type: job_type,
      workplace: workplace,
    );
  }

  @override
  Future<void> logout() async {
    try {
      // 서버 로그아웃 (현재 기기)
      final refreshToken = await _token_service.getRefreshToken();
      if (refreshToken != null) {
        final installation_id = await _installation_id_service.getOrCreate();
        await _remote_datasource.logout(refreshToken, installation_id);
      }
    } catch (e) {
      // 서버 오류가 발생해도 로컬 토큰은 삭제
    }

    try {
      // 카카오 SDK 로그아웃
      await _remote_datasource.logoutKakao();
    } catch (e) {
      // 소셜 SDK 오류가 발생해도 로컬 토큰은 삭제
    }

    try {
      // 네이버 SDK 로그아웃
      await _naver_login_service.logout();
    } catch (e) {
      // 소셜 SDK 오류가 발생해도 로컬 토큰은 삭제
    }

    try {
      // Google SDK 로그아웃
      await _google_login_service.logout();
    } catch (e) {
      // 소셜 SDK 오류가 발생해도 로컬 토큰은 삭제
    }

    // 저장된 토큰 삭제
    await _token_service.clearTokens();
  }

  @override
  Future<void> deleteAccount(User user) async {
    // 서버가 해제용 토큰을 보관하지 않는 provider는 요청 전에 해제한다.
    if (user.google_id != null && user.google_id!.isNotEmpty) {
      await _google_login_service.disconnect();
    }
    await _naver_login_service.disconnect();

    try {
      await _remote_datasource.deleteAccount();
    } on ApiException catch (error) {
      if (error.statusCode == 401 ||
          error.code == 'ACCOUNT_DELETION_IN_PROGRESS') {
        await _clearLocalSession();
      }
      rethrow;
    }

    await _clearLocalSession();
  }

  Future<void> _clearLocalSession() async {
    try {
      await _remote_datasource.logoutKakao();
    } catch (_) {
      // 서버 접수 후 SDK 정리 실패가 로컬 JWT 삭제를 막지 않는다.
    }
    try {
      await _naver_login_service.logout();
    } catch (_) {}
    try {
      await _google_login_service.logout();
    } catch (_) {}
    await _token_service.clearTokens();
  }

  @override
  Future<bool> isLoggedIn() async {
    // 토큰이 있고 유효한지 확인
    final hasTokens = await _token_service.hasTokens();
    if (!hasTokens) return false;

    final isValid = await _token_service.isTokenValid();
    if (isValid) return true;

    // 토큰이 만료되었으면 갱신 시도
    try {
      await refreshToken();
      return true;
    } catch (e) {
      // 갱신 실패 시 로그아웃 상태
      await _token_service.clearTokens();
      return false;
    }
  }

  @override
  Future<String?> getAccessToken() async {
    return await _token_service.getAccessToken();
  }
}
