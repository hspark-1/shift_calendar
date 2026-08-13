// ignore_for_file: non_constant_identifier_names

/// API 에러를 나타내는 예외 클래스
class ApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;
  final String? request_id;

  ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.request_id,
  });

  @override
  String toString() =>
      'ApiException(code: $code, message: $message, statusCode: $statusCode, request_id: $request_id)';
}
