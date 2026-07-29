// ignore_for_file: non_constant_identifier_names

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/event_api_model.dart';
import '../data/models/work_shift_api_model.dart';
import 'calendar_range_state.dart';

class CalendarRangeNotifier extends StateNotifier<CalendarRangeState> {
  CalendarRangeNotifier({required CalendarRangeLoader loader})
    : _loader = loader,
      super(const CalendarRangeState());

  final CalendarRangeLoader _loader;
  final Map<String, Future<void>> _in_flight_by_month = {};
  final Map<String, Object> _request_tokens_by_month = {};

  Future<void> ensureMonthLoaded(DateTime focused_month) {
    final focused_month_key = calendarMonthKey(focused_month);
    if (state.loaded_months.contains(focused_month_key)) {
      return Future.value();
    }

    final existing_request = _in_flight_by_month[focused_month_key];
    if (existing_request != null) return existing_request;

    final range = calendarThreeMonthRange(focused_month);
    final range_month_keys = {
      calendarMonthKey(range.start_date),
      focused_month_key,
      calendarMonthKey(range.end_date),
    };
    final request_token = Object();
    final load_future = _loadRange(
      range: range,
      range_month_keys: range_month_keys,
      request_token: request_token,
    );
    for (final month_key in range_month_keys) {
      _in_flight_by_month[month_key] = load_future;
      _request_tokens_by_month[month_key] = request_token;
    }
    return load_future;
  }

  Future<void> _loadRange({
    required ({DateTime start_date, DateTime end_date}) range,
    required Set<String> range_month_keys,
    required Object request_token,
  }) async {
    state = state.copyWith(
      loading_months: {...state.loading_months, ...range_month_keys},
      clear_error: true,
    );

    try {
      final data = await _loader(
        start_date: range.start_date,
        end_date: range.end_date,
      );
      if (!mounted) return;
      final work_shifts = Map<DateTime, WorkShiftApiModel>.from(
        state.work_shifts_by_date,
      );
      final events = <DateTime, List<EventApiModel>>{
        for (final entry in state.events_by_date.entries)
          entry.key: [...entry.value],
      };

      for (final work_shift in data.workShifts) {
        work_shifts[normalizeCalendarDate(work_shift.workDate)] = work_shift;
      }
      for (final event in data.events) {
        addEventToCalendarDateMap(events, event);
      }

      state = state.copyWith(
        work_shifts_by_date: Map.unmodifiable(work_shifts),
        events_by_date: Map.unmodifiable({
          for (final entry in events.entries)
            entry.key: List<EventApiModel>.unmodifiable(entry.value),
        }),
        loaded_months: {...state.loaded_months, ...range_month_keys},
        loading_months: _loadingMonthsAfterRequest(
          range_month_keys,
          request_token,
        ),
        clear_error: true,
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        loading_months: _loadingMonthsAfterRequest(
          range_month_keys,
          request_token,
        ),
        last_error: error,
        error_revision: state.error_revision + 1,
      );
    } finally {
      for (final month_key in range_month_keys) {
        if (identical(_request_tokens_by_month[month_key], request_token)) {
          _in_flight_by_month.remove(month_key);
          _request_tokens_by_month.remove(month_key);
        }
      }
    }
  }

  Set<String> _loadingMonthsAfterRequest(
    Set<String> range_month_keys,
    Object request_token,
  ) {
    final remaining = {...state.loading_months};
    for (final month_key in range_month_keys) {
      if (identical(_request_tokens_by_month[month_key], request_token)) {
        remaining.remove(month_key);
      }
    }
    return remaining;
  }

  void upsertWorkShifts(Iterable<WorkShiftApiModel> work_shifts) {
    final updated = Map<DateTime, WorkShiftApiModel>.from(
      state.work_shifts_by_date,
    );
    for (final work_shift in work_shifts) {
      updated[normalizeCalendarDate(work_shift.workDate)] = work_shift;
    }
    state = state.copyWith(work_shifts_by_date: Map.unmodifiable(updated));
  }

  void removeWorkShift(DateTime date) {
    final updated = Map<DateTime, WorkShiftApiModel>.from(
      state.work_shifts_by_date,
    )..remove(normalizeCalendarDate(date));
    state = state.copyWith(work_shifts_by_date: Map.unmodifiable(updated));
  }

  void addEvent(EventApiModel event) {
    final updated = <DateTime, List<EventApiModel>>{
      for (final entry in state.events_by_date.entries)
        entry.key: [...entry.value],
    };
    addEventToCalendarDateMap(updated, event);
    state = state.copyWith(
      events_by_date: Map.unmodifiable({
        for (final entry in updated.entries)
          entry.key: List<EventApiModel>.unmodifiable(entry.value),
      }),
    );
  }
}
