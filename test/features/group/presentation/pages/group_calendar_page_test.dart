// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shift_mate/features/group/application/group_providers.dart';
import 'package:shift_mate/features/group/domain/entities/group_models.dart';
import 'package:shift_mate/features/group/domain/repositories/group_repository.dart';
import 'package:shift_mate/features/group/presentation/pages/group_calendar_page.dart';
import 'package:timezone/data/latest.dart' as timezone_data;

class _FakeGroupRepository implements GroupRepository {
  @override
  Future<GroupDetail> getGroupDetail(String group_id) async {
    return GroupDetail(
      group_id: group_id,
      name: '우리 병동',
      timezone: 'Asia/Seoul',
      my_role: GroupRole.owner,
      member_count: 3,
      members: [
        GroupMember(
          user_id: 'self',
          name: '나',
          role: GroupRole.owner,
          joined_at: DateTime.utc(2026, 8, 1),
        ),
        GroupMember(
          user_id: 'visible',
          name: '공개 멤버',
          role: GroupRole.member,
          joined_at: DateTime.utc(2026, 8, 1, 1),
        ),
        GroupMember(
          user_id: 'denied',
          name: '비공개 멤버',
          role: GroupRole.member,
          joined_at: DateTime.utc(2026, 8, 1, 2),
        ),
      ],
      created_by_user_id: 'self',
      created_at: DateTime.utc(2026, 8, 1),
      updated_at: DateTime.utc(2026, 8, 1),
    );
  }

  @override
  Future<GroupCalendarRange> getGroupCalendarRange({
    required String group_id,
    required DateTime start_date,
    required DateTime end_date,
  }) async {
    return GroupCalendarRange(
      group: GroupCalendarHeader(
        group_id: group_id,
        name: '우리 병동',
        timezone: 'Asia/Seoul',
      ),
      start_date: '2026-07-01',
      end_date: '2026-09-30',
      members: [
        GroupCalendarMember(
          user_id: 'self',
          name: '나',
          role: GroupRole.owner,
          joined_at: DateTime.utc(2026, 8, 1),
          calendar_access: CalendarAccess.self,
        ),
        GroupCalendarMember(
          user_id: 'visible',
          name: '공개 멤버',
          role: GroupRole.member,
          joined_at: DateTime.utc(2026, 8, 1, 1),
          calendar_access: CalendarAccess.visible,
        ),
        GroupCalendarMember(
          user_id: 'denied',
          name: '비공개 멤버',
          role: GroupRole.member,
          joined_at: DateTime.utc(2026, 8, 1, 2),
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
          start_time: '07:00:00',
          end_time: '15:00:00',
          created_at: DateTime.utc(2026, 8, 1),
          updated_at: DateTime.utc(2026, 8, 1),
        ),
        GroupCalendarWorkShift(
          owner_user_id: 'visible',
          work_shift_id: 'shift-without-time',
          work_date: '2026-08-03',
          shift_type_code: 'F',
          shift_type_name: '플렉스',
          shift_type_color: 0xFFE85F80,
          created_at: DateTime.utc(2026, 8, 1),
          updated_at: DateTime.utc(2026, 8, 1),
        ),
      ],
      events: [
        GroupCalendarEvent(
          owner_user_id: 'self',
          event_id: 'event-1',
          title: '서울 일정',
          all_day: false,
          start_at: DateTime.utc(2026, 8, 1, 15, 30),
          end_at: DateTime.utc(2026, 8, 1, 16, 30),
          visibility_level: 0,
        ),
      ],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    timezone_data.initializeTimeZones();
    await initializeDateFormatting('ko_KR');
  });

  testWidgets('근무 미설정 문구를 숨기고 DENIED 멤버는 공개 안 함으로 표시한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(_FakeGroupRepository()),
        ],
        child: CupertinoApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 900)),
            child: GroupCalendarPage(
              group_id: 'group-1',
              initial_date: DateTime(2026, 8, 2),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('우리 병동'), findsOneWidget);
    expect(find.text('3명'), findsOneWidget);
    expect(find.text('근무 1명'), findsOneWidget);
    expect(find.text('일정 1개'), findsOneWidget);
    expect(find.text('데이 · 07:00–15:00'), findsOneWidget);
    expect(find.text('근무 없음'), findsNothing);
    expect(find.text('캘린더 공개 안 함'), findsOneWidget);
    expect(find.text('00:30 서울 일정'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('group-calendar-management-button')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('시간 없는 근무는 상세에 표시하되 날짜 셀 점은 그리지 않는다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(_FakeGroupRepository()),
        ],
        child: CupertinoApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 900)),
            child: GroupCalendarPage(
              group_id: 'group-1',
              initial_date: DateTime(2026, 8, 2),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('group-shift-dot-2026-08-02-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('group-shift-dot-2026-08-03-0')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('group-day-2026-08-03')));
    await tester.pumpAndSettle();

    expect(find.text('근무 1명'), findsOneWidget);
    expect(find.text('플렉스 · 시간 없음'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
