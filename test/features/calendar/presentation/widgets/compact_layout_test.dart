// ignore_for_file: non_constant_identifier_names

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shift_mate/core/theme/app_theme.dart';
import 'package:shift_mate/features/calendar/data/models/event_api_model.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/date_picker_sheet.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/personal_event_form_modal.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/time_picker_sheet.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/year_month_picker_sheet.dart';

Future<void> loadFonts() async {
  for (final entry in {
    'Cafe24SsurroundAir': 'assets/fonts/Cafe24SsurroundAir-v1.1.ttf',
    'Cafe24Ssurround': 'assets/fonts/Cafe24Ssurround-v2.0.ttf',
    'packages/cupertino_icons/CupertinoIcons':
        'packages/cupertino_icons/assets/CupertinoIcons.ttf',
  }.entries) {
    await (FontLoader(entry.key)..addFont(rootBundle.load(entry.value))).load();
  }
}

void expectReadableText(
  WidgetTester tester,
  Finder text_finder, {
  int max_lines = 1,
}) {
  final paragraph = tester.renderObject<RenderParagraph>(text_finder);
  final text = paragraph.text.toPlainText();
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: text.length),
  );
  expect(
    boxes.map((box) => box.top).toSet().length,
    inInclusiveRange(1, max_lines),
    reason: text,
  );
  expect(paragraph.didExceedMaxLines, isFalse, reason: text);
  for (final box in boxes) {
    expect(box.left, greaterThanOrEqualTo(-0.1), reason: text);
    expect(
      box.right,
      lessThanOrEqualTo(paragraph.size.width + 0.1),
      reason: text,
    );
  }
}

Future<void> capture(
  WidgetTester tester,
  GlobalKey capture_key,
  String name,
) async {
  final output_path = Platform.environment['COMPACT_LAYOUT_RENDER_OUTPUT'];
  if (output_path == null) return;
  final boundary =
      capture_key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final output = Directory(output_path)..createSync(recursive: true);
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File(
      '${output.path}/$name.png',
    ).writeAsBytesSync(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
    await loadFonts();
  });

  for (final scenario in [
    (name: 'small320', size: const Size(320, 568), scale: 1.0),
    (name: 'phone360', size: const Size(360, 640), scale: 1.0),
    (name: 'phone375', size: const Size(375, 667), scale: 1.0),
    (name: 'phone375_text110', size: const Size(375, 667), scale: 1.1),
    (name: 'phone375_text125', size: const Size(375, 667), scale: 1.25),
    (name: 'normal', size: const Size(390, 844), scale: 1.0),
    (name: 'large430', size: const Size(430, 932), scale: 1.0),
    (name: 'small_text2', size: const Size(320, 568), scale: 2.0),
    (name: 'small_text3', size: const Size(320, 568), scale: 3.2),
    (name: 'landscape', size: const Size(667, 375), scale: 1.0),
    (name: 'landscape_text2', size: const Size(667, 375), scale: 2.0),
    (name: 'tablet', size: const Size(768, 1024), scale: 1.0),
  ]) {
    Future<GlobalKey> openSheet(WidgetTester tester, Widget sheet) async {
      await tester.binding.setSurfaceSize(scenario.size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final capture_key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: capture_key,
          child: CupertinoApp(
            debugShowCheckedModeBanner: false,
            theme: scenario.name.contains('text2')
                ? AppTheme.darkTheme
                : AppTheme.lightTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: scenario.size,
                textScaler: TextScaler.linear(scenario.scale),
                padding: const EdgeInsets.only(top: 20, bottom: 34),
                viewPadding: const EdgeInsets.only(top: 20, bottom: 34),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: CupertinoPageScaffold(
              child: Builder(
                builder: (context) => Center(
                  child: CupertinoButton(
                    onPressed: () => showCupertinoModalPopup<void>(
                      context: context,
                      builder: (_) => sheet,
                    ),
                    child: const Text('열기'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      return capture_key;
    }

    testWidgets('개인 일정 날짜·시간이 잘리지 않고 행 정렬을 유지한다 ${scenario.name}', (
      tester,
    ) async {
      final capture_key = await openSheet(
        tester,
        PersonalEventFormModal(
          initialDate: DateTime(2026, 11, 12),
          initial_event: EventApiModel(
            eventId: 'compact',
            title: '작은 화면 검토',
            allDay: false,
            startAt: DateTime(2026, 11, 12, 9),
            endAt: DateTime(2026, 11, 12, 10),
            visibilityLevel: 1,
          ),
        ),
      );
      for (final label in ['시작', '종료']) {
        for (final kind in ['date', 'time']) {
          final button = find.byKey(ValueKey('event-$kind-$label'));
          expectReadableText(
            tester,
            find.descendant(of: button, matching: find.byType(Text)),
            max_lines: kind == 'date' && scenario.scale > 2 ? 2 : 1,
          );
          expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
        }
      }
      final start = tester.getRect(find.byKey(const ValueKey('event-time-시작')));
      final end = tester.getRect(find.byKey(const ValueKey('event-time-종료')));
      expect(start.left, closeTo(end.left, 0.1));
      expect(start.width, closeTo(end.width, 0.1));
      expect(start.height, closeTo(end.height, 0.1));
      final footer = find.byKey(const Key('personal-event-save-button'));
      final footer_rect = tester.getRect(footer);
      final memo = find.byKey(const Key('personal-event-memo-field'));
      await Scrollable.ensureVisible(tester.element(memo), alignment: 0.5);
      await tester.pumpAndSettle();
      expect(memo.hitTestable(), findsOneWidget);
      expect(tester.getRect(footer), footer_rect);
      expect(footer_rect.bottom, lessThanOrEqualTo(scenario.size.height - 34));
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(const ValueKey('event-time-시작')));
      await tester.pumpAndSettle();
      await capture(tester, capture_key, 'event_${scenario.name}');
    });

    testWidgets('긴 시간·다른 연도·종일 전환도 값을 보존한다 ${scenario.name}', (tester) async {
      await openSheet(
        tester,
        PersonalEventFormModal(
          initialDate: DateTime(2026, 12, 31),
          initial_event: EventApiModel(
            eventId: 'long-values',
            title: '연도 경계 일정',
            allDay: false,
            startAt: DateTime(2026, 12, 31, 11, 59),
            endAt: DateTime(2027, 11, 12, 12, 59),
            visibilityLevel: 1,
          ),
        ),
      );
      for (final value in [
        '2026.12.31',
        '2027.11.12',
        '오전 11:59',
        '오후 12:59',
      ]) {
        expectReadableText(
          tester,
          find.text(value),
          max_lines: scenario.scale > 2 ? 2 : 1,
        );
      }
      final all_day = find.byKey(const Key('personal-event-all-day'));
      await tester.ensureVisible(all_day);
      await tester.pumpAndSettle();
      await tester.tap(all_day);
      await tester.pumpAndSettle();
      expect(find.text('오전 11:59'), findsNothing);
      expect(find.text('2026.12.31'), findsOneWidget);
      expect(find.text('2027.11.12'), findsOneWidget);
      await tester.tap(all_day);
      await tester.pumpAndSettle();
      expect(find.text('오전 11:59'), findsOneWidget);
      expect(find.text('오후 12:59'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('시간·날짜·연월 피커의 본문과 확인 버튼에 접근한다 ${scenario.name}', (
      tester,
    ) async {
      var capture_key = await openSheet(
        tester,
        const TimePickerSheet(
          title: '종료시간 선택',
          initial_time: Duration(hours: 10),
        ),
      );
      expectReadableText(
        tester,
        find.text('오전 10:00'),
        max_lines: scenario.scale > 2 ? 2 : 1,
      );
      final time_apply = find.byKey(const ValueKey('time-picker-apply'));
      expect(time_apply.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture(tester, capture_key, 'time_${scenario.name}');
      final time_wheel = find.byType(CupertinoDatePicker);
      await tester.ensureVisible(time_wheel);
      await tester.pumpAndSettle();
      expect(time_wheel.hitTestable(), findsOneWidget);
      await capture(tester, capture_key, 'time_${scenario.name}_wheel');
      await tester.tap(time_apply);
      await tester.pumpAndSettle();

      capture_key = await openSheet(
        tester,
        YearMonthPickerSheet(
          initial_date: DateTime(2026, 11, 12),
          first_year: 2000,
          last_year: 2050,
        ),
      );
      expectReadableText(
        tester,
        find.text('2026년 11월'),
        max_lines: scenario.scale > 2 ? 2 : 1,
      );
      final month_apply = find.byKey(const ValueKey('year-month-picker-apply'));
      expect(month_apply.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture(tester, capture_key, 'month_${scenario.name}');
      expectReadableText(tester, find.text('2026년'));
      final year_wheel = find.byType(CupertinoPicker).first;
      await tester.ensureVisible(year_wheel);
      await tester.pumpAndSettle();
      expect(year_wheel.hitTestable(), findsOneWidget);
      await capture(tester, capture_key, 'month_${scenario.name}_year');
      final month_wheel = find.byType(CupertinoPicker).last;
      await tester.ensureVisible(month_wheel);
      await tester.pumpAndSettle();
      expect(month_wheel.hitTestable(), findsOneWidget);
      await capture(tester, capture_key, 'month_${scenario.name}_wheel');
      final pickers = tester
          .widgetList<CupertinoPicker>(find.byType(CupertinoPicker))
          .toList();
      for (final picker in pickers) {
        picker.scrollController!.jumpToItem(0);
      }
      await tester.pumpAndSettle();
      final current_month = find.text('이번 달');
      await tester.ensureVisible(current_month);
      await tester.pumpAndSettle();
      await tester.tap(current_month);
      await tester.pumpAndSettle();
      final now = DateTime.now();
      expect(pickers[0].scrollController!.selectedItem, now.year - 2000);
      expect(pickers[1].scrollController!.selectedItem, now.month - 1);
      expect(find.text('${now.year}년 ${now.month}월'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(month_apply);
      await tester.pumpAndSettle();

      capture_key = await openSheet(
        tester,
        DatePickerSheet(
          title: '종료일 선택',
          initial_date: DateTime(2026, 11, 12),
          minimum_date: DateTime(2000),
          maximum_date: DateTime(2050, 12, 31),
        ),
      );
      expectReadableText(
        tester,
        find.text('2026년 11월'),
        max_lines: scenario.scale > 2 ? 2 : 1,
      );
      expect(find.text('확인').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture(tester, capture_key, 'date_${scenario.name}');
    });
  }
}
