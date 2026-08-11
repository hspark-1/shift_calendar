// ignore_for_file: non_constant_identifier_names

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
        debugPrint('🚀 REQUEST[${options.method}] => PATH: ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint(
          '✅ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
        );
        return handler.next(response);
      },
      onError: (error, handler) {
        debugPrint(
          '❌ ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}',
        );
        return handler.next(error);
      },
    );
  }

  /// 인증 인터셉터
  static Interceptor _createAuthInterceptor(Dio dio) {
    final tokenService = TokenService();
    Future<bool>? refresh_future;

    Future<bool> performRefresh() async {
      try {
        final refresh_token_value = await tokenService.getRefreshToken();
        if (refresh_token_value == null) return false;

        // 토큰 갱신 요청
        final response = await dio.post(
          ApiConstants.auth_refresh,
          data: {'refresh_token': refresh_token_value},
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

        if (response.data['success'] == true) {
          final data = response.data['data'] as Map<String, dynamic>;
          final new_access_token = data['access_token'] as String;
          final new_refresh_token = data['refresh_token'] as String;

          // expires_at이 int(milliseconds) 또는 String(ISO 8601)일 수 있음
          final expires_at_raw = data['expires_at'];
          final DateTime expires_at;
          if (expires_at_raw is int) {
            expires_at = DateTime.fromMillisecondsSinceEpoch(
              expires_at_raw,
              isUtc: true,
            );
          } else {
            expires_at = DateTime.parse(expires_at_raw as String);
          }

          // 새 토큰 저장
          await tokenService.saveTokens(
            access_token: new_access_token,
            refresh_token: new_refresh_token,
            expires_at: expires_at,
          );

          return true;
        }
        return false;
      } catch (e) {
        return false;
      }
    }

    Future<bool> refreshToken() {
      final in_flight = refresh_future;
      if (in_flight != null) return in_flight;

      final future = performRefresh();
      refresh_future = future;
      future.whenComplete(() {
        if (identical(refresh_future, future)) refresh_future = null;
      });
      return future;
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
        if (_isPublicEndpoint(error.requestOptions.path)) {
          return handler.next(error);
        }

        // 401 에러 시 토큰 갱신 처리
        if (error.response?.statusCode == 401) {
          if (error.requestOptions.extra['auth_retry_attempted'] == true) {
            await tokenService.clearTokens();
            return handler.next(error);
          }
          final refreshed = await refreshToken();

          if (refreshed) {
            // 원래 요청 재시도
            final options = error.requestOptions;
            final new_token = await tokenService.getAccessToken();
            if (new_token != null) {
              options.headers['Authorization'] = 'Bearer $new_token';
              options.extra['auth_retry_attempted'] = true;

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
      ApiConstants.auth_google_token,
      ApiConstants.auth_apple_challenge,
      ApiConstants.auth_apple,
      ApiConstants.auth_apple_callback,
      ApiConstants.auth_login,
      ApiConstants.auth_register,
      ApiConstants.auth_refresh,
    ];
    return publicEndpoints.contains(path);
  }
}
