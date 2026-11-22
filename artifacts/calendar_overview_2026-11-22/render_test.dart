// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shift_mate/core/navigation/main_tab_page.dart';
import 'package:shift_mate/core/theme/app_theme.dart';
import 'package:shift_mate/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:shift_mate/features/auth/presentation/providers/auth_provider.dart';
import 'package:shift_mate/features/calendar/data/models/event_api_model.dart';
import 'package:shift_mate/features/calendar/data/models/work_shift_api_model.dart';
import 'package:shift_mate/features/calendar/data/services/calendar_service.dart';
import 'package:shift_mate/features/calendar/presentation/providers/shift_types_provider.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/calendar_month_view.dart';
import 'package:shift_mate/features/friend/presentation/providers/friend_provider.dart';
import 'package:shift_mate/features/friend/presentation/providers/notification_provider.dart';
import 'package:shift_mate/features/group/application/group_providers.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:shift_mate/features/group/domain/entities/group_models.dart';
import 'package:shift_mate/features/group/domain/repositories/group_repository.dart';
import 'package:shift_mate/features/group/presentation/pages/group_calendar_page.dart';
import 'package:shift_mate/features/friend/presentation/pages/friend_list_page.dart';

import '../design_update_2026-11-10/render_update_test.dart' as fixtures;

class _CalendarRenderService extends CalendarService {
  _CalendarRenderService() : super(Dio());

  @override
  Future<CalendarRangeResponse> getCalendarRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async => CalendarRangeResponse(
    success: true,
    data: CalendarRangeData(
      workShifts: [
        for (
          var day = startDate;
          !day.isAfter(endDate);
          day = DateTime(day.year, day.month, day.day + 1)
        )
          if (day.day % 4 != 0)
            WorkShiftApiModel(
              workShiftId: 'shift-$day',
              workDate: day,
              shiftTypeCode: day.day % 3 == 0 ? 'N' : 'D',
              shiftTypeName: day.day % 3 == 0 ? '나이트' : '데이',
              shiftTypeColor: day.day % 3 == 0 ? 0xFF805AD5 : 0xFF43A047,
              startTime: day.day % 3 == 0 ? '23:00' : '07:00',
              endTime: day.day % 3 == 0 ? '07:00' : '15:00',
              createdAt: day,
              updatedAt: day,
            ),
      ],
      events: [
        for (
          var month = DateTime(startDate.year, startDate.month);
          !month.isAfter(endDate);
          month = DateTime(month.year, month.month + 1)
        ) ...[
          EventApiModel(
            eventId: 'event-$month',
            title: '친구와 저녁 약속',
            place: '서울역',
            memo: '퇴근 후 함께 식사하기',
            allDay: false,
            startAt: DateTime(month.year, month.month, 22, 18, 30),
            endAt: DateTime(month.year, month.month, 22, 20),
            visibilityLevel: 1,
          ),
          for (var index = 0; index < 5; index++)
            EventApiModel(
              eventId: 'extra-$month-$index',
              title: '추가 일정 ${index + 1}',
              allDay: false,
              startAt: DateTime(month.year, month.month, 22, 19 + index),
              endAt: DateTime(month.year, month.month, 22, 20 + index),
              visibilityLevel: 1,
            ),
          EventApiModel(
            eventId: 'span-$month',
            title: '25일~27일 연속 일정',
            allDay: true,
            startAt: DateTime(month.year, month.month, 25),
            endAt: DateTime(month.year, month.month, 28),
            visibilityLevel: 1,
          ),
          EventApiModel(
            eventId: 'cross-$month',
            title: '주·월 경계 연속 일정',
            allDay: true,
            startAt: DateTime(month.year, month.month, 28),
            endAt: DateTime(month.year, month.month + 1, 3),
            visibilityLevel: 1,
          ),
        ],
      ],
    ),
  );
}

class _GroupRenderRepository extends fixtures.AuditGroupRepository {
  @override
  Future<PaginatedGroups> getGroups({int page = 1, int limit = 20}) async => (
    groups: <GroupSummary>[],
    pagination: GroupPagination(
      page: page,
      limit: limit,
      total: 0,
      total_pages: 0,
    ),
  );

  @override
  Future<PaginatedGroupInvitations> getReceivedInvitations({
    GroupInvitationStatus? status,
    int page = 1,
    int limit = 20,
  }) async => (
    invitations: <GroupInvitation>[],
    pagination: GroupPagination(
      page: page,
      limit: limit,
      total: 0,
      total_pages: 0,
    ),
  );

  @override
  Future<GroupDetail> getGroupDetail(String group_id) async =>
      fixtures.audit_group;

  @override
  Future<GroupCalendarRange> getGroupCalendarRange({
    required String group_id,
    required DateTime start_date,
    required DateTime end_date,
  }) async {
    final source = (await _CalendarRenderService().getCalendarRange(
      startDate: start_date,
      endDate: end_date,
    )).data;
    final location = tz.getLocation('Asia/Seoul');
    DateTime asInstant(DateTime day) => tz.TZDateTime(
      location,
      day.year,
      day.month,
      day.day,
      day.hour,
      day.minute,
    ).toUtc();
    return GroupCalendarRange(
      group: GroupCalendarHeader(
        group_id: group_id,
        name: '함께 보는 근무표',
        timezone: 'Asia/Seoul',
      ),
      start_date: start_date.toIso8601String().split('T').first,
      end_date: end_date.toIso8601String().split('T').first,
      members: [
        GroupCalendarMember(
          user_id: 'audit-user',
          name: '나',
          role: GroupRole.owner,
          joined_at: DateTime(2026),
          calendar_access: CalendarAccess.self,
        ),
        GroupCalendarMember(
          user_id: 'audit-friend',
          name: '샘플 친구',
          role: GroupRole.member,
          joined_at: DateTime(2026),
          calendar_access: CalendarAccess.visible,
        ),
      ],
      work_shifts: [
        for (final shift in source.workShifts)
          GroupCalendarWorkShift(
            owner_user_id: 'audit-user',
            work_shift_id: shift.workShiftId,
            work_date: shift.workDate.toIso8601String().split('T').first,
            shift_type_code: shift.shiftTypeCode,
            shift_type_name: shift.shiftTypeName,
            shift_type_color: shift.shiftTypeColor,
            start_time: shift.startTime,
            end_time: shift.endTime,
            created_at: shift.createdAt,
            updated_at: shift.updatedAt,
          ),
      ],
      events: [
        for (final event in source.events)
          GroupCalendarEvent(
            owner_user_id: 'audit-user',
            event_id: event.eventId,
            title: event.title,
            all_day: event.allDay,
            start_at: asInstant(event.startAt),
            end_at: asInstant(event.endAt),
            visibility_level: 1,
          ),
      ],
    );
  }
}

void main() {
  testWidgets('월간과 상세를 실제 하단 탭·글자·안전영역과 함께 렌더한다', (tester) async {
    await initializeDateFormatting('ko_KR');
    timezone_data.initializeTimeZones();
    for (final entry in {
      'Cafe24SsurroundAir': 'assets/fonts/Cafe24SsurroundAir-v1.1.ttf',
      'Cafe24Ssurround': 'assets/fonts/Cafe24Ssurround-v2.0.ttf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load(entry.value))).load();
    }
    final output = Directory('artifacts/calendar_overview_2026-11-22');
    final measurements = <String, Object>{};
    for (final scenario in [
      (
        name: 'normal',
        size: const Size(390, 844),
        scale: 1.0,
        month: 11,
        dark: false,
      ),
      (
        name: 'four_weeks',
        size: const Size(390, 844),
        scale: 1.0,
        month: 2,
        dark: false,
      ),
      (
        name: 'six_weeks',
        size: const Size(390, 844),
        scale: 1.0,
        month: 8,
        dark: false,
      ),
      (
        name: 'small',
        size: const Size(320, 568),
        scale: 1.0,
        month: 11,
        dark: false,
      ),
      (
        name: 'phone375',
        size: const Size(375, 667),
        scale: 1.0,
        month: 11,
        dark: false,
      ),
      (
        name: 'landscape',
        size: const Size(844, 390),
        scale: 1.0,
        month: 11,
        dark: false,
      ),
      (
        name: 'large_text',
        size: const Size(320, 568),
        scale: 3.2,
        month: 11,
        dark: true,
      ),
    ]) {
      await tester.binding.setSurfaceSize(scenario.size);
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            fixtures.AuditAuthRepository(),
          ),
          calendarServiceProvider.overrideWithValue(_CalendarRenderService()),
          shiftTypesProvider.overrideWith((ref) async => []),
          friendListProvider.overrideWith(
            (ref) => fixtures.AuditFriendNotifier(),
          ),
          notificationProvider.overrideWith(
            (ref) => fixtures.AuditNotificationNotifier(),
          ),
          groupRepositoryProvider.overrideWithValue(_GroupRenderRepository()),
        ],
      );
      await container.read(authProvider.notifier).checkAuthStatus();
      final capture_key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: capture_key,
          child: UncontrolledProviderScope(
            container: container,
            child: CupertinoApp(
              theme: AppTheme.lightTheme,
              debugShowCheckedModeBanner: false,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: scenario.size,
                  padding: const EdgeInsets.only(top: 47, bottom: 34),
                  viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
                  textScaler: TextScaler.linear(scenario.scale),
                  platformBrightness: scenario.dark
                      ? Brightness.dark
                      : Brightness.light,
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: const MainTabPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final calendar = find.byKey(const ValueKey('main-calendar'));
      var focused = tester.widget<TableCalendar>(calendar).focusedDay;
      final delta = (2026 - focused.year) * 12 + scenario.month - focused.month;
      for (var step = 0; step < delta.abs(); step++) {
        await tester.tap(
          find.byIcon(
            delta < 0
                ? CupertinoIcons.chevron_left
                : CupertinoIcons.chevron_right,
          ),
        );
        await tester.pumpAndSettle();
      }
      expect(
        find.byKey(const ValueKey('calendar-schedule-card')),
        findsNothing,
      );
      expect(tester.takeException(), isNull, reason: scenario.name);
      final overview_format = tester
          .widget<TableCalendar>(calendar)
          .calendarFormat;
      expect(
        overview_format,
        scenario.size.height < 750
            ? CalendarFormat.threeWeeks
            : CalendarFormat.month,
      );
      await _capture(
        tester,
        capture_key,
        '${output.path}/${scenario.name}_month.png',
      );
      final overview_row_height = tester
          .widget<TableCalendar>(calendar)
          .rowHeight;
      focused = DateTime(2026, scenario.month, 22);
      tester.widget<TableCalendar>(calendar).onDaySelected!(focused, focused);
      await tester.pumpAndSettle();
      final card = find.byKey(const ValueKey('calendar-schedule-card'));
      final close = find.byKey(const ValueKey('calendar-schedule-close'));
      await tester.ensureVisible(close);
      await tester.pumpAndSettle();
      expect(close.hitTestable(), findsOneWidget);
      expect(tester.getSize(close).height, greaterThanOrEqualTo(44));
      expect(tester.takeException(), isNull, reason: scenario.name);
      measurements[scenario.name] = {
        'overview_format': overview_format.name,
        'overview_row_height': overview_row_height,
        'detail_row_height': tester.widget<TableCalendar>(calendar).rowHeight,
        'card_height': tester.getSize(card).height,
        'close_size': tester.getSize(close).toString(),
        'exceptions': 0,
      };
      await _capture(
        tester,
        capture_key,
        '${output.path}/${scenario.name}_detail.png',
      );
      if (scenario.name == 'normal') {
        await tester.tap(find.byIcon(CupertinoIcons.chevron_right));
        await tester.pumpAndSettle();
        expect(card, findsOneWidget);
        expect(find.text('11월 22일 일요일'), findsOneWidget);
        await _capture(
          tester,
          capture_key,
          '${output.path}/normal_other_month_detail.png',
        );
        await tester.tap(
          find.descendant(
            of: find.byType(CalendarMonthHeader),
            matching: find.byIcon(CupertinoIcons.chevron_left),
          ),
        );
        await tester.pumpAndSettle();
        final header = find.byKey(const ValueKey('selected-day-header'));
        final gesture = await tester.startGesture(
          tester.getTopLeft(header) + const Offset(60, 20),
        );
        await gesture.moveBy(const Offset(0, 20));
        await tester.pump();
        await gesture.moveBy(const Offset(0, 40));
        await tester.pump();
        await _capture(tester, capture_key, '${output.path}/normal_drag.png');
        await tester.pump(const Duration(milliseconds: 500));
        await gesture.up();
        await tester.pumpAndSettle();
      }
      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(card, findsNothing);
      expect(tester.takeException(), isNull, reason: scenario.name);
      if (scenario.name == 'normal') {
        await tester.tap(find.byKey(const ValueKey('main-tab-1')));
        await tester.pumpAndSettle();
        Navigator.of(tester.element(find.byType(FriendListPage))).push<void>(
          CupertinoPageRoute(
            builder: (_) => GroupCalendarPage(
              group_id: 'audit-group',
              initial_date: DateTime(2026, 11, 22),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('25일~27일 연속 일정'), findsOneWidget);
        expect(find.text('나 · 25일~27일 연속 일정'), findsNothing);
        await _capture(tester, capture_key, '${output.path}/group_month.png');
        final group_calendar = find.byKey(const ValueKey('group-calendar'));
        tester.widget<TableCalendar>(group_calendar).onDaySelected!(
          DateTime(2026, 11, 22),
          DateTime(2026, 11, 22),
        );
        await tester.pumpAndSettle();
        await _capture(tester, capture_key, '${output.path}/group_detail.png');
        final header = find.byKey(
          const ValueKey('group-calendar-selected-day-header'),
        );
        final gesture = await tester.startGesture(
          tester.getTopLeft(header) + const Offset(60, 20),
        );
        await gesture.moveBy(const Offset(0, 20));
        await tester.pump();
        await gesture.moveBy(const Offset(0, 100));
        await tester.pump();
        await _capture(tester, capture_key, '${output.path}/group_drag.png');
        await gesture.up();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('group-calendar-selected-day-detail')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    }
    await tester.runAsync(
      () => File(
        '${output.path}/measurements.json',
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(measurements)),
    );
    await tester.binding.setSurfaceSize(null);
  });
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String path) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bitmap = await boundary.toImage(pixelRatio: 2);
    final bytes = await bitmap.toByteData(format: ui.ImageByteFormat.png);
    await File(path).writeAsBytes(bytes!.buffer.asUint8List());
    bitmap.dispose();
  });
}
