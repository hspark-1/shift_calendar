// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shift_calendar/core/theme/app_theme.dart';
import 'package:shift_calendar/features/calendar/presentation/widgets/shift_color_picker_page.dart';
import 'package:shift_calendar/features/calendar/presentation/widgets/shift_custom_color_picker_page.dart';

const String _recent_colors_storage_key = 'shift_custom_recent_colors_v1';
const List<String> _default_recent_colors = [
  'FF9500',
  'E85F80',
  '4355B8',
  '448F53',
  '713700',
  'BA1A1A',
];

Widget buildPickerApp({Color initial_color = const Color(0xFFFF9500)}) {
  return CupertinoApp(
    theme: AppTheme.lightTheme,
    home: ShiftColorPickerPage(initial_color: initial_color),
  );
}

Widget buildPickerResultApp({required ValueChanged<Color?> on_result}) {
  return CupertinoApp(
    theme: AppTheme.lightTheme,
    home: CupertinoPageScaffold(
      child: Builder(
        builder: (context) => Center(
          child: CupertinoButton(
            onPressed: () async {
              final result = await Navigator.of(context).push<Color>(
                CupertinoPageRoute(
                  builder: (context) => const ShiftColorPickerPage(
                    initial_color: Color(0xFFFF9500),
                  ),
                ),
              );
              on_result(result);
            },
            child: const Text('색상 열기'),
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

  testWidgets('시안 구조와 초기 프리셋 색상을 표시한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildPickerApp());
    await tester.pumpAndSettle();

    expect(find.text('색상 선택'), findsOneWidget);
    expect(find.text('선택한 색상'), findsOneWidget);
    expect(find.text('#FF9500'), findsOneWidget);
    expect(find.text('데이 오렌지'), findsOneWidget);
    expect(find.text('프리셋 색상'), findsOneWidget);
    expect(find.text('12개 선택 가능'), findsNothing);
    expect(find.text('색상 농도'), findsOneWidget);
    expect(find.text('불투명하게 색을 옅게 조절해요'), findsOneWidget);
    expect(find.text('커스텀 색상 선택'), findsOneWidget);
    expect(find.text('SATURATION'), findsNothing);
    expect(find.text('BRIGHTNESS'), findsNothing);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('적용'), findsOneWidget);
    expect(find.byKey(const Key('shift_color_back_button')), findsOneWidget);
    expect(
      find.byKey(const Key('shift_color_complete_button')),
      findsOneWidget,
    );
    expect(find.byIcon(CupertinoIcons.xmark), findsNothing);
    expect(find.byIcon(CupertinoIcons.pencil), findsNothing);
    expect(find.text('선택 완료'), findsNothing);

    final preview_rect = tester.getRect(
      find.byKey(const Key('shift_color_preview')),
    );
    final divider_rect = tester.getRect(
      find.byKey(const Key('shift_color_preview_divider')),
    );
    final hex_rect = tester.getRect(
      find.byKey(const Key('shift_color_hex_label')),
    );
    final name_rect = tester.getRect(
      find.byKey(const Key('shift_color_name_label')),
    );
    expect(preview_rect.width, closeTo(76.8, 0.01));
    expect(preview_rect.height, closeTo(76.8, 0.01));
    expect(preview_rect.right, lessThan(divider_rect.left));
    expect(divider_rect.right, lessThan(name_rect.left));
    expect(divider_rect.right, lessThan(hex_rect.left));
    expect(name_rect.bottom, lessThan(hex_rect.top));
    expect(
      find.descendant(
        of: find.byKey(const Key('shift_color_preview_card')),
        matching: find.byKey(const Key('shift_color_preview')),
      ),
      findsOneWidget,
    );
    final preview_card = tester.widget<Container>(
      find.byKey(const Key('shift_color_preview_card')),
    );
    final preview_card_decoration = preview_card.decoration! as BoxDecoration;
    expect(preview_card_decoration.color, AppTheme.surface_color);
    expect(preview_card_decoration.border, isNotNull);

    final swatch_size = tester.getSize(
      find.byKey(const Key('shift_color_swatch_0')),
    );
    expect(swatch_size.width, closeTo(41.6, 0.01));
    expect(swatch_size.height, closeTo(41.6, 0.01));
    expect(
      tester
          .getSize(find.byKey(const Key('shift_color_complete_button')))
          .height,
      44,
    );

    final navigation_title = tester.widget<Text>(find.text('색상 선택'));
    final color_name = tester.widget<Text>(
      find.byKey(const Key('shift_color_name_label')),
    );
    expect(navigation_title.style?.fontSize, AppTheme.heading_small.fontSize);
    expect(color_name.style?.fontSize, 12.8);

    for (var index = 0; index < 12; index++) {
      expect(find.byKey(Key('shift_color_preset_$index')), findsOneWidget);
    }
    final preset_rect = tester.getRect(
      find.byKey(const Key('shift_color_preset_card')),
    );
    final intensity_rect = tester.getRect(
      find.byKey(const Key('shift_color_intensity_card')),
    );
    final custom_rect = tester.getRect(
      find.byKey(const Key('shift_color_custom_button')),
    );
    expect(preset_rect.bottom, lessThan(intensity_rect.top));
    expect(intensity_rect.bottom, lessThan(custom_rect.top));
    expect(tester.takeException(), isNull);
  });

  testWidgets('프리셋과 불투명 색상 농도를 선택 색상에 반영한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildPickerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('shift_color_preset_2')));
    await tester.pump();

    expect(find.text('#4355B8'), findsOneWidget);
    expect(find.text('나이트 인디고'), findsOneWidget);

    final slider = tester.widget<CupertinoSlider>(
      find.byKey(const Key('shift_color_intensity_slider')),
    );
    slider.onChanged?.call(0.5);
    await tester.pump();

    expect(find.text('50%'), findsOneWidget);
    expect(find.text('#A1AADC'), findsOneWidget);
    expect(find.text('나이트 인디고'), findsOneWidget);
    final preview = tester.widget<AnimatedContainer>(
      find.byKey(const Key('shift_color_preview')),
    );
    final preview_decoration = preview.decoration! as BoxDecoration;
    expect(
      preview_decoration.color?.toARGB32(),
      const Color(0xFFA1AADC).toARGB32(),
    );
    expect(preview_decoration.color?.a, 1);
  });

  testWidgets('농도 트랙 터치와 원하는 위치에서 시작한 드래그를 지원한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildPickerApp());
    await tester.pumpAndSettle();

    final gesture_area = find.byKey(
      const Key('shift_color_intensity_gesture_area'),
    );
    final gesture_rect = tester.getRect(gesture_area);
    const track_inset = 22.0;
    final track_width = gesture_rect.width - (track_inset * 2);
    final track_center_y = gesture_rect.center.dy;

    await tester.tapAt(
      Offset(
        gesture_rect.left + track_inset + (track_width * 0.5),
        track_center_y,
      ),
    );
    await tester.pump();
    expect(find.text('50%'), findsOneWidget);

    await tester.drag(gesture_area, Offset(-(track_width * 0.25), 0));
    await tester.pump();
    final intensity_label = tester.widget<Text>(
      find.byKey(const Key('shift_color_intensity_label')),
    );
    expect(intensity_label.data, '25%');

    final drag = await tester.startGesture(
      Offset(
        gesture_rect.left + track_inset + (track_width * 0.25),
        track_center_y,
      ),
    );
    await drag.moveTo(
      Offset(
        gesture_rect.left + track_inset + (track_width * 0.75),
        track_center_y,
      ),
    );
    await drag.up();
    await tester.pump();

    expect(find.text('75%'), findsOneWidget);
  });

  testWidgets('모든 프리셋 선택에서 하단 섹션 위치가 유지된다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildPickerApp());
    await tester.pumpAndSettle();

    final list_view = find.byType(ListView);
    final scrollable_state = tester.state<ScrollableState>(
      find.descendant(of: list_view, matching: find.byType(Scrollable)).first,
    );
    final initial_scroll_offset = scrollable_state.position.pixels;
    final initial_name_slot_height = tester
        .getSize(find.byKey(const Key('shift_color_name_slot')))
        .height;
    final initial_preset_top = tester
        .getRect(find.byKey(const Key('shift_color_preset_card')))
        .top;
    final initial_intensity_top = tester
        .getRect(find.byKey(const Key('shift_color_intensity_card')))
        .top;
    final initial_custom_top = tester
        .getRect(find.byKey(const Key('shift_color_custom_button')))
        .top;
    expect(initial_name_slot_height, closeTo(19.2, 0.01));

    for (var index = 0; index < 12; index++) {
      await tester.tap(find.byKey(Key('shift_color_preset_$index')));
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byKey(const Key('shift_color_name_slot'))).height,
        closeTo(initial_name_slot_height, 0.01),
        reason: '프리셋 $index 선택 후 색상명 슬롯 높이',
      );
      expect(
        scrollable_state.position.pixels,
        closeTo(initial_scroll_offset, 0.01),
        reason: '프리셋 $index 선택 후 스크롤 위치',
      );
      expect(
        tester.getRect(find.byKey(const Key('shift_color_preset_card'))).top,
        closeTo(initial_preset_top, 0.01),
        reason: '프리셋 $index 선택 후 프리셋 카드 위치',
      );
      expect(
        tester.getRect(find.byKey(const Key('shift_color_intensity_card'))).top,
        closeTo(initial_intensity_top, 0.01),
        reason: '프리셋 $index 선택 후 농도 카드 위치',
      );
      expect(
        tester.getRect(find.byKey(const Key('shift_color_custom_button'))).top,
        closeTo(initial_custom_top, 0.01),
        reason: '프리셋 $index 선택 후 커스텀 버튼 위치',
      );
    }
  });

  testWidgets('헤더 적용은 현재 프리셋 색상을 호출 화면에 반환한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Color? selected_color;
    await tester.pumpWidget(
      buildPickerResultApp(on_result: (result) => selected_color = result),
    );

    await tester.tap(find.text('색상 열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shift_color_preset_7')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('shift_color_complete_button')));
    await tester.pumpAndSettle();

    expect(selected_color?.toARGB32(), const Color(0xFF27AE60).toARGB32());
  });

  testWidgets('좌측 화살표는 변경한 색상을 반환하지 않는다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var result_received = false;
    Color? selected_color;
    await tester.pumpWidget(
      buildPickerResultApp(
        on_result: (result) {
          result_received = true;
          selected_color = result;
        },
      ),
    );

    await tester.tap(find.text('색상 열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shift_color_preset_7')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('shift_color_back_button')));
    await tester.pumpAndSettle();

    expect(result_received, isTrue);
    expect(selected_color, isNull);
  });

  testWidgets('전체 화면 커스텀 색상 페이지에서 선택한 색상을 적용한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildPickerApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('shift_color_custom_button')),
    );
    await tester.tap(find.byKey(const Key('shift_color_custom_button')));
    await tester.pumpAndSettle();

    expect(find.byType(ShiftCustomColorPickerPage), findsOneWidget);
    expect(find.text('Hex Code'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.text('최근 사용한 색상'), findsOneWidget);
    await tester.tap(find.byKey(const Key('shift_custom_color_recent_5')));
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('shift_custom_color_complete_button')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shift_color_name_label')), findsOneWidget);
    expect(find.text('커스텀 색상'), findsOneWidget);
    expect(find.text('#BA1A1A'), findsOneWidget);
  });
}
