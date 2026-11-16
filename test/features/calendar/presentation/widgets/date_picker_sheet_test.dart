// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/date_picker_sheet.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('ko_KR'));
  testWidgets('날짜 탭은 선택만 바꾸고 확인을 눌러야 날짜를 반환한다', (tester) async {
    DateTime? selected_date;

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: Builder(
            builder: (context) {
              return Center(
                child: CupertinoButton(
                  onPressed: () async {
                    selected_date = await showDatePickerSheet(
                      context: context,
                      title: '시작일 선택',
                      initial_date: DateTime(2026, 8, 15),
                      minimum_date: DateTime(2000, 1, 1),
                      maximum_date: DateTime(2050, 12, 31),
                    );
                  },
                  child: const Text('날짜 선택'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('날짜 선택'));
    await tester.pumpAndSettle();

    expect(find.text('시작일 선택'), findsOneWidget);
    expect(find.text('2026년 8월 15일 (토)'), findsOneWidget);
    expect(find.text('오늘'), findsOneWidget);
    expect(find.byType(CupertinoDatePicker), findsNothing);
    expect(find.byType(TableCalendar), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('date-picker-day-2026-8-16')));
    await tester.pumpAndSettle();
    expect(selected_date, isNull);
    expect(find.byType(DatePickerSheet), findsOneWidget);
    expect(find.text('2026년 8월 16일 (일)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('date-picker-confirm')));
    await tester.pumpAndSettle();
    expect(selected_date, DateTime(2026, 8, 16));
  });

  testWidgets('취소하면 선택값을 반환하지 않는다', (tester) async {
    DateTime? selected_date;

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: Builder(
            builder: (context) {
              return Center(
                child: CupertinoButton(
                  onPressed: () async {
                    selected_date = await showDatePickerSheet(
                      context: context,
                      title: '종료일 선택',
                      initial_date: DateTime(2026, 8, 15),
                      minimum_date: DateTime(2000, 1, 1),
                      maximum_date: DateTime(2050, 12, 31),
                    );
                  },
                  child: const Text('날짜 선택'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('날짜 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('date-picker-day-2026-8-16')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(selected_date, isNull);
    expect(find.text('종료일 선택'), findsNothing);
  });

  testWidgets('날짜 범위를 벗어난 초기값을 보정하고 월 경계·비활성 날짜를 지킨다', (tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: DatePickerSheet(
          title: '날짜 선택',
          initial_date: DateTime(2025),
          minimum_date: DateTime(2026, 8, 10),
          maximum_date: DateTime(2026, 9, 20),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('2026년 8월 10일 (월)'), findsOneWidget);
    final calendar = tester.widget<TableCalendar>(
      find.byKey(const ValueKey('date-picker-calendar')),
    );
    expect(calendar.selectedDayPredicate!(DateTime(2026, 8, 10)), isTrue);
    expect(
      tester
          .widget<CupertinoButton>(
            find.byKey(const ValueKey('date-picker-previous-month')),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('date-picker-next-month')));
    await tester.pumpAndSettle();
    expect(find.text('2026년 9월'), findsOneWidget);
    expect(
      tester
          .widget<CupertinoButton>(
            find.byKey(const ValueKey('date-picker-next-month')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<Semantics>(
            find.byKey(const ValueKey('date-picker-day-2026-9-21')),
          )
          .properties
          .enabled,
      isFalse,
    );
    expect(
      tester
          .widget<Semantics>(
            find.byKey(const ValueKey('date-picker-day-2026-9-20')),
          )
          .properties
          .enabled,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('연월 빠른 이동을 취소해도 선택 날짜는 유지한다', (tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: DatePickerSheet(
          title: '날짜 선택',
          initial_date: DateTime(2026, 8, 15),
          minimum_date: DateTime(2000),
          maximum_date: DateTime(2050, 12, 31),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('date-picker-month')));
    await tester.pumpAndSettle();
    expect(find.text('날짜 이동'), findsOneWidget);
    await tester.tap(find.text('취소').last);
    await tester.pumpAndSettle();
    expect(find.text('2026년 8월 15일 (토)'), findsOneWidget);
    expect(find.byType(DatePickerSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('오늘은 달력 위에서 날짜/월만 갱신하고 확인 전에는 시트를 닫지 않는다', (tester) async {
    final today = DateTime.now();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      CupertinoApp(
        home: DatePickerSheet(
          title: '시작일 선택',
          initial_date: DateTime(today.year, today.month - 1, 1),
          minimum_date: DateTime(2000),
          maximum_date: DateTime(2050, 12, 31),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey('date-picker-today'));
    final calendar = find.byKey(const ValueKey('date-picker-calendar'));
    expect(
      tester.getRect(button).bottom,
      lessThanOrEqualTo(tester.getRect(calendar).top),
    );
    expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerSheet), findsOneWidget);
    final widget = tester.widget<TableCalendar>(calendar);
    expect(
      widget.selectedDayPredicate!(
        DateTime(today.year, today.month, today.day),
      ),
      isTrue,
    );
    expect(widget.focusedDay.month, today.month);
    expect(
      find.byKey(const ValueKey('date-picker-confirm')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
