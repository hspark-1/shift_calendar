// ignore_for_file: non_constant_identifier_names

import 'package:timezone/timezone.dart' as tz;

import '../../calendar/data/models/work_shift_api_model.dart';

/// 날짜는 UTC instant가 아니라 사용자 시간대의 근무일이다.
class ShiftWidgetSnapshot {
  ShiftWidgetSnapshot({
    required this.owner_id,
    required this.timezone,
    required this.updated_at,
    required this.start_date,
    required this.end_date,
    required this.shifts,
  });

  final String owner_id;
  final String timezone;
  final DateTime updated_at;
  final DateTime start_date;
  final DateTime end_date;
  final List<WorkShiftApiModel> shifts;

  static String dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// 이번 주 월요일부터 6주. DST에서도 날짜 성분으로 계산한다.
  static ({DateTime start_date, DateTime end_date}) rangeFor(
    DateTime now,
    String timezone,
  ) {
    final local_now = tz.TZDateTime.from(now, tz.getLocation(timezone));
    final start_date = DateTime(
      local_now.year,
      local_now.month,
      local_now.day - local_now.weekday + 1,
    );
    return (
      start_date: start_date,
      end_date: DateTime(
        start_date.year,
        start_date.month,
        start_date.day + 41,
      ),
    );
  }

  Map<String, Object?> toJson() {
    final sorted_shifts = [...shifts]
      ..sort((first, second) => first.workDate.compareTo(second.workDate));
    return {
      'schema_version': 1,
      'owner_id': owner_id,
      'timezone': timezone,
      'updated_at': updated_at.toUtc().toIso8601String(),
      'start_date': dateKey(start_date),
      'end_date': dateKey(end_date),
      'shifts': [
        for (final shift in sorted_shifts)
          if (dateKey(shift.workDate).compareTo(dateKey(start_date)) >= 0 &&
              dateKey(shift.workDate).compareTo(dateKey(end_date)) <= 0)
            {
              'date': dateKey(shift.workDate),
              'code': shift.shiftTypeCode,
              'name': shift.shiftTypeName,
              'color': shift.shiftTypeColor,
              'start_time': shift.startTime,
              'end_time': shift.endTime,
            },
      ],
    };
  }
}
