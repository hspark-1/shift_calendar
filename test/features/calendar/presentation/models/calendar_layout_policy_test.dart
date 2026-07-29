// ignore_for_file: non_constant_identifier_names

import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/features/calendar/presentation/models/calendar_layout_policy.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  test('750px 미만은 2주 보기, 이상은 화면의 선호 형식을 사용한다', () {
    expect(
      CalendarLayoutPolicy.visibleFormat(
        screen_height: 749,
        preferred_format: CalendarFormat.month,
      ),
      CalendarFormat.twoWeeks,
    );
    expect(
      CalendarLayoutPolicy.visibleFormat(
        screen_height: 750,
        preferred_format: CalendarFormat.week,
      ),
      CalendarFormat.week,
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
