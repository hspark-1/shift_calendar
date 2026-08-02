// ignore_for_file: non_constant_identifier_names

import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/features/group/application/group_calendar_range_notifier.dart';
import 'package:shift_mate/features/group/domain/entities/group_models.dart';
import 'package:shift_mate/features/group/domain/repositories/group_repository.dart';
import 'package:timezone/data/latest.dart' as timezone_data;

class _FakeGroupRepository implements GroupRepository {
  DateTime? requested_start_date;
  DateTime? requested_end_date;

  @override
  Future<GroupCalendarRange> getGroupCalendarRange({
    required String group_id,
    required DateTime start_date,
    required DateTime end_date,
  }) async {
    requested_start_date = start_date;
    requested_end_date = end_date;
    return GroupCalendarRange(
      group: const GroupCalendarHeader(
        group_id: 'group-1',
        name: '우리 병동',
        timezone: 'Asia/Seoul',
      ),
      start_date: '2026-07-01',
      end_date: '2026-09-30',
      members: [
        GroupCalendarMember(
          user_id: 'self',
          name: '나',
          role: GroupRole.member,
          joined_at: DateTime.utc(2026, 8, 1),
          calendar_access: CalendarAccess.self,
        ),
        GroupCalendarMember(
          user_id: 'hidden',
          name: '비공개',
          role: GroupRole.member,
          joined_at: DateTime.utc(2026, 8, 1),
          calendar_access: CalendarAccess.denied,
        ),
      ],
      work_shifts: [
        GroupCalendarWorkShift(
          owner_user_id: 'self',
          work_shift_id: 'shift-1',
          work_date: '2026-08-02',
          shift_type_code: 'D',
          shift_type_name: '데이',
          shift_type_color: 0xFFFF9500,
          created_at: DateTime.utc(2026, 8, 1),
          updated_at: DateTime.utc(2026, 8, 1),
        ),
      ],
      events: [
        GroupCalendarEvent(
          owner_user_id: 'self',
          event_id: 'event-seoul-day',
          title: '서울 자정 이후 일정',
          all_day: false,
          start_at: DateTime.utc(2026, 8, 1, 15, 30),
          end_at: DateTime.utc(2026, 8, 1, 16, 30),
          visibility_level: 0,
        ),
        GroupCalendarEvent(
          owner_user_id: 'self',
          event_id: 'event-exclusive-end',
          title: '하루 일정',
          all_day: true,
          start_at: DateTime.utc(2026, 8, 2, 15),
          end_at: DateTime.utc(2026, 8, 3, 15),
          visibility_level: 0,
        ),
      ],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(timezone_data.initializeTimeZones);

  test('3개월 범위를 요청하고 그룹 시간대로 이벤트 날짜를 배치한다', () async {
    final repository = _FakeGroupRepository();
    final notifier = GroupCalendarRangeNotifier(
      repository: repository,
      group_id: 'group-1',
    );
    addTearDown(notifier.dispose);

    await notifier.ensureMonthLoaded(DateTime(2026, 8, 15));

    expect(repository.requested_start_date, DateTime(2026, 7, 1));
    expect(repository.requested_end_date, DateTime(2026, 9, 30));
    expect(
      notifier.state.loaded_months,
      containsAll(['2026-07', '2026-08', '2026-09']),
    );
    expect(notifier.state.members.length, 2);
    expect(notifier.state.members.last.calendar_access, CalendarAccess.denied);
    expect(
      notifier.state.shiftsFor(DateTime(2026, 8, 2)).single.owner_user_id,
      'self',
    );
    expect(
      notifier.state
          .eventsFor(DateTime(2026, 8, 2))
          .map((item) => item.event_id),
      contains('event-seoul-day'),
    );
    expect(
      notifier.state
          .eventsFor(DateTime(2026, 8, 3))
          .map((item) => item.event_id),
      contains('event-exclusive-end'),
    );
    expect(
      notifier.state
          .eventsFor(DateTime(2026, 8, 4))
          .map((item) => item.event_id),
      isNot(contains('event-exclusive-end')),
    );
  });

  test('같은 달을 다시 요청하면 중복 API 호출을 만들지 않는다', () async {
    final repository = _CountingGroupRepository();
    final notifier = GroupCalendarRangeNotifier(
      repository: repository,
      group_id: 'group-1',
    );
    addTearDown(notifier.dispose);

    await notifier.ensureMonthLoaded(DateTime(2026, 8));
    await notifier.ensureMonthLoaded(DateTime(2026, 8, 20));

    expect(repository.call_count, 1);
  });
}

class _CountingGroupRepository extends _FakeGroupRepository {
  int call_count = 0;

  @override
  Future<GroupCalendarRange> getGroupCalendarRange({
    required String group_id,
    required DateTime start_date,
    required DateTime end_date,
  }) {
    call_count += 1;
    return super.getGroupCalendarRange(
      group_id: group_id,
      start_date: start_date,
      end_date: end_date,
    );
  }
}
