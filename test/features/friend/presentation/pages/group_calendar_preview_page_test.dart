// ignore_for_file: non_constant_identifier_names

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shift_calendar/core/theme/app_theme.dart';
import 'package:shift_calendar/features/friend/data/models/friend_model.dart';
import 'package:shift_calendar/features/friend/data/services/friend_service.dart';
import 'package:shift_calendar/features/friend/presentation/pages/friend_list_page.dart';
import 'package:shift_calendar/features/friend/presentation/pages/group_calendar_preview_page.dart';
import 'package:table_calendar/table_calendar.dart';

class _FakeFriendService extends FriendService {
  _FakeFriendService() : super(Dio());

  @override
  Future<FriendsResponse> getFriends({int page = 1, int limit = 20}) async {
    return FriendsResponse(
      success: true,
      data: FriendsData(
        friends: const [],
        pagination: PaginationInfo(
          page: page,
          limit: limit,
          total: 0,
          totalPages: 0,
        ),
      ),
    );
  }
}

Widget _buildTestApp({required double screen_height, DateTime? initial_date}) {
  return CupertinoApp(
    home: MediaQuery(
      data: MediaQueryData(size: Size(390, screen_height)),
      child: GroupCalendarPreviewPage(initial_date: initial_date),
    ),
  );
}

Widget _buildFriendListTestApp({required double screen_height}) {
  return ProviderScope(
    overrides: [friendServiceProvider.overrideWithValue(_FakeFriendService())],
    child: CupertinoApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(390, screen_height)),
        child: const FriendListPage(),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('ko_KR');
  });

  test('5일 동안 4명부터 0명까지의 근무 패턴과 2~3개 일정이 반복된다', () {
    final day_data = List.generate(
      5,
      (index) => buildGroupPreviewDayData(DateTime(2026, 1, index + 1)),
    );

    expect(
      day_data.map((data) => data.working_count),
      orderedEquals([4, 3, 2, 1, 0]),
    );
    expect(
      day_data.map((data) => data.personal_event_count),
      orderedEquals([2, 3, 2, 3, 2]),
    );
    expect(day_data.every((data) => data.members.length == 4), isTrue);
  });

  test('그룹 구성원 색상은 첨부 Shift Harmony 시안의 분류 색상을 사용한다', () {
    expect(
      group_preview_members.map((member) => member.color),
      orderedEquals(const [
        Color(0xFFFF9500),
        Color(0xFFE85F80),
        Color(0xFF4355B8),
        Color(0xFF717782),
      ]),
    );
  });

  testWidgets('월 화면에 4명 그룹과 선택 날짜의 근무·일정 상세를 표시한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _buildTestApp(screen_height: 800, initial_date: DateTime(2026, 1, 1)),
    );
    await tester.pumpAndSettle();

    expect(find.text('우리 병동 · 그룹 보기'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('group-preview-member-overview')),
      findsOneWidget,
    );
    expect(find.text('그룹 멤버'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('group-preview-member-avatars')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('group-preview-add-member')),
      findsOneWidget,
    );
    expect(find.text('2026.01'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('group-preview-today-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('group-preview-calendar-card')),
      findsOneWidget,
    );
    for (final member_id in ['me', 'minsu', 'jiyeon', 'donguk']) {
      expect(
        find.byKey(ValueKey('group-preview-avatar-$member_id')),
        findsOneWidget,
      );
    }
    expect(find.text('박현서'), findsWidgets);
    expect(
      tester
          .widget<TableCalendar<void>>(
            find.byKey(const ValueKey('group-preview-calendar')),
          )
          .calendarFormat,
      CalendarFormat.month,
    );
    expect(find.text('근무 4명 · 개인 일정 2개'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('group-preview-member-list')),
      findsOneWidget,
    );

    final calendar_card = tester.widget<Container>(
      find.byKey(const ValueKey('group-preview-calendar-card')),
    );
    final calendar_decoration = calendar_card.decoration! as BoxDecoration;
    expect(calendar_decoration.color, AppTheme.surface_color);
    expect(calendar_decoration.border, isNotNull);

    final selected_cell = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('group-day-2026-01-01')),
    );
    final selected_decoration = selected_cell.decoration! as BoxDecoration;
    final selected_border = selected_decoration.border! as Border;
    expect(
      selected_decoration.color,
      AppTheme.primary_color.withValues(alpha: 0.08),
    );
    expect(selected_border.top.color, AppTheme.primary_dark_color);
    expect(selected_border.top.width, 2);

    final first_shift_bar = tester.widget<Container>(
      find.byKey(const ValueKey('group-preview-shift-bar-me')),
    );
    expect(first_shift_bar.color, const Color(0xFFFF9500));
    expect(tester.takeException(), isNull);
  });

  testWidgets('사람별 일정 목록은 근무 시간을 개인 일정보다 먼저 표시한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _buildTestApp(screen_height: 800, initial_date: DateTime(2026, 1, 1)),
    );
    await tester.pumpAndSettle();

    final member_card = find.byKey(const ValueKey('group-preview-member-me'));
    final schedule_row = find.descendant(
      of: member_card,
      matching: find.byKey(const ValueKey('group-preview-schedule-row-me')),
    );
    final row_widget = tester.widget<Row>(schedule_row);

    expect(
      row_widget.children.first.key,
      const ValueKey('group-preview-shift-time-me'),
    );
    expect(
      find.descendant(of: member_card, matching: find.text('07:00–15:00')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: member_card, matching: find.text('09:30 병원 예약')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('0명 근무 날짜 선택 시 휴무와 개인 일정 상세로 갱신된다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _buildTestApp(screen_height: 800, initial_date: DateTime(2026, 1, 1)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('group-day-2026-01-05')));
    await tester.pumpAndSettle();

    expect(find.text('근무 0명 · 개인 일정 2개'), findsOneWidget);
    expect(find.text('OFF'), findsWidgets);
    final first_member_card = find.byKey(
      const ValueKey('group-preview-member-me'),
    );
    expect(
      find.descendant(
        of: first_member_card,
        matching: find.byKey(const ValueKey('group-preview-shift-time-me')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: first_member_card, matching: find.text('근무 없음')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('작은 화면에서는 2주 보기로 고정하고 오버플로 없이 렌더링한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _buildTestApp(screen_height: 740, initial_date: DateTime(2026, 1, 1)),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TableCalendar<void>>(
            find.byKey(const ValueKey('group-preview-calendar')),
          )
          .calendarFormat,
      CalendarFormat.twoWeeks,
    );
    expect(
      find.byKey(const ValueKey('group-preview-selected-day-detail')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('친구 화면의 그룹 버튼으로 미리보기 화면에 진입한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_buildFriendListTestApp(screen_height: 800));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('group-calendar-preview-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('우리 병동 · 그룹 보기'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('group-preview-calendar')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
