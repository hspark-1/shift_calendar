// ignore_for_file: non_constant_identifier_names

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shift_mate/core/theme/app_theme.dart';
import 'package:shift_mate/features/friend/data/models/friend_model.dart';
import 'package:shift_mate/features/friend/data/services/friend_service.dart';
import 'package:shift_mate/features/friend/presentation/pages/friend_list_page.dart';
import 'package:shift_mate/features/friend/presentation/pages/group_calendar_preview_page.dart';
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

    expect(find.text('우리 병동'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('group-preview-member-count')),
      findsOneWidget,
    );
    expect(find.text('4명'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('group-preview-calendar-section')),
      findsOneWidget,
    );
    expect(find.text('2026.01'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('group-preview-today-button')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TableCalendar<void>>(
            find.byKey(const ValueKey('group-preview-calendar')),
          )
          .calendarFormat,
      CalendarFormat.month,
    );
    expect(find.text('선택일 근무 현황'), findsNothing);
    expect(find.text('근무 4명'), findsOneWidget);
    expect(find.text('일정 2개'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('group-preview-member-list')),
      findsOneWidget,
    );

    final calendar_section = tester.widget<Container>(
      find.byKey(const ValueKey('group-preview-calendar-section')),
    );
    expect(calendar_section.color, AppTheme.background_color);
    expect(calendar_section.decoration, isNull);

    final selected_day_detail = tester.widget<Container>(
      find.byKey(const ValueKey('group-preview-selected-day-detail')),
    );
    final selected_day_decoration =
        selected_day_detail.decoration! as BoxDecoration;
    expect(selected_day_decoration.color, AppTheme.surface_color);
    expect(
      selected_day_decoration.borderRadius,
      BorderRadius.circular(AppTheme.card_radius),
    );
    expect(selected_day_decoration.border, isNotNull);
    expect(
      find.byKey(const ValueKey('group-preview-selected-day-header')),
      findsOneWidget,
    );
    final selected_day_header = tester.widget<Container>(
      find.byKey(const ValueKey('group-preview-selected-day-header')),
    );
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('group-preview-selected-day-header')),
          )
          .height,
      44.5,
    );
    expect(
      find.byKey(const ValueKey('group-preview-working-count-chip')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('group-preview-event-count-chip')),
      findsOneWidget,
    );
    final selected_day_header_decoration =
        selected_day_header.decoration! as BoxDecoration;
    expect(selected_day_header_decoration.border?.bottom.width, 0.5);
    expect(
      800 -
          tester
              .getBottomRight(
                find.byKey(const ValueKey('group-preview-selected-day-detail')),
              )
              .dy,
      greaterThanOrEqualTo(AppTheme.spacing_md),
    );

    final selected_cell = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('group-selection-2026-01-01')),
    );
    final selected_decoration = selected_cell.decoration! as BoxDecoration;
    final selected_border = selected_decoration.border! as Border;
    expect(
      selected_decoration.color,
      AppTheme.primary_color.withValues(alpha: 0.08),
    );
    expect(selected_border.top.color, AppTheme.primary_dark_color);
    expect(selected_border.top.width, 2);
    final expected_shift_colors = <Color>[
      const Color(0xFFFF9500),
      const Color(0xFFE85F80),
      const Color(0xFF4355B8),
      const Color(0xFF448F53),
    ];
    for (var index = 0; index < expected_shift_colors.length; index++) {
      final shift_dot = find.byKey(
        ValueKey('group-preview-shift-dot-2026-01-01-$index'),
      );
      expect(shift_dot, findsOneWidget);
      final shift_dot_decoration =
          tester.widget<Container>(shift_dot).decoration! as BoxDecoration;
      expect(shift_dot_decoration.color, expected_shift_colors[index]);
    }
    expect(find.text('1명 근무'), findsNothing);

    final first_shift_bar = tester.widget<Container>(
      find.byKey(const ValueKey('group-preview-shift-bar-me')),
    );
    expect(first_shift_bar.color, const Color(0xFFFF9500));
    final first_member_card = tester.widget<Container>(
      find.byKey(const ValueKey('group-preview-member-me')),
    );
    final first_member_decoration =
        first_member_card.decoration! as BoxDecoration;
    expect(
      first_member_decoration.borderRadius,
      BorderRadius.circular(AppTheme.card_radius),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('선택된 토요일과 일요일도 날짜 의미 색상을 유지한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _buildTestApp(screen_height: 800, initial_date: DateTime(2026, 1, 3)),
    );
    await tester.pumpAndSettle();

    Text selectedDateText(String day, String key) {
      return tester.widget<Text>(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.text(day),
        ),
      );
    }

    expect(
      selectedDateText('3', 'group-day-2026-01-03').style?.color,
      AppTheme.primary_color,
    );

    await tester.tap(find.byKey(const ValueKey('group-day-2026-01-04')));
    await tester.pumpAndSettle();

    expect(
      selectedDateText('4', 'group-day-2026-01-04').style?.color,
      AppTheme.accent_red_color,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('구성원 카드는 이름·근무 시간·개인 일정 순서로 표시한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _buildTestApp(screen_height: 800, initial_date: DateTime(2026, 1, 1)),
    );
    await tester.pumpAndSettle();

    final member_card = find.byKey(const ValueKey('group-preview-member-me'));
    final shift_time = find.descendant(
      of: member_card,
      matching: find.byKey(const ValueKey('group-preview-shift-time-me')),
    );
    expect(
      find.descendant(of: member_card, matching: find.text('데이 · 07:00–15:00')),
      findsOneWidget,
    );
    final personal_event = find.descendant(
      of: member_card,
      matching: find.text('09:30 병원 예약'),
    );
    expect(personal_event, findsOneWidget);
    expect(
      tester.getTopLeft(shift_time).dy,
      lessThan(tester.getTopLeft(personal_event).dy),
    );
    expect(
      find.descendant(
        of: member_card,
        matching: find.byKey(const ValueKey('group-preview-member-avatar-me')),
      ),
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

    expect(find.text('근무 0명'), findsOneWidget);
    expect(find.text('일정 2개'), findsOneWidget);
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
      find.descendant(of: first_member_card, matching: find.text('휴무 · 근무 없음')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('group-preview-shift-dot-2026-01-05-0')),
      findsNothing,
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

  testWidgets('친구 화면 footer에서 그룹 방 목록을 거쳐 미리보기 화면에 진입한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_buildFriendListTestApp(screen_height: 800));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('friend-list-footer-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('group-room-footer-button')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('add-friend-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('group-room-list')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('group-room-footer-button')));
    await tester.pump();

    expect(find.byKey(const ValueKey('group-room-list')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('group-room-preview-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('group-room-preview-avatars')),
      findsOneWidget,
    );
    expect(find.text('우리 병동'), findsOneWidget);
    expect(find.text('4명 · 그룹 캘린더'), findsOneWidget);
    expect(
      find.text('그룹 방'),
      findsNWidgets(2),
      reason: '본문 중복 제목 없이 내비게이션과 footer에만 표시해야 한다.',
    );
    expect(find.byKey(const ValueKey('add-friend-button')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('friend-list-footer-button')));
    await tester.pump();

    expect(find.byKey(const ValueKey('group-room-list')), findsNothing);
    expect(find.byKey(const ValueKey('add-friend-button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('group-room-footer-button')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('group-room-preview-card')));
    await tester.pumpAndSettle();

    expect(find.text('우리 병동'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('group-preview-calendar')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
