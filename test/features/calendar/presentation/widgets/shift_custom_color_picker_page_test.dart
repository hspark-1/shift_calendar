// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/cupertino.dart';
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

Widget buildCustomPickerResultApp({required ValueChanged<Color?> on_result}) {
  return CupertinoApp(
    theme: AppTheme.lightTheme,
    home: CupertinoPageScaffold(
      child: Builder(
        builder: (context) => Center(
          child: CupertinoButton(
            onPressed: () async {
              final result = await Navigator.of(context).push<Color>(
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
    expect(find.text('적용'), findsOneWidget);
    expect(find.text('SELECTED COLOR'), findsOneWidget);
    expect(find.text('#0061A4'), findsOneWidget);
    expect(find.text('Hex Code'), findsOneWidget);
    expect(find.text('Red'), findsOneWidget);
    expect(find.text('Green'), findsOneWidget);
    expect(find.text('Blue'), findsOneWidget);

    final preview_size = tester.getSize(
      find.byKey(const Key('shift_custom_color_preview')),
    );
    expect(preview_size.width, closeTo(102.4, 0.01));
    expect(preview_size.height, closeTo(102.4, 0.01));

    final wheel_size = tester.getSize(
      find.byKey(const Key('shift_custom_color_wheel')),
    );
    expect(wheel_size.width, inInclusiveRange(160, 176));
    expect(wheel_size.height, closeTo(wheel_size.width, 0.01));

    final red_slider_transform = tester.widget<Transform>(
      find.byKey(const Key('shift_custom_color_red_slider_transform')),
    );
    expect(red_slider_transform.transform.storage[0], 1);
    expect(red_slider_transform.transform.storage[5], closeTo(0.8, 0.01));

    final wheel_rect = tester.getRect(
      find.byKey(const Key('shift_custom_color_wheel')),
    );
    final rgb_controls_rect = tester.getRect(
      find.byKey(const Key('shift_custom_color_rgb_controls')),
    );
    expect(wheel_rect.right, lessThan(rgb_controls_rect.left));
    expect(
      find.descendant(
        of: find.byKey(const Key('shift_custom_color_wheel_card')),
        matching: find.byKey(const Key('shift_custom_color_rgb_controls')),
      ),
      findsOneWidget,
    );

    final list_view = tester.widget<ListView>(find.byType(ListView));
    expect(list_view.physics, isA<NeverScrollableScrollPhysics>());
    final preview_top_before_drag = tester.getTopLeft(
      find.byKey(const Key('shift_custom_color_preview')),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.byKey(const Key('shift_custom_color_preview'))),
      preview_top_before_drag,
    );
    expect(find.text('최근 사용한 색상'), findsOneWidget);
    expect(
      find.byKey(const Key('shift_custom_color_recent_5')),
      findsOneWidget,
    );
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

    expect(find.text('#FF0000'), findsOneWidget);
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

    expect(find.text('#0000A4'), findsOneWidget);

    await tester.tapAt(
      tester.getCenter(find.byKey(const Key('shift_custom_color_wheel'))),
    );
    await tester.pump();

    expect(find.text('#FFFFFF'), findsOneWidget);
  });

  testWidgets('최근 색상 선택을 모든 정밀 제어 값에 반영한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildCustomPickerApp());
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shift_custom_color_recent_2')));
    await tester.pump();

    expect(find.text('#4355B8'), findsOneWidget);
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
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('shift_custom_color_recent_empty')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('shift_custom_color_recent_0')), findsNothing);
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

    final results = <Color?>[];
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
    expect(results.single?.toARGB32(), const Color(0xFFABCDEF).toARGB32());
  });

  testWidgets('적용은 선택 색상을 반환하고 뒤로가기는 값을 폐기한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final results = <Color?>[];
    await tester.pumpWidget(buildCustomPickerResultApp(on_result: results.add));

    await tester.tap(find.text('커스텀 열기'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shift_custom_color_recent_4')));
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('shift_custom_color_complete_button')),
    );
    await tester.pumpAndSettle();

    expect(results.single?.toARGB32(), const Color(0xFF713700).toARGB32());

    await tester.tap(find.text('커스텀 열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shift_custom_color_back_button')));
    await tester.pumpAndSettle();

    expect(results, hasLength(2));
    expect(results.last, isNull);
  });
}
