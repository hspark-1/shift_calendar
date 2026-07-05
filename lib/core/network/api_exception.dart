/// API 에러를 나타내는 예외 클래스
class ApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;

  ApiException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'ApiException(code: $code, message: $message, statusCode: $statusCode)';
}

