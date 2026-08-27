// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/features/calendar/application/calendar_range_notifier.dart';
import 'package:shift_mate/features/calendar/data/models/event_api_model.dart';
import 'package:shift_mate/features/calendar/data/models/work_shift_api_model.dart';

WorkShiftApiModel _workShift(DateTime date, {String id = 'shift-1'}) {
  return WorkShiftApiModel(
    workShiftId: id,
    workDate: date,
    shiftTypeCode: 'D',
    shiftTypeName: '데이',
    createdAt: date,
    updatedAt: date,
  );
}

void main() {
  test('같은 월의 중복 요청을 하나로 합치고 3개월 데이터를 병합한다', () async {
    final completer = Completer<CalendarRangeData>();
    var request_count = 0;
    late DateTime requested_start_date;
    late DateTime requested_end_date;
    final notifier = CalendarRangeNotifier(
      loader: ({required start_date, required end_date}) {
        request_count += 1;
        requested_start_date = start_date;
        requested_end_date = end_date;
        return completer.future;
      },
    );

    final first_request = notifier.ensureMonthLoaded(DateTime(2026, 1, 15));
    final duplicate_request = notifier.ensureMonthLoaded(DateTime(2026, 1, 28));

    expect(identical(first_request, duplicate_request), isTrue);
    expect(request_count, 1);
    expect(requested_start_date, DateTime(2025, 12, 1));
    expect(requested_end_date, DateTime(2026, 2, 28));
    expect(notifier.state.loading_months, {'2025-12', '2026-01', '2026-02'});

    final shift_date = DateTime(2026, 1, 10, 8);
    final event = EventApiModel(
      eventId: 'event-1',
      title: '이틀 일정',
      allDay: true,
      startAt: DateTime(2026, 1, 10),
      endAt: DateTime(2026, 1, 12),
      visibilityLevel: 0,
    );
    completer.complete(
      CalendarRangeData(workShifts: [_workShift(shift_date)], events: [event]),
    );
    await first_request;

    expect(notifier.state.loaded_months, {'2025-12', '2026-01', '2026-02'});
    expect(notifier.state.loading_months, isEmpty);
    expect(
      notifier.state.workShiftFor(DateTime(2026, 1, 10))?.workShiftId,
      'shift-1',
    );
    expect(notifier.state.eventsFor(DateTime(2026, 1, 10)), [event]);
    expect(notifier.state.eventsFor(DateTime(2026, 1, 11)), [event]);

    await notifier.ensureMonthLoaded(DateTime(2026, 2, 1));
    expect(request_count, 1);
  });

  test('조회 실패를 상태로 전달하고 동일 월 재시도를 허용한다', () async {
    var request_count = 0;
    final notifier = CalendarRangeNotifier(
      loader: ({required start_date, required end_date}) async {
        request_count += 1;
        if (request_count == 1) throw StateError('조회 실패');
        return CalendarRangeData(workShifts: const [], events: const []);
      },
    );

    await notifier.ensureMonthLoaded(DateTime(2026, 3));

    expect(notifier.state.loaded_months, isEmpty);
    expect(notifier.state.loading_months, isEmpty);
    expect(notifier.state.last_error, isA<StateError>());
    expect(notifier.state.error_revision, 1);

    await notifier.ensureMonthLoaded(DateTime(2026, 3));

    expect(request_count, 2);
    expect(notifier.state.loaded_months, contains('2026-03'));
    expect(notifier.state.last_error, isNull);
  });

  test('생성·수정·삭제 결과를 조회 캐시에 직접 반영한다', () {
    final notifier = CalendarRangeNotifier(
      loader: ({required start_date, required end_date}) async =>
          CalendarRangeData(workShifts: const [], events: const []),
    );
    final date = DateTime(2026, 4, 2);
    final shift = _workShift(date);
    final event = EventApiModel(
      eventId: 'event-2',
      title: '약속',
      allDay: false,
      startAt: date.add(const Duration(hours: 18)),
      endAt: date.add(const Duration(hours: 19)),
      visibilityLevel: 0,
    );

    notifier.upsertWorkShifts([shift]);
    notifier.addEvent(event);

    expect(notifier.state.workShiftFor(date), same(shift));
    expect(notifier.state.eventsFor(date), [event]);

    notifier.removeWorkShift(date);
    expect(notifier.state.workShiftFor(date), isNull);

    notifier.removeEvent(event.eventId);
    expect(notifier.state.eventsFor(date), isEmpty);
  });

  test('여러 날짜에 걸친 개인 일정 삭제 시 모든 날짜 캐시에서 제거한다', () {
    final notifier = CalendarRangeNotifier(
      loader: ({required start_date, required end_date}) async =>
          CalendarRangeData(workShifts: const [], events: const []),
    );
    final event = EventApiModel(
      eventId: 'event-multi-day',
      title: '연속 일정',
      allDay: true,
      startAt: DateTime(2026, 4, 2),
      endAt: DateTime(2026, 4, 5),
      visibilityLevel: 0,
    );

    notifier.addEvent(event);
    notifier.removeEvent(event.eventId);

    expect(notifier.state.eventsFor(DateTime(2026, 4, 2)), isEmpty);
    expect(notifier.state.eventsFor(DateTime(2026, 4, 3)), isEmpty);
    expect(notifier.state.eventsFor(DateTime(2026, 4, 4)), isEmpty);
    expect(notifier.state.events_by_date, isEmpty);
  });
}
