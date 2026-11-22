// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import '../../../../helpers/calendar_header_assertions.dart';
import 'package:shift_mate/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:shift_mate/features/auth/domain/entities/user.dart';
import 'package:shift_mate/features/auth/presentation/providers/auth_provider.dart';
import 'package:shift_mate/features/calendar/presentation/providers/calendar_range_provider.dart';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shift_mate/core/theme/app_theme.dart';
import 'package:shift_mate/core/utils/korean_holidays.dart';
import 'package:shift_mate/core/network/api_exception.dart';
import 'package:shift_mate/features/calendar/data/models/event_api_model.dart';
import 'package:shift_mate/features/calendar/data/models/shift_type_api_model.dart';
import 'package:shift_mate/features/calendar/data/models/work_shift_api_model.dart';
import 'package:shift_mate/features/calendar/data/services/calendar_service.dart';
import 'package:shift_mate/features/calendar/data/services/work_shift_service.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/calendar_delete_toast.dart';
import 'package:shift_mate/features/calendar/domain/entities/shift_type_info.dart';
import 'package:shift_mate/features/calendar/presentation/pages/calendar_page.dart';
import 'package:shift_mate/features/calendar/presentation/providers/shift_types_provider.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/calendar_schedule_card.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/calendar_viewport.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/personal_event_form_modal.dart';
import 'package:shift_mate/features/friend/data/services/friend_service.dart';
import 'package:shift_mate/features/friend/data/services/notification_service.dart';
import 'package:shift_mate/features/friend/presentation/providers/notification_provider.dart';
import 'package:table_calendar/table_calendar.dart';

class _FakeCalendarService extends CalendarService {
  _FakeCalendarService({
    this.work_shifts = const [],
    this.events = const [],
    this.delete_error,
    this.delete_future,
    this.update_error,
    this.update_future,
  }) : super(Dio());

  final List<WorkShiftApiModel> work_shifts;
  final List<EventApiModel> events;
  final Object? delete_error;
  final Future<String>? delete_future;
  Object? update_error;
  final Future<EventApiModel>? update_future;
  int update_request_count = 0;
  EventApiModel? updated_event;

  @override
  Future<EventApiModel> updateEvent(
    String event_id,
    UpdateEventRequest request,
  ) async {
    update_request_count++;
    if (update_future != null) return update_future!;
    if (update_error != null) throw update_error!;
    return updated_event = EventApiModel(
      eventId: event_id,
      title: request.title,
      memo: request.memo,
      place: request.place,
      allDay: request.allDay,
      startAt: request.startAt,
      endAt: request.endAt,
      visibilityLevel: request.visibilityLevel,
      isPrivate: request.isPrivate,
    );
  }

  int request_count = 0;
  int delete_request_count = 0;
  String? deleted_event_id;
  final Set<String> deleted_event_ids = {};

  @override
  Future<CalendarRangeResponse> getCalendarRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    request_count += 1;
    return CalendarRangeResponse(
      success: true,
      data: CalendarRangeData(
        workShifts: work_shifts,
        events: [
          for (final event in events.where(
            (event) => !deleted_event_ids.contains(event.eventId),
          ))
            if (updated_event?.eventId == event.eventId)
              updated_event!
            else
              event,
        ],
      ),
    );
  }

  @override
  Future<String> deleteEvent(String event_id) async {
    delete_request_count += 1;
    deleted_event_id = event_id;
    if (delete_error != null) throw delete_error!;
    final result = delete_future == null ? event_id : await delete_future!;
    deleted_event_ids.add(result);
    return result;
  }
}

class _EditAuthRepository implements AuthRepository {
  User user = const User(
    id: 'first-account',
    email: 'first@test.test',
    name: '테스트',
    requires_profile_setup: false,
  );
  @override
  Future<bool> isLoggedIn() async => true;
  @override
  Future<User> getProfile() async => user;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWorkShiftService extends WorkShiftService {
  _FakeWorkShiftService({this.delete_error}) : super(Dio());
  final Object? delete_error;
  final List<String> deleted_ids = [];

  @override
  Future<void> deleteWorkShift(String work_shift_id) async {
    deleted_ids.add(work_shift_id);
    if (delete_error != null) throw delete_error!;
  }
}

class _FakeNotificationNotifier extends NotificationNotifier {
  _FakeNotificationNotifier()
    : super(NotificationService(Dio()), FriendService(Dio()));

  @override
  Future<void> fetchUnreadCount() async {}
}

DateTime _secondSaturdayOfVisibleTwoWeeks(TableCalendar calendar) {
  final first_day = calendar.firstDay;
  final focused_day = calendar.focusedDay;
  final first_page_start = first_day.subtract(
    Duration(days: first_day.weekday % DateTime.daysPerWeek),
  );
  final focused_utc = DateTime.utc(
    focused_day.year,
    focused_day.month,
    focused_day.day,
  );
  final page_index = focused_utc.difference(first_page_start).inDays ~/ 14;
  final page_base = first_day.add(Duration(days: page_index * 14));
  final visible_start = page_base.subtract(
    Duration(days: page_base.weekday % DateTime.daysPerWeek),
  );
  return visible_start.add(const Duration(days: 13));
}

DateTime _firstWeekdayOfMonth(DateTime date, int weekday) {
  final first_day = DateTime(date.year, date.month);
  final day_offset =
      (weekday - first_day.weekday + DateTime.daysPerWeek) %
      DateTime.daysPerWeek;
  return first_day.add(Duration(days: day_offset));
}

EventApiModel _eventForToday({String event_id = 'event-delete-test'}) {
  final now = DateTime.now();
  final start_at = DateTime(now.year, now.month, now.day, 18);
  return EventApiModel(
    eventId: event_id,
    title: '삭제할 개인 일정',
    allDay: false,
    startAt: start_at,
    endAt: start_at.add(const Duration(hours: 1)),
    visibilityLevel: 0,
  );
}

WorkShiftApiModel _workShiftForToday() {
  final date = DateTime.now();
  return WorkShiftApiModel(
    workShiftId: 'undo-work-shift',
    workDate: DateTime(date.year, date.month, date.day),
    shiftTypeCode: 'D',
    shiftTypeName: '데이',
    shiftTypeColor: 0xFF0061A4,
    createdAt: date,
    updatedAt: date,
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    dotenv.testLoad(fileInput: '');
    await initializeDateFormatting('ko_KR');
    for (final entry in {
      'Cafe24SsurroundAir': 'assets/fonts/Cafe24SsurroundAir-v1.1.ttf',
      'Cafe24Ssurround': 'assets/fonts/Cafe24Ssurround-v2.0.ttf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load(entry.value))).load();
    }
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 740),
    const Size(390, 750),
    const Size(375, 812),
    const Size(430, 932),
    const Size(768, 1024),
  ]) {
    testWidgets('${size.width}x${size.height} 일정 카드는 달력 뒤 남은 높이를 채운다', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            calendarServiceProvider.overrideWithValue(_FakeCalendarService()),
            notificationProvider.overrideWith(
              (ref) => _FakeNotificationNotifier(),
            ),
            shiftTypesProvider.overrideWith((ref) async => []),
          ],
          child: CupertinoApp(
            theme: AppTheme.lightTheme,
            home: MediaQuery(
              data: MediaQueryData(size: size),
              child: const CalendarPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final layout = find.byKey(const ValueKey('main-calendar-layout'));
      final card = find.byKey(const ValueKey('calendar-schedule-card'));
      final body_rect = tester.getRect(layout);
      final calendar_scroll = find.byKey(
        const ValueKey('main-calendar-grid-scroll'),
      );
      void verifyRemainingSpace() {
        final card_rect = tester.getRect(card);
        expect(
          card_rect.top,
          tester.getRect(calendar_scroll).bottom + AppTheme.spacing_xs,
        );
        expect(body_rect.bottom - card_rect.bottom, AppTheme.spacing_md);
        expect(card_rect.height, greaterThanOrEqualTo(144));
        expect(
          find.byKey(const ValueKey('main-calendar-scroll')),
          findsNothing,
        );
      }

      verifyRemainingSpace();
      // 짧은 달력 위/아래에 비율 유지를 위한 빈 슬롯을 만들지 않는다.
      expect(
        tester.getSize(calendar_scroll).height,
        tester.getSize(find.byType(CalendarViewport)).height,
      );
      expect(find.text('일정 추가하기...').hitTestable(), findsOneWidget);

      final calendar = find.byKey(const ValueKey('main-calendar'));
      // 2026년2월은4주,11월은5주,8월은6주다(일요일 시작).
      for (final month in [2, 11, 8]) {
        final focused_day = tester.widget<TableCalendar>(calendar).focusedDay;
        final month_delta =
            (2026 - focused_day.year) * 12 + month - focused_day.month;
        for (var step = 0; step < month_delta.abs(); step++) {
          await tester.tap(
            find.byIcon(
              month_delta < 0
                  ? CupertinoIcons.chevron_left
                  : CupertinoIcons.chevron_right,
            ),
          );
          await tester.pumpAndSettle();
        }
        expect(tester.widget<TableCalendar>(calendar).focusedDay.month, month);
        verifyRemainingSpace();
      }
      if (size.height >= 750) {
        for (final format in CalendarFormat.values) {
          tester.widget<TableCalendar>(calendar).onFormatChanged?.call(format);
          await tester.pumpAndSettle();
          verifyRemainingSpace();
        }
      }

      final card_rect = tester.getRect(card);
      await tester.tap(find.byIcon(CupertinoIcons.add));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(const ValueKey('shift-add-card'))),
        card_rect,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final scenario in [
    (size: const Size(844, 300), scale: 1.0),
    (size: const Size(320, 568), scale: 2.0),
  ]) {
    testWidgets('${scenario.size}/${scenario.scale}배는 전체 스크롤로 버튼 접근을 보장한다', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(scenario.size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            calendarServiceProvider.overrideWithValue(_FakeCalendarService()),
            notificationProvider.overrideWith(
              (ref) => _FakeNotificationNotifier(),
            ),
          ],
          child: CupertinoApp(
            theme: AppTheme.lightTheme,
            home: MediaQuery(
              data: MediaQueryData(
                size: scenario.size,
                textScaler: TextScaler.linear(scenario.scale),
              ),
              child: const CalendarPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('main-calendar-scroll')),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('일정 추가하기...'));
      await tester.pumpAndSettle();
      expect(find.text('일정 추가하기...').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('일정 목록 스크롤이 캘린더 헤더의 배경을 바꾸지 않는다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calendarServiceProvider.overrideWithValue(
            _FakeCalendarService(
              events: List.generate(
                20,
                (index) => _eventForToday(event_id: 'scroll-$index'),
              ),
            ),
          ),
          notificationProvider.overrideWith(
            (ref) => _FakeNotificationNotifier(),
          ),
        ],
        child: CupertinoApp(
          theme: AppTheme.lightTheme,
          home: const MediaQuery(
            data: MediaQueryData(size: Size(390, 800)),
            child: CalendarPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await verifyCalendarHeaderOnScroll(
      tester,
      calendar: find.byKey(const ValueKey('main-calendar')),
      list: find.descendant(
        of: find.byKey(const ValueKey('calendar-schedule-card')),
        matching: find.byType(SingleChildScrollView),
      ),
    );
  });

  testWidgets('750px 미만 화면은 2주 보기로 고정한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calendarServiceProvider.overrideWithValue(_FakeCalendarService()),
          notificationProvider.overrideWith(
            (ref) => _FakeNotificationNotifier(),
          ),
        ],
        child: const CupertinoApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(390, 740)),
            child: CalendarPage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    for (var wait_count = 0; wait_count < 50; wait_count++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final calendar = find.byKey(const ValueKey('main-calendar'));
    expect(
      tester.widget<TableCalendar>(calendar).calendarFormat,
      CalendarFormat.twoWeeks,
    );
    expect(tester.takeException(), isNull);

    await tester.drag(calendar, const Offset(0, -100));
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      tester.widget<TableCalendar>(calendar).calendarFormat,
      CalendarFormat.twoWeeks,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('750px 경계 화면은 기존 월 보기를 유지한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 750));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calendarServiceProvider.overrideWithValue(_FakeCalendarService()),
          notificationProvider.overrideWith(
            (ref) => _FakeNotificationNotifier(),
          ),
        ],
        child: const CupertinoApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(390, 750)),
            child: CalendarPage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final calendar = find.byKey(const ValueKey('main-calendar'));
    expect(
      tester.widget<TableCalendar>(calendar).calendarFormat,
      CalendarFormat.month,
    );
    expect(tester.takeException(), isNull);
  });

  for (final screen_height in [740.0, 800.0]) {
    testWidgets(
      '${screen_height.toInt()}px 화면은 근무 설정 진입 전후 달력과 하단 카드 크기를 유지한다',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(390, screen_height));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              calendarServiceProvider.overrideWithValue(_FakeCalendarService()),
              notificationProvider.overrideWith(
                (ref) => _FakeNotificationNotifier(),
              ),
              shiftTypesProvider.overrideWith(
                (ref) async => const [
                  ShiftTypeInfo(
                    code: 'D',
                    name: '데이',
                    color: Color(0xFF0061A4),
                    sort_order: 0,
                  ),
                ],
              ),
            ],
            child: CupertinoApp(
              home: MediaQuery(
                data: MediaQueryData(size: Size(390, screen_height)),
                child: const CalendarPage(),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        for (var wait_count = 0; wait_count < 50; wait_count++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        final calendar_finder = find.byKey(const ValueKey('main-calendar'));
        if (screen_height < 750) {
          await tester.drag(calendar_finder, const Offset(0, -100));
          await tester.pumpAndSettle();
        } else {
          tester
              .widget<TableCalendar>(calendar_finder)
              .onFormatChanged
              ?.call(CalendarFormat.twoWeeks);
          await tester.pumpAndSettle();
        }

        final schedule_card = find.byKey(
          const ValueKey('calendar-schedule-card'),
        );
        final calendar_before = tester.widget<TableCalendar>(calendar_finder);
        final schedule_card_size = tester.getSize(schedule_card);

        await tester.tap(find.byIcon(CupertinoIcons.add));
        await tester.pumpAndSettle();

        final shift_add_card = find.byKey(const ValueKey('shift-add-card'));
        final calendar_after = tester.widget<TableCalendar>(calendar_finder);

        expect(shift_add_card, findsOneWidget);
        expect(calendar_after.calendarFormat, calendar_before.calendarFormat);
        expect(calendar_after.rowHeight, calendar_before.rowHeight);
        expect(tester.getSize(shift_add_card), schedule_card_size);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('선택일 날짜와 일정 수를 같은 헤더 행에 배치한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 750));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    final work_shift = WorkShiftApiModel(
      workShiftId: 'work-shift-header-test',
      workDate: DateTime(now.year, now.month, now.day),
      shiftTypeCode: 'D',
      shiftTypeName: '데이',
      shiftTypeColor: 0xFF0061A4,
      startTime: '07:00:00',
      endTime: '15:00:00',
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calendarServiceProvider.overrideWithValue(
            _FakeCalendarService(work_shifts: [work_shift]),
          ),
          notificationProvider.overrideWith(
            (ref) => _FakeNotificationNotifier(),
          ),
        ],
        child: const CupertinoApp(home: CalendarPage()),
      ),
    );
    await tester.pump();
    await tester.pump();
    for (var wait_count = 0; wait_count < 50; wait_count++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final header = find.byKey(const ValueKey('selected-day-header-content'));
    final title_content = find.byKey(
      const ValueKey('selected-day-title-content'),
    );
    final schedule_count_chip = find.byKey(
      const ValueKey('selected-day-schedule-count'),
    );
    final selected_date = DateFormat('M월 d일 EEEE', 'ko_KR').format(now);

    expect(header, findsOneWidget);
    expect(tester.widget(header), isA<Wrap>());
    expect(
      tester.getSize(find.byKey(const ValueKey('selected-day-header'))).height,
      44.5,
    );
    expect(
      tester.widget<Wrap>(title_content).crossAxisAlignment,
      WrapCrossAlignment.end,
    );
    expect(
      tester.widget<CalendarScheduleSummaryChip>(schedule_count_chip).label,
      '일정 1개',
    );
    expect(
      tester.getBottomLeft(find.text(selected_date)).dy,
      closeTo(tester.getBottomLeft(schedule_count_chip).dy, 0.1),
    );
    expect(find.text('1개의 일정'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('근무 타입 수정 응답으로 이미 로드된 메인 캘린더 표시만 갱신한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 750));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    final initial_type = ShiftTypeApiModel(
      shiftTypeId: 'shift-type-day',
      code: 'D',
      name: '데이',
      color: 0xFF0061A4,
      sortOrder: 0,
      startTime: '07:00:00',
      endTime: '15:00:00',
      crossesMidnight: false,
      durationMinutes: 480,
    );
    final updated_type = ShiftTypeApiModel(
      shiftTypeId: initial_type.shiftTypeId,
      code: 'M',
      name: '모닝',
      color: 0xFFE53935,
      sortOrder: 0,
      startTime: '08:00:00',
      endTime: '16:00:00',
      crossesMidnight: false,
      durationMinutes: 480,
    );
    final calendar_service = _FakeCalendarService(
      work_shifts: [
        WorkShiftApiModel(
          workShiftId: 'work-shift-sync-test',
          workDate: DateTime(now.year, now.month, now.day),
          shiftTypeCode: initial_type.code,
          shiftTypeName: initial_type.name,
          shiftTypeColor: initial_type.color,
          startTime: initial_type.startTime,
          endTime: initial_type.endTime,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        calendarServiceProvider.overrideWithValue(calendar_service),
        notificationProvider.overrideWith((ref) => _FakeNotificationNotifier()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const CupertinoApp(home: CalendarPage()),
      ),
    );
    await tester.pump();
    await tester.pump();
    for (var wait_count = 0; wait_count < 50; wait_count++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('데이'), findsOneWidget);
    expect(find.text('07:00 - 15:00'), findsOneWidget);
    expect(calendar_service.request_count, 1);

    container
        .read(shiftTypeDisplayUpdatesProvider.notifier)
        .applyUpdate(previous_type: initial_type, updated_type: updated_type);
    await tester.pump();

    expect(find.text('데이'), findsNothing);
    expect(find.text('모닝'), findsOneWidget);
    expect(find.text('08:00 - 16:00'), findsOneWidget);
    expect(calendar_service.request_count, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('일정과 근무 설정은 같은 선택일 헤더 위치와 공휴일명을 사용한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 750));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    SharedPreferences.setMockInitialValues({});
    KoreanHolidays.resetForTesting();
    addTearDown(() {
      KoreanHolidays.resetForTesting();
      SharedPreferences.setMockInitialValues({});
    });

    final now = DateTime.now();
    final selected_date = DateTime(now.year, now.month, now.day);
    KoreanHolidays.setHolidayFetcherForTesting((year, month) async {
      return {selected_date: '테스트 공휴일'};
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calendarServiceProvider.overrideWithValue(_FakeCalendarService()),
          notificationProvider.overrideWith(
            (ref) => _FakeNotificationNotifier(),
          ),
          shiftTypesProvider.overrideWith(
            (ref) async => const [
              ShiftTypeInfo(
                code: 'D',
                name: '데이',
                color: Color(0xFF0061A4),
                sort_order: 0,
              ),
            ],
          ),
        ],
        child: const CupertinoApp(home: CalendarPage()),
      ),
    );
    await tester.pump();
    await tester.pump();
    for (var wait_count = 0; wait_count < 50; wait_count++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final formatted_date = DateFormat('M월 d일 EEEE', 'ko_KR').format(now);
    final header = find.byKey(const ValueKey('selected-day-header'));
    final date_text = find.text(formatted_date);
    final holiday_name = find.byKey(
      const ValueKey('selected-day-holiday-name'),
    );

    expect(header, findsOneWidget);
    expect(holiday_name, findsOneWidget);
    final schedule_header_rect = tester.getRect(header);
    final schedule_date_rect = tester.getRect(date_text);

    await tester.tap(find.byIcon(CupertinoIcons.add));
    await tester.pumpAndSettle();

    expect(header, findsOneWidget);
    expect(holiday_name, findsOneWidget);
    expect(tester.getRect(header), schedule_header_rect);
    expect(tester.getRect(date_text), schedule_date_rect);

    final header_container = tester.widget<Container>(header);
    final header_decoration = header_container.decoration! as BoxDecoration;
    final header_border = header_decoration.border! as Border;
    expect(header_border.bottom.width, 0.5);
    expect(header_border.bottom.color, AppTheme.outline_variant_color);
    expect(tester.takeException(), isNull);
  });

  testWidgets('2주 보기 마지막 토요일 근무 입력 후 다음 페이지 일요일로 이동한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calendarServiceProvider.overrideWithValue(_FakeCalendarService()),
          notificationProvider.overrideWith(
            (ref) => _FakeNotificationNotifier(),
          ),
          shiftTypesProvider.overrideWith(
            (ref) async => const [
              ShiftTypeInfo(
                code: 'D',
                name: '데이',
                color: Color(0xFF0061A4),
                sort_order: 0,
              ),
            ],
          ),
        ],
        child: const CupertinoApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(390, 740)),
            child: CalendarPage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final calendar_finder = find.byKey(const ValueKey('main-calendar'));
    var calendar = tester.widget<TableCalendar>(calendar_finder);
    var second_saturday = _secondSaturdayOfVisibleTwoWeeks(calendar);
    var next_day = second_saturday.add(const Duration(days: 1));

    if (second_saturday.month != next_day.month) {
      await tester.drag(calendar_finder, const Offset(-300, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
      calendar = tester.widget<TableCalendar>(calendar_finder);
      second_saturday = _secondSaturdayOfVisibleTwoWeeks(calendar);
      next_day = second_saturday.add(const Duration(days: 1));
    }
    expect(second_saturday.month, next_day.month);

    final saturday_cell = find.byKey(
      ValueKey(
        'CellContent-${second_saturday.year}-${second_saturday.month}-${second_saturday.day}',
      ),
    );
    expect(saturday_cell, findsOneWidget);
    await tester.tapAt(tester.getCenter(saturday_cell));
    await tester.pump();

    await tester.tap(find.byIcon(CupertinoIcons.add));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('shift_type_D')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));

    calendar = tester.widget<TableCalendar>(calendar_finder);
    expect(isSameDay(calendar.focusedDay, next_day), isTrue);
    expect(calendar.selectedDayPredicate?.call(next_day), isTrue);
    expect(
      find.byKey(
        ValueKey(
          'CellContent-${next_day.year}-${next_day.month}-${next_day.day}',
        ),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('월 보기에서 날짜 셀과 선택 박스 레이아웃을 유지한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calendarServiceProvider.overrideWithValue(_FakeCalendarService()),
          notificationProvider.overrideWith(
            (ref) => _FakeNotificationNotifier(),
          ),
        ],
        child: const CupertinoApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(390, 800)),
            child: CalendarPage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    // 초기 빌드에서 같은 월의 공휴일 요청이 겹치면 중복 요청 방지 로직이
    // 100ms 간격으로 완료를 확인한다. 최대 대기 횟수만큼 가상 시간을
    // 순차적으로 진행해 레이아웃 검증과 무관한 비동기 타이머를 정리한다.
    for (var wait_count = 0; wait_count < 50; wait_count++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(tester.takeException(), isNull);

    final now = DateTime.now();
    final selected_cell = find.byKey(
      ValueKey('CellContent-${now.year}-${now.month}-${now.day}'),
    );
    final selected_container = find.descendant(
      of: selected_cell,
      matching: find.byWidgetPredicate((widget) {
        if (widget is! AnimatedContainer) return false;
        final decoration = widget.decoration;
        return decoration is BoxDecoration && decoration.border != null;
      }),
    );

    expect(selected_container, findsOneWidget);

    final saturday = _firstWeekdayOfMonth(now, DateTime.saturday);
    final saturday_cell = find.byKey(
      ValueKey(
        'CellContent-${saturday.year}-${saturday.month}-${saturday.day}',
      ),
    );
    await tester.tapAt(tester.getCenter(saturday_cell));
    await tester.pump(const Duration(milliseconds: 200));

    final saturday_date_text = tester.widget<Text>(
      find.descendant(
        of: saturday_cell,
        matching: find.text('${saturday.day}'),
      ),
    );
    expect(saturday_date_text.style?.color, AppTheme.primary_color);

    final saturday_selection = find.descendant(
      of: saturday_cell,
      matching: find.byWidgetPredicate((widget) {
        if (widget is! AnimatedContainer) return false;
        final decoration = widget.decoration;
        return decoration is BoxDecoration && decoration.border != null;
      }),
    );
    final saturday_selection_widget = tester.widget<AnimatedContainer>(
      saturday_selection,
    );
    final saturday_selection_decoration =
        saturday_selection_widget.decoration! as BoxDecoration;
    final saturday_selection_border =
        saturday_selection_decoration.border! as Border;
    expect(
      saturday_selection_decoration.color,
      AppTheme.primary_color.withValues(alpha: 0.08),
    );
    expect(saturday_selection_border.top.color, AppTheme.primary_dark_color);
    expect(saturday_selection_border.top.width, 2);

    final sunday = _firstWeekdayOfMonth(now, DateTime.sunday);
    final sunday_cell = find.byKey(
      ValueKey('CellContent-${sunday.year}-${sunday.month}-${sunday.day}'),
    );
    await tester.tapAt(tester.getCenter(sunday_cell));
    await tester.pump(const Duration(milliseconds: 200));

    final sunday_date_text = tester.widget<Text>(
      find.descendant(of: sunday_cell, matching: find.text('${sunday.day}')),
    );
    expect(sunday_date_text.style?.color, AppTheme.accent_red_color);

    final next_day = DateTime(now.year, now.month, now.day + 1);
    final next_cell = find.byKey(
      ValueKey(
        'CellContent-${next_day.year}-${next_day.month}-${next_day.day}',
      ),
    );
    final next_date_text = find.descendant(
      of: next_cell,
      matching: find.text('${next_day.day}'),
    );
    final date_center_before_selection = tester.getCenter(next_date_text).dy;

    await tester.tapAt(tester.getCenter(next_cell));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.takeException(), isNull);
    expect(
      tester.getCenter(next_date_text).dy,
      closeTo(date_center_before_selection, 0.1),
    );

    final next_selected_container = find.descendant(
      of: next_cell,
      matching: find.byWidgetPredicate((widget) {
        if (widget is! AnimatedContainer) return false;
        final decoration = widget.decoration;
        return decoration is BoxDecoration && decoration.border != null;
      }),
    );
    expect(next_selected_container, findsOneWidget);

    final last_day = DateTime(now.year, now.month + 1, 0);
    final last_day_cell = find.byKey(
      ValueKey(
        'CellContent-${last_day.year}-${last_day.month}-${last_day.day}',
      ),
    );
    await tester.tapAt(tester.getCenter(last_day_cell));
    await tester.pumpAndSettle();

    final last_day_selection = find.descendant(
      of: last_day_cell,
      matching: find.byWidgetPredicate((widget) {
        if (widget is! AnimatedContainer) return false;
        final decoration = widget.decoration;
        return decoration is BoxDecoration && decoration.border != null;
      }),
    );
    final calendar = find.byWidgetPredicate(
      (widget) => widget is TableCalendar,
    );
    expect(
      tester.getBottomRight(last_day_selection).dy,
      lessThanOrEqualTo(tester.getBottomLeft(calendar).dy),
    );

    await tester.drag(calendar, const Offset(0, -100));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(tester.takeException(), isNull);
    expect(tester.getSize(last_day_selection), const Size.square(48));
    expect(
      tester.getCenter(last_day_selection).dy -
          tester.getCenter(last_day_cell).dy,
      closeTo(8, 0.1),
    );
    expect(
      tester.getBottomRight(last_day_selection).dy,
      lessThanOrEqualTo(tester.getBottomLeft(calendar).dy),
    );
  });

  Future<void> openCalendar(
    WidgetTester tester,
    _FakeCalendarService service, {
    bool disable_animations = false,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calendarServiceProvider.overrideWithValue(service),
          notificationProvider.overrideWith(
            (ref) => _FakeNotificationNotifier(),
          ),
        ],
        child: CupertinoApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: disable_animations),
            child: child!,
          ),
          home: const CalendarPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('3초 삭제 토스트는 달력·카드·추가 버튼의 위치와 크기를 바꾸지 않는다', (tester) async {
    final event = _eventForToday();
    final service = _FakeCalendarService(events: [event]);
    await openCalendar(tester, service);
    final calendar = find.byKey(const ValueKey('main-calendar'));
    final card = find.byKey(const ValueKey('calendar-schedule-card'));
    final add = find.text('일정 추가하기...');
    final calendar_rect = tester.getRect(calendar);
    final card_rect = tester.getRect(card);
    final add_rect = tester.getRect(add);
    final scroll_count = find
        .byKey(const ValueKey('main-calendar-scroll'))
        .evaluate()
        .length;
    await tester.drag(
      find.byKey(const ValueKey('event-event-delete-test-0')),
      const Offset(-360, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('되돌리기'), findsOneWidget);
    expect(tester.getRect(calendar), calendar_rect);
    expect(tester.getRect(card), card_rect);
    expect(tester.getRect(add), add_rect);
    expect(
      find.byKey(const ValueKey('main-calendar-scroll')).evaluate().length,
      scroll_count,
    );
    // 토스트 밖의 날짜 버튼은 배리어 없이 계속 누를 수 있다.
    // 2주 보기의 마지막 토요일에도 화면 안에 있는 이웃 날짜를 누른다.
    final neighbor_offset = event.startAt.weekday == DateTime.saturday ? -1 : 1;
    final next_day = DateTime(
      event.startAt.year,
      event.startAt.month,
      event.startAt.day + neighbor_offset,
    );
    final next_cell = find.byKey(
      ValueKey(
        'CellContent-${next_day.year}-${next_day.month}-${next_day.day}',
      ),
    );
    await tester.tap(
      find
          .ancestor(of: next_cell, matching: find.byType(GestureDetector))
          .first,
    );
    await tester.pumpAndSettle();
    expect(
      normalizeCalendarDate(
        tester
            .widget<CalendarScheduleHeader>(find.byType(CalendarScheduleHeader))
            .selected_date,
      ),
      normalizeCalendarDate(next_day),
    );
    await tester.tap(find.text('되돌리기'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    expect(service.delete_request_count, 0);
    expect(tester.takeException(), isNull);
  });

  for (final scenario in [
    (from_undo: false, reduced: false),
    (from_undo: true, reduced: false),
    (from_undo: false, reduced: true),
  ]) {
    testWidgets(
      '토스트 ${scenario.from_undo ? '되돌리기 버튼' : '본문'} 아래 끌기는 알림만 닫고 삭제 예약을 유지한다 (${scenario.reduced})',
      (tester) async {
        final event = _eventForToday();
        final service = _FakeCalendarService(events: [event]);
        await openCalendar(
          tester,
          service,
          disable_animations: scenario.reduced,
        );
        final card = find.byKey(const ValueKey('calendar-schedule-card'));
        final before_rect = tester.getRect(card);
        await tester.drag(
          find.byKey(const ValueKey('event-event-delete-test-0')),
          const Offset(-360, 0),
        );
        await tester.pumpAndSettle();
        final toast = find.byKey(const ValueKey('calendar-delete-toast'));
        final origin = scenario.from_undo
            ? tester.getCenter(
                find.byKey(const ValueKey('calendar-delete-undo')),
              )
            : Offset(
                tester.getRect(toast).left + 24,
                tester.getRect(toast).center.dy,
              );
        await tester.dragFrom(origin, const Offset(0, 100));
        await tester.pumpAndSettle();
        expect(toast, findsNothing);
        expect(find.text(event.title), findsNothing);
        expect(service.delete_request_count, 0);
        expect(tester.getRect(card), before_rect);
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        expect(service.delete_request_count, 1);
        expect(service.deleted_event_id, event.eventId);
        expect(find.text(event.title), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('토스트의 위/가로/짧은 아래 끌기는 닫지 않고 되돌리기 탭을 유지한다', (tester) async {
    final service = _FakeCalendarService(events: [_eventForToday()]);
    await openCalendar(tester, service);
    await tester.drag(
      find.byKey(const ValueKey('event-event-delete-test-0')),
      const Offset(-360, 0),
    );
    await tester.pumpAndSettle();
    final toast = find.byKey(const ValueKey('calendar-delete-toast'));
    final top = tester.getTopLeft(toast).dy;
    for (final offset in [
      const Offset(0, -100),
      const Offset(-100, 0),
      const Offset(0, 12),
    ]) {
      await tester.dragFrom(
        Offset(
          tester.getRect(toast).left + 24,
          tester.getRect(toast).center.dy,
        ),
        offset,
      );
      await tester.pumpAndSettle();
      expect(toast, findsOneWidget);
      expect(tester.getTopLeft(toast).dy, closeTo(top, 0.1));
    }
    await tester.tap(find.text('되돌리기'));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarEventItem), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(service.delete_request_count, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('토스트를 닫은 뒤 추가 삭제는 새 알림을 표시하고 이전 닫기 콜백을 무시한다', (tester) async {
    final service = _FakeCalendarService(
      events: [
        _eventForToday(event_id: 'first'),
        _eventForToday(event_id: 'second'),
      ],
    );
    await openCalendar(tester, service);
    await tester.drag(
      find.byKey(const ValueKey('event-first-0')),
      const Offset(-360, 0),
    );
    await tester.pumpAndSettle();
    final old_toast = tester.widget<CalendarDeleteToast>(
      find.byType(CalendarDeleteToast),
    );
    await tester.drag(
      find.byKey(const ValueKey('calendar-delete-toast')),
      const Offset(0, 100),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CalendarDeleteToast), findsNothing);
    await tester.drag(
      find.byKey(const ValueKey('event-second-0')),
      const Offset(-360, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('일정 2개를 삭제했어요.'), findsOneWidget);
    old_toast.onDismiss();
    await tester.pumpAndSettle();
    expect(find.byType(CalendarDeleteToast), findsOneWidget);
    await tester.tap(find.text('되돌리기'));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarEventItem), findsNWidgets(2));
    await tester.pump(const Duration(seconds: 4));
    expect(service.delete_request_count, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('토스트를 닫았어도 서버 삭제 실패는 항목을 복원하고 재시도 알림을 표시한다', (tester) async {
    final event = _eventForToday();
    final service = _FakeCalendarService(
      events: [event],
      delete_error: ApiException(
        code: 'INTERNAL_SERVER_ERROR',
        message: '삭제 실패',
        statusCode: 500,
      ),
    );
    await openCalendar(tester, service);
    final row = find.byKey(const ValueKey('event-event-delete-test-0'));
    await tester.drag(row, const Offset(-360, 0));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('calendar-delete-toast')),
      const Offset(0, 100),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('삭제 실패'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(row, findsOneWidget);
    await tester.drag(row, const Offset(-360, 0));
    await tester.pumpAndSettle();
    expect(find.text('되돌리기'), findsOneWidget);
    await tester.tap(find.text('되돌리기'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    expect(service.delete_request_count, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('토스트 접근성 닫기 액션도 삭제 예약을 취소하지 않는다', (tester) async {
    final semantics_handle = tester.ensureSemantics();
    try {
      final service = _FakeCalendarService(events: [_eventForToday()]);
      await openCalendar(tester, service);
      await tester.drag(
        find.byKey(const ValueKey('event-event-delete-test-0')),
        const Offset(-360, 0),
      );
      await tester.pumpAndSettle();
      final notice = find.bySemanticsLabel('일정 삭제 알림');
      final semantics = tester.getSemantics(notice);
      expect(
        semantics.getSemanticsData().hasAction(SemanticsAction.dismiss),
        isTrue,
      );
      tester
          .element(notice)
          .findRenderObject()!
          .owner!
          .semanticsOwner!
          .performAction(semantics.id, SemanticsAction.dismiss);
      await tester.pumpAndSettle();
      expect(find.byType(CalendarDeleteToast), findsNothing);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(service.delete_request_count, 1);
      expect(tester.takeException(), isNull);
    } finally {
      semantics_handle.dispose();
    }
  });

  testWidgets('개인 일정 탭은 수정 시트 하나를 열고 저장 응답으로 목록을 즉시 교체한다', (tester) async {
    final event = _eventForToday();
    final service = _FakeCalendarService(events: [event]);
    await openCalendar(tester, service);
    final row = find.byKey(const ValueKey('event-event-delete-test-0'));
    final open_action = tester
        .widget<CupertinoButton>(
          find
              .ancestor(
                of: find.byType(CalendarEventItem),
                matching: find.byType(CupertinoButton),
              )
              .first,
        )
        .onPressed!;
    await tester.tap(row);
    open_action();
    await tester.pumpAndSettle();
    expect(find.byType(PersonalEventFormModal), findsOneWidget);
    expect(find.text('개인 일정 수정'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('personal-event-title-field')),
      '수정한 개인 일정',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('personal-event-save-button')));
    await tester.pumpAndSettle();
    expect(service.update_request_count, 1);
    expect(service.delete_request_count, 0);
    expect(find.text(event.title), findsNothing);
    expect(find.text('수정한 개인 일정'), findsOneWidget);
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CupertinoTextField>(
            find.byKey(const Key('personal-event-title-field')),
          )
          .controller!
          .text,
      '수정한 개인 일정',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('짧은 스와이프는 복귀하고 삭제 유예/요청 중인 일정은 수정할 수 없다', (tester) async {
    final pending = Completer<String>();
    final event = _eventForToday();
    final service = _FakeCalendarService(
      events: [event],
      delete_future: pending.future,
    );
    await openCalendar(tester, service);
    final row = find.byKey(const ValueKey('event-event-delete-test-0'));
    await tester.drag(row, const Offset(-30, 0));
    await tester.pumpAndSettle();
    expect(service.delete_request_count, 0);
    expect(find.byType(PersonalEventFormModal), findsNothing);
    await tester.drag(row, const Offset(-360, 0));
    await tester.pumpAndSettle();
    expect(service.delete_request_count, 0);
    expect(row, findsNothing);
    expect(find.text('되돌리기'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(service.delete_request_count, 1);
    expect(row, findsNothing);
    expect(find.text('되돌리기'), findsNothing);
    expect(find.byType(PersonalEventFormModal), findsNothing);
    pending.complete(event.eventId);
    await tester.pumpAndSettle();
    expect(find.text(event.title), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('메인 수정 실패는 입력을 보존하고 404는 안내 후 대상 행을 제거한다', (tester) async {
    final event = _eventForToday();
    final service = _FakeCalendarService(
      events: [event],
      update_error: ApiException(
        code: 'INTERNAL_SERVER_ERROR',
        message: '서버 오류',
        statusCode: 500,
      ),
    );
    await openCalendar(tester, service);
    await tester.tap(find.byKey(const ValueKey('event-event-delete-test-0')));
    await tester.pumpAndSettle();
    final title = find.byKey(const Key('personal-event-title-field'));
    await tester.enterText(title, '보존할 수정 내용');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('personal-event-save-button')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<CupertinoTextField>(title).controller!.text,
      '보존할 수정 내용',
    );
    expect(find.text('목록 다시 확인'), findsOneWidget);
    service.update_error = ApiException(
      code: 'EVENT_NOT_FOUND',
      message: '없는 일정',
      statusCode: 404,
    );
    await tester.tap(find.byKey(const Key('personal-event-save-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.byType(PersonalEventFormModal), findsNothing);
    expect(find.text(event.title), findsNothing);
    expect(service.update_request_count, 2);
    expect(service.delete_request_count, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('수정 중 계정이 바뀌면 이전 응답을 새 계정 캐시에 쓰지 않는다', (tester) async {
    final pending = Completer<EventApiModel>();
    final event = _eventForToday();
    final repository = _EditAuthRepository();
    final service = _FakeCalendarService(
      events: [event],
      update_future: pending.future,
    );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        calendarServiceProvider.overrideWithValue(service),
        notificationProvider.overrideWith((ref) => _FakeNotificationNotifier()),
      ],
    );
    await container.read(authProvider.notifier).checkAuthStatus();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const CupertinoApp(home: CalendarPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('event-event-delete-test-0')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('personal-event-title-field')),
      '이전 계정 수정',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('personal-event-save-button')));
    await tester.pump();
    repository.user = const User(
      id: 'second-account',
      email: 'second@test.test',
      name: '다른 계정',
      requires_profile_setup: false,
    );
    await container.read(authProvider.notifier).checkAuthStatus();
    pending.complete(
      EventApiModel(
        eventId: event.eventId,
        title: '이전 계정 응답',
        allDay: false,
        startAt: event.startAt,
        endAt: event.endAt,
        visibilityLevel: 0,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      container
          .read(calendarRangeProvider)
          .eventsFor(event.startAt)
          .map((item) => item.title),
      isNot(contains('이전 계정 응답')),
    );
    expect(find.text('계정이 변경되어 저장 결과를 표시할 수 없습니다.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('다일 중간 날짜에서 제목 수정은 선택일을 유지하고 기간 이동은 새 시작일을 선택한다', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final event = EventApiModel(
      eventId: 'multi-edit',
      title: '다일 일정',
      allDay: true,
      startAt: DateTime(now.year, now.month, now.day - 1),
      endAt: DateTime(now.year, now.month, now.day + 1),
      visibilityLevel: 2,
    );
    final service = _FakeCalendarService(events: [event]);
    await openCalendar(tester, service);
    final row = find.byKey(const ValueKey('event-multi-edit-0'));
    await tester.tap(row);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('personal-event-title-field')),
      '다일 제목 수정',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('personal-event-save-button')));
    await tester.pumpAndSettle();
    expect(
      normalizeCalendarDate(
        tester
            .widget<CalendarScheduleHeader>(find.byType(CalendarScheduleHeader))
            .selected_date,
      ),
      today,
    );
    await tester.tap(row);
    await tester.pumpAndSettle();
    final moved_date = DateTime(now.year, now.month + 1, 5);
    for (final label in ['시작', '종료']) {
      final date_button = find.byKey(ValueKey('event-date-$label'));
      await tester.ensureVisible(date_button);
      await tester.pumpAndSettle();
      await tester.tap(date_button);
      await tester.pumpAndSettle();
      tester
          .widget<TableCalendar>(
            find.byKey(const ValueKey('date-picker-calendar')),
          )
          .onDaySelected!(moved_date, moved_date);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('date-picker-confirm')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const Key('personal-event-save-button')));
    await tester.pumpAndSettle();
    expect(service.update_request_count, 2);
    expect(
      tester
          .widget<CalendarScheduleHeader>(find.byType(CalendarScheduleHeader))
          .selected_date,
      moved_date,
    );
    final page_context = tester.element(find.byType(CalendarPage));
    final range = ProviderScope.containerOf(
      page_context,
    ).read(calendarRangeProvider);
    expect(range.eventsFor(today), isEmpty);
    expect(range.eventsFor(moved_date).single.title, '다일 제목 수정');
    expect(tester.takeException(), isNull);
  });

  testWidgets('개인 일정 스와이프는 즉시 숨기고 3초가 지난 뒤 삭제 API를 한 번 호출한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final event = _eventForToday();
    final calendar_service = _FakeCalendarService(events: [event]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calendarServiceProvider.overrideWithValue(calendar_service),
          notificationProvider.overrideWith(
            (ref) => _FakeNotificationNotifier(),
          ),
        ],
        child: const CupertinoApp(home: CalendarPage()),
      ),
    );
    await tester.pump();
    await tester.pump();
    for (var wait_count = 0; wait_count < 50; wait_count++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final event_item = find.byKey(const ValueKey('event-event-delete-test-0'));
    expect(event_item, findsOneWidget);

    await tester.drag(event_item, const Offset(-360, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(calendar_service.delete_request_count, 0);
    expect(find.text(event.title), findsNothing);
    expect(find.text('되돌리기'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(calendar_service.delete_request_count, 0);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(calendar_service.delete_request_count, 1);
    expect(calendar_service.deleted_event_id, event.eventId);
    expect(find.text(event.title), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('이미 삭제된 개인 일정은 로컬에서 제거하고 안내한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final event = _eventForToday();
    final calendar_service = _FakeCalendarService(
      events: [event],
      delete_error: ApiException(
        code: 'EVENT_NOT_FOUND',
        message: '일정을 찾을 수 없습니다.',
        statusCode: 404,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calendarServiceProvider.overrideWithValue(calendar_service),
          notificationProvider.overrideWith(
            (ref) => _FakeNotificationNotifier(),
          ),
        ],
        child: const CupertinoApp(home: CalendarPage()),
      ),
    );
    await tester.pump();
    await tester.pump();
    for (var wait_count = 0; wait_count < 50; wait_count++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    await tester.drag(
      find.byKey(const ValueKey('event-event-delete-test-0')),
      const Offset(-360, 0),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(calendar_service.delete_request_count, 0);
    expect(find.text(event.title), findsNothing);
    expect(find.text('되돌리기'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(calendar_service.delete_request_count, 0);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(calendar_service.delete_request_count, 1);
    expect(find.text(event.title), findsNothing);
    expect(find.text('이미 삭제된 일정입니다.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('개인 일정 삭제 서버 오류 시 항목을 유지하고 오류를 안내한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final event = _eventForToday();
    final calendar_service = _FakeCalendarService(
      events: [event],
      delete_error: ApiException(
        code: 'INTERNAL_SERVER_ERROR',
        message: '일정을 삭제하지 못했습니다.',
        statusCode: 500,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calendarServiceProvider.overrideWithValue(calendar_service),
          notificationProvider.overrideWith(
            (ref) => _FakeNotificationNotifier(),
          ),
        ],
        child: const CupertinoApp(home: CalendarPage()),
      ),
    );
    await tester.pump();
    await tester.pump();
    for (var wait_count = 0; wait_count < 50; wait_count++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    await tester.drag(
      find.byKey(const ValueKey('event-event-delete-test-0')),
      const Offset(-360, 0),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(calendar_service.delete_request_count, 0);
    expect(find.text(event.title), findsNothing);
    expect(find.text('되돌리기'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(calendar_service.delete_request_count, 0);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(calendar_service.delete_request_count, 1);
    expect(find.text(event.title), findsOneWidget);
    expect(find.text('일정을 삭제하지 못했습니다.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('되돌리기는 원본 ID와 모든 편집값을 보존하며 서버 삭제를 보내지 않는다', (tester) async {
    final now = DateTime.now();
    final event = EventApiModel(
      eventId: 'undo-private',
      title: '원본 일정',
      memo: '원본 메모',
      place: '서울역',
      allDay: true,
      startAt: DateTime(now.year, now.month, now.day - 1),
      endAt: DateTime(now.year, now.month, now.day + 2),
      visibilityLevel: 4,
      isPrivate: true,
    );
    final service = _FakeCalendarService(events: [event]);
    await openCalendar(tester, service);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CalendarPage)),
    );
    await tester.drag(
      find.byKey(const ValueKey('event-undo-private-0')),
      const Offset(-360, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('일정 0개'), findsOneWidget);
    expect(
      container.read(calendarRangeProvider).eventsFor(event.startAt).single,
      same(event),
    );
    // 삭제 유예 중 재조회한 값도 화면에서는 숨겨야 한다.
    await container.read(calendarRangeProvider.notifier).refreshMonth(now);
    await tester.pumpAndSettle();
    expect(find.text(event.title), findsNothing);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    tester
        .widget<TableCalendar>(find.byKey(const ValueKey('main-calendar')))
        .onDaySelected!(tomorrow, tomorrow);
    await tester.pumpAndSettle();
    expect(find.text(event.title), findsNothing);
    await tester.tap(find.byKey(const ValueKey('calendar-delete-undo')));
    await tester.pumpAndSettle();
    expect(find.text(event.title), findsOneWidget);
    expect(find.text('일정 1개'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    expect(service.delete_request_count, 0);
    expect(service.update_request_count, 0);
    expect(
      container.read(calendarRangeProvider).eventsFor(tomorrow).single,
      same(event),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('연속 삭제는 유예 시간을 다시 시작하고 한 번에 모두 되돌린다', (tester) async {
    final first = _eventForToday(event_id: 'first');
    final second = _eventForToday(event_id: 'second');
    final service = _FakeCalendarService(events: [first, second]);
    await openCalendar(tester, service);
    await tester.drag(
      find.byKey(const ValueKey('event-first-0')),
      const Offset(-360, 0),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.drag(
      find.byKey(const ValueKey('event-second-0')),
      const Offset(-360, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('일정 2개를 삭제했어요.'), findsOneWidget);
    expect(find.text('일정 0개'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(service.delete_request_count, 0);
    await tester.tap(find.text('되돌리기'));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarEventItem), findsNWidgets(2));
    await tester.pump(const Duration(seconds: 10));
    expect(service.delete_request_count, 0);
    expect(tester.takeException(), isNull);
  });

  for (final undo in [true, false]) {
    testWidgets('근무와 개인 일정 연속 삭제를 ${undo ? '함께 되돌린다' : '유예 후 각각 확정한다'}', (
      tester,
    ) async {
      final work_shift = _workShiftForToday();
      final event = _eventForToday();
      final service = _FakeCalendarService(
        events: [event],
        work_shifts: [work_shift],
      );
      final work_service = _FakeWorkShiftService();
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            calendarServiceProvider.overrideWithValue(service),
            workShiftServiceProvider.overrideWithValue(work_service),
            notificationProvider.overrideWith(
              (ref) => _FakeNotificationNotifier(),
            ),
          ],
          child: const CupertinoApp(home: CalendarPage()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey('undo-work-shift_0')),
        const Offset(-360, 0),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CalendarWorkShiftItem), findsNothing);
      await tester.drag(
        find.byKey(const ValueKey('event-event-delete-test-0')),
        const Offset(-360, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('일정 2개를 삭제했어요.'), findsOneWidget);
      expect(work_service.deleted_ids, isEmpty);
      expect(service.delete_request_count, 0);
      if (undo) {
        await tester.tap(find.text('되돌리기'));
        await tester.pumpAndSettle();
        expect(find.byType(CalendarWorkShiftItem), findsOneWidget);
        expect(find.byType(CalendarEventItem), findsOneWidget);
      }
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(service.delete_request_count, undo ? 0 : 1);
      expect(
        work_service.deleted_ids,
        undo ? isEmpty : [work_shift.workShiftId],
      );
      expect(find.text('되돌리기'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('여러 삭제 실패는 목록을 복원하고 오류창 하나로 알린다', (tester) async {
    final service = _FakeCalendarService(
      events: [
        _eventForToday(event_id: 'first'),
        _eventForToday(event_id: 'second'),
      ],
      delete_error: ApiException(
        code: 'INTERNAL_SERVER_ERROR',
        message: '삭제 실패',
        statusCode: 500,
      ),
    );
    await openCalendar(tester, service);
    for (final id in ['first', 'second']) {
      await tester.drag(
        find.byKey(ValueKey('event-$id-0')),
        const Offset(-360, 0),
      );
      await tester.pumpAndSettle();
    }
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(service.delete_request_count, 2);
    expect(find.byType(CupertinoAlertDialog), findsOneWidget);
    expect(find.text('삭제 실패'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarEventItem), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('혼합 삭제에서 근무만 실패하면 근무 행·배지를 복원하고 성공한 개인 일정은 제거한다', (tester) async {
    final work_shift = _workShiftForToday();
    final event = _eventForToday();
    final service = _FakeCalendarService(
      events: [event],
      work_shifts: [work_shift],
    );
    final work_service = _FakeWorkShiftService(
      delete_error: ApiException(
        code: 'INTERNAL_SERVER_ERROR',
        message: '근무 삭제 실패',
        statusCode: 500,
      ),
    );
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calendarServiceProvider.overrideWithValue(service),
          workShiftServiceProvider.overrideWithValue(work_service),
          notificationProvider.overrideWith(
            (ref) => _FakeNotificationNotifier(),
          ),
        ],
        child: const CupertinoApp(home: CalendarPage()),
      ),
    );
    await tester.pumpAndSettle();
    for (final key in ['undo-work-shift_0', 'event-event-delete-test-0']) {
      await tester.drag(find.byKey(ValueKey(key)), const Offset(-360, 0));
      await tester.pumpAndSettle();
    }
    final add_button = find.widgetWithIcon(CupertinoButton, CupertinoIcons.add);
    expect(tester.widget<CupertinoButton>(add_button).onPressed, isNull);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(service.delete_request_count, 1);
    expect(work_service.deleted_ids, [work_shift.workShiftId]);
    expect(find.text('근무 삭제 실패'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarWorkShiftItem), findsOneWidget);
    expect(find.byType(CalendarEventItem), findsNothing);
    expect(find.text('일정 1개'), findsOneWidget);
    expect(tester.widget<CupertinoButton>(add_button).onPressed, isNotNull);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CalendarPage)),
    );
    expect(
      container.read(calendarRangeProvider).workShiftFor(work_shift.workDate),
      same(work_shift),
    );
    expect(
      container.read(calendarRangeProvider).eventsFor(event.startAt),
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('화면 dispose와 앱 비활성화는 아직 전송하지 않은 삭제를 취소한다', (tester) async {
    for (final dispose in [false, true]) {
      final service = _FakeCalendarService(events: [_eventForToday()]);
      await openCalendar(tester, service);
      await tester.drag(
        find.byKey(const ValueKey('event-event-delete-test-0')),
        const Offset(-360, 0),
      );
      await tester.pumpAndSettle();
      if (dispose) {
        await tester.pumpWidget(const SizedBox.shrink());
      } else {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pumpAndSettle();
        expect(find.byType(CalendarEventItem), findsOneWidget);
        expect(find.text('되돌리기'), findsNothing);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
      }
      await tester.pump(const Duration(seconds: 10));
      expect(service.delete_request_count, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    }
  });

  for (final in_flight in [false, true]) {
    testWidgets('계정 전환은 ${in_flight ? '이전 삭제 응답을 무시한다' : '삭제 예약을 취소한다'}', (
      tester,
    ) async {
      final pending = Completer<String>();
      final event = _eventForToday();
      final repository = _EditAuthRepository();
      final service = _FakeCalendarService(
        events: [event],
        delete_future: pending.future,
      );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          calendarServiceProvider.overrideWithValue(service),
          notificationProvider.overrideWith(
            (ref) => _FakeNotificationNotifier(),
          ),
        ],
      );
      await container.read(authProvider.notifier).checkAuthStatus();
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const CupertinoApp(home: CalendarPage()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey('event-event-delete-test-0')),
        const Offset(-360, 0),
      );
      await tester.pumpAndSettle();
      if (in_flight) await tester.pump(const Duration(seconds: 5));
      repository.user = const User(
        id: 'second-account',
        email: 'second@test.test',
        name: '다른 계정',
        requires_profile_setup: false,
      );
      await container.read(authProvider.notifier).checkAuthStatus();
      await tester.pumpAndSettle();
      expect(find.text('되돌리기'), findsNothing);
      if (in_flight) {
        pending.completeError(
          ApiException(
            code: 'INTERNAL_SERVER_ERROR',
            message: '이전 계정 오류',
            statusCode: 500,
          ),
        );
      }
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      expect(service.delete_request_count, in_flight ? 1 : 0);
      expect(find.text('이전 계정 오류'), findsNothing);
      expect(
        container.read(calendarRangeProvider).eventsFor(event.startAt),
        isNotEmpty,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('접근성 탐색에서는 되돌리기 시간을 10초 제공한다', (tester) async {
    final service = _FakeCalendarService(events: [_eventForToday()]);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calendarServiceProvider.overrideWithValue(service),
          notificationProvider.overrideWith(
            (ref) => _FakeNotificationNotifier(),
          ),
        ],
        child: CupertinoApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(accessibleNavigation: true),
            child: child!,
          ),
          home: const CalendarPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('event-event-delete-test-0')),
      const Offset(-360, 0),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    expect(service.delete_request_count, 0);
    expect(find.text('되돌리기'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(service.delete_request_count, 1);
    expect(find.text('되돌리기'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('토스트는 좁은 화면/큰 글자/가로/다크에서 안전영역과 버튼 크기를 유지한다', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      for (final size in [
        const Size(320, 568),
        const Size(375, 812),
        const Size(844, 390),
        const Size(768, 1024),
      ]) {
        await tester.binding.setSurfaceSize(size);
        for (final scale in [1.0, 3.0]) {
          for (final brightness in [Brightness.light, Brightness.dark]) {
            await tester.pumpWidget(
              CupertinoApp(
                theme: CupertinoThemeData(brightness: brightness),
                home: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: TextScaler.linear(scale),
                    padding: const EdgeInsets.only(bottom: 34),
                    disableAnimations: true,
                  ),
                  child: CupertinoPageScaffold(
                    child: SafeArea(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: CalendarDeleteToast(
                            count: 12,
                            onUndo: () {},
                            onDismiss: () {},
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            final button = find.byKey(const ValueKey('calendar-delete-undo'));
            final toast = find.byKey(const ValueKey('calendar-delete-toast'));
            expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
            expect(
              tester.getRect(button).bottom,
              lessThanOrEqualTo(size.height - 34),
            );
            expect(tester.getRect(toast).left, greaterThanOrEqualTo(16));
            expect(
              tester.getRect(toast).right,
              lessThanOrEqualTo(size.width - 16),
            );
            expect(
              tester.getSemantics(find.bySemanticsLabel('되돌리기')),
              matchesSemantics(
                label: '되돌리기',
                isButton: true,
                hasTapAction: true,
                isFocusable: true,
                hasFocusAction: true,
              ),
            );
            expect(tester.takeException(), isNull);
          }
        }
      }
    } finally {
      semantics.dispose();
      await tester.binding.setSurfaceSize(null);
    }
  });

  testWidgets('근무 일정 부분 스와이프 시 노출 폭 전체에 radius를 적용한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    final work_shift = WorkShiftApiModel(
      workShiftId: 'work-shift-radius-test',
      workDate: DateTime(now.year, now.month, now.day),
      shiftTypeCode: 'D',
      shiftTypeName: '데이',
      shiftTypeColor: 0xFF0061A4,
      startTime: '07:00:00',
      endTime: '15:00:00',
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calendarServiceProvider.overrideWithValue(
            _FakeCalendarService(work_shifts: [work_shift]),
          ),
          notificationProvider.overrideWith(
            (ref) => _FakeNotificationNotifier(),
          ),
        ],
        child: const CupertinoApp(home: CalendarPage()),
      ),
    );
    await tester.pump();
    await tester.pump();

    for (var wait_count = 0; wait_count < 50; wait_count++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final dismissible = find.byKey(const ValueKey('work-shift-radius-test_0'));
    expect(dismissible, findsOneWidget);

    final gesture = await tester.startGesture(tester.getCenter(dismissible));
    await gesture.moveBy(const Offset(-72, 0));
    await tester.pump();

    final delete_background = find.byKey(
      const ValueKey('work-shift-delete-background'),
    );
    expect(delete_background, findsOneWidget);
    expect(tester.getSize(delete_background).width, closeTo(72, 0.1));

    final background_container = tester.widget<Container>(delete_background);
    final decoration = background_container.decoration! as BoxDecoration;
    expect(decoration.borderRadius, AppTheme.input_border_radius);

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });
}
