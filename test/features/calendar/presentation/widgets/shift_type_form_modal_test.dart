// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/core/theme/app_theme.dart';
import 'package:shift_mate/features/calendar/data/models/shift_type_api_model.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/shift_color_picker_page.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/shift_type_form_modal.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/time_picker_sheet.dart';

ShiftTypeApiModel buildShiftType() {
  return ShiftTypeApiModel(
    shiftTypeId: 'shift-type-day',
    code: 'D',
    name: '데이',
    color: const Color(0xFFFF9500).toARGB32(),
    sortOrder: 0,
    startTime: '06:30:00',
    endTime: '15:00:00',
    crossesMidnight: false,
    durationMinutes: 510,
  );
}

ShiftTypeApiModel buildEveningShiftType() {
  return ShiftTypeApiModel(
    shiftTypeId: 'shift-type-evening',
    code: 'E',
    name: '이브닝',
    color: const Color(0xFF4355B8).toARGB32(),
    sortOrder: 1,
    startTime: '14:30:00',
    endTime: '23:00:00',
    crossesMidnight: false,
    durationMinutes: 510,
  );
}

ShiftTypeApiModel buildPaleShiftType() {
  return ShiftTypeApiModel(
    shiftTypeId: 'shift-type-pale',
    code: 'P',
    name: '옅은 근무',
    color: const Color(0xFFF5F7FA).toARGB32(),
    sortOrder: 2,
    startTime: '09:00:00',
    endTime: '18:00:00',
    crossesMidnight: false,
    durationMinutes: 540,
  );
}

ShiftTypeApiModel buildIntensityShiftType() {
  return ShiftTypeApiModel(
    shiftTypeId: 'shift-type-intensity',
    code: 'N',
    name: '나이트',
    color: const Color(0xFFA1AADC).toARGB32(),
    baseColor: const Color(0xFF4355B8).toARGB32(),
    colorIntensity: 50,
    sortOrder: 3,
    startTime: '22:30:00',
    endTime: '07:00:00',
    crossesMidnight: true,
    durationMinutes: 510,
  );
}

Widget buildTestApp() {
  return CupertinoApp(
    theme: AppTheme.lightTheme,
    home: ShiftTypeFormModal(
      shiftType: buildShiftType(),
      existingTypes: [buildShiftType()],
    ),
  );
}

Widget buildResultTestApp({
  required ValueChanged<UpdateShiftTypeRequest?> on_result,
  ShiftTypeApiModel? shift_type,
}) {
  final target_shift_type = shift_type ?? buildShiftType();

  return CupertinoApp(
    theme: AppTheme.lightTheme,
    home: CupertinoPageScaffold(
      child: Builder(
        builder: (context) => Center(
          child: CupertinoButton(
            onPressed: () async {
              final result = await Navigator.of(context)
                  .push<UpdateShiftTypeRequest>(
                    CupertinoPageRoute(
                      builder: (context) => ShiftTypeFormModal(
                        shiftType: target_shift_type,
                        existingTypes: [target_shift_type],
                      ),
                    ),
                  );
              on_result(result);
            },
            child: const Text('편집 열기'),
          ),
        ),
      ),
    ),
  );
}

Widget buildCreateResultTestApp({
  required ValueChanged<CreateShiftTypeRequest?> on_result,
}) {
  return CupertinoApp(
    theme: AppTheme.lightTheme,
    home: CupertinoPageScaffold(
      child: Builder(
        builder: (context) => Center(
          child: CupertinoButton(
            onPressed: () async {
              final result = await Navigator.of(context)
                  .push<CreateShiftTypeRequest>(
                    CupertinoPageRoute(
                      builder: (context) =>
                          const ShiftTypeFormModal(existingTypes: []),
                    ),
                  );
              on_result(result);
            },
            child: const Text('추가 열기'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('작은 미리보기와 하단 저장으로 편집값을 표시한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('근무 타입 편집'), findsOneWidget);
    expect(find.byKey(const Key('shift_type_back_button')), findsOneWidget);
    expect(find.text('변경사항 저장'), findsOneWidget);
    expect(find.text('취소'), findsNothing);
    expect(find.byIcon(CupertinoIcons.chevron_back), findsOneWidget);
    expect(find.text('표시 색상'), findsOneWidget);
    expect(find.text('근무 시간'), findsOneWidget);
    expect(find.text('시작 시간'), findsOneWidget);
    expect(find.text('종료 시간'), findsOneWidget);
    expect(find.text('06:30'), findsOneWidget);
    expect(find.text('15:00'), findsOneWidget);

    final preview_size = tester.getSize(
      find.byKey(const Key('shift_type_code_preview')),
    );
    expect(preview_size.width, closeTo(52, 0.01));
    expect(preview_size.height, closeTo(52, 0.01));
    expect(
      tester.getSize(find.byKey(const Key('shift_type_start_time_row'))).height,
      greaterThanOrEqualTo(56),
    );

    final navigation_title = tester.widget<Text>(find.text('근무 타입 편집'));
    final section_title = tester.widget<Text>(find.text('근무 시간'));
    expect(navigation_title.style?.fontSize, AppTheme.heading_small.fontSize);
    expect(section_title.style?.fontSize, 16);

    expect(find.byKey(const Key('shift_type_identity_card')), findsOneWidget);
    expect(find.byKey(const Key('shift_type_time_card')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('코드 입력을 3자로 제한하고 대문자 미리보기에 즉시 반영한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('shift_type_code_field')),
      'offx',
    );
    await tester.pump();

    final code_field = tester.widget<CupertinoTextField>(
      find.byKey(const Key('shift_type_code_field')),
    );

    expect(code_field.controller?.text, 'OFF');
    expect(
      find.descendant(
        of: find.byKey(const Key('shift_type_code_preview')),
        matching: find.text('OFF'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('조합 입력 중에는 값을 다시 쓰지 않고 입력 완료 후 대문자로 변환한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      CupertinoApp(
        theme: AppTheme.lightTheme,
        home: const ShiftTypeFormModal(existingTypes: []),
      ),
    );
    await tester.pumpAndSettle();

    final code_field_finder = find.byKey(const Key('shift_type_code_field'));
    await tester.tap(code_field_finder);
    await tester.pump();

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'd',
        selection: TextSelection.collapsed(offset: 1),
        composing: TextRange(start: 0, end: 1),
      ),
    );
    await tester.pump();

    var code_field = tester.widget<CupertinoTextField>(code_field_finder);
    expect(code_field.controller?.text, 'd');
    expect(code_field.focusNode?.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'd',
        selection: TextSelection.collapsed(offset: 1),
      ),
    );
    await tester.pump();

    code_field = tester.widget<CupertinoTextField>(code_field_finder);
    expect(code_field.controller?.text, 'D');
    expect(code_field.focusNode?.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('옅은 근무 색상에서도 미리보기 코드에 어두운 대비색을 사용한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final pale_shift_type = buildPaleShiftType();
    await tester.pumpWidget(
      CupertinoApp(
        theme: AppTheme.lightTheme,
        home: ShiftTypeFormModal(
          shiftType: pale_shift_type,
          existingTypes: [pale_shift_type],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final preview_code = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('shift_type_code_preview')),
        matching: find.text('P'),
      ),
    );

    expect(preview_code.style?.color, AppTheme.on_surface_color);
  });

  testWidgets('이름부터 표시 코드까지 화면 순서대로 입력하고 완료하면 키보드를 닫는다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();
    final name_finder = find.byKey(const Key('shift_type_name_field'));
    final code_finder = find.byKey(const Key('shift_type_code_field'));
    expect(
      tester.getTopLeft(name_finder).dy,
      lessThan(tester.getTopLeft(code_finder).dy),
    );
    await tester.tap(name_finder);
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    final code_field = tester.widget<CupertinoTextField>(code_finder);
    expect(code_field.focusNode?.hasFocus, isTrue);
    expect(code_field.controller?.selection.baseOffset, 'D'.length);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(code_field.focusNode?.hasFocus, isFalse);
    expect(find.byType(TimePickerSheet), findsNothing);
  });

  testWidgets('코드와 이름 밖 화면을 터치하면 텍스트 포커스를 해제한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    final code_field = tester.widget<CupertinoTextField>(
      find.byKey(const Key('shift_type_code_field')),
    );

    await tester.tap(find.byKey(const Key('shift_type_code_field')));
    await tester.pump();
    expect(code_field.focusNode?.hasFocus, isTrue);

    await tester.tap(find.byKey(const Key('shift_type_code_preview')));
    await tester.pump();

    expect(code_field.focusNode?.hasFocus, isFalse);
  });

  testWidgets('신규 코드는 기존 코드 접두어를 입력하는 동안 중복 표시 없이 키보드를 유지한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      CupertinoApp(
        theme: AppTheme.lightTheme,
        home: ShiftTypeFormModal(existingTypes: [buildShiftType()]),
      ),
    );
    await tester.pumpAndSettle();

    final code_field_finder = find.byKey(const Key('shift_type_code_field'));
    final name_field_finder = find.byKey(const Key('shift_type_name_field'));

    await tester.tap(code_field_finder);
    await tester.enterText(code_field_finder, 'd');
    await tester.pump();

    var code_field = tester.widget<CupertinoTextField>(code_field_finder);
    expect(code_field.controller?.text, 'D');
    expect(code_field.focusNode?.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
    expect(
      find.byKey(const Key('shift_type_code_duplicate_message')),
      findsNothing,
    );

    await tester.enterText(code_field_finder, 'de');
    await tester.pump();

    code_field = tester.widget<CupertinoTextField>(code_field_finder);
    expect(code_field.controller?.text, 'DE');
    expect(code_field.focusNode?.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
    expect(
      find.byKey(const Key('shift_type_code_duplicate_message')),
      findsNothing,
    );

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    final name_field = tester.widget<CupertinoTextField>(name_field_finder);
    expect(code_field.focusNode?.hasFocus, isFalse);
    expect(name_field.focusNode?.hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(
      find.byKey(const Key('shift_type_code_duplicate_message')),
      findsNothing,
    );
  });

  testWidgets('수정 코드는 기존 코드 접두어를 입력하는 동안 중복 표시 없이 키보드를 유지한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      CupertinoApp(
        theme: AppTheme.lightTheme,
        home: ShiftTypeFormModal(
          shiftType: buildEveningShiftType(),
          existingTypes: [buildShiftType(), buildEveningShiftType()],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final code_field_finder = find.byKey(const Key('shift_type_code_field'));

    await tester.tap(code_field_finder);
    await tester.enterText(code_field_finder, 'd');
    await tester.pump();

    var code_field = tester.widget<CupertinoTextField>(code_field_finder);
    expect(code_field.controller?.text, 'D');
    expect(code_field.focusNode?.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
    expect(
      find.byKey(const Key('shift_type_code_duplicate_message')),
      findsNothing,
    );

    await tester.enterText(code_field_finder, 'de');
    await tester.pump();

    code_field = tester.widget<CupertinoTextField>(code_field_finder);
    expect(code_field.controller?.text, 'DE');
    expect(code_field.focusNode?.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
    expect(
      find.byKey(const Key('shift_type_code_duplicate_message')),
      findsNothing,
    );
  });

  testWidgets('다른 근무 타입과 같은 코드는 입력 완료 후 사용 불가를 표시한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      CupertinoApp(
        theme: AppTheme.lightTheme,
        home: ShiftTypeFormModal(
          shiftType: buildShiftType(),
          existingTypes: [buildShiftType(), buildEveningShiftType()],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('shift_type_code_duplicate_message')),
      findsNothing,
    );
    expect(find.byKey(const Key('shift_type_code_error_border')), findsNothing);
    expect(
      tester
          .widget<CupertinoButton>(
            find.byKey(const Key('shift_type_complete_button')),
          )
          .onPressed,
      isNotNull,
    );

    final code_field_finder = find.byKey(const Key('shift_type_code_field'));
    final name_field_finder = find.byKey(const Key('shift_type_name_field'));

    await tester.tap(code_field_finder);
    await tester.enterText(code_field_finder, 'e');
    await tester.pump();

    var code_field = tester.widget<CupertinoTextField>(code_field_finder);
    expect(code_field.controller?.text, 'E');
    expect(code_field.focusNode?.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
    expect(
      find.byKey(const Key('shift_type_code_duplicate_message')),
      findsNothing,
    );
    expect(find.byKey(const Key('shift_type_code_error_border')), findsNothing);
    expect(
      tester
          .widget<CupertinoButton>(
            find.byKey(const Key('shift_type_complete_button')),
          )
          .onPressed,
      isNotNull,
    );

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    code_field = tester.widget<CupertinoTextField>(code_field_finder);
    final name_field = tester.widget<CupertinoTextField>(name_field_finder);
    expect(code_field.focusNode?.hasFocus, isFalse);
    expect(name_field.focusNode?.hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(
      find.byKey(const Key('shift_type_code_duplicate_message')),
      findsOneWidget,
    );
    expect(find.text('이미 사용 중인 코드입니다.'), findsOneWidget);
    final code_error_border = tester.widget<Container>(
      find.byKey(const Key('shift_type_code_error_border')),
    );
    final error_decoration = code_error_border.decoration as BoxDecoration;
    final error_border = error_decoration.border as Border;
    expect(error_border.top.color, AppTheme.accent_red_color);
    expect(error_border.top.width, closeTo(2, 0.01));
    expect(
      tester
          .widget<CupertinoTextField>(
            find.byKey(const Key('shift_type_code_field')),
          )
          .style
          ?.color,
      AppTheme.on_surface_color,
    );
    expect(
      tester
          .widget<CupertinoButton>(
            find.byKey(const Key('shift_type_complete_button')),
          )
          .onPressed,
      isNull,
    );

    tester.testTextInput.hide();
    await tester.pump();
    expect(tester.testTextInput.isVisible, isFalse);

    await tester.tap(code_field_finder);
    await tester.pump();

    code_field = tester.widget<CupertinoTextField>(code_field_finder);
    expect(code_field.focusNode?.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
    expect(
      find.byKey(const Key('shift_type_code_duplicate_message')),
      findsOneWidget,
    );

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'n',
        selection: TextSelection.collapsed(offset: 1),
      ),
    );
    await tester.pump();

    code_field = tester.widget<CupertinoTextField>(code_field_finder);
    expect(code_field.controller?.text, 'N');
    expect(code_field.focusNode?.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
    expect(
      find.byKey(const Key('shift_type_code_duplicate_message')),
      findsNothing,
    );
    expect(find.byKey(const Key('shift_type_code_error_border')), findsNothing);
    expect(
      tester
          .widget<CupertinoButton>(
            find.byKey(const Key('shift_type_complete_button')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('시간 지정을 끄면 두 시간을 숨기고 다시 켜면 편집값을 복원한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();
    final toggle = find.byKey(const Key('shift_type_has_time_switch'));
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shift_type_start_time_row')), findsNothing);
    expect(find.byKey(const Key('shift_type_end_time_row')), findsNothing);
    expect(find.text('시간 없음'), findsOneWidget);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.text('06:30'), findsOneWidget);
    expect(find.text('15:00'), findsOneWidget);
    expect(find.text('총 8시간 30분'), findsOneWidget);
  });

  testWidgets('시간 지정 해제는 수정 요청에 두 시간을 명시적 null로 전송한다', (tester) async {
    UpdateShiftTypeRequest? saved_request;
    await tester.pumpWidget(
      buildResultTestApp(on_result: (result) => saved_request = result),
    );
    await tester.tap(find.text('편집 열기'));
    await tester.pumpAndSettle();
    final toggle = find.byKey(const Key('shift_type_has_time_switch'));
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shift_type_complete_button')));
    await tester.pumpAndSettle();
    expect(saved_request, isNotNull);
    final json = saved_request!.toJson();
    expect(json.containsKey('start_time'), isTrue);
    expect(json.containsKey('end_time'), isTrue);
    expect(json['start_time'], isNull);
    expect(json['end_time'], isNull);
  });

  testWidgets('시간 지정을 껐다 켜고 저장하면 기존 시간 쌍을 유지한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    UpdateShiftTypeRequest? saved_request;
    await tester.pumpWidget(
      buildResultTestApp(on_result: (result) => saved_request = result),
    );
    await tester.tap(find.text('편집 열기'));
    await tester.pumpAndSettle();
    final toggle = find.byKey(const Key('shift_type_has_time_switch'));
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shift_type_complete_button')));
    await tester.pumpAndSettle();
    expect(saved_request?.startTime, '06:30:00');
    expect(saved_request?.endTime, '15:00:00');
  });

  testWidgets('필수 입력 오류는 필드 옆에 표시하고 첫 오류로 포커스를 이동한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var calls = 0;
    await tester.pumpWidget(
      CupertinoApp(
        theme: AppTheme.lightTheme,
        home: ShiftTypeFormModal(
          existingTypes: [],
          onCreate: (_) async {
            calls++;
            return null;
          },
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('shift_type_complete_button')));
    await tester.pumpAndSettle();
    final name = find.byKey(const Key('shift_type_name_field'));
    final code = find.byKey(const Key('shift_type_code_field'));
    expect(find.text('이름을 입력해주세요.'), findsOneWidget);
    expect(find.text('코드를 입력해주세요.'), findsOneWidget);
    expect(tester.widget<CupertinoTextField>(name).focusNode?.hasFocus, isTrue);
    expect(name.hitTestable(), findsOneWidget);
    expect(calls, 0);
    await tester.enterText(name, '오프');
    await tester.tap(find.byKey(const Key('shift_type_complete_button')));
    await tester.pumpAndSettle();
    expect(find.text('이름을 입력해주세요.'), findsNothing);
    expect(tester.widget<CupertinoTextField>(code).focusNode?.hasFocus, isTrue);
    expect(code.hitTestable(), findsOneWidget);
    expect(calls, 0);
  });

  testWidgets('신규 타입은 기본으로 시간을 지정하며 한 시간만 입력하면 인접 오류와 입력을 보존한다', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    CreateShiftTypeRequest? saved_request;
    await tester.pumpWidget(
      buildCreateResultTestApp(on_result: (result) => saved_request = result),
    );
    await tester.tap(find.text('추가 열기'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('shift_type_name_field')),
      '데이',
    );
    await tester.enterText(find.byKey(const Key('shift_type_code_field')), 'D');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    final toggle = find.byKey(const Key('shift_type_has_time_switch'));
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<CupertinoSwitch>(toggle).value, isTrue);
    final start_row = find.byKey(const Key('shift_type_start_time_row'));
    await tester.ensureVisible(start_row);
    await tester.pumpAndSettle();
    await tester.tap(start_row);
    await tester.pumpAndSettle();
    await tester.tap(find.text('선택한 시간 적용'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shift_type_complete_button')));
    await tester.pumpAndSettle();
    expect(saved_request, isNull);
    expect(find.byKey(const Key('shift_type_time_error')), findsOneWidget);
    expect(find.text('시작 시간과 종료 시간을 모두 선택해주세요.'), findsOneWidget);
    expect(
      tester
          .widget<CupertinoTextField>(
            find.byKey(const Key('shift_type_name_field')),
          )
          .controller
          ?.text,
      '데이',
    );
  });

  testWidgets('야간은 다음 날 종료와 시간 간격을 표시하며 같은 시간은 서버처럼 0시간이다', (tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        theme: AppTheme.lightTheme,
        home: ShiftTypeFormModal(
          shiftType: buildIntensityShiftType(),
          existingTypes: [buildIntensityShiftType()],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('22:30 – 다음 날 07:00'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('shift_type_duration_summary')),
    );
    expect(find.text('다음 날 종료 · 총 8시간 30분'), findsOneWidget);
    await tester.pumpWidget(
      CupertinoApp(
        theme: AppTheme.lightTheme,
        home: ShiftTypeFormModal(
          key: const ValueKey('equal-time'),
          shiftType: ShiftTypeApiModel(
            shiftTypeId: 'equal',
            code: 'EQ',
            name: '동일 시간',
            startTime: '09:00:00',
            endTime: '09:00:00',
            crossesMidnight: false,
            durationMinutes: 0,
          ),
          existingTypes: [],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('shift_type_duration_summary')),
    );
    expect(find.text('총 0시간'), findsOneWidget);
    expect(find.text('다음 날'), findsNothing);
  });

  testWidgets('개인 일정과 같은 공용 시간 선택 시트를 사용한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('shift_type_start_time_row')),
    );
    await tester.tap(find.byKey(const Key('shift_type_start_time_row')));
    await tester.pumpAndSettle();

    expect(find.byType(TimePickerSheet), findsOneWidget);
    expect(find.text('시작시간 선택'), findsOneWidget);
    expect(find.text('오전 06:30'), findsOneWidget);
    expect(find.text('지금'), findsOneWidget);
    expect(find.text('선택한 시간 적용'), findsOneWidget);

    await tester.tap(find.text('선택한 시간 적용'));
    await tester.pumpAndSettle();

    expect(find.byType(TimePickerSheet), findsOneWidget);
    expect(find.text('종료시간 선택'), findsOneWidget);
    expect(find.text('06:30'), findsOneWidget);

    await tester.tap(find.text('취소').last);
    await tester.pumpAndSettle();

    expect(find.byType(TimePickerSheet), findsNothing);
  });

  testWidgets('색상 변경은 기존 액션 시트 대신 전체 화면 선택 페이지를 연다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('shift_type_color_button')));
    await tester.pumpAndSettle();

    expect(find.byType(ShiftColorPickerPage), findsOneWidget);
    expect(find.byType(CupertinoActionSheet), findsNothing);

    await tester.tap(find.byKey(const Key('shift_color_preset_2')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('shift_color_complete_button')));
    await tester.pumpAndSettle();

    final preview = tester.widget<Container>(
      find.byKey(const Key('shift_type_code_preview')),
    );
    final decoration = preview.decoration as BoxDecoration;
    expect(decoration.color?.toARGB32(), const Color(0xFF4355B8).toARGB32());
  });

  testWidgets('저장된 기준 색상과 농도를 선택 화면에서 복원해 수정 요청으로 반환한다', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    UpdateShiftTypeRequest? saved_request;
    await tester.pumpWidget(
      buildResultTestApp(
        shift_type: buildIntensityShiftType(),
        on_result: (result) => saved_request = result,
      ),
    );

    await tester.tap(find.text('편집 열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shift_type_color_button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('농도 50%'), findsOneWidget);
    expect(find.textContaining('#A1AADC'), findsOneWidget);
    expect(find.text('나이트 인디고'), findsOneWidget);

    await tester.tap(find.byKey(const Key('shift_color_custom_button')));
    await tester.pumpAndSettle();
    tester
        .widget<CupertinoSlider>(
          find.byKey(const Key('shift_color_intensity_slider')),
        )
        .onChanged!(0.25);
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('shift_custom_color_complete_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shift_color_complete_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shift_type_complete_button')));
    await tester.pumpAndSettle();

    expect(saved_request, isNotNull);
    expect(saved_request?.color, isNull);
    expect(saved_request?.baseColor, const Color(0xFF4355B8).toARGB32());
    expect(saved_request?.colorIntensity, 25);
    expect(saved_request?.toJson()['base_color'], '#FF4355B8');
    expect(saved_request?.toJson()['color_intensity'], 25);
    expect(saved_request?.toJson().containsKey('color'), isFalse);
  });

  testWidgets('색상을 변경하지 않은 편집은 색상 필드를 요청에서 생략한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    UpdateShiftTypeRequest? saved_request;
    await tester.pumpWidget(
      buildResultTestApp(on_result: (result) => saved_request = result),
    );

    await tester.tap(find.text('편집 열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shift_type_complete_button')));
    await tester.pumpAndSettle();

    expect(saved_request, isNotNull);
    expect(saved_request?.code, 'D');
    expect(saved_request?.name, '데이');
    expect(saved_request?.color, isNull);
    expect(saved_request?.baseColor, isNull);
    expect(saved_request?.colorIntensity, isNull);
    expect(saved_request?.toJson().containsKey('color'), isFalse);
    expect(saved_request?.toJson().containsKey('base_color'), isFalse);
    expect(saved_request?.toJson().containsKey('color_intensity'), isFalse);
    expect(saved_request?.startTime, '06:30:00');
    expect(saved_request?.endTime, '15:00:00');
  });

  testWidgets('추가 화면은 기본 기준 색상과 100퍼센트 농도를 요청한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    CreateShiftTypeRequest? saved_request;
    await tester.pumpWidget(
      buildCreateResultTestApp(on_result: (result) => saved_request = result),
    );

    await tester.tap(find.text('추가 열기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('shift_type_code_field')), 'D');
    await tester.enterText(
      find.byKey(const Key('shift_type_name_field')),
      '데이',
    );
    final toggle = find.byKey(const Key('shift_type_has_time_switch'));
    expect(tester.widget<CupertinoSwitch>(toggle).value, isTrue);
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shift_type_complete_button')));
    await tester.pumpAndSettle();

    expect(saved_request, isNotNull);
    expect(saved_request?.color, isNull);
    expect(saved_request?.baseColor, AppTheme.primary_color.toARGB32());
    expect(saved_request?.colorIntensity, 100);
    expect(saved_request?.toJson()['base_color'], '#FF0061A4');
    expect(saved_request?.toJson()['color_intensity'], 100);
    expect(saved_request?.toJson().containsKey('color'), isFalse);
  });

  testWidgets('뒤로가기 화살표는 편집 결과를 반환하지 않는다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var result_received = false;
    UpdateShiftTypeRequest? saved_request;
    await tester.pumpWidget(
      buildResultTestApp(
        on_result: (result) {
          result_received = true;
          saved_request = result;
        },
      ),
    );

    await tester.tap(find.text('편집 열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shift_type_back_button')));
    await tester.pumpAndSettle();

    expect(result_received, isTrue);
    expect(saved_request, isNull);
  });
}
