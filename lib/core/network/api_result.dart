import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_result.freezed.dart';

/// API 응답 결과를 나타내는 sealed class
@freezed
class ApiResult<T> with _$ApiResult<T> {
  /// 성공
  const factory ApiResult.success(T data) = Success<T>;

  /// 실패
  const factory ApiResult.failure(String message, {int? status_code}) =
      Failure<T>;

  /// 로딩 중
  const factory ApiResult.loading() = Loading<T>;
}

