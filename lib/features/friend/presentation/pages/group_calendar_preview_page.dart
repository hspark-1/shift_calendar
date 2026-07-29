// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../calendar/presentation/controllers/calendar_viewport_controller.dart';
import '../../../calendar/presentation/models/calendar_day_presentation.dart';
import '../../../calendar/presentation/models/calendar_layout_policy.dart';
import '../../../calendar/presentation/widgets/calendar_month_view.dart';
import '../../../calendar/presentation/widgets/calendar_schedule_card.dart';
import '../../../calendar/presentation/widgets/calendar_viewport.dart';
import '../../../calendar/presentation/widgets/year_month_picker_sheet.dart';

const List<GroupPreviewMember> group_preview_members = [
  GroupPreviewMember(
    id: 'me',
    name: '박현서',
    initial: '박',
    color: Color(0xFFFF9500),
  ),
  GroupPreviewMember(
    id: 'minsu',
    name: '김민수',
    initial: '김',
    color: Color(0xFFE85F80),
  ),
  GroupPreviewMember(
    id: 'jiyeon',
    name: '이지연',
    initial: '이',
    color: Color(0xFF4355B8),
  ),
  GroupPreviewMember(
    id: 'donguk',
    name: '이동욱',
    initial: '이',
    color: Color(0xFF717782),
  ),
];

const List<_GroupPreviewShiftTemplate> _shift_templates = [
  _GroupPreviewShiftTemplate(
    code: 'D',
    name: '데이',
    time_text: '07:00–15:00',
    color: Color(0xFFFF9500),
  ),
  _GroupPreviewShiftTemplate(
    code: 'E',
    name: '이브닝',
    time_text: '14:30–22:30',
    color: Color(0xFFE85F80),
  ),
  _GroupPreviewShiftTemplate(
    code: 'N',
    name: '나이트',
    time_text: '22:00–익일 08:00',
    color: Color(0xFF4355B8),
  ),
  _GroupPreviewShiftTemplate(
    code: 'F',
    name: '플렉스',
    time_text: '10:00–18:00',
    color: Color(0xFF448F53),
  ),
];

const List<_GroupPreviewEventTemplate> _event_templates = [
  _GroupPreviewEventTemplate(
    title: '병원 예약',
    time_text: '09:30',
    icon: CupertinoIcons.heart,
  ),
  _GroupPreviewEventTemplate(
    title: '저녁 약속',
    time_text: '18:30',
    icon: CupertinoIcons.person_2,
  ),
  _GroupPreviewEventTemplate(
    title: '운동',
    time_text: '20:00',
    icon: CupertinoIcons.sportscourt,
  ),
  _GroupPreviewEventTemplate(
    title: '장보기',
    time_text: '16:00',
    icon: CupertinoIcons.cart,
  ),
  _GroupPreviewEventTemplate(
    title: '스터디',
    time_text: '19:00',
    icon: CupertinoIcons.book,
  ),
];

class GroupPreviewMember {
  const GroupPreviewMember({
    required this.id,
    required this.name,
    required this.initial,
    required this.color,
  });

  final String id;
  final String name;
  final String initial;
  final Color color;
}

class GroupPreviewEvent {
  const GroupPreviewEvent({
    required this.title,
    required this.time_text,
    required this.icon,
  });

  final String title;
  final String time_text;
  final IconData icon;
}

class GroupPreviewMemberDay {
  const GroupPreviewMemberDay({
    required this.member,
    required this.shift_code,
    required this.shift_name,
    required this.shift_time_text,
    required this.shift_color,
    required this.events,
  });

  final GroupPreviewMember member;
  final String shift_code;
  final String shift_name;
  final String shift_time_text;
  final Color shift_color;
  final List<GroupPreviewEvent> events;

  bool get is_working => shift_code != 'OFF';
}

class GroupPreviewDayData {
  const GroupPreviewDayData({required this.date, required this.members});

  final DateTime date;
  final List<GroupPreviewMemberDay> members;

  int get working_count =>
      members.where((member_day) => member_day.is_working).length;

  int get personal_event_count =>
      members.fold(0, (total, member_day) => total + member_day.events.length);
}

class _GroupPreviewShiftTemplate {
  const _GroupPreviewShiftTemplate({
    required this.code,
    required this.name,
    required this.time_text,
    required this.color,
  });

  final String code;
  final String name;
  final String time_text;
  final Color color;
}

class _GroupPreviewEventTemplate {
  const _GroupPreviewEventTemplate({
    required this.title,
    required this.time_text,
    required this.icon,
  });

  final String title;
  final String time_text;
  final IconData icon;
}

/// 날짜별로 4명 → 3명 → 2명 → 1명 → 0명 근무 패턴을 반복한다.
///
/// 화면 테스트가 매번 동일한 결과를 얻도록 현재 시각이나 난수에는 의존하지 않는다.
GroupPreviewDayData buildGroupPreviewDayData(DateTime date) {
  final normalized_date = DateTime(date.year, date.month, date.day);
  final day_serial = DateTime.utc(
    normalized_date.year,
    normalized_date.month,
    normalized_date.day,
  ).difference(DateTime.utc(2026)).inDays;
  final pattern_index = ((day_serial % 5) + 5) % 5;
  final working_count = 4 - pattern_index;
  final event_count = day_serial.isEven ? 2 : 3;
  final rotation_index =
      ((day_serial % group_preview_members.length) +
          group_preview_members.length) %
      group_preview_members.length;

  final events_by_member = <String, List<GroupPreviewEvent>>{
    for (final member in group_preview_members) member.id: [],
  };
  for (var event_index = 0; event_index < event_count; event_index++) {
    final event_template =
        _event_templates[(pattern_index + event_index) %
            _event_templates.length];
    final member =
        group_preview_members[(rotation_index + event_index) %
            group_preview_members.length];
    events_by_member[member.id]!.add(
      GroupPreviewEvent(
        title: event_template.title,
        time_text: event_template.time_text,
        icon: event_template.icon,
      ),
    );
  }

  final working_member_ids = <String>{
    for (var index = 0; index < working_count; index++)
      group_preview_members[(rotation_index + index) %
              group_preview_members.length]
          .id,
  };

  final member_days = group_preview_members
      .map((member) {
        if (!working_member_ids.contains(member.id)) {
          return GroupPreviewMemberDay(
            member: member,
            shift_code: 'OFF',
            shift_name: '휴무',
            shift_time_text: '근무 없음',
            shift_color: const Color(0xFF448F53),
            events: List.unmodifiable(events_by_member[member.id]!),
          );
        }

        final member_index = group_preview_members.indexOf(member);
        final shift_template =
            _shift_templates[(pattern_index + member_index) %
                _shift_templates.length];
        return GroupPreviewMemberDay(
          member: member,
          shift_code: shift_template.code,
          shift_name: shift_template.name,
          shift_time_text: shift_template.time_text,
          shift_color: shift_template.color,
          events: List.unmodifiable(events_by_member[member.id]!),
        );
      })
      .toList(growable: false);

  return GroupPreviewDayData(
    date: normalized_date,
    members: List.unmodifiable(member_days),
  );
}

class GroupCalendarPreviewPage extends StatefulWidget {
  const GroupCalendarPreviewPage({super.key, this.initial_date});

  final DateTime? initial_date;

  @override
  State<GroupCalendarPreviewPage> createState() =>
      _GroupCalendarPreviewPageState();
}

class _GroupCalendarPreviewPageState extends State<GroupCalendarPreviewPage> {
  static final _viewport_controller = const CalendarViewportController();

  late DateTime _focused_day;
  late DateTime _selected_day;

  CalendarFormat get _calendar_format => CalendarLayoutPolicy.visibleFormat(
    screen_height: MediaQuery.sizeOf(context).height,
    preferred_format: CalendarFormat.month,
  );

  double get _calendar_row_height => CalendarLayoutPolicy.rowHeight(
    screen_height: MediaQuery.sizeOf(context).height,
    layout_mode: CalendarCellLayoutMode.detailed,
  );

  @override
  void initState() {
    super.initState();
    final initial_date = widget.initial_date ?? DateTime.now();
    _focused_day = _normalizeDate(initial_date);
    _selected_day = _focused_day;
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _canGoToPreviousMonth() {
    return _viewport_controller.canMoveMonth(_focused_day, -1);
  }

  bool _canGoToNextMonth() {
    return _viewport_controller.canMoveMonth(_focused_day, 1);
  }

  void _goToPreviousMonth() {
    final previous_month = _viewport_controller.monthAt(_focused_day, -1);
    if (previous_month == null) return;
    setState(() => _focused_day = previous_month);
  }

  void _goToNextMonth() {
    final next_month = _viewport_controller.monthAt(_focused_day, 1);
    if (next_month == null) return;
    setState(() => _focused_day = next_month);
  }

  void _goToToday() {
    final today = _normalizeDate(DateTime.now());
    setState(() {
      _focused_day = today;
      _selected_day = today;
    });
  }

  Future<void> _showYearMonthPicker() async {
    final selected_date = await showYearMonthPickerSheet(
      context: context,
      initial_date: _focused_day,
      first_year: _viewport_controller.first_year,
      last_year: _viewport_controller.last_year,
    );
    if (selected_date == null || !mounted) return;

    setState(() {
      _focused_day = selected_date;
      _selected_day = selected_date;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected_day_data = buildGroupPreviewDayData(_selected_day);

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background_color,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('우리 병동'),
        trailing: Semantics(
          label: '그룹 멤버 ${group_preview_members.length}명',
          child: Container(
            key: const ValueKey('group-preview-member-count'),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primary_color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.chip_radius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.person_2_fill,
                  size: 14,
                  color: AppTheme.primary_dark_color,
                ),
                const SizedBox(width: AppTheme.spacing_xs),
                Text(
                  '${group_preview_members.length}명',
                  style: AppTheme.body_small.copyWith(
                    color: AppTheme.primary_dark_color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      child: SafeArea(
        minimum: const EdgeInsets.only(bottom: AppTheme.spacing_md),
        child: Column(
          children: [
            Container(
              key: const ValueKey('group-preview-calendar-section'),
              color: AppTheme.background_color,
              child: _buildCalendarViewport(),
            ),
            const SizedBox(height: AppTheme.spacing_sm),
            Expanded(child: _buildSelectedDayDetail(selected_day_data)),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarViewport() {
    return CalendarViewport(
      focused_day: _focused_day,
      can_go_to_previous_month: _canGoToPreviousMonth(),
      can_go_to_next_month: _canGoToNextMonth(),
      onPreviousMonth: _goToPreviousMonth,
      onNextMonth: _goToNextMonth,
      onSelectYearMonth: _showYearMonthPicker,
      header_key: const ValueKey('group-preview-month-header'),
      trailing: CupertinoButton(
        key: const ValueKey('group-preview-today-button'),
        minimumSize: const Size(54, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: AppTheme.primary_color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radius_md),
        onPressed: _goToToday,
        child: Text(
          '오늘',
          style: AppTheme.body_medium.copyWith(
            color: AppTheme.primary_dark_color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      grid_wrapper: (child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing_sm),
        child: child,
      ),
      month_view: CalendarMonthView<void>(
        calendar_key: const ValueKey('group-preview-calendar'),
        focused_day: _focused_day,
        selected_day: _selected_day,
        calendar_format: _calendar_format,
        row_height: _calendar_row_height,
        days_of_week_height: 30,
        cell_layout: CalendarCellLayout.dots,
        day_key_prefix: 'group-day',
        selection_key_prefix: 'group-selection',
        day_presentation_builder: (date) {
          final day_data = buildGroupPreviewDayData(date);
          final working_member_days = day_data.members
              .where((member_day) => member_day.is_working)
              .toList(growable: false);
          final date_color = date.weekday == DateTime.sunday
              ? AppTheme.accent_red_color
              : date.weekday == DateTime.saturday
              ? AppTheme.primary_color
              : AppTheme.on_surface_color;
          return CalendarDayPresentation(
            date_color: date_color,
            semantic_label:
                '${date.month}월 ${date.day}일, '
                '${day_data.working_count}명 근무, '
                '개인 일정 ${day_data.personal_event_count}개',
            indicator: CalendarDotsIndicator(
              key_prefix: 'group-preview-shift',
              colors: [
                for (final member_day in working_member_days)
                  member_day.shift_color,
              ],
            ),
          );
        },
        onDaySelected: (selected_day, focused_day) {
          setState(() {
            _selected_day = _normalizeDate(selected_day);
            _focused_day = focused_day;
          });
        },
        onPageChanged: (focused_day) =>
            setState(() => _focused_day = focused_day),
      ),
    );
  }

  Widget _buildSelectedDayDetail(GroupPreviewDayData day_data) {
    return Container(
      key: const ValueKey('group-preview-selected-day-detail'),
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing_md),
      decoration: AppTheme.cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            key: const ValueKey('group-preview-selected-day-header'),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing_md,
              vertical: AppTheme.spacing_sm,
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.outline_variant_color,
                  width: 0.5,
                ),
              ),
            ),
            child: SizedBox(
              height: 28,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('M월 d일 EEEE', 'ko_KR').format(day_data.date),
                      style: AppTheme.heading_small.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing_sm),
                  Row(
                    key: const ValueKey('group-preview-day-summary'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CalendarScheduleSummaryChip(
                        key: const ValueKey('group-preview-working-count-chip'),
                        label: '근무 ${day_data.working_count}명',
                        is_primary: true,
                      ),
                      const SizedBox(width: 6),
                      CalendarScheduleSummaryChip(
                        key: const ValueKey('group-preview-event-count-chip'),
                        label: '일정 ${day_data.personal_event_count}개',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              key: const ValueKey('group-preview-member-list'),
              padding: EdgeInsets.fromLTRB(
                AppTheme.spacing_sm,
                AppTheme.spacing_sm,
                AppTheme.spacing_sm,
                AppTheme.spacing_sm,
              ),
              itemCount: day_data.members.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _buildMemberDayCard(day_data.members[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberDayCard(GroupPreviewMemberDay member_day) {
    final badge_text_color = AppTheme.readableForegroundColor(
      member_day.shift_color,
      preferred_color: AppTheme.surface_color,
    );
    final shift_description = member_day.is_working
        ? '${member_day.shift_name} · ${member_day.shift_time_text}'
        : '${member_day.shift_name} · 근무 없음';

    return Container(
      key: ValueKey('group-preview-member-${member_day.member.id}'),
      decoration: AppTheme.cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              key: ValueKey('group-preview-shift-bar-${member_day.member.id}'),
              width: 4,
              color: member_day.shift_color,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      key: ValueKey(
                        'group-preview-member-avatar-'
                        '${member_day.member.id}',
                      ),
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: member_day.member.color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: member_day.member.color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        member_day.member.initial,
                        style: TextStyle(
                          color: member_day.member.color,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member_day.member.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.body_large.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            key: ValueKey(
                              'group-preview-schedule-row-'
                              '${member_day.member.id}',
                            ),
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: member_day.shift_color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  shift_description,
                                  key: ValueKey(
                                    'group-preview-shift-time-'
                                    '${member_day.member.id}',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.body_medium.copyWith(
                                    color: AppTheme.on_surface_variant_color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      key: ValueKey(
                        'group-preview-shift-code-${member_day.member.id}',
                      ),
                      constraints: const BoxConstraints(minWidth: 36),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: member_day.shift_color,
                        borderRadius: BorderRadius.circular(AppTheme.radius_md),
                      ),
                      child: Text(
                        member_day.shift_code,
                        textAlign: TextAlign.center,
                        style: AppTheme.body_small.copyWith(
                          color: badge_text_color,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                if (member_day.events.isNotEmpty) ...[
                  const SizedBox(height: 11),
                  Padding(
                    padding: const EdgeInsets.only(left: 56),
                    child: SingleChildScrollView(
                      key: ValueKey(
                        'group-preview-event-scroll-'
                        '${member_day.member.id}',
                      ),
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (
                            var index = 0;
                            index < member_day.events.length;
                            index++
                          ) ...[
                            if (index > 0) const SizedBox(width: 6),
                            _buildEventChip(member_day.events[index]),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventChip(GroupPreviewEvent event) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface_container_low_color,
        borderRadius: BorderRadius.circular(AppTheme.chip_radius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(event.icon, size: 13, color: AppTheme.on_surface_variant_color),
          const SizedBox(width: 5),
          Text(
            '${event.time_text} ${event.title}',
            style: AppTheme.body_small.copyWith(
              color: AppTheme.on_surface_variant_color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
