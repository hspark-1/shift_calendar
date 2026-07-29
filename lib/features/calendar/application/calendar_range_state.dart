// ignore_for_file: non_constant_identifier_names

import '../data/models/event_api_model.dart';
import '../data/models/work_shift_api_model.dart';

typedef CalendarRangeLoader =
    Future<CalendarRangeData> Function({
      required DateTime start_date,
      required DateTime end_date,
    });

String calendarMonthKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}';
}

({DateTime start_date, DateTime end_date}) calendarThreeMonthRange(
  DateTime focused_month,
) {
  return (
    start_date: DateTime(focused_month.year, focused_month.month - 1, 1),
    end_date: DateTime(focused_month.year, focused_month.month + 2, 0),
  );
}

class CalendarRangeState {
  const CalendarRangeState({
    this.work_shifts_by_date = const {},
    this.events_by_date = const {},
    this.loaded_months = const {},
    this.loading_months = const {},
    this.last_error,
    this.error_revision = 0,
  });

  final Map<DateTime, WorkShiftApiModel> work_shifts_by_date;
  final Map<DateTime, List<EventApiModel>> events_by_date;
  final Set<String> loaded_months;
  final Set<String> loading_months;
  final Object? last_error;
  final int error_revision;

  bool get is_loading => loading_months.isNotEmpty;

  WorkShiftApiModel? workShiftFor(DateTime date) {
    return work_shifts_by_date[normalizeCalendarDate(date)];
  }

  List<EventApiModel> eventsFor(DateTime date) {
    return events_by_date[normalizeCalendarDate(date)] ?? const [];
  }

  CalendarRangeState copyWith({
    Map<DateTime, WorkShiftApiModel>? work_shifts_by_date,
    Map<DateTime, List<EventApiModel>>? events_by_date,
    Set<String>? loaded_months,
    Set<String>? loading_months,
    Object? last_error,
    bool clear_error = false,
    int? error_revision,
  }) {
    return CalendarRangeState(
      work_shifts_by_date: work_shifts_by_date ?? this.work_shifts_by_date,
      events_by_date: events_by_date ?? this.events_by_date,
      loaded_months: loaded_months ?? this.loaded_months,
      loading_months: loading_months ?? this.loading_months,
      last_error: clear_error ? null : last_error ?? this.last_error,
      error_revision: error_revision ?? this.error_revision,
    );
  }
}
