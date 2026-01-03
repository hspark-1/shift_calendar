import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' hide User;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/user.dart';

/// Auth Remote DataSource Provider
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRemoteDataSource(dio);
});

/// 인증 관련 API 호출 DataSource
class AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSource(this._dio);

  /// DioException에서 에러 메시지를 안전하게 추출
  /// 서버 응답이 Map, String, 또는 null인 경우 모두 처리
  String _extractErrorMessage(DioException e, String defaultMessage) {
    final data = e.response?.data;
    if (data == null) return defaultMessage;
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ?? defaultMessage;
    }
    if (data is String && data.isNotEmpty) {
      return data;
    }
    return defaultMessage;
  }

  /// 카카오 SDK 로그인
  /// 카카오톡 설치 여부에 따라 카카오톡 또는 카카오 계정으로 로그인
  Future<OAuthToken> loginWithKakaoSdk() async {
    try {
      if (await isKakaoTalkInstalled()) {
        return await UserApi.instance.loginWithKakaoTalk();
      } else {
        return await UserApi.instance.loginWithKakaoAccount();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 카카오 access_token으로 서버 로그인
  Future<AuthResponse> loginWithKakaoToken(String kakaoAccessToken) async {
    try {
      final response = await _dio.post(
        ApiConstants.auth_kakao_token,
        data: {'access_token': kakaoAccessToken},
      );

      if (response.data['success'] == true) {
        return AuthResponse.fromJson(response.data);
      }

      throw Exception(response.data['message'] ?? '로그인에 실패했습니다.');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, '로그인에 실패했습니다.'));
    }
  }

  /// 토큰 갱신
  Future<AuthToken> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        ApiConstants.auth_refresh,
        data: {'refresh_token': refreshToken},
      );

      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;

        // expires_at이 int(milliseconds) 또는 String(ISO 8601)일 수 있음
        final expiresAtRaw = data['expires_at'];
        final DateTime expiresAt;
        if (expiresAtRaw is int) {
          expiresAt = DateTime.fromMillisecondsSinceEpoch(
            expiresAtRaw,
            isUtc: true,
          );
        } else {
          expiresAt = DateTime.parse(expiresAtRaw as String);
        }

        return AuthToken(
          access_token: data['access_token'] as String,
          refresh_token: data['refresh_token'] as String,
          expires_at: expiresAt,
        );
      }

      throw Exception(response.data['message'] ?? '토큰 갱신에 실패했습니다.');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, '토큰 갱신에 실패했습니다.'));
    }
  }

  /// 내 프로필 조회
  Future<User> getProfile() async {
    try {
      final response = await _dio.get(ApiConstants.auth_profile);

      if (response.data['success'] == true) {
        return User.fromJson(response.data['data'] as Map<String, dynamic>);
      }

      throw Exception(response.data['message'] ?? '프로필 조회에 실패했습니다.');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, '프로필 조회에 실패했습니다.'));
    }
  }

  /// 프로필 수정
  Future<User> updateProfile({
    String? name,
    String? timezone,
    String? profile_image_url,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (timezone != null) data['timezone'] = timezone;
      if (profile_image_url != null) {
        data['profile_image_url'] = profile_image_url;
      }

      final response = await _dio.patch(ApiConstants.auth_profile, data: data);

      if (response.data['success'] == true) {
        return User.fromJson(response.data['data'] as Map<String, dynamic>);
      }

      throw Exception(response.data['message'] ?? '프로필 수정에 실패했습니다.');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, '프로필 수정에 실패했습니다.'));
    }
  }

  /// 카카오 로그아웃
  Future<void> logoutKakao() async {
    try {
      await UserApi.instance.logout();
    } catch (e) {
      // 카카오 로그아웃 실패해도 앱 로그아웃은 진행
    }
  }

  /// 로그아웃 (현재 기기)
  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post(
        ApiConstants.auth_logout,
        data: {'refresh_token': refreshToken},
      );
    } on DioException catch (e) {
      // 서버 오류가 발생해도 로컬 토큰은 삭제
      throw Exception(_extractErrorMessage(e, '로그아웃에 실패했습니다.'));
    }
  }

  /// 로그아웃 (모든 기기)
  Future<void> logoutAll() async {
    try {
      await _dio.post(ApiConstants.auth_logout_all);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, '전체 로그아웃에 실패했습니다.'));
    }
  }
}
