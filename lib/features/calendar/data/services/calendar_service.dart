// ignore_for_file: non_constant_identifier_names

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error_handler.dart';
import '../models/event_api_model.dart';

/// CalendarService Provider
final calendarServiceProvider = Provider<CalendarService>((ref) {
  final dio = ref.watch(dioProvider);
  return CalendarService(dio);
});

/// 일정 조회 서비스
class CalendarService {
  final Dio _dio;

  CalendarService(this._dio);

  /// 날짜 형식 변환 (YYYY-MM-DD)
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 특정 날짜의 일정 조회
  ///
  /// 엔드포인트: GET /api/v1/calendar/day?date=YYYY-MM-DD
  /// 인증: 필요
  Future<DayScheduleResponse> getDaySchedule(DateTime date) async {
    try {
      final response = await _dio.get(
        ApiConstants.calendar_day,
        queryParameters: {'date': _formatDate(date)},
      );
      return DayScheduleResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw handleApiError(e);
    }
  }

  /// 기간별 일정 조회
  ///
  /// 엔드포인트: GET /api/v1/events?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD
  /// 인증: 필요
  Future<EventsResponse> getEvents({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.events,
        queryParameters: {
          'start_date': _formatDate(startDate),
          'end_date': _formatDate(endDate),
        },
      );
      return EventsResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw handleApiError(e);
    }
  }

  /// 개인 일정 생성
  ///
  /// 엔드포인트: POST /api/v1/events
  /// 인증: 필요
  Future<EventApiModel> createEvent(CreateEventRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstants.events,
        data: request.toJson(),
      );
      return EventApiModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw handleApiError(e);
    }
  }

  /// 개인 일정 삭제
  ///
  /// 엔드포인트: DELETE /api/v1/events/:event_id
  /// 인증: 필요
  Future<String> deleteEvent(String event_id) async {
    try {
      final response = await _dio.delete('${ApiConstants.events}/$event_id');
      final response_data = response.data as Map<String, dynamic>;
      final data = response_data['data'] as Map<String, dynamic>;
      return data['event_id'] as String;
    } on DioException catch (error) {
      throw handleApiError(error);
    }
  }

  /// 통합 캘린더 데이터 조회 (근무표 + 일정)
  ///
  /// 엔드포인트: GET /api/v1/calendar/range?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD
  /// 인증: 필요
  ///
  /// 달력 페이지에서 3달치 데이터를 한 번에 조회할 때 사용 (권장)
  Future<CalendarRangeResponse> getCalendarRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.calendar_range,
        queryParameters: {
          'start_date': _formatDate(startDate),
          'end_date': _formatDate(endDate),
        },
      );
      return CalendarRangeResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw handleApiError(e);
    }
  }

  /// 3달 범위 계산 (전월 1일 ~ 다음월 마지막 날)
  ///
  /// 예: 2026-01-04 입력 시
  /// - 전월: 2025-12-01 ~ 2025-12-31
  /// - 현재월: 2026-01-01 ~ 2026-01-31
  /// - 다음월: 2026-02-01 ~ 2026-02-28
  ///
  /// 반환: (startDate: 2025-12-01, endDate: 2026-02-28)
  ({DateTime startDate, DateTime endDate}) calculateThreeMonthRange(
    DateTime focusedMonth,
  ) {
    // 전월 1일
    final prevMonth = DateTime(focusedMonth.year, focusedMonth.month - 1, 1);

    // 다음월 마지막 날
    final nextMonth = DateTime(focusedMonth.year, focusedMonth.month + 2, 0);

    return (startDate: prevMonth, endDate: nextMonth);
  }
}
