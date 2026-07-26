// ignore_for_file: non_constant_identifier_names

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shift_mate/core/theme/app_theme.dart';
import 'package:shift_mate/core/utils/korean_holidays.dart';
import 'package:shift_mate/features/calendar/data/models/event_api_model.dart';
import 'package:shift_mate/features/calendar/data/models/work_shift_api_model.dart';
import 'package:shift_mate/features/friend/data/models/friend_model.dart';
import 'package:shift_mate/features/friend/data/services/friend_service.dart';
import 'package:shift_mate/features/friend/presentation/pages/friend_calendar_page.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeFriendService extends FriendService {
  _FakeFriendService(this.response) : super(Dio());

  final CalendarRangeResponse response;

  @override
  Future<CalendarRangeResponse> getFriendCalendarRange({
    required String friendUserId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return response;
  }
}

class _RefreshingFriendService extends _FakeFriendService {
  _RefreshingFriendService(super.response, this.refreshed_friend);

  final FriendModel refreshed_friend;
  int get_friends_call_count = 0;

  @override
  Future<UpdateFriendSettingsResponse> updateFriendSettings({
    required String friendUserId,
    int? friendLevel,
    bool? canView,
  }) async {
    return UpdateFriendSettingsResponse(
      success: true,
      data: FriendSettingsData(
        ownerUserId: 'owner-1',
        friendUserId: friendUserId,
        friendLevel: friendLevel ?? refreshed_friend.friendLevel,
        canView: canView ?? refreshed_friend.canView,
        updatedAt: DateTime(2026, 7, 19),
      ),
      message: '설정이 변경되었습니다.',
    );
  }

  @override
  Future<FriendsResponse> getFriends({int page = 1, int limit = 20}) async {
    get_friends_call_count++;
    return FriendsResponse(
      success: true,
      data: FriendsData(
        friends: [refreshed_friend],
        pagination: PaginationInfo(
          page: page,
          limit: limit,
          total: 1,
          totalPages: 1,
        ),
      ),
    );
  }
}

Widget _buildTestApp({
  required double screen_height,
  required CalendarRangeResponse response,
  required FriendModel friend,
  FriendService? service,
}) {
  return ProviderScope(
    overrides: [
      friendServiceProvider.overrideWithValue(
        service ?? _FakeFriendService(response),
      ),
    ],
    child: CupertinoApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(390, screen_height)),
        child: FriendCalendarPage(friend: friend),
      ),
    ),
  );
}

DateTime _firstWeekdayOfMonth(DateTime date, int weekday) {
  final first_day = DateTime(date.year, date.month);
  final day_offset =
      (weekday - first_day.weekday + DateTime.daysPerWeek) %
      DateTime.daysPerWeek;
  return first_day.add(Duration(days: day_offset));
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('ko_KR');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    KoreanHolidays.resetForTesting();
  });

  tearDown(KoreanHolidays.resetForTesting);

  testWidgets('설정 저장 후 친구 목록을 새로고침하고 최신 설정으로 재진입한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    final response = CalendarRangeResponse(
      success: true,
      data: CalendarRangeData(workShifts: const [], events: const []),
    );
    final friend = FriendModel(
      userId: 'friend-refresh',
      name: '새로고침 친구',
      email: 'refresh@example.com',
      friendLevel: 0,
      canView: true,
      createdAt: now,
    );
    final refreshed_friend = FriendModel(
      userId: friend.userId,
      name: friend.name,
      email: friend.email,
      friendLevel: friend.friendLevel,
      canView: false,
      createdAt: friend.createdAt,
    );
    final service = _RefreshingFriendService(response, refreshed_friend);

    await tester.pumpWidget(
      _buildTestApp(
        screen_height: 800,
        response: response,
        friend: friend,
        service: service,
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byIcon(CupertinoIcons.gear));
    await tester.pumpAndSettle();
    expect(
      tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch)).value,
      isTrue,
    );

    await tester.tap(find.byType(CupertinoSwitch));
    await tester.pump();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(service.get_friends_call_count, 1);
    expect(find.byKey(const ValueKey('friend-calendar')), findsOneWidget);

    await tester.tap(find.byIcon(CupertinoIcons.gear));
    await tester.pumpAndSettle();

    expect(
      tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch)).value,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('750px 미만 친구 캘린더는 2주 보기로 고정한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    final response = CalendarRangeResponse(
      success: true,
      data: CalendarRangeData(workShifts: const [], events: const []),
    );
    final friend = FriendModel(
      userId: 'friend-short-screen',
      name: '작은 화면 친구',
      email: 'short@example.com',
      friendLevel: 0,
      canView: true,
      createdAt: now,
    );

    await tester.pumpWidget(
      _buildTestApp(screen_height: 740, response: response, friend: friend),
    );
    await tester.pump();
    await tester.pump();

    final calendar = find.byKey(const ValueKey('friend-calendar'));
    expect(
      tester.widget<TableCalendar>(calendar).calendarFormat,
      CalendarFormat.twoWeeks,
    );

    await tester.tap(find.byIcon(CupertinoIcons.chevron_right));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TableCalendar>(calendar).calendarFormat,
      CalendarFormat.twoWeeks,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('750px 친구 캘린더는 기존 월 보기를 유지한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 750));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    final response = CalendarRangeResponse(
      success: true,
      data: CalendarRangeData(workShifts: const [], events: const []),
    );
    final friend = FriendModel(
      userId: 'friend-boundary-screen',
      name: '경계 화면 친구',
      email: 'boundary@example.com',
      friendLevel: 0,
      canView: true,
      createdAt: now,
    );

    await tester.pumpWidget(
      _buildTestApp(screen_height: 750, response: response, friend: friend),
    );
    await tester.pump();
    await tester.pump();

    final calendar = find.byKey(const ValueKey('friend-calendar'));
    expect(
      tester.widget<TableCalendar>(calendar).calendarFormat,
      CalendarFormat.month,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('친구 캘린더가 공용 캐시의 공휴일 색상과 이름을 표시한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    final selected_date = DateTime(now.year, now.month, now.day);
    KoreanHolidays.setHolidayFetcherForTesting((year, month) async {
      return {selected_date: '테스트 공휴일'};
    });

    final response = CalendarRangeResponse(
      success: true,
      data: CalendarRangeData(workShifts: const [], events: const []),
    );
    final friend = FriendModel(
      userId: 'friend-holiday',
      name: '공휴일 친구',
      email: 'holiday@example.com',
      friendLevel: 0,
      canView: true,
      createdAt: selected_date,
    );

    await tester.pumpWidget(
      _buildTestApp(screen_height: 800, response: response, friend: friend),
    );
    await tester.pump();
    await tester.pump();

    final calendar = tester.widget<TableCalendar>(
      find.byKey(const ValueKey('friend-calendar')),
    );
    expect(calendar.holidayPredicate?.call(selected_date), isTrue);
    expect(find.text('테스트 공휴일'), findsOneWidget);

    final selected_cell = find.byKey(
      ValueKey(
        'CellContent-${selected_date.year}-${selected_date.month}-${selected_date.day}',
      ),
    );
    final selected_date_text = tester.widget<Text>(
      find.descendant(
        of: selected_cell,
        matching: find.text('${selected_date.day}'),
      ),
    );
    expect(selected_date_text.style?.color, AppTheme.accent_red_color);
    expect(tester.takeException(), isNull);
  });

  testWidgets('친구 캘린더가 메인 달력 규칙과 읽기 전용 일정 카드를 사용한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    final selected_date = DateTime(now.year, now.month, now.day);
    final response = CalendarRangeResponse(
      success: true,
      data: CalendarRangeData(
        workShifts: [
          WorkShiftApiModel(
            workShiftId: 'shift-1',
            workDate: selected_date,
            shiftTypeCode: 'D',
            shiftTypeName: '데이',
            shiftTypeColor: 0xFFFF8A00,
            startTime: '06:30:00',
            endTime: '15:00:00',
            createdAt: selected_date,
            updatedAt: selected_date,
          ),
        ],
        events: [
          EventApiModel(
            eventId: 'event-1',
            title: '개인 일정',
            allDay: false,
            startAt: selected_date.add(const Duration(hours: 18)),
            endAt: selected_date.add(const Duration(hours: 19)),
            visibilityLevel: 0,
          ),
        ],
      ),
    );
    final friend = FriendModel(
      userId: 'friend-1',
      name: '박현서',
      email: 'friend@example.com',
      friendLevel: 0,
      canView: true,
      createdAt: selected_date,
    );

    await tester.pumpWidget(
      _buildTestApp(screen_height: 800, response: response, friend: friend),
    );
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('박현서'), findsOneWidget);
    expect(find.text('friend@example.com'), findsNothing);
    expect(find.text('2개의 일정'), findsOneWidget);
    expect(find.text('데이'), findsOneWidget);
    expect(find.text('06:30 ~ 15:00'), findsOneWidget);
    expect(find.text('개인 일정'), findsOneWidget);

    final schedule_card = find.byKey(
      const ValueKey('friend-selected-day-schedule-card'),
    );
    final calendar = find.byType(TableCalendar);
    final calendar_table = find.descendant(
      of: calendar,
      matching: find.byType(Table),
    );
    final calendar_to_schedule_gap =
        tester.getTopLeft(schedule_card).dy -
        tester.getBottomLeft(calendar_table).dy;
    expect(calendar_to_schedule_gap, greaterThanOrEqualTo(16));

    final schedule_card_bottom = tester.getBottomRight(schedule_card).dy;
    expect(800 - schedule_card_bottom, greaterThanOrEqualTo(16));

    final saturday_label = find.descendant(
      of: calendar,
      matching: find.text('토'),
    );
    final saturday_text = tester.widget<Text>(saturday_label);
    expect(saturday_text.style?.color, AppTheme.primary_color);

    final selected_cell = find.byKey(
      ValueKey(
        'CellContent-${selected_date.year}-${selected_date.month}-${selected_date.day}',
      ),
    );
    final selection_box = find.descendant(
      of: selected_cell,
      matching: find.byWidgetPredicate((widget) {
        if (widget is! AnimatedContainer) return false;
        final decoration = widget.decoration;
        return decoration is BoxDecoration && decoration.border != null;
      }),
    );
    final selection_widget = tester.widget<AnimatedContainer>(selection_box);
    final selection_decoration = selection_widget.decoration! as BoxDecoration;
    expect(selection_decoration.shape, BoxShape.rectangle);
    final selection_border = selection_decoration.border! as Border;
    expect(
      selection_decoration.color,
      AppTheme.primary_color.withValues(alpha: 0.08),
    );
    expect(selection_border.top.color, AppTheme.primary_dark_color);
    expect(selection_border.top.width, 2);

    final saturday = _firstWeekdayOfMonth(selected_date, DateTime.saturday);
    final saturday_cell = find.byKey(
      ValueKey(
        'CellContent-${saturday.year}-${saturday.month}-${saturday.day}',
      ),
    );
    await tester.tapAt(tester.getCenter(saturday_cell));
    await tester.pump(const Duration(milliseconds: 200));
    final selected_saturday_text = tester.widget<Text>(
      find.descendant(
        of: saturday_cell,
        matching: find.text('${saturday.day}'),
      ),
    );
    expect(selected_saturday_text.style?.color, AppTheme.primary_color);

    final sunday = _firstWeekdayOfMonth(selected_date, DateTime.sunday);
    final sunday_cell = find.byKey(
      ValueKey('CellContent-${sunday.year}-${sunday.month}-${sunday.day}'),
    );
    await tester.tapAt(tester.getCenter(sunday_cell));
    await tester.pump(const Duration(milliseconds: 200));
    final selected_sunday_text = tester.widget<Text>(
      find.descendant(of: sunday_cell, matching: find.text('${sunday.day}')),
    );
    expect(selected_sunday_text.style?.color, AppTheme.accent_red_color);

    final last_day = DateTime(selected_date.year, selected_date.month + 1, 0);
    final last_day_cell = find.byKey(
      ValueKey(
        'CellContent-${last_day.year}-${last_day.month}-${last_day.day}',
      ),
    );
    await tester.tapAt(tester.getCenter(last_day_cell));
    await tester.pumpAndSettle();

    final last_row_selection_box = find.descendant(
      of: last_day_cell,
      matching: find.byWidgetPredicate((widget) {
        if (widget is! AnimatedContainer) return false;
        final decoration = widget.decoration;
        return decoration is BoxDecoration && decoration.border != null;
      }),
    );
    final selection_box_bottom = tester
        .getBottomRight(last_row_selection_box)
        .dy;
    final calendar_bottom = tester.getBottomLeft(calendar).dy;
    expect(selection_box_bottom, lessThanOrEqualTo(calendar_bottom));

    final future_month = DateTime(
      selected_date.year,
      selected_date.month + 3,
      1,
    );
    final future_month_text =
        '${future_month.year}.${future_month.month.toString().padLeft(2, '0')}';
    for (var move_count = 0; move_count < 3; move_count++) {
      await tester.tap(find.byIcon(CupertinoIcons.chevron_right));
      await tester.pumpAndSettle();
    }
    expect(find.text(future_month_text), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.byKey(const ValueKey('friend-calendar-today-button')),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final today_calendar = tester.widget<TableCalendar>(calendar);
    expect(isSameDay(today_calendar.focusedDay, selected_date), isTrue);
    expect(today_calendar.selectedDayPredicate!(selected_date), isTrue);
    expect(
      find.text(
        '${selected_date.year}.${selected_date.month.toString().padLeft(2, '0')}.${selected_date.day.toString().padLeft(2, '0')}',
      ),
      findsOneWidget,
    );

    final month_text =
        '${selected_date.year}.${selected_date.month.toString().padLeft(2, '0')}';
    await tester.tap(find.text(month_text));
    await tester.pumpAndSettle();
    expect(find.text('날짜 이동'), findsOneWidget);
  });
}
