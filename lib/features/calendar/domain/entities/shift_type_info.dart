import 'package:flutter/cupertino.dart';

/// 근무 타입 정보 클래스 (DB shift_types + shift_type_schedules 매핑)
class ShiftTypeInfo {
  const ShiftTypeInfo({
    required this.code,
    required this.name,
    required this.color,
    required this.sort_order,
    this.start_time,
    this.end_time,
  });

  /// DB shift_types.code
  final String code;

  /// DB shift_types.name
  final String name;

  /// DB shift_types.color (0xFFRRGGBB 형태)
  final Color color;

  /// DB shift_types.sort_order (버튼 표시 순서)
  final int sort_order;

  /// DB shift_type_schedules.start_time
  final String? start_time;

  /// DB shift_type_schedules.end_time
  final String? end_time;

  /// 시간 표시 문자열 반환
  String get timeDisplay {
    if (start_time == null || end_time == null) {
      return '근무없음';
    }
    return '$start_time ~ $end_time';
  }

  /// 근무 시간 유효 여부
  bool get hasWorkTime => start_time != null && end_time != null;

  /// JSON에서 생성 (API 응답 파싱용)
  factory ShiftTypeInfo.fromJson(Map<String, dynamic> json) {
    return ShiftTypeInfo(
      code: json['code'] as String,
      name: json['name'] as String,
      color: Color(json['color'] as int),
      sort_order: json['sort_order'] as int? ?? 0,
      start_time: json['start_time'] as String?,
      end_time: json['end_time'] as String?,
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'color': color.value,
      'sort_order': sort_order,
      'start_time': start_time,
      'end_time': end_time,
    };
  }
}
