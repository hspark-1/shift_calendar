// ignore_for_file: non_constant_identifier_names

import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/features/calendar/presentation/models/calendar_layout_policy.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  test('750px 미만은 3주 보기, 이상은 화면의 선호 형식을 사용한다', () {
    expect(
      CalendarLayoutPolicy.visibleFormat(
        screen_height: 749,
        preferred_format: CalendarFormat.month,
      ),
      CalendarFormat.threeWeeks,
    );
    expect(
      CalendarLayoutPolicy.visibleFormat(
        screen_height: 750,
        preferred_format: CalendarFormat.week,
      ),
      CalendarFormat.week,
    );
  });

  test('카드가 없어도 750px 미만은 3주, 이상은 월 전체를 사용한다', () {
    for (final height in [568.0, 749.0, 750.0]) {
      expect(
        CalendarLayoutPolicy.visibleFormat(
          screen_height: height,
          preferred_format: CalendarFormat.week,
          is_month_overview: true,
        ),
        height < 750 ? CalendarFormat.threeWeeks : CalendarFormat.month,
      );
    }
  });

  test('카드 없는 달력의 실제 표시 주 수와 본문 높이로 행을 배분한다', () {
    for (final entry in {2: 4, 11: 5, 8: 6}.entries) {
      final month = DateTime(2026, entry.key);
      expect(CalendarLayoutPolicy.monthWeekCount(month), entry.value);
      final row = CalendarLayoutPolicy.overviewRowHeight(
        month: month,
        available_height: 700,
        weekday_height: 32,
        text_height: 14,
      );
      expect(row * entry.value + 40, closeTo(700, 0.01));
      final three_week_row = CalendarLayoutPolicy.overviewRowHeight(
        month: month,
        available_height: 700,
        weekday_height: 32,
        text_height: 14,
        calendar_format: CalendarFormat.threeWeeks,
      );
      expect(three_week_row * 3 + 40, closeTo(700, 0.01));
    }
    expect(
      CalendarLayoutPolicy.overviewRowHeight(
        month: DateTime(2026, 8),
        available_height: 180,
        weekday_height: 32,
        text_height: 44.8,
      ),
      greaterThan(160),
    );
  });

  test('행 높이는 compact 48, 상세 화면은 52 또는 56을 사용한다', () {
    expect(
      CalendarLayoutPolicy.rowHeight(
        screen_height: 800,
        layout_mode: CalendarCellLayoutMode.compact,
      ),
      48,
    );
    expect(
      CalendarLayoutPolicy.rowHeight(
        screen_height: 740,
        layout_mode: CalendarCellLayoutMode.detailed,
      ),
      52,
    );
    expect(
      CalendarLayoutPolicy.rowHeight(
        screen_height: 800,
        layout_mode: CalendarCellLayoutMode.detailed,
      ),
      56,
    );
  });
}
