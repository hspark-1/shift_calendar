import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/token_service.dart';
import '../../domain/entities/user.dart';
import '../datasources/auth_remote_datasource.dart';

/// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDatasource = ref.watch(authRemoteDataSourceProvider);
  final tokenService = ref.watch(tokenServiceProvider);
  return AuthRepositoryImpl(remoteDatasource, tokenService);
});

/// 인증 Repository 인터페이스
abstract class AuthRepository {
  /// 카카오 로그인 (SDK + 서버 인증)
  Future<AuthResponse> loginWithKakao();

  /// 토큰 갱신
  Future<AuthToken> refreshToken();

  /// 프로필 조회
  Future<User> getProfile();

  /// 프로필 수정
  Future<User> updateProfile({
    String? name,
    String? timezone,
    String? profile_image_url,
  });

  /// 로그아웃
  Future<void> logout();

  /// 토큰 유효성 확인
  Future<bool> isLoggedIn();

  /// 저장된 Access Token 조회
  Future<String?> getAccessToken();
}

/// 인증 Repository 구현체
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote_datasource;
  final TokenService _token_service;

  AuthRepositoryImpl(this._remote_datasource, this._token_service);

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
  }) async {
    return await _remote_datasource.updateProfile(
      name: name,
      timezone: timezone,
      profile_image_url: profile_image_url,
    );
  }

  @override
  Future<void> logout() async {
    try {
      // 서버 로그아웃 (현재 기기)
      final refreshToken = await _token_service.getRefreshToken();
      if (refreshToken != null) {
        await _remote_datasource.logout(refreshToken);
      }
    } catch (e) {
      // 서버 오류가 발생해도 로컬 토큰은 삭제
    }

    // 카카오 로그아웃
    await _remote_datasource.logoutKakao();

    // 저장된 토큰 삭제
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
