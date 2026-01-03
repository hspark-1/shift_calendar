import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/shift_type_info.dart';

/// 근무 타입 목록 Provider
///
/// 현재는 하드코딩된 기본값을 제공하지만,
/// 추후 API에서 동적으로 가져오도록 확장 예정
/// (DB: shift_types + shift_type_schedules)
final shiftTypesProvider = Provider<List<ShiftTypeInfo>>((ref) {
  // TODO: API에서 동적으로 가져오도록 변경
  // 현재는 기본 3교대 근무 타입을 하드코딩
  return const [
    ShiftTypeInfo(
      code: 'D',
      name: '데이',
      color: Color(0xFFF5A623), // 밝은 오렌지/골드
      sort_order: 0,
      start_time: '06:30',
      end_time: '15:00',
    ),
    ShiftTypeInfo(
      code: 'E',
      name: '이브닝',
      color: Color(0xFFE91E63), // 핑크/마젠타
      sort_order: 1,
      start_time: '14:30',
      end_time: '23:00',
    ),
    ShiftTypeInfo(
      code: 'N',
      name: '나이트',
      color: Color(0xFF5856D6), // 인디고/보라
      sort_order: 2,
      start_time: '22:30',
      end_time: '07:00',
    ),
    ShiftTypeInfo(
      code: 'OFF',
      name: '오프',
      color: Color(0xFF34C759), // 초록
      sort_order: 3,
      start_time: null,
      end_time: null,
    ),
  ];
});

/// 근무 타입 Map Provider (code로 빠른 조회용)
final shiftTypesMapProvider = Provider<Map<String, ShiftTypeInfo>>((ref) {
  final shiftTypes = ref.watch(shiftTypesProvider);
  return {for (final type in shiftTypes) type.code: type};
});

/// 근무 타입 코드 목록 Provider (버튼 표시 순서대로 정렬)
final shiftTypeOrderProvider = Provider<List<String>>((ref) {
  final shiftTypes = ref.watch(shiftTypesProvider);
  final sortedTypes = [...shiftTypes]
    ..sort((a, b) => a.sort_order.compareTo(b.sort_order));
  return sortedTypes.map((type) => type.code).toList();
});

/// 근무 타입 색상 가져오기 헬퍼
Color getShiftColor(WidgetRef ref, String code) {
  final shiftTypesMap = ref.read(shiftTypesMapProvider);
  return shiftTypesMap[code]?.color ?? CupertinoColors.systemGrey;
}
