import 'package:flutter/cupertino.dart';

import '../../../../core/utils/color_parser.dart';

/// API 응답의 근무 타입 정보 모델
class ShiftTypeApiModel {
  final String shiftTypeId;
  final String code;
  final String name;
  final int? color;
  final int? sortOrder;
  final String? startTime; // "06:30:00" 형식
  final String? endTime; // "15:00:00" 형식
  final bool crossesMidnight;
  final int durationMinutes;

  ShiftTypeApiModel({
    required this.shiftTypeId,
    required this.code,
    required this.name,
    this.color,
    this.sortOrder,
    this.startTime,
    this.endTime,
    required this.crossesMidnight,
    required this.durationMinutes,
  });

  factory ShiftTypeApiModel.fromJson(Map<String, dynamic> json) {
    return ShiftTypeApiModel(
      shiftTypeId: json['shift_type_id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      color: parseApiColorValue(json['color']),
      sortOrder: json['sort_order'] as int?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      crossesMidnight: json['crosses_midnight'] as bool,
      durationMinutes: json['duration_minutes'] as int,
    );
  }

  /// 시간을 "HH:mm" 형식으로 변환 (UI 표시용)
  String? get startTimeDisplay {
    if (startTime == null) return null;
    return startTime!.substring(0, 5); // "06:30:00" -> "06:30"
  }

  String? get endTimeDisplay {
    if (endTime == null) return null;
    return endTime!.substring(0, 5); // "15:00:00" -> "15:00"
  }

  /// Color 객체로 변환
  Color? get colorValue {
    if (color == null) return null;
    return Color(color!);
  }
}

/// 근무 타입 목록 응답 데이터
class ShiftTypesData {
  final String templateId;
  final String templateName;
  final List<ShiftTypeApiModel> shiftTypes;

  ShiftTypesData({
    required this.templateId,
    required this.templateName,
    required this.shiftTypes,
  });

  factory ShiftTypesData.fromJson(Map<String, dynamic> json) {
    return ShiftTypesData(
      templateId: json['template_id'] as String,
      templateName: json['template_name'] as String,
      shiftTypes: (json['shift_types'] as List)
          .map((e) => ShiftTypeApiModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// 근무 타입 목록 응답
class ShiftTypesResponse {
  final bool success;
  final ShiftTypesData data;

  ShiftTypesResponse({required this.success, required this.data});

  factory ShiftTypesResponse.fromJson(Map<String, dynamic> json) {
    // API 응답이 { success, data } 형태인지, 직접 데이터인지 확인
    if (json.containsKey('success') && json.containsKey('data')) {
      // 표준 형태: { success: true, data: {...} }
      return ShiftTypesResponse(
        success: json['success'] as bool? ?? true,
        data: ShiftTypesData.fromJson(json['data'] as Map<String, dynamic>),
      );
    } else {
      // 직접 데이터 형태: { template_id, template_name, shift_types }
      return ShiftTypesResponse(
        success: true,
        data: ShiftTypesData.fromJson(json),
      );
    }
  }
}

/// 근무 타입 추가 요청
class CreateShiftTypeRequest {
  final String code;
  final String name;
  final int? color;
  final String? startTime; // "HH:mm:ss" 형식
  final String? endTime; // "HH:mm:ss" 형식
  final int? sortOrder;

  CreateShiftTypeRequest({
    required this.code,
    required this.name,
    this.color,
    this.startTime,
    this.endTime,
    this.sortOrder,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'code': code, 'name': name};
    if (color != null) json['color'] = color;
    if (startTime != null) json['start_time'] = startTime;
    if (endTime != null) json['end_time'] = endTime;
    if (sortOrder != null) json['sort_order'] = sortOrder;
    return json;
  }
}

/// 근무 타입 추가 응답
class CreateShiftTypeResponse {
  final bool success;
  final ShiftTypeApiModel data;

  CreateShiftTypeResponse({required this.success, required this.data});

  factory CreateShiftTypeResponse.fromJson(Map<String, dynamic> json) {
    return CreateShiftTypeResponse(
      success: json['success'] as bool? ?? true,
      data: ShiftTypeApiModel.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

/// 근무 타입 수정 요청
class UpdateShiftTypeRequest {
  final String? code;
  final String? name;
  final int? color;
  final String? startTime; // "HH:mm:ss" 형식 또는 null
  final String? endTime; // "HH:mm:ss" 형식 또는 null
  final int? sortOrder;

  UpdateShiftTypeRequest({
    this.code,
    this.name,
    this.color,
    this.startTime,
    this.endTime,
    this.sortOrder,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (code != null) json['code'] = code;
    if (name != null) json['name'] = name;
    if (color != null) json['color'] = color;
    // 시간 필드: Partial update이지만 시간은 특별 처리
    // - 둘 다 null이면 스케줄 삭제를 위해 명시적으로 null 전송
    // - 둘 다 값이 있으면 스케줄 업데이트/생성
    // - 하나만 null이면 validation error (클라이언트에서 체크)
    // 시간 필드는 항상 포함 (변경 여부와 관계없이)
    json['start_time'] = startTime;
    json['end_time'] = endTime;
    if (sortOrder != null) json['sort_order'] = sortOrder;
    return json;
  }
}

/// 근무 타입 수정 응답
class UpdateShiftTypeResponse {
  final bool success;
  final ShiftTypeApiModel data;

  UpdateShiftTypeResponse({required this.success, required this.data});

  factory UpdateShiftTypeResponse.fromJson(Map<String, dynamic> json) {
    return UpdateShiftTypeResponse(
      success: json['success'] as bool? ?? true,
      data: ShiftTypeApiModel.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

/// 근무 타입 삭제 응답
class DeleteShiftTypeResponse {
  final bool success;
  final DeleteShiftTypeData data;

  DeleteShiftTypeResponse({required this.success, required this.data});

  factory DeleteShiftTypeResponse.fromJson(Map<String, dynamic> json) {
    return DeleteShiftTypeResponse(
      success: json['success'] as bool? ?? true,
      data: DeleteShiftTypeData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class DeleteShiftTypeData {
  final String shiftTypeId;
  final DateTime deletedAt;

  DeleteShiftTypeData({required this.shiftTypeId, required this.deletedAt});

  factory DeleteShiftTypeData.fromJson(Map<String, dynamic> json) {
    return DeleteShiftTypeData(
      shiftTypeId: json['shift_type_id'] as String,
      deletedAt: DateTime.parse(json['deleted_at'] as String),
    );
  }
}
