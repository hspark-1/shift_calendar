// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';

/// 날짜 셀의 배치 규칙.
///
/// 캘린더 종류가 아니라 셀에 표시할 정보량을 기준으로 선택한다.
enum CalendarCellLayout { compact, badge, dots }

sealed class CalendarDayIndicator {
  const CalendarDayIndicator();
}

class CalendarBadgeIndicator extends CalendarDayIndicator {
  const CalendarBadgeIndicator({required this.text, required this.color});

  final String text;
  final Color color;
}

class CalendarDotsIndicator extends CalendarDayIndicator {
  const CalendarDotsIndicator({
    required this.colors,
    this.dot_size = 5,
    this.spacing = 3,
    this.key_prefix,
  });

  final List<Color> colors;
  final double dot_size;
  final double spacing;
  final String? key_prefix;
}

/// 도메인 데이터를 공용 날짜 셀이 이해할 수 있는 표시 정보로 변환한 값.
class CalendarDayPresentation {
  const CalendarDayPresentation({
    required this.date_color,
    this.indicator,
    this.semantic_label,
    this.events = const [],
  });

  final Color date_color;
  final CalendarDayIndicator? indicator;
  final String? semantic_label;
  final List<CalendarEventPresentation> events;
}

/// 날짜별 조회 결과를 기간 막대로 그리기 위한 표시 정보. end_at은 exclusive다.
class CalendarEventPresentation {
  CalendarEventPresentation({
    required this.id,
    required this.title,
    required this.start_at,
    required DateTime end_at,
    required this.color,
  }) : start_day = DateTime(start_at.year, start_at.month, start_at.day),
       end_day = _lastDay(start_at, end_at);

  final String id;
  final String title;
  final DateTime start_at;
  final DateTime start_day;
  final DateTime end_day;
  final Color color;

  static DateTime _lastDay(DateTime start_at, DateTime end_at) {
    final last_instant = end_at.subtract(const Duration(microseconds: 1));
    final last_day = DateTime(
      last_instant.year,
      last_instant.month,
      last_instant.day,
    );
    final first_day = DateTime(start_at.year, start_at.month, start_at.day);
    return last_day.isBefore(first_day) ? first_day : last_day;
  }
}

class CalendarEventSegment {
  const CalendarEventSegment({
    required this.event,
    required this.start_column,
    required this.end_column,
    required this.lane,
    required this.week_start,
  });

  final CalendarEventPresentation event;
  final int start_column;
  final int end_column;
  final int lane;
  final DateTime week_start;

  bool get continues_before => event.start_day.isBefore(
    DateTime(week_start.year, week_start.month, week_start.day + start_column),
  );
  bool get continues_after => event.end_day.isAfter(
    DateTime(week_start.year, week_start.month, week_start.day + end_column),
  );
}

/// 실제로 받은 날짜별 결과만 연결한다. 미조회/비공개 날짜까지 기간을 확장하지 않는다.
List<CalendarEventSegment> calendarEventSegmentsForWeek(
  DateTime week_start,
  CalendarDayPresentationBuilder builder,
) {
  final events_by_id = <String, CalendarEventPresentation>{};
  final columns_by_id = <String, Set<int>>{};
  for (var column = 0; column < 7; column++) {
    final day = DateTime(
      week_start.year,
      week_start.month,
      week_start.day + column,
    );
    for (final event in builder(day).events) {
      events_by_id[event.id] = event;
      columns_by_id.putIfAbsent(event.id, () => {}).add(column);
    }
  }
  final runs = <({CalendarEventPresentation event, int start, int end})>[];
  for (final entry in columns_by_id.entries) {
    final columns = entry.value.toList()..sort();
    var start = columns.first;
    var end = start;
    for (final column in columns.skip(1)) {
      if (column == end + 1) {
        end = column;
      } else {
        runs.add((event: events_by_id[entry.key]!, start: start, end: end));
        start = end = column;
      }
    }
    runs.add((event: events_by_id[entry.key]!, start: start, end: end));
  }
  runs.sort((a, b) {
    final by_start = a.start.compareTo(b.start);
    if (by_start != 0) return by_start;
    final by_length = (b.end - b.start).compareTo(a.end - a.start);
    if (by_length != 0) return by_length;
    final by_time = a.event.start_at.compareTo(b.event.start_at);
    return by_time != 0 ? by_time : a.event.id.compareTo(b.event.id);
  });
  final lane_ends = <int>[];
  final result = <CalendarEventSegment>[];
  for (final run in runs) {
    var lane = lane_ends.indexWhere((end) => end < run.start);
    if (lane < 0) {
      lane = lane_ends.length;
      lane_ends.add(run.end);
    } else {
      lane_ends[lane] = run.end;
    }
    result.add(
      CalendarEventSegment(
        event: run.event,
        start_column: run.start,
        end_column: run.end,
        lane: lane,
        week_start: week_start,
      ),
    );
  }
  return result;
}

typedef CalendarDayPresentationBuilder =
    CalendarDayPresentation Function(DateTime date);
