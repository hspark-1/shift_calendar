// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:math' as math;

import 'package:table_calendar/table_calendar.dart';

abstract final class CalendarLayoutPolicy {
  static const double short_screen_height = 750;

  static CalendarFormat visibleFormat({
    required double screen_height,
    required CalendarFormat preferred_format,
    bool is_month_overview = false,
  }) {
    if (screen_height < short_screen_height) return CalendarFormat.threeWeeks;
    return is_month_overview ? CalendarFormat.month : preferred_format;
  }

  static double rowHeight({
    required double screen_height,
    required CalendarCellLayoutMode layout_mode,
  }) {
    if (layout_mode == CalendarCellLayoutMode.compact) {
      return 48;
    }
    return screen_height < short_screen_height ? 52 : 56;
  }

  static int monthWeekCount(DateTime month) {
    final first_weekday = DateTime(month.year, month.month, 1).weekday % 7;
    final day_count = DateTime(month.year, month.month + 1, 0).day;
    return ((first_weekday + day_count) / 7).ceil();
  }

  static int weekCount(CalendarFormat format, DateTime month) =>
      switch (format) {
        CalendarFormat.month => monthWeekCount(month),
        CalendarFormat.threeWeeks => 3,
        CalendarFormat.twoWeeks => 2,
        CalendarFormat.week => 1,
      };

  static double overviewRowHeight({
    required DateTime month,
    required double available_height,
    required double weekday_height,
    required double text_height,
    CalendarFormat calendar_format = CalendarFormat.month,
  }) {
    final minimum_height = math.max(80.0, text_height * 3 + 32);
    final week_count = weekCount(calendar_format, month);
    return math.max(
      minimum_height,
      (available_height - weekday_height - 8) / week_count,
    );
  }
}

enum CalendarCellLayoutMode { compact, detailed }
