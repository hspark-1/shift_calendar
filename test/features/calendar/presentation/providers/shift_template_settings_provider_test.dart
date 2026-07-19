// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_calendar/features/calendar/data/models/shift_template_api_model.dart';
import 'package:shift_calendar/features/calendar/data/models/shift_type_api_model.dart';
import 'package:shift_calendar/features/calendar/data/services/shift_template_service.dart';
import 'package:shift_calendar/features/calendar/data/services/shift_type_service.dart';
import 'package:shift_calendar/features/calendar/domain/entities/shift_type_info.dart';
import 'package:shift_calendar/features/calendar/presentation/providers/shift_template_settings_provider.dart';
import 'package:shift_calendar/features/calendar/presentation/providers/shift_types_provider.dart';

ShiftTypeApiModel _buildShiftType({
  String code = 'D',
  String name = '데이',
  int color = 0xFF0061A4,
  String start_time = '07:00:00',
  String end_time = '15:00:00',
}) {
  return ShiftTypeApiModel(
    shiftTypeId: 'shift-type-day',
    code: code,
    name: name,
    color: color,
    sortOrder: 0,
    startTime: start_time,
    endTime: end_time,
    crossesMidnight: false,
    durationMinutes: 480,
  );
}

class _FakeShiftTemplateService extends ShiftTemplateService {
  _FakeShiftTemplateService() : super(Dio());

  @override
  Future<ShiftTemplateResponse> getCurrentTemplate() async {
    return ShiftTemplateResponse(
      success: true,
      data: ShiftTemplateApiModel(
        templateId: 'template-1',
        templateName: '기본',
        ownerUserId: 'user-1',
        createdAt: DateTime(2026),
      ),
    );
  }
}

class _FakeShiftTypeService extends ShiftTypeService {
  _FakeShiftTypeService({required this.initial_type}) : super(Dio());

  final ShiftTypeApiModel initial_type;
  final update_completer = Completer<UpdateShiftTypeResponse>();
  int update_call_count = 0;

  @override
  Future<ShiftTypesResponse> getShiftTypes() async {
    return ShiftTypesResponse(
      success: true,
      data: ShiftTypesData(
        templateId: 'template-1',
        templateName: '기본',
        shiftTypes: [initial_type],
      ),
    );
  }

  @override
  Future<UpdateShiftTypeResponse> updateShiftType(
    String shiftTypeId,
    UpdateShiftTypeRequest request,
  ) {
    update_call_count += 1;
    return update_completer.future;
  }
}

void main() {
  test('수정 요청 중 전체 로딩 상태로 전환하지 않고 응답값만 목록에 반영한다', () async {
    final initial_type = _buildShiftType();
    final updated_type = _buildShiftType(
      code: 'M',
      name: '모닝',
      color: 0xFFE53935,
      start_time: '08:00:00',
      end_time: '16:00:00',
    );
    final shift_type_service = _FakeShiftTypeService(
      initial_type: initial_type,
    );
    final notifier = ShiftTemplateSettingsNotifier(
      templateService: _FakeShiftTemplateService(),
      shiftTypeService: shift_type_service,
    );
    addTearDown(notifier.dispose);

    await notifier.loadData();
    final update_future = notifier.updateShiftType(
      initial_type.shiftTypeId,
      UpdateShiftTypeRequest(code: updated_type.code),
    );

    expect(shift_type_service.update_call_count, 1);
    expect(notifier.state.is_loading, isFalse);
    expect(notifier.state.shiftTypes.single.name, '데이');

    shift_type_service.update_completer.complete(
      UpdateShiftTypeResponse(success: true, data: updated_type),
    );
    final response_type = await update_future;

    expect(response_type, same(updated_type));
    expect(notifier.state.is_loading, isFalse);
    expect(notifier.state.shiftTypes.single, same(updated_type));
  });

  test('수정 API 응답을 기존 GET 캐시 위에 합성한다', () async {
    final initial_type = _buildShiftType();
    final updated_type = _buildShiftType(
      code: 'M',
      name: '모닝',
      color: 0xFFE53935,
      start_time: '08:00:00',
      end_time: '16:00:00',
    );
    final container = ProviderContainer(
      overrides: [
        shiftTypesProvider.overrideWith(
          (ref) async => const [
            ShiftTypeInfo(
              code: 'D',
              name: '데이',
              color: Color(0xFF0061A4),
              sort_order: 0,
              start_time: '07:00',
              end_time: '15:00',
            ),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(shiftTypesProvider.future);
    container
        .read(shiftTypeDisplayUpdatesProvider.notifier)
        .applyUpdate(previous_type: initial_type, updated_type: updated_type);

    final effective_types = container
        .read(effectiveShiftTypesProvider)
        .requireValue;
    expect(effective_types.single.code, 'M');
    expect(effective_types.single.name, '모닝');
    expect(effective_types.single.color, const Color(0xFFE53935));
    expect(effective_types.single.start_time, '08:00');
    expect(effective_types.single.end_time, '16:00');
  });
}
