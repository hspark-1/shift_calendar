import 'package:dio/dio.dart';
import 'api_exception.dart';

/// DioException을 ApiException으로 변환하는 유틸리티
Exception handleApiError(DioException error) {
  if (error.response != null) {
    final data = error.response!.data;
    if (data is Map<String, dynamic> && data.containsKey('error')) {
      final errorData = data['error'] as Map<String, dynamic>;
      return ApiException(
        code: errorData['code'] as String? ?? 'UNKNOWN_ERROR',
        message: errorData['message'] as String? ?? '알 수 없는 오류가 발생했습니다.',
        statusCode: error.response!.statusCode,
      );
    }

    // 에러 응답이 있지만 형식이 다른 경우
    return ApiException(
      code: 'HTTP_ERROR',
      message: data is Map<String, dynamic> && data.containsKey('message')
          ? data['message'] as String
          : '서버 오류가 발생했습니다.',
      statusCode: error.response!.statusCode,
    );
  }

  // 네트워크 오류 등
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout) {
    return ApiException(
      code: 'TIMEOUT_ERROR',
      message: '요청 시간이 초과되었습니다.',
      statusCode: null,
    );
  }

  if (error.type == DioExceptionType.connectionError) {
    return ApiException(
      code: 'NETWORK_ERROR',
      message: '네트워크 연결을 확인해주세요.',
      statusCode: null,
    );
  }

  return ApiException(
    code: 'UNKNOWN_ERROR',
    message: '알 수 없는 오류가 발생했습니다.',
    statusCode: null,
  );
}

