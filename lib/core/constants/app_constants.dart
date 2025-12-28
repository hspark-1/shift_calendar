import 'package:flutter/cupertino.dart';

/// 근무 타입 정보 클래스
class ShiftTypeInfo {
  const ShiftTypeInfo({
    required this.code,
    required this.name,
    required this.color,
    this.start_time,
    this.end_time,
  });

  final String code;
  final String name;
  final Color color;
  final String? start_time;
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
}

/// 앱 전역 상수
class AppConstants {
  AppConstants._();

  /// 앱 이름
  static const String app_name = 'Shift Calendar';

  /// 앱 버전
  static const String app_version = '1.0.0';

  /// 3교대 근무 타입 코드
  static const String shift_day = 'D'; // 데이
  static const String shift_evening = 'E'; // 이브닝
  static const String shift_night = 'N'; // 나이트
  static const String shift_off = 'OFF'; // 오프

  /// 근무 타입 상세 정보 (하드코딩)
  static const Map<String, ShiftTypeInfo> shift_types = {
    'D': ShiftTypeInfo(
      code: 'D',
      name: '데이',
      color: Color(0xFFF5A623), // 밝은 오렌지/골드
      start_time: '06:30',
      end_time: '15:00',
    ),
    'E': ShiftTypeInfo(
      code: 'E',
      name: '이브닝',
      color: Color(0xFFE91E63), // 핑크/마젠타
      start_time: '14:30',
      end_time: '23:00',
    ),
    'N': ShiftTypeInfo(
      code: 'N',
      name: '나이트',
      color: Color(0xFF5856D6), // 인디고/보라
      start_time: '22:30',
      end_time: '07:00',
    ),
    'OFF': ShiftTypeInfo(
      code: 'OFF',
      name: '오프',
      color: Color(0xFF34C759), // 초록
      start_time: null,
      end_time: null,
    ),
  };

  /// 근무 타입 색상 가져오기
  static Color getShiftColor(String code) {
    return shift_types[code]?.color ?? CupertinoColors.systemGrey;
  }

  /// 근무 타입 목록 (버튼 표시 순서)
  static const List<String> shift_type_order = ['D', 'E', 'N', 'OFF'];

  /// 기본 근무 패턴 (3교대)
  static const List<String> default_shift_pattern = [
    shift_day,
    shift_day,
    shift_evening,
    shift_evening,
    shift_night,
    shift_night,
    shift_off,
    shift_off,
  ];

  /// 로컬 저장소 키
  static const String storage_key_token = 'access_token';
  static const String storage_key_refresh_token = 'refresh_token';
  static const String storage_key_user = 'user_data';
  static const String storage_key_shift_pattern = 'shift_pattern';
}
