// ignore_for_file: non_constant_identifier_names

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shift_calendar/core/theme/app_theme.dart';
import 'package:shift_calendar/features/calendar/data/models/event_api_model.dart';
import 'package:shift_calendar/features/calendar/data/models/work_shift_api_model.dart';
import 'package:shift_calendar/features/friend/data/models/friend_model.dart';
import 'package:shift_calendar/features/friend/data/services/friend_service.dart';
import 'package:shift_calendar/features/friend/presentation/pages/friend_calendar_page.dart';
import 'package:table_calendar/table_calendar.dart';

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

Widget _buildTestApp({
  required double screen_height,
  required CalendarRangeResponse response,
  required FriendModel friend,
}) {
  return ProviderScope(
    overrides: [
      friendServiceProvider.overrideWithValue(_FakeFriendService(response)),
    ],
    child: CupertinoApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(390, screen_height)),
        child: FriendCalendarPage(friend: friend),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('ko_KR');
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
