import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error_handler.dart';
import '../models/shift_type_api_model.dart';

/// ShiftTypeService Provider
final shiftTypeServiceProvider = Provider<ShiftTypeService>((ref) {
  final dio = ref.watch(dioProvider);
  return ShiftTypeService(dio);
});

/// 근무 타입 정보 조회 및 관리 서비스
class ShiftTypeService {
  final Dio _dio;

  ShiftTypeService(this._dio);

  /// 근무 타입 정보 조회
  ///
  /// 엔드포인트: GET /api/v1/shift-types
  /// 인증: 필요
  Future<ShiftTypesResponse> getShiftTypes() async {
    try {
      final response = await _dio.get(ApiConstants.shift_types);
      return ShiftTypesResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw handleApiError(e);
    }
  }

  /// 근무 타입 추가
  ///
  /// 엔드포인트: POST /api/v1/shift-types
  /// 인증: 필요
  Future<CreateShiftTypeResponse> createShiftType(
    CreateShiftTypeRequest request,
  ) async {
    try {
      final response = await _dio.post(
        ApiConstants.shift_types,
        data: request.toJson(),
      );
      return CreateShiftTypeResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw handleApiError(e);
    }
  }

  /// 근무 타입 수정
  ///
  /// 엔드포인트: PUT /api/v1/shift-types/:shift_type_id
  /// 인증: 필요
  Future<UpdateShiftTypeResponse> updateShiftType(
    String shiftTypeId,
    UpdateShiftTypeRequest request,
  ) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.shift_types}/$shiftTypeId',
        data: request.toJson(),
      );
      return UpdateShiftTypeResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw handleApiError(e);
    }
  }

  /// 근무 타입 삭제
  ///
  /// 엔드포인트: DELETE /api/v1/shift-types/:shift_type_id
  /// 인증: 필요
  Future<DeleteShiftTypeResponse> deleteShiftType(String shiftTypeId) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.shift_types}/$shiftTypeId',
      );
      return DeleteShiftTypeResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw handleApiError(e);
    }
  }
}
