import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';

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
    dio.interceptors.add(_createAuthInterceptor());

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
  static Interceptor _createAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // TODO: 저장된 토큰을 헤더에 추가
        // final token = await SecureStorage.getToken();
        // if (token != null) {
        //   options.headers['Authorization'] = 'Bearer $token';
        // }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // 401 에러 시 토큰 갱신 처리
        if (error.response?.statusCode == 401) {
          // TODO: 토큰 갱신 로직
        }
        return handler.next(error);
      },
    );
  }
}

