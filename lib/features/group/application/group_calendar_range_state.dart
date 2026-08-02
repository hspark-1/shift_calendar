// ignore_for_file: non_constant_identifier_names

import '../domain/entities/group_models.dart';

String groupCalendarMonthKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}';
}

DateTime normalizeGroupCalendarDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

({DateTime start_date, DateTime end_date}) groupCalendarThreeMonthRange(
  DateTime focused_month,
) {
  return (
    start_date: DateTime(focused_month.year, focused_month.month - 1, 1),
    end_date: DateTime(focused_month.year, focused_month.month + 2, 0),
  );
}

class GroupCalendarRangeState {
  const GroupCalendarRangeState({
    this.group,
    this.members_by_user_id = const {},
    this.member_order = const [],
    this.work_shifts_by_date = const {},
    this.events_by_date = const {},
    this.loaded_months = const {},
    this.loading_months = const {},
    this.last_error,
    this.error_revision = 0,
  });

  final GroupCalendarHeader? group;
  final Map<String, GroupCalendarMember> members_by_user_id;
  final List<String> member_order;
  final Map<DateTime, List<GroupCalendarWorkShift>> work_shifts_by_date;
  final Map<DateTime, List<GroupCalendarEvent>> events_by_date;
  final Set<String> loaded_months;
  final Set<String> loading_months;
  final Object? last_error;
  final int error_revision;

  bool get is_loading => loading_months.isNotEmpty;

  List<GroupCalendarMember> get members => member_order
      .map((user_id) => members_by_user_id[user_id])
      .whereType<GroupCalendarMember>()
      .toList(growable: false);

  List<GroupCalendarWorkShift> shiftsFor(DateTime date) {
    return work_shifts_by_date[normalizeGroupCalendarDate(date)] ?? const [];
  }

  List<GroupCalendarEvent> eventsFor(DateTime date) {
    return events_by_date[normalizeGroupCalendarDate(date)] ?? const [];
  }

  GroupCalendarRangeState copyWith({
    GroupCalendarHeader? group,
    Map<String, GroupCalendarMember>? members_by_user_id,
    List<String>? member_order,
    Map<DateTime, List<GroupCalendarWorkShift>>? work_shifts_by_date,
    Map<DateTime, List<GroupCalendarEvent>>? events_by_date,
    Set<String>? loaded_months,
    Set<String>? loading_months,
    Object? last_error,
    bool clear_error = false,
    int? error_revision,
  }) {
    return GroupCalendarRangeState(
      group: group ?? this.group,
      members_by_user_id: members_by_user_id ?? this.members_by_user_id,
      member_order: member_order ?? this.member_order,
      work_shifts_by_date: work_shifts_by_date ?? this.work_shifts_by_date,
      events_by_date: events_by_date ?? this.events_by_date,
      loaded_months: loaded_months ?? this.loaded_months,
      loading_months: loading_months ?? this.loading_months,
      last_error: clear_error ? null : last_error ?? this.last_error,
      error_revision: error_revision ?? this.error_revision,
    );
  }
}
