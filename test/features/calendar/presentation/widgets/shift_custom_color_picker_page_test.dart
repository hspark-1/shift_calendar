// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/shift_color_selection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shift_mate/core/theme/app_theme.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/shift_custom_color_picker_page.dart';

const String _recent_colors_storage_key = 'shift_custom_recent_colors_v1';
const List<String> _default_recent_colors = [
  'FF9500',
  'E85F80',
  '4355B8',
  '448F53',
  '713700',
  'BA1A1A',
];

Widget buildCustomPickerApp({Color initial_color = const Color(0xFF0061A4)}) {
  return CupertinoApp(
    theme: AppTheme.lightTheme,
    home: ShiftCustomColorPickerPage(initial_color: initial_color),
  );
}

Widget buildCustomPickerResultApp({
  required ValueChanged<ShiftColorSelection?> on_result,
}) {
  return CupertinoApp(
    theme: AppTheme.lightTheme,
    home: CupertinoPageScaffold(
      child: Builder(
        builder: (context) => Center(
          child: CupertinoButton(
            onPressed: () async {
              final result = await Navigator.of(context)
                  .push<ShiftColorSelection>(
                    CupertinoPageRoute(
                      builder: (context) => const ShiftCustomColorPickerPage(
                        initial_color: Color(0xFF0061A4),
                      ),
                    ),
                  );
              on_result(result);
            },
            child: const Text('커스텀 열기'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      _recent_colors_storage_key: _default_recent_colors,
    });
  });

  testWidgets('시안의 전체 화면 구조와 초기 색상 정보를 표시한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildCustomPickerApp());
    await tester.pumpAndSettle();

    expect(find.text('커스텀 색상 선택'), findsOneWidget);
    expect(find.text('완료'), findsOneWidget);
    expect(
      tester
          .widget<CupertinoTextField>(
            find.byKey(const Key('shift_custom_color_hex_field')),
          )
          .controller
          ?.text,
      '0061A4',
    );
    expect(find.text('HEX 코드'), findsOneWidget);
    expect(find.text('R'), findsOneWidget);
    expect(find.text('G'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);

    final preview_size = tester.getSize(
      find.byKey(const Key('shift_custom_color_preview')),
    );
    expect(preview_size.width, closeTo(56, 0.01));
    expect(preview_size.height, closeTo(56, 0.01));

    final wheel_size = tester.getSize(
      find.byKey(const Key('shift_custom_color_wheel')),
    );
    expect(wheel_size.width, inInclusiveRange(160, 200));
    expect(wheel_size.height, closeTo(wheel_size.width, 0.01));

    final slider_size = tester.getSize(
      find.byKey(const Key('shift_custom_color_red_slider')),
    );
    expect(slider_size.width, greaterThan(220));
    expect(slider_size.height, greaterThanOrEqualTo(44));
    expect(
      tester
          .getRect(find.byKey(const Key('shift_custom_color_hex_field')))
          .bottom,
      lessThan(
        tester.getRect(find.byKey(const Key('shift_custom_color_wheel'))).top,
      ),
    );

    final wheel_rect = tester.getRect(
      find.byKey(const Key('shift_custom_color_wheel')),
    );
    final rgb_controls_rect = tester.getRect(
      find.byKey(const Key('shift_custom_color_rgb_controls')),
    );
    expect(wheel_rect.bottom, lessThan(rgb_controls_rect.top));
    expect(
      find.descendant(
        of: find.byKey(const Key('shift_custom_color_wheel_card')),
        matching: find.byKey(const Key('shift_custom_color_rgb_controls')),
      ),
      findsOneWidget,
    );

    final scroll_state = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    expect(scroll_state.position.maxScrollExtent, greaterThanOrEqualTo(0));
    await tester.dragFrom(const Offset(8, 500), const Offset(0, -1200));
    await tester.pumpAndSettle();
    expect(scroll_state.position.pixels, greaterThanOrEqualTo(0));
    expect(find.text('최근 사용한 색상'), findsOneWidget);
    expect(
      find.byKey(const Key('shift_custom_color_recent_5')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('휠에서 시작한 빠른 세로 드래그는 스크롤 없이 색상을 계속 조절한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildCustomPickerApp());
    await tester.pumpAndSettle();
    final wheel = find.byKey(const Key('shift_custom_color_wheel'));
    final scroll = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    await tester.ensureVisible(wheel);
    await tester.pumpAndSettle();
    final center = tester.getCenter(wheel);
    final initial_scroll = scroll.pixels;
    final gesture = await tester.startGesture(center + const Offset(20, 50));
    await gesture.moveBy(const Offset(0, -22));
    await tester.pump();
    await gesture.moveBy(const Offset(0, -45));
    await tester.pump();
    expect(scroll.pixels, initial_scroll);
    final first_color = tester
        .widget<CupertinoTextField>(
          find.byKey(const Key('shift_custom_color_hex_field')),
        )
        .controller!
        .text;
    await gesture.moveBy(const Offset(30, -20));
    await tester.pump();
    final next_color = tester
        .widget<CupertinoTextField>(
          find.byKey(const Key('shift_custom_color_hex_field')),
        )
        .controller!
        .text;
    expect(next_color, isNot(first_color));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(scroll.pixels, initial_scroll);
  });

  testWidgets('휠 밖 모서리에서 시작한 드래그는 색상을 바꾸지 않고 스크롤한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildCustomPickerApp());
    await tester.pumpAndSettle();
    final wheel_rect = tester.getRect(
      find.byKey(const Key('shift_custom_color_wheel')),
    );
    final scroll = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    await tester.dragFrom(
      wheel_rect.bottomLeft + const Offset(3, -3),
      const Offset(55, -110),
    );
    await tester.pumpAndSettle();
    expect(scroll.pixels, greaterThan(0));
    expect(
      tester
          .widget<CupertinoTextField>(
            find.byKey(const Key('shift_custom_color_hex_field')),
          )
          .controller!
          .text,
      '0061A4',
    );
  });

  testWidgets('휠 밖까지 드래그한 뒤 취소해도 다음 스크롤과 휠 조절이 정상이다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildCustomPickerApp());
    await tester.pumpAndSettle();
    final wheel = find.byKey(const Key('shift_custom_color_wheel'));
    final scroll = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    await tester.ensureVisible(wheel);
    await tester.pumpAndSettle();
    final initial_scroll = scroll.pixels;
    final gesture = await tester.startGesture(tester.getCenter(wheel));
    await gesture.moveBy(const Offset(120, -120));
    await tester.pump();
    expect(scroll.pixels, initial_scroll);
    await gesture.cancel();
    await tester.pumpAndSettle();
    await tester.dragFrom(const Offset(8, 400), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(scroll.pixels, greaterThan(0));
    final current_scroll = scroll.pixels;
    await tester.tapAt(tester.getCenter(wheel));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CupertinoTextField>(
            find.byKey(const Key('shift_custom_color_hex_field')),
          )
          .controller!
          .text,
      'FFFFFF',
    );
    expect(scroll.pixels, current_scroll);
  });

  testWidgets('휠 조절 중 두 번째 손가락은 선택 색상을 가로채지 않는다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildCustomPickerApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('shift_custom_color_wheel')),
    );
    await tester.pumpAndSettle();
    final center = tester.getCenter(
      find.byKey(const Key('shift_custom_color_wheel')),
    );
    final first = await tester.startGesture(center, pointer: 1);
    await tester.pump();
    final second = await tester.startGesture(
      center + const Offset(50, 0),
      pointer: 2,
    );
    await second.moveBy(const Offset(0, -20));
    await tester.pump();
    expect(
      tester
          .widget<CupertinoTextField>(
            find.byKey(const Key('shift_custom_color_hex_field')),
          )
          .controller!
          .text,
      'FFFFFF',
    );
    await second.up();
    await first.moveBy(const Offset(40, 0));
    await tester.pump();
    expect(
      tester
          .widget<CupertinoTextField>(
            find.byKey(const Key('shift_custom_color_hex_field')),
          )
          .controller!
          .text,
      isNot('FFFFFF'),
    );
    await first.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('HEX 입력을 미리보기와 RGB 값에 동기화한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildCustomPickerApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('shift_custom_color_hex_field')),
      'ff0000',
    );
    await tester.pump();

    expect(
      tester
          .widget<CupertinoTextField>(
            find.byKey(const Key('shift_custom_color_hex_field')),
          )
          .controller
          ?.text,
      'FF0000',
    );
    final red_value = tester.widget<Text>(
      find.byKey(const Key('shift_custom_color_red_value')),
    );
    final green_value = tester.widget<Text>(
      find.byKey(const Key('shift_custom_color_green_value')),
    );
    final blue_value = tester.widget<Text>(
      find.byKey(const Key('shift_custom_color_blue_value')),
    );
    expect(red_value.data, '255');
    expect(green_value.data, '0');
    expect(blue_value.data, '0');
  });

  testWidgets('RGB 슬라이더와 색상 휠이 HEX 값에 동기화된다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildCustomPickerApp());
    await tester.pumpAndSettle();

    final green_slider = tester.widget<CupertinoSlider>(
      find.byKey(const Key('shift_custom_color_green_slider')),
    );
    green_slider.onChanged?.call(0);
    await tester.pump();

    expect(
      tester
          .widget<CupertinoTextField>(
            find.byKey(const Key('shift_custom_color_hex_field')),
          )
          .controller
          ?.text,
      '0000A4',
    );

    await tester.tapAt(
      tester.getCenter(find.byKey(const Key('shift_custom_color_wheel'))),
    );
    await tester.pump();

    expect(
      tester
          .widget<CupertinoTextField>(
            find.byKey(const Key('shift_custom_color_hex_field')),
          )
          .controller
          ?.text,
      'FFFFFF',
    );
  });

  testWidgets('최근 색상 선택을 모든 정밀 제어 값에 반영한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildCustomPickerApp());
    await tester.pumpAndSettle();

    await tester.dragFrom(const Offset(8, 500), const Offset(0, -1200));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shift_custom_color_recent_2')));
    await tester.pump();

    expect(
      tester
          .widget<CupertinoTextField>(
            find.byKey(const Key('shift_custom_color_hex_field')),
          )
          .controller
          ?.text,
      '4355B8',
    );
    final hex_field = tester.widget<CupertinoTextField>(
      find.byKey(const Key('shift_custom_color_hex_field')),
    );
    expect(hex_field.controller?.text, '4355B8');
  });

  testWidgets('저장된 최근 색상이 없으면 빈 상태를 표시한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(buildCustomPickerApp());
    await tester.pumpAndSettle();
    await tester.dragFrom(const Offset(8, 500), const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('shift_custom_color_recent_empty')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('shift_custom_color_recent_0')), findsNothing);
  });

  testWidgets('농도는 적용색만 바꾸고 HEX와 RGB는 기준색을 유지한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      CupertinoApp(
        theme: AppTheme.lightTheme,
        home: ShiftCustomColorPickerPage(
          initial_color: Color(0xFFA1AADC),
          initial_base_color: Color(0xFF4355B8),
          initial_color_intensity: 50,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final field = find.byKey(const Key('shift_custom_color_hex_field'));
    expect(tester.widget<CupertinoTextField>(field).controller!.text, '4355B8');
    expect(find.text('#A1AADC'), findsOneWidget);
    final slider = find.byKey(const Key('shift_color_intensity_slider'));
    tester.widget<CupertinoSlider>(slider).onChanged!(0);
    await tester.pump();
    expect(find.text('#FFFFFF'), findsOneWidget);
    expect(tester.widget<CupertinoTextField>(field).controller!.text, '4355B8');
    tester.widget<CupertinoSlider>(slider).onChanged!(1);
    await tester.pump();
    expect(find.text('#4355B8'), findsOneWidget);
    tester.widget<CupertinoSlider>(slider).onChanged!(0.5);
    await tester.enterText(field, 'FF0000');
    await tester.pump();
    expect(find.text('#FF8080'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('shift_custom_color_red_value')))
          .data,
      '255',
    );
    expect(tester.widget<CupertinoSlider>(slider).value, 0.5);
    expect(
      (tester
                  .widget<Container>(
                    find.byKey(const Key('shift_custom_color_preview')),
                  )
                  .decoration!
              as BoxDecoration)
          .color!
          .a,
      1,
    );
  });

  testWidgets('최근 색상은 기준색과 농도를 저장하고 다시 선택하면 그대로 복원한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final results = <ShiftColorSelection?>[];
    await tester.pumpWidget(buildCustomPickerResultApp(on_result: results.add));
    await tester.tap(find.text('커스텀 열기'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('shift_custom_color_hex_field')),
      '4355B8',
    );
    tester
        .widget<CupertinoSlider>(
          find.byKey(const Key('shift_color_intensity_slider')),
        )
        .onChanged!(0.5);
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('shift_custom_color_complete_button')),
    );
    await tester.pumpAndSettle();
    expect(results.single!.base_color, 0xFF4355B8);
    expect(results.single!.color_intensity, 50);
    expect(results.single!.final_color, 0xFFA1AADC);
    final preferences = await SharedPreferences.getInstance();
    expect(
      jsonDecode(
        preferences.getStringList('shift_custom_recent_selections_v2')!.first,
      ),
      {'base_color': '4355B8', 'color_intensity': 50},
    );
    expect(
      preferences.getStringList(_recent_colors_storage_key)!.first,
      'A1AADC',
    );
    await tester.tap(find.text('커스텀 열기'));
    await tester.pumpAndSettle();
    await tester.dragFrom(const Offset(8, 500), const Offset(0, -1400));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shift_custom_color_recent_0')));
    await tester.pump();
    expect(
      tester
          .widget<CupertinoTextField>(
            find.byKey(const Key('shift_custom_color_hex_field')),
          )
          .controller!
          .text,
      '4355B8',
    );
    expect(
      tester
          .widget<CupertinoSlider>(
            find.byKey(const Key('shift_color_intensity_slider')),
          )
          .value,
      0.5,
    );
    await tester.tap(
      find.byKey(const Key('shift_custom_color_complete_button')),
    );
    await tester.pumpAndSettle();
    expect(results.last!.final_color, 0xFFA1AADC);
    expect(results.last!.color_intensity, 50);
  });

  testWidgets('잘못된 최근 색상 메타데이터는 제외하고 기존 RGB 기록으로 복구한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      _recent_colors_storage_key: ['4355B8'],
      'shift_custom_recent_selections_v2': [
        'broken json',
        jsonEncode({'base_color': '4355B8', 'color_intensity': 101}),
        jsonEncode({'base_color': 'INVALID', 'color_intensity': 50}),
      ],
    });
    await tester.pumpWidget(buildCustomPickerApp());
    await tester.pumpAndSettle();
    await tester.dragFrom(const Offset(8, 500), const Offset(0, -1400));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shift_custom_color_recent_0')));
    await tester.pump();
    expect(
      tester
          .widget<CupertinoTextField>(
            find.byKey(const Key('shift_custom_color_hex_field')),
          )
          .controller!
          .text,
      '4355B8',
    );
    expect(
      tester
          .widget<CupertinoSlider>(
            find.byKey(const Key('shift_color_intensity_slider')),
          )
          .value,
      1,
    );
    expect(find.text('#4355B8'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('농도 슬라이더는 트랙 터치와 드래그로 조절되고 화면은 스크롤되지 않는다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildCustomPickerApp());
    await tester.pumpAndSettle();
    final slider = find.byKey(const Key('shift_color_intensity_slider'));
    await tester.ensureVisible(slider);
    await tester.pumpAndSettle();
    final scroll = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    final initial_scroll = scroll.pixels;
    await tester.tap(slider);
    await tester.pumpAndSettle();
    expect(tester.widget<CupertinoSlider>(slider).value, closeTo(0.5, 0.02));
    await tester.drag(slider, const Offset(40, 0));
    await tester.pumpAndSettle();
    expect(tester.widget<CupertinoSlider>(slider).value, greaterThan(0.5));
    expect(scroll.pixels, initial_scroll);
  });

  testWidgets('적용 색상을 최신순·중복 없이 최대 6개까지 저장한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      _recent_colors_storage_key: [
        '111111',
        'ABCDEF',
        '222222',
        'INVALID',
        '333333',
        '444444',
        '555555',
        '666666',
      ],
    });

    final results = <ShiftColorSelection?>[];
    await tester.pumpWidget(buildCustomPickerResultApp(on_result: results.add));

    await tester.tap(find.text('커스텀 열기'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('shift_custom_color_hex_field')),
      'ABCDEF',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('shift_custom_color_complete_button')),
    );
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getStringList(_recent_colors_storage_key), [
      'ABCDEF',
      '111111',
      '222222',
      '333333',
      '444444',
      '555555',
    ]);
    expect(results.single?.final_color, const Color(0xFFABCDEF).toARGB32());
  });

  testWidgets('적용은 선택 색상을 반환하고 뒤로가기는 값을 폐기한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final results = <ShiftColorSelection?>[];
    await tester.pumpWidget(buildCustomPickerResultApp(on_result: results.add));

    await tester.tap(find.text('커스텀 열기'));
    await tester.pumpAndSettle();
    await tester.dragFrom(const Offset(8, 500), const Offset(0, -1200));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shift_custom_color_recent_4')));
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('shift_custom_color_complete_button')),
    );
    await tester.pumpAndSettle();

    expect(results.single?.final_color, const Color(0xFF713700).toARGB32());

    await tester.tap(find.text('커스텀 열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shift_custom_color_back_button')));
    await tester.pumpAndSettle();

    expect(results, hasLength(2));
    expect(results.last, isNull);
  });
}
