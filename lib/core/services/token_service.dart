import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 토큰 저장 키
class _TokenKeys {
  static const String access_token = 'access_token';
  static const String refresh_token = 'refresh_token';
  static const String expires_at = 'expires_at';
}

/// 토큰 서비스 Provider
final tokenServiceProvider = Provider<TokenService>((ref) {
  return TokenService();
});

/// JWT 토큰 저장/조회/삭제 서비스
class TokenService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Access Token 저장
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _TokenKeys.access_token, value: token);
  }

  /// Refresh Token 저장
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _TokenKeys.refresh_token, value: token);
  }

  /// 만료 시간 저장
  Future<void> saveExpiresAt(DateTime expiresAt) async {
    await _storage.write(
      key: _TokenKeys.expires_at,
      value: expiresAt.toIso8601String(),
    );
  }

  /// 모든 토큰 저장
  Future<void> saveTokens({
    required String access_token,
    required String refresh_token,
    required DateTime expires_at,
  }) async {
    await Future.wait([
      saveAccessToken(access_token),
      saveRefreshToken(refresh_token),
      saveExpiresAt(expires_at),
    ]);
  }

  /// Access Token 조회
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _TokenKeys.access_token);
  }

  /// Refresh Token 조회
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _TokenKeys.refresh_token);
  }

  /// 만료 시간 조회
  Future<DateTime?> getExpiresAt() async {
    final value = await _storage.read(key: _TokenKeys.expires_at);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  /// 토큰 유효성 확인 (만료 여부)
  Future<bool> isTokenValid() async {
    final accessToken = await getAccessToken();
    if (accessToken == null) return false;

    final expiresAt = await getExpiresAt();
    if (expiresAt == null) return false;

    // 만료 시간 1분 전부터 갱신 필요로 판단
    return expiresAt.isAfter(DateTime.now().add(const Duration(minutes: 1)));
  }

  /// 토큰 만료 여부 확인 (가이드 호환)
  Future<bool> isTokenExpired() async {
    final expiresAt = await getExpiresAt();
    if (expiresAt == null) return true;
    // 만료 1분 전부터 만료로 간주
    return DateTime.now().isAfter(
      expiresAt.subtract(const Duration(minutes: 1)),
    );
  }

  /// 토큰이 존재하는지 확인
  Future<bool> hasTokens() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return accessToken != null && refreshToken != null;
  }

  /// 모든 토큰 삭제 (로그아웃)
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _TokenKeys.access_token),
      _storage.delete(key: _TokenKeys.refresh_token),
      _storage.delete(key: _TokenKeys.expires_at),
    ]);
  }
}
