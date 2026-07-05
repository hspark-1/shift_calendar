import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error_handler.dart';
import '../models/work_shift_api_model.dart';

/// WorkShiftService Provider
final workShiftServiceProvider = Provider<WorkShiftService>((ref) {
  final dio = ref.watch(dioProvider);
  return WorkShiftService(dio);
});

/// 근무표 조회/생성/수정/삭제 서비스
class WorkShiftService {
  final Dio _dio;

  WorkShiftService(this._dio);

  /// 날짜 형식 변환 (YYYY-MM-DD)
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 기간별 근무표 조회
  /// 
  /// 엔드포인트: GET /api/v1/work-shifts?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD
  /// 인증: 필요
  Future<WorkShiftsResponse> getWorkShifts({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.work_shifts,
        queryParameters: {
          'start_date': _formatDate(startDate),
          'end_date': _formatDate(endDate),
        },
      );
      return WorkShiftsResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw handleApiError(e);
    }
  }

  /// 근무표 생성/수정 (UPSERT)
  /// 
  /// 엔드포인트: POST /api/v1/work-shifts
  /// 인증: 필요
  Future<WorkShiftApiModel> upsertWorkShift({
    required DateTime workDate,
    required String shiftTypeCode,
    String? note,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.work_shifts,
        data: {
          'work_date': _formatDate(workDate),
          'shift_type_code': shiftTypeCode,
          if (note != null) 'note': note,
        },
      );
      return WorkShiftApiModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw handleApiError(e);
    }
  }

  /// 근무표 수정
  /// 
  /// 엔드포인트: PUT /api/v1/work-shifts/:work_shift_id
  /// 인증: 필요
  Future<WorkShiftApiModel> updateWorkShift({
    required String workShiftId,
    String? shiftTypeCode,
    String? note,
  }) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.work_shifts}/$workShiftId',
        data: {
          if (shiftTypeCode != null) 'shift_type_code': shiftTypeCode,
          if (note != null) 'note': note,
        },
      );
      return WorkShiftApiModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw handleApiError(e);
    }
  }

  /// 근무표 삭제
  /// 
  /// 엔드포인트: DELETE /api/v1/work-shifts/:work_shift_id
  /// 인증: 필요
  Future<void> deleteWorkShift(String workShiftId) async {
    try {
      await _dio.delete('${ApiConstants.work_shifts}/$workShiftId');
    } on DioException catch (e) {
      throw handleApiError(e);
    }
  }

  /// 근무표 배치 생성/수정 (UPSERT)
  /// 
  /// 엔드포인트: POST /api/v1/work-shifts/batch
  /// 인증: 필요
  /// 
  /// 요청 형식:
  /// {
  ///   "work_shifts": [
  ///     {
  ///       "work_date": "2024-01-15",
  ///       "shift_type_code": "D",
  ///       "note": "선택사항"
  ///     },
  ///     ...
  ///   ]
  /// }
  Future<WorkShiftsResponse> batchUpsertWorkShifts({
    required List<Map<String, dynamic>> workShifts,
  }) async {
    try {
      // 최대 100개 제한 검증
      if (workShifts.length > 100) {
        throw Exception('최대 100개의 근무 일정만 한 번에 저장할 수 있습니다.');
      }

      final response = await _dio.post(
        '${ApiConstants.work_shifts}/batch',
        data: {
          'work_shifts': workShifts,
        },
      );
      return WorkShiftsResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw handleApiError(e);
    }
  }
}

