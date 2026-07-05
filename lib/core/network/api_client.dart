import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_constants.dart';
import '../services/token_service.dart';

/// Dio 인스턴스 Provider
final dioProvider = Provider<Dio>((ref) {
  return ApiClient.createDio();
});

/// API 클라이언트 설정
class ApiClient {
  ApiClient._();

  /// Dio 인스턴스 생성
  static Dio createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.base_url,
        connectTimeout: Duration(seconds: ApiConstants.connection_timeout),
        receiveTimeout: Duration(seconds: ApiConstants.receive_timeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // 인터셉터 추가
    dio.interceptors.add(_createLogInterceptor());
    dio.interceptors.add(_createAuthInterceptor(dio));

    return dio;
  }

  /// 로깅 인터셉터
  static Interceptor _createLogInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        print('🚀 REQUEST[${options.method}] => PATH: ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print(
          '✅ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
        );
        return handler.next(response);
      },
      onError: (error, handler) {
        print(
          '❌ ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}',
        );
        return handler.next(error);
      },
    );
  }

  /// 인증 인터셉터
  static Interceptor _createAuthInterceptor(Dio dio) {
    final tokenService = TokenService();
    bool isRefreshing = false;

    Future<bool> refreshToken() async {
      if (isRefreshing) return false;
      isRefreshing = true;

      try {
        final refreshTokenValue = await tokenService.getRefreshToken();
        if (refreshTokenValue == null) {
          isRefreshing = false;
          return false;
        }

        // 토큰 갱신 요청
        final response = await dio.post(
          ApiConstants.auth_refresh,
          data: {'refresh_token': refreshTokenValue},
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

        if (response.data['success'] == true) {
          final data = response.data['data'] as Map<String, dynamic>;
          final newAccessToken = data['access_token'] as String;
          final newRefreshToken = data['refresh_token'] as String;

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

          // 새 토큰 저장
          await tokenService.saveTokens(
            access_token: newAccessToken,
            refresh_token: newRefreshToken,
            expires_at: expiresAt,
          );

          isRefreshing = false;
          return true;
        }
        isRefreshing = false;
        return false;
      } catch (e) {
        isRefreshing = false;
        return false;
      }
    }

    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 인증이 필요없는 엔드포인트는 스킵
        if (_isPublicEndpoint(options.path)) {
          return handler.next(options);
        }

        // 만료 임박 시 미리 갱신
        if (await tokenService.isTokenExpired()) {
          await refreshToken();
        }

        // 저장된 토큰을 헤더에 추가
        final token = await tokenService.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // 401 에러 시 토큰 갱신 처리
        if (error.response?.statusCode == 401) {
          final refreshed = await refreshToken();

          if (refreshed) {
            // 원래 요청 재시도
            final options = error.requestOptions;
            final newToken = await tokenService.getAccessToken();
            if (newToken != null) {
              options.headers['Authorization'] = 'Bearer $newToken';

              try {
                final retryResponse = await dio.fetch(options);
                return handler.resolve(retryResponse);
              } catch (e) {
                return handler.next(error);
              }
            }
          } else {
            // 갱신 실패 → 로그아웃 처리 (토큰 삭제)
            await tokenService.clearTokens();
          }
        }
        return handler.next(error);
      },
    );
  }

  /// 인증이 필요없는 엔드포인트인지 확인
  static bool _isPublicEndpoint(String path) {
    const publicEndpoints = [
      ApiConstants.auth_kakao_token,
      ApiConstants.auth_naver_token,
      ApiConstants.auth_login,
      ApiConstants.auth_register,
      ApiConstants.auth_refresh,
    ];
    return publicEndpoints.contains(path);
  }
}
