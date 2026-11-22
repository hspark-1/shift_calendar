// ignore_for_file: non_constant_identifier_names

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/event_api_model.dart';
import '../data/models/work_shift_api_model.dart';
import 'calendar_range_state.dart';

class CalendarRangeNotifier extends StateNotifier<CalendarRangeState> {
  CalendarRangeNotifier({
    required CalendarRangeLoader loader,
    bool Function(Object error)? access_denied_when,
  }) : _loader = loader,
       _access_denied_when = access_denied_when,
       super(const CalendarRangeState());

  final CalendarRangeLoader _loader;
  final bool Function(Object error)? _access_denied_when;
  int _access_revision = 0;
  final Map<String, Future<void>> _in_flight_by_month = {};
  final Map<String, Object> _request_tokens_by_month = {};
  final Map<Object, Map<String, EventApiModel?>> _event_changes_by_request = {};
  final Map<Object, Map<DateTime, WorkShiftApiModel?>>
  _work_shift_changes_by_request = {};

  Future<void> ensureMonthLoaded(DateTime focused_month) =>
      _loadMonth(focused_month);

  Future<void> refreshMonth(DateTime focused_month) async {
    await _in_flight_by_month[calendarMonthKey(focused_month)];
    if (!mounted) return;
    await _loadMonth(focused_month, refresh: true);
  }

  Future<void> _loadMonth(DateTime focused_month, {bool refresh = false}) {
    final focused_month_key = calendarMonthKey(focused_month);
    if (!refresh && state.loaded_months.contains(focused_month_key)) {
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
    _event_changes_by_request[request_token] = {};
    _work_shift_changes_by_request[request_token] = {};
    final load_future = _loadRange(
      range: range,
      range_month_keys: range_month_keys,
      request_token: request_token,
      refresh: refresh,
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
    required bool refresh,
  }) async {
    final access_revision = _access_revision;
    state = state.copyWith(
      loading_months: {...state.loading_months, ...range_month_keys},
      clear_error: true,
    );

    try {
      final data = await _loader(
        start_date: range.start_date,
        end_date: range.end_date,
      );
      if (!mounted || access_revision != _access_revision) return;
      final work_shifts = Map<DateTime, WorkShiftApiModel>.from(
        state.work_shifts_by_date,
      );
      final events = <DateTime, List<EventApiModel>>{
        for (final entry in state.events_by_date.entries)
          entry.key: [...entry.value],
      };

      if (refresh) {
        final replaced_ids = <String>{
          for (final entry in events.entries)
            if (!entry.key.isBefore(range.start_date) &&
                !entry.key.isAfter(range.end_date))
              for (final event in entry.value) event.eventId,
        };
        for (final event_id in replaced_ids) {
          _removeEventFromMap(events, event_id);
        }
      }

      for (final work_shift in data.workShifts) {
        work_shifts[normalizeCalendarDate(work_shift.workDate)] = work_shift;
      }
      for (final change
          in _work_shift_changes_by_request[request_token]!.entries) {
        if (change.value == null) {
          work_shifts.remove(change.key);
        } else {
          work_shifts[change.key] = change.value!;
        }
      }
      for (final event in data.events) {
        _removeEventFromMap(events, event.eventId);
        addEventToCalendarDateMap(events, event);
      }
      // 조회가 시작된 뒤 성공한 mutation을 늦은 GET 결과 위에 다시 적용한다.
      for (final change in _event_changes_by_request[request_token]!.entries) {
        _removeEventFromMap(events, change.key);
        if (change.value != null) {
          addEventToCalendarDateMap(events, change.value!);
        }
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
        is_access_denied: false,
      );
    } catch (error) {
      if (!mounted || access_revision != _access_revision) return;
      if (_access_denied_when?.call(error) == true) {
        // 거절 이전에 시작한 다른 월 요청도 캐시를 복원하지 못하게 한다.
        _access_revision += 1;
        _in_flight_by_month.clear();
        _request_tokens_by_month.clear();
        state = CalendarRangeState(
          is_access_denied: true,
          last_error: error,
          error_revision: state.error_revision + 1,
        );
        return;
      }
      state = state.copyWith(
        loading_months: _loadingMonthsAfterRequest(
          range_month_keys,
          request_token,
        ),
        last_error: error,
        error_revision: state.error_revision + 1,
      );
    } finally {
      _event_changes_by_request.remove(request_token);
      _work_shift_changes_by_request.remove(request_token);
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
    if (!mounted) return;
    final updated = Map<DateTime, WorkShiftApiModel>.from(
      state.work_shifts_by_date,
    );
    for (final work_shift in work_shifts) {
      final date = normalizeCalendarDate(work_shift.workDate);
      updated[date] = work_shift;
      for (final changes in _work_shift_changes_by_request.values) {
        changes[date] = work_shift;
      }
    }
    state = state.copyWith(work_shifts_by_date: Map.unmodifiable(updated));
  }

  void removeWorkShift(DateTime date) {
    if (!mounted) return;
    final normalized_date = normalizeCalendarDate(date);
    for (final changes in _work_shift_changes_by_request.values) {
      changes[normalized_date] = null;
    }
    final updated = Map<DateTime, WorkShiftApiModel>.from(
      state.work_shifts_by_date,
    )..remove(normalized_date);
    state = state.copyWith(work_shifts_by_date: Map.unmodifiable(updated));
  }

  void addEvent(EventApiModel event) => replaceEvent(event);

  void replaceEvent(EventApiModel event) {
    if (!mounted) return;
    _recordEventChange(event.eventId, event);
    final updated = <DateTime, List<EventApiModel>>{
      for (final entry in state.events_by_date.entries)
        entry.key: [...entry.value],
    };
    _removeEventFromMap(updated, event.eventId);
    addEventToCalendarDateMap(updated, event);
    state = state.copyWith(
      events_by_date: Map.unmodifiable({
        for (final entry in updated.entries)
          entry.key: List<EventApiModel>.unmodifiable(entry.value),
      }),
    );
  }

  void removeEvent(String event_id) {
    if (!mounted) return;
    _recordEventChange(event_id, null);
    final updated = <DateTime, List<EventApiModel>>{};
    for (final entry in state.events_by_date.entries) {
      final remaining_events = entry.value
          .where((event) => event.eventId != event_id)
          .toList(growable: false);
      if (remaining_events.isNotEmpty) {
        updated[entry.key] = List<EventApiModel>.unmodifiable(remaining_events);
      }
    }
    state = state.copyWith(events_by_date: Map.unmodifiable(updated));
  }

  void _recordEventChange(String event_id, EventApiModel? event) {
    for (final changes in _event_changes_by_request.values) {
      changes[event_id] = event;
    }
  }

  void _removeEventFromMap(
    Map<DateTime, List<EventApiModel>> events,
    String event_id,
  ) {
    for (final event_list in events.values) {
      event_list.removeWhere((event) => event.eventId == event_id);
    }
    events.removeWhere((_, event_list) => event_list.isEmpty);
  }
}
