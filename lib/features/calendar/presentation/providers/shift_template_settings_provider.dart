import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/shift_type_api_model.dart';
import '../../data/services/shift_template_service.dart';
import '../../data/services/shift_type_service.dart';

/// 템플릿 설정 상태
class ShiftTemplateSettingsState {
  final String? templateId;
  final String? templateName;
  final List<ShiftTypeApiModel> shiftTypes;
  final bool is_loading;
  final dynamic error;

  ShiftTemplateSettingsState({
    this.templateId,
    this.templateName,
    required this.shiftTypes,
    this.is_loading = false,
    this.error,
  });

  ShiftTemplateSettingsState copyWith({
    String? templateId,
    String? templateName,
    List<ShiftTypeApiModel>? shiftTypes,
    bool? is_loading,
    dynamic error,
  }) {
    return ShiftTemplateSettingsState(
      templateId: templateId ?? this.templateId,
      templateName: templateName ?? this.templateName,
      shiftTypes: shiftTypes ?? this.shiftTypes,
      is_loading: is_loading ?? this.is_loading,
      error: error ?? this.error,
    );
  }
}

/// 템플릿 설정 Notifier
class ShiftTemplateSettingsNotifier
    extends StateNotifier<ShiftTemplateSettingsState> {
  final ShiftTemplateService _templateService;
  final ShiftTypeService _shiftTypeService;

  ShiftTemplateSettingsNotifier({
    required ShiftTemplateService templateService,
    required ShiftTypeService shiftTypeService,
  })  : _templateService = templateService,
        _shiftTypeService = shiftTypeService,
        super(ShiftTemplateSettingsState(shiftTypes: []));

  /// 초기 데이터 로드
  Future<void> loadData() async {
    state = state.copyWith(is_loading: true, error: null);
    try {
      // 템플릿 정보 조회
      final templateResponse = await _templateService.getCurrentTemplate();
      final template = templateResponse.data;

      // 근무 타입 목록 조회
      final shiftTypesResponse = await _shiftTypeService.getShiftTypes();

      state = state.copyWith(
        templateId: template.templateId,
        templateName: template.templateName,
        shiftTypes: shiftTypesResponse.data.shiftTypes,
        is_loading: false,
      );
    } catch (e) {
      state = state.copyWith(
        is_loading: false,
        error: e,
      );
    }
  }

  /// 템플릿 이름 변경
  Future<bool> updateTemplateName(String name) async {
    state = state.copyWith(is_loading: true, error: null);
    try {
      final response = await _templateService.updateTemplateName(name);
      state = state.copyWith(
        templateName: response.data.templateName,
        is_loading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        is_loading: false,
        error: e,
      );
      return false;
    }
  }

  /// 근무 타입 추가
  Future<bool> createShiftType(CreateShiftTypeRequest request) async {
    state = state.copyWith(is_loading: true, error: null);
    try {
      final response = await _shiftTypeService.createShiftType(request);
      final updatedTypes = [...state.shiftTypes, response.data];
      state = state.copyWith(
        shiftTypes: updatedTypes,
        is_loading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        is_loading: false,
        error: e,
      );
      return false;
    }
  }

  /// 근무 타입 수정
  Future<bool> updateShiftType(
    String shiftTypeId,
    UpdateShiftTypeRequest request,
  ) async {
    state = state.copyWith(is_loading: true, error: null);
    try {
      final response = await _shiftTypeService.updateShiftType(
        shiftTypeId,
        request,
      );
      final updatedTypes = state.shiftTypes.map((type) {
        if (type.shiftTypeId == shiftTypeId) {
          return response.data;
        }
        return type;
      }).toList();
      state = state.copyWith(
        shiftTypes: updatedTypes,
        is_loading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        is_loading: false,
        error: e,
      );
      return false;
    }
  }

  /// 근무 타입 삭제
  Future<bool> deleteShiftType(String shiftTypeId) async {
    state = state.copyWith(is_loading: true, error: null);
    try {
      await _shiftTypeService.deleteShiftType(shiftTypeId);
      final updatedTypes = state.shiftTypes
          .where((type) => type.shiftTypeId != shiftTypeId)
          .toList();
      state = state.copyWith(
        shiftTypes: updatedTypes,
        is_loading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        is_loading: false,
        error: e,
      );
      return false;
    }
  }
}

/// 템플릿 설정 Provider
final shiftTemplateSettingsProvider =
    StateNotifierProvider<ShiftTemplateSettingsNotifier,
        ShiftTemplateSettingsState>((ref) {
  final templateService = ref.watch(shiftTemplateServiceProvider);
  final shiftTypeService = ref.watch(shiftTypeServiceProvider);
  return ShiftTemplateSettingsNotifier(
    templateService: templateService,
    shiftTypeService: shiftTypeService,
  );
});

