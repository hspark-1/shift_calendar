// ignore_for_file: non_constant_identifier_names

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../domain/entities/group_models.dart';
import '../domain/repositories/group_repository.dart';
import 'group_calendar_range_state.dart';

class GroupCalendarRangeNotifier
    extends StateNotifier<GroupCalendarRangeState> {
  GroupCalendarRangeNotifier({
    required GroupRepository repository,
    required String group_id,
  }) : _repository = repository,
       _group_id = group_id,
       super(const GroupCalendarRangeState());

  final GroupRepository _repository;
  final String _group_id;
  final Map<String, Future<void>> _in_flight_by_month = {};

  Future<void> ensureMonthLoaded(DateTime focused_month) {
    final focused_key = groupCalendarMonthKey(focused_month);
    if (state.loaded_months.contains(focused_key)) return Future.value();

    final existing = _in_flight_by_month[focused_key];
    if (existing != null) return existing;

    final range = groupCalendarThreeMonthRange(focused_month);
    final inclusive_days =
        range.end_date.difference(range.start_date).inDays + 1;
    if (inclusive_days > 100) {
      state = state.copyWith(
        last_error: StateError('그룹 캘린더 조회 범위는 100일 이하여야 합니다.'),
        error_revision: state.error_revision + 1,
      );
      return Future.value();
    }

    final range_keys = {
      groupCalendarMonthKey(range.start_date),
      focused_key,
      groupCalendarMonthKey(range.end_date),
    };
    final overlapping = range_keys
        .map((key) => _in_flight_by_month[key])
        .whereType<Future<void>>()
        .firstOrNull;
    if (overlapping != null) {
      return overlapping.then((_) => ensureMonthLoaded(focused_month));
    }

    final future = _loadRange(range: range, range_keys: range_keys);
    for (final key in range_keys) {
      _in_flight_by_month[key] = future;
    }
    return future;
  }

  Future<void> refreshMonth(DateTime focused_month) {
    final range = groupCalendarThreeMonthRange(focused_month);
    final keys = {
      groupCalendarMonthKey(range.start_date),
      groupCalendarMonthKey(focused_month),
      groupCalendarMonthKey(range.end_date),
    };
    state = state.copyWith(
      loaded_months: {...state.loaded_months}..removeAll(keys),
    );
    return ensureMonthLoaded(focused_month);
  }

  Future<void> _loadRange({
    required ({DateTime start_date, DateTime end_date}) range,
    required Set<String> range_keys,
  }) async {
    state = state.copyWith(
      loading_months: {...state.loading_months, ...range_keys},
      clear_error: true,
    );

    try {
      final result = await _repository.getGroupCalendarRange(
        group_id: _group_id,
        start_date: range.start_date,
        end_date: range.end_date,
      );
      if (!mounted) return;
      final location = tz.getLocation(result.group.timezone);
      final shifts = _copyShiftsOutsideRange(state.work_shifts_by_date, range);
      final events = _copyEventsOutsideRange(state.events_by_date, range);

      for (final shift in result.work_shifts) {
        final date = DateTime.parse(shift.work_date);
        final key = normalizeGroupCalendarDate(date);
        shifts.putIfAbsent(key, () => []).add(shift);
      }
      for (final values in shifts.values) {
        values.sort((a, b) => a.owner_user_id.compareTo(b.owner_user_id));
      }

      for (final event in result.events) {
        _addEventToDateMap(
          events: events,
          event: event,
          location: location,
          range: range,
        );
      }

      final members_by_id = <String, GroupCalendarMember>{
        for (final member in result.members) member.user_id: member,
      };
      state = state.copyWith(
        group: result.group,
        members_by_user_id: Map.unmodifiable(members_by_id),
        member_order: List.unmodifiable(
          result.members.map((member) => member.user_id),
        ),
        work_shifts_by_date: Map.unmodifiable({
          for (final entry in shifts.entries)
            entry.key: List<GroupCalendarWorkShift>.unmodifiable(entry.value),
        }),
        events_by_date: Map.unmodifiable({
          for (final entry in events.entries)
            entry.key: List<GroupCalendarEvent>.unmodifiable(entry.value),
        }),
        loaded_months: {...state.loaded_months, ...range_keys},
        loading_months: {...state.loading_months}..removeAll(range_keys),
        clear_error: true,
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        loading_months: {...state.loading_months}..removeAll(range_keys),
        last_error: error,
        error_revision: state.error_revision + 1,
      );
    } finally {
      for (final key in range_keys) {
        _in_flight_by_month.remove(key);
      }
    }
  }

  Map<DateTime, List<GroupCalendarWorkShift>> _copyShiftsOutsideRange(
    Map<DateTime, List<GroupCalendarWorkShift>> source,
    ({DateTime start_date, DateTime end_date}) range,
  ) {
    return {
      for (final entry in source.entries)
        if (!_isWithinRange(entry.key, range)) entry.key: [...entry.value],
    };
  }

  Map<DateTime, List<GroupCalendarEvent>> _copyEventsOutsideRange(
    Map<DateTime, List<GroupCalendarEvent>> source,
    ({DateTime start_date, DateTime end_date}) range,
  ) {
    return {
      for (final entry in source.entries)
        if (!_isWithinRange(entry.key, range)) entry.key: [...entry.value],
    };
  }

  bool _isWithinRange(
    DateTime date,
    ({DateTime start_date, DateTime end_date}) range,
  ) {
    final normalized = normalizeGroupCalendarDate(date);
    return !normalized.isBefore(range.start_date) &&
        !normalized.isAfter(range.end_date);
  }

  void _addEventToDateMap({
    required Map<DateTime, List<GroupCalendarEvent>> events,
    required GroupCalendarEvent event,
    required tz.Location location,
    required ({DateTime start_date, DateTime end_date}) range,
  }) {
    final local_start = tz.TZDateTime.from(event.start_at, location);
    final local_end = tz.TZDateTime.from(event.end_at, location);
    var start_date = DateTime(
      local_start.year,
      local_start.month,
      local_start.day,
    );
    var end_date = DateTime(local_end.year, local_end.month, local_end.day);
    final is_exclusive_midnight =
        local_end.hour == 0 &&
        local_end.minute == 0 &&
        local_end.second == 0 &&
        local_end.millisecond == 0 &&
        local_end.microsecond == 0;
    if (is_exclusive_midnight) {
      end_date = end_date.subtract(const Duration(days: 1));
    }
    if (end_date.isBefore(start_date)) end_date = start_date;
    if (start_date.isBefore(range.start_date)) start_date = range.start_date;
    if (end_date.isAfter(range.end_date)) end_date = range.end_date;

    var cursor = start_date;
    while (!cursor.isAfter(end_date)) {
      final list = events.putIfAbsent(cursor, () => []);
      if (!list.any((item) => item.event_id == event.event_id)) {
        list.add(event);
        list.sort((a, b) => a.start_at.compareTo(b.start_at));
      }
      cursor = cursor.add(const Duration(days: 1));
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
