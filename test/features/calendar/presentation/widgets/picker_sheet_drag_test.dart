// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shift_mate/core/theme/app_theme.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/date_picker_sheet.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/time_picker_sheet.dart';

Future<void> openPicker(
  WidgetTester tester, {
  required bool date,
  required ValueChanged<Object?> on_result,
  Size size = const Size(390, 844),
  double scale = 1,
  bool reduced_motion = false,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    CupertinoApp(
      theme: AppTheme.lightTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: reduced_motion,
        ),
        child: child!,
      ),
      home: CupertinoPageScaffold(
        child: Builder(
          builder: (context) => Center(
            child: CupertinoButton(
              child: const Text('피커 열기'),
              onPressed: () async {
                final Object? result = date
                    ? await showDatePickerSheet(
                        context: context,
                        title: '시작일 선택',
                        initial_date: DateTime(2026, 8, 15),
                        minimum_date: DateTime(2000),
                        maximum_date: DateTime(2050, 12, 31),
                      )
                    : await showTimePickerSheet(
                        context: context,
                        title: '시작시간 선택',
                        initial_time: const Duration(hours: 9),
                      );
                on_result(result);
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('피커 열기'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('ko_KR'));
  for (final date in [true, false]) {
    final prefix = date ? 'date-picker' : 'time-picker';
    final name = date ? '날짜' : '시간';
    for (final handle in [false, true]) {
      testWidgets('$name ${handle ? '손잡이' : '본문 상단'}를 충분히 끌면 값 확정 없이 닫힌다', (
        tester,
      ) async {
        var completions = 0;
        Object? result;
        await openPicker(
          tester,
          date: date,
          on_result: (value) {
            result = value;
            completions++;
          },
        );
        final scroll = find.byKey(ValueKey('$prefix-scroll'));
        final rect = tester.getRect(scroll);
        final origin = handle
            ? tester.getCenter(find.byKey(ValueKey('$prefix-handle')))
            : Offset(rect.left + 8, rect.top + 32);
        await tester.dragFrom(origin, const Offset(0, 170));
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey('$prefix-sheet')), findsNothing);
        expect(completions, 1);
        expect(result, isNull);
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        '$name ${handle ? '손잡이' : '본문 상단'}의 짧은 고속 끌기는 선택값을 보존하고 복귀한다',
        (tester) async {
          Object? result;
          var completions = 0;
          await openPicker(
            tester,
            date: date,
            on_result: (value) {
              result = value;
              completions++;
            },
          );
          if (date) {
            await tester.tap(
              find.byKey(const ValueKey('date-picker-day-2026-8-16')),
            );
          } else {
            tester
                .widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker))
                .onDateTimeChanged(DateTime(2026, 1, 1, 14, 30));
          }
          await tester.pumpAndSettle();
          final sheet = find.byKey(ValueKey('$prefix-sheet'));
          final top = tester.getTopLeft(sheet).dy;
          final rect = tester.getRect(find.byKey(ValueKey('$prefix-scroll')));
          final origin = handle
              ? tester.getCenter(find.byKey(ValueKey('$prefix-handle')))
              : Offset(rect.left + 8, rect.top + 32);
          await tester.flingFrom(origin, const Offset(0, 70), 2000);
          await tester.pumpAndSettle();
          expect(completions, 0);
          expect(tester.getTopLeft(sheet).dy, closeTo(top, 0.1));
          if (date) {
            expect(find.text('2026년 8월 16일 (일)'), findsOneWidget);
            await tester.tap(find.byKey(const ValueKey('date-picker-confirm')));
          } else {
            expect(find.text('오후 02:30'), findsOneWidget);
            await tester.tap(find.text('선택한 시간 적용'));
          }
          await tester.pumpAndSettle();
          expect(
            result,
            date
                ? DateTime(2026, 8, 16)
                : const Duration(hours: 14, minutes: 30),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }

    for (final distance in [119.0, 121.0]) {
      testWidgets('$name 손잡이 실제 이동${distance}px에서120px 경계를 따른다', (
        tester,
      ) async {
        var completions = 0;
        await openPicker(
          tester,
          date: date,
          reduced_motion: true,
          on_result: (_) => completions++,
        );
        final sheet = find.byKey(ValueKey('$prefix-sheet'));
        final top = tester.getTopLeft(sheet).dy;
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(ValueKey('$prefix-handle'))),
        );
        await gesture.moveBy(const Offset(0, 24));
        await tester.pump();
        await gesture.moveBy(Offset(0, distance - 24));
        await tester.pump();
        expect(tester.getTopLeft(sheet).dy - top, closeTo(distance, 0.1));
        await gesture.up();
        await tester.pumpAndSettle();
        expect(completions, distance >= 120 ? 1 : 0);
        expect(sheet, distance >= 120 ? findsNothing : findsOneWidget);
        if (distance < 120) {
          expect(tester.getTopLeft(sheet).dy, closeTo(top, 0.1));
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('$name 본문 중간을 내리면 내용만 스크롤하고 시트는 움직이지 않는다', (tester) async {
      var completions = 0;
      await openPicker(
        tester,
        date: date,
        size: const Size(320, 568),
        scale: 2,
        on_result: (_) => completions++,
      );
      final scroll = find.byKey(ValueKey('$prefix-scroll'));
      final controller = tester
          .widget<SingleChildScrollView>(scroll)
          .controller!;
      expect(controller.position.maxScrollExtent, greaterThan(0));
      controller.jumpTo(math.min(80, controller.position.maxScrollExtent));
      await tester.pumpAndSettle();
      final initial_offset = controller.offset;
      final sheet = find.byKey(ValueKey('$prefix-sheet'));
      final top = tester.getTopLeft(sheet).dy;
      final rect = tester.getRect(scroll);
      await tester.dragFrom(
        Offset(rect.left + 4, rect.top + 32),
        const Offset(0, 35),
      );
      await tester.pumpAndSettle();
      expect(completions, 0);
      expect(controller.offset, lessThan(initial_offset));
      expect(tester.getTopLeft(sheet).dy, closeTo(top, 0.1));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('시간 휠을 아래로 길게 조작해도 시트가 끌리거나 닫히지 않는다', (tester) async {
    var completions = 0;
    await openPicker(tester, date: false, on_result: (_) => completions++);
    final sheet = find.byKey(const ValueKey('time-picker-sheet'));
    final top = tester.getTopLeft(sheet).dy;
    final rect = tester.getRect(find.byType(CupertinoDatePicker));
    await tester.dragFrom(
      Offset(rect.left + rect.width * 0.43, rect.center.dy),
      const Offset(0, 170),
    );
    await tester.pumpAndSettle();
    expect(completions, 0);
    expect(tester.getTopLeft(sheet).dy, closeTo(top, 0.1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('달력 가로 넘김은 월만 바꾸고 시트를 닫거나 날짜를 확정하지 않는다', (tester) async {
    var completions = 0;
    await openPicker(tester, date: true, on_result: (_) => completions++);
    final sheet = find.byKey(const ValueKey('date-picker-sheet'));
    final top = tester.getTopLeft(sheet).dy;
    final calendar = find.byKey(const ValueKey('date-picker-calendar'));
    await tester.drag(calendar, const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(completions, 0);
    expect(tester.widget<TableCalendar>(calendar).focusedDay.month, 9);
    expect(tester.getTopLeft(sheet).dy, closeTo(top, 0.1));
    expect(tester.takeException(), isNull);
  });
}
