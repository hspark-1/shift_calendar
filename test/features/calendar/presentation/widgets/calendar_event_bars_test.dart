// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shift_mate/core/theme/app_theme.dart';
import 'package:shift_mate/features/calendar/presentation/models/calendar_day_presentation.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/calendar_month_view.dart';
import 'package:table_calendar/table_calendar.dart';

CalendarEventPresentation event(
  String id,
  int start,
  int end, {
  int month = 11,
}) => CalendarEventPresentation(
  id: id,
  title: id,
  start_at: DateTime(2026, month, start),
  end_at: DateTime(2026, month, end + 1),
  color: AppTheme.primary_color,
);

CalendarDayPresentation presentation(
  DateTime day,
  List<CalendarEventPresentation> events,
) => CalendarDayPresentation(
  date_color: AppTheme.on_surface_color,
  events: events
      .where(
        (event) =>
            !day.isBefore(event.start_day) && !day.isAfter(event.end_day),
      )
      .toList(),
);

Widget calendarApp(
  List<CalendarEventPresentation> events, {
  double height = 600,
  double scale = 1,
  void Function(DateTime)? onSelected,
}) => CupertinoApp(
  theme: AppTheme.lightTheme,
  home: MediaQuery(
    data: MediaQueryData(
      size: const Size(390, 844),
      textScaler: TextScaler.linear(scale),
      disableAnimations: true,
    ),
    child: Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: height,
        child: CalendarMonthView<void>(
          calendar_key: const ValueKey('event-calendar'),
          focused_day: DateTime(2026, 11, 22),
          selected_day: null,
          calendar_format: CalendarFormat.month,
          row_height: 56,
          is_month_overview: true,
          cell_layout: CalendarCellLayout.badge,
          day_presentation_builder: (day) =>
              presentation(DateTime(day.year, day.month, day.day), events),
          onDaySelected: (day, _) => onSelected?.call(day),
          onPageChanged: (_) {},
        ),
      ),
    ),
  ),
);

Finder bars() => find.byWidgetPredicate(
  (widget) =>
      widget is Container &&
      widget.key is ValueKey<String> &&
      (widget.key! as ValueKey<String>).value.startsWith('calendar-event-bar-'),
);

void main() {
  setUpAll(() => initializeDateFormatting('ko_KR'));

  test('종료 자정은 제외하고 시간 있는 마지막 날짜는 포함한다', () {
    expect(event('연속', 25, 27).end_day, DateTime(2026, 11, 27));
    final timed = CalendarEventPresentation(
      id: 'timed',
      title: '시간',
      start_at: DateTime(2026, 11, 25, 18),
      end_at: DateTime(2026, 11, 27, 20),
      color: AppTheme.primary_color,
    );
    expect(timed.end_day, DateTime(2026, 11, 27));
  });

  test('25~27일은 단일 구간이고 겹치는 일정은 별도 행을 사용한다', () {
    final events = [event('A', 25, 27), event('B', 26, 28), event('C', 28, 28)];
    final segments = calendarEventSegmentsForWeek(
      DateTime(2026, 11, 22),
      (day) => presentation(day, events),
    );
    final first = segments.firstWhere((segment) => segment.event.id == 'A');
    expect((first.start_column, first.end_column, first.lane), (3, 5, 0));
    expect(segments.firstWhere((segment) => segment.event.id == 'B').lane, 1);
    expect(segments.firstWhere((segment) => segment.event.id == 'C').lane, 0);
  });

  test('주 경계는 다음 행으로 이어지고 월 경계는 같은 주에서 연결한다', () {
    final events = [event('주 경계', 28, 30), event('월 경계', 30, 32)];
    final before = calendarEventSegmentsForWeek(
      DateTime(2026, 11, 22),
      (day) => presentation(day, events),
    );
    expect(before.single.continues_after, isTrue);
    expect((before.single.start_column, before.single.end_column), (6, 6));
    final after = calendarEventSegmentsForWeek(
      DateTime(2026, 11, 29),
      (day) => presentation(day, events),
    );
    expect(after.first.continues_before, isTrue);
    final cross_month = after.firstWhere(
      (segment) => segment.event.id == '월 경계',
    );
    expect((cross_month.start_column, cross_month.end_column), (1, 3));
  });

  test('조회 결과에 없는 날짜를 막대로 연결하거나 노출하지 않는다', () {
    final value = event('제한', 25, 27);
    final segments = calendarEventSegmentsForWeek(
      DateTime(2026, 11, 22),
      (day) => CalendarDayPresentation(
        date_color: AppTheme.on_surface_color,
        events: [if (day.day == 25 || day.day == 27) value],
      ),
    );
    expect(
      segments.map((segment) => (segment.start_column, segment.end_column)),
      [(3, 3), (5, 5)],
    );
  });

  testWidgets('연속 막대는 세 칸을 덮고 제목은 한 번 표시하며 날짜 탭을 통과시킨다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    DateTime? selected;
    await tester.pumpWidget(
      calendarApp([
        event('25~27 연속 일정', 25, 27),
      ], onSelected: (day) => selected = day),
    );
    await tester.pumpAndSettle();
    expect(bars(), findsOneWidget);
    expect(find.text('25~27 연속 일정'), findsOneWidget);
    final rect = tester.getRect(bars());
    expect(rect.width, closeTo(390 / 7 * 3 - 4, 0.01));
    await tester.tapAt(Offset(rect.left + 390 / 7 * 1.5, rect.center.dy));
    await tester.pumpAndSettle();
    expect(isSameDay(selected, DateTime(2026, 11, 26)), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('일정은 실제 행 공간까지 표시하고 작은 행에서는 넘치지 않는다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final events = [
      for (var index = 0; index < 8; index++) event('일정 $index', 22, 22),
    ];
    await tester.pumpWidget(calendarApp(events));
    await tester.pumpAndSettle();
    expect(bars(), findsNWidgets(3));
    final first_rect = tester.getRect(bars().first);
    final last_rect = tester.getRect(bars().last);
    expect(first_rect.overlaps(last_rect), isFalse);
    await tester.pumpWidget(calendarApp(events, height: 400));
    await tester.pumpAndSettle();
    expect(bars(), findsOneWidget);
    await tester.pumpWidget(calendarApp(events, height: 400, scale: 3.2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
