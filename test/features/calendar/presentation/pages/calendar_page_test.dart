// ignore_for_file: non_constant_identifier_names

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shift_calendar/core/theme/app_theme.dart';
import 'package:shift_calendar/features/calendar/data/models/event_api_model.dart';
import 'package:shift_calendar/features/calendar/data/models/work_shift_api_model.dart';
import 'package:shift_calendar/features/calendar/data/services/calendar_service.dart';
import 'package:shift_calendar/features/calendar/domain/entities/shift_type_info.dart';
import 'package:shift_calendar/features/calendar/presentation/pages/calendar_page.dart';
import 'package:shift_calendar/features/calendar/presentation/providers/shift_types_provider.dart';
import 'package:shift_calendar/features/friend/data/services/friend_service.dart';
import 'package:shift_calendar/features/friend/data/services/notification_service.dart';
import 'package:shift_calendar/features/friend/presentation/providers/notification_provider.dart';
import 'package:table_calendar/table_calendar.dart';

class _FakeCalendarService extends CalendarService {
  _FakeCalendarService({this.work_shifts = const []}) : super(Dio());

  final List<WorkShiftApiModel> work_shifts;

  @override
  Future<CalendarRangeResponse> getCalendarRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return CalendarRangeResponse(
      success: true,
      data: CalendarRangeData(workShifts: work_shifts, events: const []),
    );
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

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    dotenv.testLoad(fileInput: '');
    await initializeDateFormatting('ko_KR');
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
    final selected_date =
        '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';

    expect(header, findsOneWidget);
    expect(tester.widget(header), isA<Row>());
    expect(
      tester.widget<Row>(title_content).crossAxisAlignment,
      CrossAxisAlignment.end,
    );
    expect(
      tester.getCenter(find.text(selected_date)).dy,
      closeTo(tester.getCenter(find.text('1개의 일정')).dy, 0.1),
    );
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
    expect(saturday_selection_decoration.color, AppTheme.surface_color);
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
