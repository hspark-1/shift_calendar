// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
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
  testWidgets('친구 설정 화면과 같은 컴팩트 카드 레이아웃으로 편집값을 표시한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('근무 타입 편집'), findsOneWidget);
    expect(find.byKey(const Key('shift_type_back_button')), findsOneWidget);
    expect(find.text('완료'), findsOneWidget);
    expect(find.text('취소'), findsNothing);
    expect(find.text('저장'), findsNothing);
    expect(find.text('색상 변경'), findsOneWidget);
    expect(find.text('근무 시간'), findsOneWidget);
    expect(find.text('시작 시간'), findsOneWidget);
    expect(find.text('종료 시간'), findsOneWidget);
    expect(find.text('06:30'), findsOneWidget);
    expect(find.text('15:00'), findsOneWidget);

    final preview_size = tester.getSize(
      find.byKey(const Key('shift_type_code_preview')),
    );
    expect(preview_size.width, closeTo(76.8, 0.01));
    expect(preview_size.height, closeTo(76.8, 0.01));
    expect(
      tester.getSize(find.byKey(const Key('shift_type_start_time_row'))).height,
      closeTo(44.8, 0.01),
    );

    final navigation_title = tester.widget<Text>(find.text('근무 타입 편집'));
    final section_title = tester.widget<Text>(find.text('근무 시간'));
    expect(navigation_title.style?.fontSize, AppTheme.heading_small.fontSize);
    expect(section_title.style?.fontSize, 12.8);

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

  testWidgets('코드부터 종료 시간까지 입력 포커스를 순서대로 이동한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    final code_field = tester.widget<CupertinoTextField>(
      find.byKey(const Key('shift_type_code_field')),
    );
    final name_field = tester.widget<CupertinoTextField>(
      find.byKey(const Key('shift_type_name_field')),
    );
    code_field.controller?.selection = const TextSelection.collapsed(offset: 0);
    name_field.controller?.selection = const TextSelection.collapsed(offset: 0);

    await tester.tap(find.byKey(const Key('shift_type_code_field')));
    await tester.pump();

    expect(code_field.focusNode?.hasFocus, isTrue);
    expect(code_field.controller?.selection.baseOffset, 'D'.length);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(code_field.focusNode?.hasFocus, isFalse);
    expect(name_field.focusNode?.hasFocus, isTrue);
    expect(name_field.controller?.selection.baseOffset, '데이'.length);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(name_field.focusNode?.hasFocus, isFalse);
    expect(find.byType(TimePickerSheet), findsOneWidget);
    expect(find.text('시작시간 선택'), findsOneWidget);

    await tester.tap(find.text('선택한 시간 적용'));
    await tester.pumpAndSettle();

    expect(find.byType(TimePickerSheet), findsOneWidget);
    expect(find.text('시작시간 선택'), findsNothing);
    expect(find.text('종료시간 선택'), findsOneWidget);

    await tester.tap(find.text('선택한 시간 적용'));
    await tester.pumpAndSettle();

    expect(find.byType(TimePickerSheet), findsNothing);
    expect(code_field.focusNode?.hasFocus, isFalse);
    expect(name_field.focusNode?.hasFocus, isFalse);
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

  testWidgets('다른 근무 타입의 코드를 입력하면 사용 불가를 즉시 표시한다', (tester) async {
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
    expect(
      tester
          .widget<Container>(find.byKey(const Key('shift_type_code_row')))
          .foregroundDecoration,
      isNull,
    );
    expect(
      tester
          .widget<CupertinoButton>(
            find.byKey(const Key('shift_type_complete_button')),
          )
          .onPressed,
      isNotNull,
    );

    await tester.enterText(find.byKey(const Key('shift_type_code_field')), 'e');
    await tester.pump();

    expect(
      find.byKey(const Key('shift_type_code_duplicate_message')),
      findsOneWidget,
    );
    expect(find.text('이미 사용 중인 코드입니다.'), findsOneWidget);
    final code_row = tester.widget<Container>(
      find.byKey(const Key('shift_type_code_row')),
    );
    final error_decoration = code_row.foregroundDecoration as BoxDecoration;
    final error_border = error_decoration.border as Border;
    expect(error_border.top.color, AppTheme.accent_red_color);
    expect(error_border.top.width, closeTo(1.6, 0.01));
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

    await tester.enterText(find.byKey(const Key('shift_type_code_field')), 'n');
    await tester.pump();

    expect(
      find.byKey(const Key('shift_type_code_duplicate_message')),
      findsNothing,
    );
    expect(
      tester
          .widget<Container>(find.byKey(const Key('shift_type_code_row')))
          .foregroundDecoration,
      isNull,
    );
    expect(
      tester
          .widget<CupertinoButton>(
            find.byKey(const Key('shift_type_complete_button')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('시간 삭제 액션은 누른 시간만 비운다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsNWidgets(2));

    final clear_icon_right = tester
        .getRect(find.byIcon(CupertinoIcons.xmark_circle_fill).first)
        .right;
    final code_editable = find.descendant(
      of: find.byKey(const Key('shift_type_code_field')),
      matching: find.byType(EditableText),
    );
    final name_editable = find.descendant(
      of: find.byKey(const Key('shift_type_name_field')),
      matching: find.byType(EditableText),
    );
    expect(
      tester.getRect(code_editable).right,
      closeTo(clear_icon_right, 0.01),
    );
    expect(
      tester.getRect(name_editable).right,
      closeTo(clear_icon_right, 0.01),
    );

    await tester.tap(find.byKey(const Key('shift_type_start_time_clear')));
    await tester.pump();

    expect(find.text('06:30'), findsNothing);
    expect(find.text('15:00'), findsOneWidget);
    expect(find.text('시간 선택'), findsOneWidget);
    expect(find.byKey(const Key('shift_type_start_time_clear')), findsNothing);
    expect(find.byKey(const Key('shift_type_end_time_clear')), findsOneWidget);
    expect(find.byType(CupertinoDatePicker), findsNothing);
    expect(
      tester
          .getRect(find.byKey(const Key('shift_type_start_time_value')))
          .right,
      closeTo(clear_icon_right, 0.01),
    );

    await tester.tap(find.byKey(const Key('shift_type_complete_button')));
    await tester.pumpAndSettle();

    expect(find.text('시작시간과 종료시간을 모두 입력하거나 모두 비워주세요.'), findsOneWidget);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shift_type_end_time_clear')));
    await tester.pump();

    expect(find.text('15:00'), findsNothing);
    expect(find.text('시간 선택'), findsNWidgets(2));
    expect(
      tester.getRect(find.byKey(const Key('shift_type_end_time_value'))).right,
      closeTo(clear_icon_right, 0.01),
    );
  });

  testWidgets('개인 일정과 같은 공용 시간 선택 시트를 사용한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

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

    await tester.tap(find.text('취소'));
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

    expect(find.text('50%'), findsOneWidget);
    expect(find.text('#A1AADC'), findsOneWidget);
    expect(find.text('나이트 인디고'), findsOneWidget);

    await tester.tap(find.byKey(const Key('shift_color_complete_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shift_type_complete_button')));
    await tester.pumpAndSettle();

    expect(saved_request, isNotNull);
    expect(saved_request?.color, isNull);
    expect(saved_request?.baseColor, const Color(0xFF4355B8).toARGB32());
    expect(saved_request?.colorIntensity, 50);
    expect(saved_request?.toJson()['base_color'], '#FF4355B8');
    expect(saved_request?.toJson()['color_intensity'], 50);
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

  testWidgets('좌측 화살표는 편집 결과를 반환하지 않는다', (tester) async {
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
