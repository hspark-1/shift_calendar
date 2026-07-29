// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:table_calendar/table_calendar.dart';

abstract final class CalendarLayoutPolicy {
  static const double short_screen_height = 750;

  static CalendarFormat visibleFormat({
    required double screen_height,
    required CalendarFormat preferred_format,
  }) {
    return screen_height < short_screen_height
        ? CalendarFormat.twoWeeks
        : preferred_format;
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
}

enum CalendarCellLayoutMode { compact, detailed }
