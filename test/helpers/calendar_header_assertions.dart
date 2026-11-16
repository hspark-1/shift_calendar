// ignore_for_file: non_constant_identifier_names

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/core/theme/app_theme.dart';
import 'package:table_calendar/table_calendar.dart';

/// 실제 페이지의 달력 치수, 일정 접근, 탐색을 여러 화면 조건에서 검증한다.
Future<void> verifyResponsiveCalendar(
  WidgetTester tester, {
  required WidgetBuilder page_builder,
  required String prefix,
  required String calendar_key,
  required String last_member_key,
}) async {
  for (final entry in {
    'Cafe24SsurroundAir': 'assets/fonts/Cafe24SsurroundAir-v1.1.ttf',
    'Cafe24Ssurround': 'assets/fonts/Cafe24Ssurround-v2.0.ttf',
    'packages/cupertino_icons/CupertinoIcons':
        'packages/cupertino_icons/assets/CupertinoIcons.ttf',
  }.entries) {
    await (FontLoader(entry.key)..addFont(rootBundle.load(entry.value))).load();
  }
  addTearDown(() => tester.binding.setSurfaceSize(null));
  for (final scenario in [
    (size: const Size(320, 568), scale: 1.0, dark: false),
    (size: const Size(375, 667), scale: 1.0, dark: false),
    (size: const Size(390, 844), scale: 1.0, dark: false),
    (size: const Size(667, 375), scale: 1.0, dark: false),
    (size: const Size(768, 1024), scale: 1.0, dark: false),
    (size: const Size(375, 667), scale: 3.2, dark: false),
    (size: const Size(375, 667), scale: 1.0, dark: true),
  ]) {
    await tester.binding.setSurfaceSize(scenario.size);
    final capture_key = GlobalKey();
    await tester.pumpWidget(
      CupertinoApp(
        theme: AppTheme.lightTheme.copyWith(
          brightness: scenario.dark ? Brightness.dark : Brightness.light,
        ),
        home: MediaQuery(
          data: MediaQueryData(
            size: scenario.size,
            textScaler: TextScaler.linear(scenario.scale),
            disableAnimations: scenario.dark,
            padding: const EdgeInsets.only(top: 20, bottom: 24),
          ),
          child: RepaintBoundary(
            key: capture_key,
            child: Builder(builder: page_builder),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final calendar = find.byKey(ValueKey(calendar_key));
    final table = tester.widget<TableCalendar<void>>(calendar);
    expect(table.daysOfWeekHeight, greaterThanOrEqualTo(32));
    final month_title = find.text(
      '${table.focusedDay.year}.${table.focusedDay.month.toString().padLeft(2, '0')}',
    );
    final title_paragraph = tester.renderObject<RenderParagraph>(month_title);
    final title_boxes = title_paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 7),
    );
    expect(title_boxes.map((box) => box.top).toSet(), hasLength(1));
    final weekday = tester.renderObject<RenderParagraph>(find.text('월').first);
    expect(weekday.size.height, lessThanOrEqualTo(table.daysOfWeekHeight));
    expect(tester.getSize(calendar).width, scenario.size.width);
    final today = find.byKey(ValueKey('$prefix-today-button'));
    expect(tester.getSize(today).width, greaterThanOrEqualTo(44));
    expect(tester.getSize(today).height, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);

    final output = Platform.environment['GROUP_CALENDAR_RENDER_OUTPUT'];
    if (output != null) {
      final boundary =
          capture_key.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        Directory(output).createSync(recursive: true);
        final bitmap = await boundary.toImage(pixelRatio: 2);
        final bytes = await bitmap.toByteData(format: ui.ImageByteFormat.png);
        File(
          '$output/${prefix}_${scenario.size.width}_${scenario.size.height}'
          '_${scenario.scale}_${scenario.dark}.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        bitmap.dispose();
      });
    }

    // 큰 글자에서는 전체 페이지를 먼저 내려 고정 높이의 구성원 목록에 접근한다.
    final list = find.byKey(ValueKey('$prefix-member-list'));
    await tester.ensureVisible(list);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(ValueKey(last_member_key)),
      120,
      scrollable: find.descendant(
        of: list,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey(last_member_key)).hitTestable(), findsOneWidget);
    final next_month = find.byIcon(CupertinoIcons.chevron_right);
    await tester.ensureVisible(next_month);
    await tester.pumpAndSettle();
    await tester.tap(next_month);
    await tester.pumpAndSettle();
    final next_table = tester.widget<TableCalendar<void>>(calendar);
    expect(
      next_table.focusedDay.year * 12 + next_table.focusedDay.month,
      table.focusedDay.year * 12 + table.focusedDay.month + 1,
    );
    await tester.ensureVisible(today);
    await tester.pumpAndSettle();
    await tester.tap(today);
    await tester.pumpAndSettle();
    final updated_table = tester.widget<TableCalendar<void>>(calendar);
    expect(isSameDay(updated_table.focusedDay, DateTime.now()), isTrue);
    expect(updated_table.selectedDayPredicate!(DateTime.now()), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }
}

/// 실제 목록 이동 전후의 헤더 배경과 고정 달력 위치를 확인한다.
Future<void> verifyCalendarHeaderOnScroll(
  WidgetTester tester, {
  required Finder calendar,
  required Finder list,
}) async {
  final calendar_rect = tester.getRect(calendar);
  final background = find
      .descendant(
        of: find.byType(CupertinoNavigationBar),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is DecoratedBox &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color != null,
        ),
      )
      .first;
  final initial_background =
      tester.widget<DecoratedBox>(background).decoration as BoxDecoration;
  expect(initial_background.color, AppTheme.background_color);
  expect(initial_background.border, isNull);
  final scrollable = find
      .descendant(
        of: list,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      )
      .first;
  final position = tester.state<ScrollableState>(scrollable).position;
  expect(position.maxScrollExtent, greaterThan(0));

  await tester.drag(list, const Offset(0, -180));
  await tester.pumpAndSettle();
  expect(position.pixels, greaterThan(0));
  expect(tester.getRect(calendar), calendar_rect);
  expect(
    tester.widget<DecoratedBox>(background).decoration,
    initial_background,
  );

  position.jumpTo(0);
  await tester.pumpAndSettle();
  expect(
    tester.widget<DecoratedBox>(background).decoration,
    initial_background,
  );
  expect(tester.getRect(calendar), calendar_rect);
  expect(tester.takeException(), isNull);
}
