// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:table_calendar/table_calendar.dart';

List<DateTime> visibleDates(WidgetTester tester) {
  final dates =
      find
          .byWidgetPredicate((widget) {
            final key = widget.key;
            return key is ValueKey<String> &&
                key.value.startsWith('CellContent-');
          })
          .hitTestable()
          .evaluate()
          .map((element) {
            final parts = (element.widget.key! as ValueKey<String>).value.split(
              '-',
            );
            return DateTime.utc(
              int.parse(parts[1]),
              int.parse(parts[2]),
              int.parse(parts[3]),
            );
          })
          .toList()
        ..sort();
  return dates;
}

Finder dateCell(DateTime date) =>
    find.byKey(ValueKey('CellContent-${date.year}-${date.month}-${date.day}'));

Future<void> mountCalendar(
  WidgetTester tester, {
  CalendarFormat format = CalendarFormat.threeWeeks,
  DateTime? focused_day,
  DateTime? first_day,
  DateTime? last_day,
  ValueChanged<DateTime>? onPageChanged,
  ValueChanged<DateTime>? onSelected,
}) async {
  var focused = focused_day ?? DateTime.utc(2026, 11, 22);
  DateTime? selected;
  await tester.pumpWidget(
    CupertinoApp(
      home: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 350,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return TableCalendar<void>(
                    firstDay: first_day ?? DateTime.utc(2026),
                    lastDay: last_day ?? DateTime.utc(2027, 12, 31),
                    focusedDay: focused,
                    calendarFormat: format,
                    headerVisible: false,
                    rowHeight: 40,
                    daysOfWeekHeight: 24,
                    availableGestures: AvailableGestures.horizontalSwipe,
                    selectedDayPredicate: (date) => isSameDay(date, selected),
                    onDaySelected: (date, next_focus) {
                      setState(() {
                        selected = date;
                        focused = next_focus;
                      });
                      onSelected?.call(date);
                    },
                    onPageChanged: (date) {
                      setState(() => focused = date);
                      onPageChanged?.call(date);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final entry in {
    CalendarFormat.month: 35,
    CalendarFormat.threeWeeks: 21,
    CalendarFormat.twoWeeks: 14,
    CalendarFormat.week: 7,
  }.entries) {
    testWidgets('${entry.key.name}은 날짜가 연속되고 실제 ${entry.value ~/ 7}행을 그린다', (
      tester,
    ) async {
      await mountCalendar(tester, format: entry.key);
      final dates = visibleDates(tester);
      expect(dates, hasLength(entry.value));
      for (var index = 1; index < dates.length; index++) {
        expect(dates[index].difference(dates[index - 1]).inDays, 1);
      }
      final rows = {
        for (final date in dates) tester.getTopLeft(dateCell(date)).dy,
      };
      expect(rows, hasLength(entry.value ~/ 7));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('3주 좌우 스와이프는 연도를 넘어 21일씩 이동하고 원래 날짜로 돌아온다', (tester) async {
    final pages = <DateTime>[];
    await mountCalendar(
      tester,
      focused_day: DateTime.utc(2026, 12, 23),
      onPageChanged: pages.add,
    );
    final initial = visibleDates(tester);
    expect(initial.first.year, 2026);
    expect(initial.last.year, 2027);
    await tester.drag(find.byType(TableCalendar<void>), const Offset(-320, 0));
    await tester.pumpAndSettle();
    final next = visibleDates(tester);
    expect(next, hasLength(21));
    expect(next.first.difference(initial.first).inDays, 21);
    expect(pages.last.difference(DateTime.utc(2026, 12, 23)).inDays, 21);
    await tester.drag(find.byType(TableCalendar<void>), const Offset(320, 0));
    await tester.pumpAndSettle();
    expect(visibleDates(tester), initial);
    expect(tester.takeException(), isNull);
  });

  testWidgets('3주 마지막 행의 날짜 선택과 선택 표시를 보존한다', (tester) async {
    DateTime? selected;
    await mountCalendar(tester, onSelected: (date) => selected = date);
    final last = visibleDates(tester).last;
    await tester.tap(dateCell(last));
    await tester.pumpAndSettle();
    expect(selected, last);
    expect(
      tester
          .widget<TableCalendar<void>>(find.byType(TableCalendar<void>))
          .selectedDayPredicate!(last),
      isTrue,
    );
    expect(visibleDates(tester), contains(last));
    expect(tester.takeException(), isNull);
  });

  for (final at_start in [true, false]) {
    testWidgets('3주 범위 ${at_start ? '시작' : '끝'}에서는 바깥 페이지로 넘어가지 않는다', (
      tester,
    ) async {
      final first = DateTime.utc(2026);
      final last = DateTime.utc(2026, 1, 20);
      final pages = <DateTime>[];
      await mountCalendar(
        tester,
        first_day: first,
        last_day: last,
        focused_day: at_start ? first : last,
        onPageChanged: pages.add,
      );
      final initial = visibleDates(tester);
      await tester.drag(
        find.byType(TableCalendar<void>),
        Offset(at_start ? 320 : -320, 0),
      );
      await tester.pumpAndSettle();
      expect(visibleDates(tester), initial);
      expect(pages, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }
}
