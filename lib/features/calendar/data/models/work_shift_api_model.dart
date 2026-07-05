import '../../../../core/utils/color_parser.dart';

/// API 응답의 근무표 정보 모델
class WorkShiftApiModel {
  final String workShiftId;
  final DateTime workDate;
  final String shiftTypeCode;
  final String shiftTypeName;
  final int? shiftTypeColor;
  final String? startTime;
  final String? endTime;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkShiftApiModel({
    required this.workShiftId,
    required this.workDate,
    required this.shiftTypeCode,
    required this.shiftTypeName,
    this.shiftTypeColor,
    this.startTime,
    this.endTime,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkShiftApiModel.fromJson(Map<String, dynamic> json) {
    return WorkShiftApiModel(
      workShiftId: json['work_shift_id'] as String,
      workDate: DateTime.parse(json['work_date'] as String),
      shiftTypeCode: json['shift_type_code'] as String,
      shiftTypeName: json['shift_type_name'] as String,
      shiftTypeColor: parseApiColorValue(json['shift_type_color']),
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// 캘린더 그리드용 변환: `Map<DateTime, List<String>>`
  static Map<DateTime, List<String>> toCalendarMap(
    List<WorkShiftApiModel> shifts,
  ) {
    final Map<DateTime, List<String>> result = {};
    for (final shift in shifts) {
      final normalizedDate = DateTime(
        shift.workDate.year,
        shift.workDate.month,
        shift.workDate.day,
      );
      result[normalizedDate] = [shift.shiftTypeCode];
    }
    return result;
  }
}

/// 근무표 목록 응답 데이터
class WorkShiftsData {
  final List<WorkShiftApiModel> workShifts;

  WorkShiftsData({required this.workShifts});

  factory WorkShiftsData.fromJson(Map<String, dynamic> json) {
    return WorkShiftsData(
      workShifts: (json['work_shifts'] as List)
          .map((e) => WorkShiftApiModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// 근무표 목록 응답
class WorkShiftsResponse {
  final bool success;
  final WorkShiftsData data;

  WorkShiftsResponse({required this.success, required this.data});

  factory WorkShiftsResponse.fromJson(Map<String, dynamic> json) {
    return WorkShiftsResponse(
      success: json['success'] as bool,
      data: WorkShiftsData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}
