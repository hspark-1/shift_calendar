import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/shift_type_service.dart';
import '../../domain/entities/shift_type_info.dart';

/// 근무 타입 목록 Provider (API에서 동적으로 가져옴)
final shiftTypesProvider = FutureProvider<List<ShiftTypeInfo>>((ref) async {
  final service = ref.watch(shiftTypeServiceProvider);
  final response = await service.getShiftTypes();

  // ShiftTypeApiModel을 ShiftTypeInfo로 변환
  return response.data.shiftTypes.map((apiModel) {
    return ShiftTypeInfo(
      code: apiModel.code,
      name: apiModel.name,
      color: apiModel.colorValue ?? CupertinoColors.systemGrey,
      sort_order: apiModel.sortOrder ?? 0,
      start_time: apiModel.startTimeDisplay, // "HH:mm" 형식으로 변환됨
      end_time: apiModel.endTimeDisplay, // "HH:mm" 형식으로 변환됨
    );
  }).toList();
});

/// 근무 타입 Map Provider (code로 빠른 조회용)
final shiftTypesMapProvider = Provider<Map<String, ShiftTypeInfo>>((ref) {
  final shiftTypesAsync = ref.watch(shiftTypesProvider);
  return shiftTypesAsync.when(
    data: (shiftTypes) => {for (final type in shiftTypes) type.code: type},
    loading: () => <String, ShiftTypeInfo>{},
    error: (_, __) => <String, ShiftTypeInfo>{},
  );
});

/// 근무 타입 코드 목록 Provider (버튼 표시 순서대로 정렬)
final shiftTypeOrderProvider = Provider<List<String>>((ref) {
  final shiftTypesAsync = ref.watch(shiftTypesProvider);
  return shiftTypesAsync.when(
    data: (shiftTypes) {
      final sortedTypes = [...shiftTypes]
        ..sort((a, b) => a.sort_order.compareTo(b.sort_order));
      return sortedTypes.map((type) => type.code).toList();
    },
    loading: () => <String>[],
    error: (_, __) => <String>[],
  );
});

/// 근무 타입 색상 가져오기 헬퍼
Color getShiftColor(WidgetRef ref, String code) {
  final shiftTypesMap = ref.read(shiftTypesMapProvider);
  return shiftTypesMap[code]?.color ?? CupertinoColors.systemGrey;
}
