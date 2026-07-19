// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/shift_type_api_model.dart';
import '../../data/services/shift_type_service.dart';
import '../../domain/entities/shift_type_info.dart';

ShiftTypeInfo shiftTypeInfoFromApiModel(ShiftTypeApiModel api_model) {
  return ShiftTypeInfo(
    code: api_model.code,
    name: api_model.name,
    color: api_model.colorValue ?? CupertinoColors.systemGrey,
    sort_order: api_model.sortOrder ?? 0,
    start_time: api_model.startTimeDisplay,
    end_time: api_model.endTimeDisplay,
  );
}

/// 근무 타입 목록 Provider (API에서 동적으로 가져옴)
final shiftTypesProvider = FutureProvider<List<ShiftTypeInfo>>((ref) async {
  final service = ref.watch(shiftTypeServiceProvider);
  final response = await service.getShiftTypes();

  return response.data.shiftTypes.map(shiftTypeInfoFromApiModel).toList();
});

class ShiftTypeDisplayUpdate {
  const ShiftTypeDisplayUpdate({
    required this.shift_type_id,
    required this.original_code,
    required this.previous_code,
    required this.updated_type,
  });

  final String shift_type_id;
  final String original_code;
  final String previous_code;
  final ShiftTypeApiModel updated_type;
}

class ShiftTypeDisplayUpdatesNotifier
    extends StateNotifier<Map<String, ShiftTypeDisplayUpdate>> {
  ShiftTypeDisplayUpdatesNotifier() : super(const {});

  void applyUpdate({
    required ShiftTypeApiModel previous_type,
    required ShiftTypeApiModel updated_type,
  }) {
    final existing_update = state[updated_type.shiftTypeId];
    final update = ShiftTypeDisplayUpdate(
      shift_type_id: updated_type.shiftTypeId,
      original_code: existing_update?.original_code ?? previous_type.code,
      previous_code: previous_type.code,
      updated_type: updated_type,
    );

    state = {...state, updated_type.shiftTypeId: update};
  }
}

/// 수정 API 응답으로 현재 세션의 표시 데이터를 동기화한다.
final shiftTypeDisplayUpdatesProvider =
    StateNotifierProvider<
      ShiftTypeDisplayUpdatesNotifier,
      Map<String, ShiftTypeDisplayUpdate>
    >((ref) => ShiftTypeDisplayUpdatesNotifier());

/// GET 캐시 위에 수정 API 응답을 합성한 현재 표시용 근무 타입 목록.
final effectiveShiftTypesProvider = Provider<AsyncValue<List<ShiftTypeInfo>>>((
  ref,
) {
  final shift_types_async = ref.watch(shiftTypesProvider);
  final display_updates = ref.watch(shiftTypeDisplayUpdatesProvider);

  return shift_types_async.whenData((shift_types) {
    return shift_types.map((shift_type) {
      for (final update in display_updates.values) {
        final updated_code = update.updated_type.code;
        if (shift_type.code == update.original_code ||
            shift_type.code == update.previous_code ||
            shift_type.code == updated_code) {
          return shiftTypeInfoFromApiModel(update.updated_type);
        }
      }
      return shift_type;
    }).toList();
  });
});

/// 근무 타입 Map Provider (code로 빠른 조회용)
final shiftTypesMapProvider = Provider<Map<String, ShiftTypeInfo>>((ref) {
  final shiftTypesAsync = ref.watch(effectiveShiftTypesProvider);
  return shiftTypesAsync.when(
    data: (shiftTypes) => {for (final type in shiftTypes) type.code: type},
    loading: () => <String, ShiftTypeInfo>{},
    error: (error, stack_trace) => <String, ShiftTypeInfo>{},
  );
});

/// 근무 타입 코드 목록 Provider (버튼 표시 순서대로 정렬)
final shiftTypeOrderProvider = Provider<List<String>>((ref) {
  final shiftTypesAsync = ref.watch(effectiveShiftTypesProvider);
  return shiftTypesAsync.when(
    data: (shiftTypes) {
      final sortedTypes = [...shiftTypes]
        ..sort((a, b) => a.sort_order.compareTo(b.sort_order));
      return sortedTypes.map((type) => type.code).toList();
    },
    loading: () => <String>[],
    error: (error, stack_trace) => <String>[],
  );
});

/// 근무 타입 색상 가져오기 헬퍼
Color getShiftColor(WidgetRef ref, String code) {
  final shiftTypesMap = ref.read(shiftTypesMapProvider);
  return shiftTypesMap[code]?.color ?? CupertinoColors.systemGrey;
}
