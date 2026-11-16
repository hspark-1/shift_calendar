// ignore_for_file: non_constant_identifier_names

import '../../../../helpers/calendar_header_assertions.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:shift_mate/core/theme/app_theme.dart';
import 'package:shift_mate/features/calendar/presentation/models/calendar_day_presentation.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/calendar_month_view.dart';
import 'package:table_calendar/table_calendar.dart';
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

  testWidgets('구성원 목록 스크롤이 그룹 이름 헤더의 배경을 바꾸지 않는다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(_FakeGroupRepository()),
        ],
        child: CupertinoApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 800)),
            child: GroupCalendarPage(
              group_id: 'group-1',
              initial_date: DateTime(2026, 8, 2),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await verifyCalendarHeaderOnScroll(
      tester,
      calendar: find.byKey(const ValueKey('group-calendar')),
      list: find.byKey(const ValueKey('group-calendar-member-list')),
    );
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
    expect(find.text('데이 · 07:00 - 15:00'), findsOneWidget);
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

  testWidgets('작은 화면에서 긴 선택일과 요약이 잘리거나 겹치지 않는다', (tester) async {
    for (final entry in {
      'Cafe24SsurroundAir': 'assets/fonts/Cafe24SsurroundAir-v1.1.ttf',
      'Cafe24Ssurround': 'assets/fonts/Cafe24Ssurround-v2.0.ttf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load(entry.value))).load();
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final width in [320.0, 375.0, 390.0]) {
      await tester.binding.setSurfaceSize(Size(width, 667));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupRepositoryProvider.overrideWithValue(_FakeGroupRepository()),
          ],
          child: CupertinoApp(
            theme: AppTheme.lightTheme,
            home: GroupCalendarPage(
              group_id: 'group-1',
              initial_date: DateTime(2026, 11, 12),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final title = find.text('11월 12일 목요일');
      final paragraph = tester.renderObject<RenderParagraph>(title);
      final boxes = paragraph.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 11),
      );
      final title_rect = tester.getRect(title);
      final detail_rect = tester.getRect(
        find.byKey(const ValueKey('group-calendar-selected-day-detail')),
      );
      expect(
        boxes.map((box) => box.top).toSet(),
        hasLength(1),
        reason: '$width',
      );
      for (final box in boxes) {
        expect(box.bottom, lessThanOrEqualTo(paragraph.size.height + 0.1));
        expect(box.right, lessThanOrEqualTo(paragraph.size.width + 0.1));
      }
      expect(detail_rect.contains(title_rect.topLeft), isTrue);
      expect(detail_rect.contains(title_rect.bottomRight), isTrue);
      for (final label in ['근무 0명', '일정 0개']) {
        expect(title_rect.overlaps(tester.getRect(find.text(label))), isFalse);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
  testWidgets('그룹 달력 공용 배치와 탐색은 작은 화면·가로·확대 글자에서도 유지된다', (tester) async {
    await verifyResponsiveCalendar(
      tester,
      prefix: 'group-calendar',
      calendar_key: 'group-calendar',
      last_member_key: 'group-calendar-member-denied',
      page_builder: (_) => ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(_FakeGroupRepository()),
        ],
        child: GroupCalendarPage(
          group_id: 'group-1',
          initial_date: DateTime(2026, 8, 2),
        ),
      ),
    );
  });
  testWidgets('그룹 점 표시와 메인·친구 배지의 날짜 선택 네모는 크기와 셀 내 위치가 같다', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final selected_date = DateTime(2026, 11, 12);
    for (final width in [320.0, 375.0, 390.0, 430.0, 667.0, 768.0]) {
      for (final row_height in [52.0, 56.0]) {
        await tester.binding.setSurfaceSize(Size(width, 667));
        await tester.pumpWidget(
          CupertinoApp(
            home: Column(
              children: [
                for (final layout in [
                  CalendarCellLayout.badge,
                  CalendarCellLayout.dots,
                ])
                  CalendarMonthView<void>(
                    calendar_key: ValueKey(layout),
                    focused_day: selected_date,
                    selected_day: selected_date,
                    calendar_format: CalendarFormat.twoWeeks,
                    row_height: row_height,
                    cell_layout: layout,
                    day_key_prefix: '${layout.name}-day',
                    selection_key_prefix: '${layout.name}-selection',
                    day_presentation_builder: (_) => CalendarDayPresentation(
                      date_color: AppTheme.on_surface_color,
                      indicator: layout == CalendarCellLayout.badge
                          ? const CalendarBadgeIndicator(
                              text: 'D',
                              color: AppTheme.primary_color,
                            )
                          : const CalendarDotsIndicator(
                              colors: [AppTheme.primary_color],
                            ),
                    ),
                    onDaySelected: (_, _) {},
                    onPageChanged: (_) {},
                  ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        Rect selectionRect(String mode) {
          final selection = tester.getRect(
            find.byKey(ValueKey('$mode-selection-2026-11-12')),
          );
          final cell = tester.getRect(
            find.byKey(ValueKey('$mode-day-2026-11-12')),
          );
          return selection.shift(-cell.topLeft);
        }

        expect(
          selectionRect('dots'),
          selectionRect('badge'),
          reason: 'width=$width row=$row_height',
        );
        expect(tester.takeException(), isNull);
      }
    }
  });
}
