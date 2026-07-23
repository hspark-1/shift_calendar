// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_theme.dart';
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
  static final DateTime _first_day = DateTime.utc(2000);
  static final DateTime _last_day = DateTime.utc(2050, 12, 31);

  late DateTime _focused_day;
  late DateTime _selected_day;

  bool get _is_short_screen => MediaQuery.sizeOf(context).height < 750;

  CalendarFormat get _calendar_format =>
      _is_short_screen ? CalendarFormat.twoWeeks : CalendarFormat.month;

  double get _calendar_row_height => _is_short_screen ? 52 : 56;

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
    final previous_month = DateTime(_focused_day.year, _focused_day.month - 1);
    return !previous_month.isBefore(_first_day);
  }

  bool _canGoToNextMonth() {
    final next_month = DateTime(_focused_day.year, _focused_day.month + 1);
    return !next_month.isAfter(_last_day);
  }

  void _goToPreviousMonth() {
    if (!_canGoToPreviousMonth()) return;
    setState(() {
      _focused_day = DateTime(_focused_day.year, _focused_day.month - 1, 1);
    });
  }

  void _goToNextMonth() {
    if (!_canGoToNextMonth()) return;
    setState(() {
      _focused_day = DateTime(_focused_day.year, _focused_day.month + 1, 1);
    });
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
      first_year: _first_day.year,
      last_year: _last_day.year,
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
      navigationBar: const CupertinoNavigationBar(
        middle: Text('우리 병동 · 그룹 보기'),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildMemberOverview(),
            const SizedBox(height: AppTheme.spacing_md),
            _buildMonthHeader(),
            const SizedBox(height: AppTheme.spacing_sm),
            _buildCalendar(),
            const SizedBox(height: AppTheme.spacing_md),
            Expanded(child: _buildSelectedDayDetail(selected_day_data)),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberOverview() {
    return Padding(
      key: const ValueKey('group-preview-member-overview'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '그룹 멤버',
                style: AppTheme.body_medium.copyWith(
                  color: AppTheme.on_surface_variant_color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppTheme.spacing_sm),
              Container(
                key: const ValueKey('group-preview-member-count'),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary_color.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(AppTheme.chip_radius),
                ),
                child: Text(
                  '${group_preview_members.length}',
                  style: AppTheme.body_small.copyWith(
                    color: AppTheme.primary_dark_color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            key: const ValueKey('group-preview-member-avatars'),
            height: 44,
            width: 166,
            child: Stack(
              children: [
                for (
                  var index = 0;
                  index < group_preview_members.length;
                  index++
                )
                  Positioned(
                    left: index * 30,
                    child: _buildMemberAvatar(group_preview_members[index]),
                  ),
                Positioned(left: 120, child: _buildAddMemberAvatar()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberAvatar(GroupPreviewMember member) {
    return Semantics(
      label: member.name,
      child: Container(
        key: ValueKey('group-preview-avatar-${member.id}'),
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: member.color,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.background_color, width: 2),
        ),
        child: Text(
          member.initial,
          style: const TextStyle(
            color: AppTheme.surface_color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildAddMemberAvatar() {
    return Semantics(
      label: '그룹 멤버 추가',
      child: Container(
        key: const ValueKey('group-preview-add-member'),
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.surface_container_high_color,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.background_color, width: 2),
        ),
        child: const Icon(
          CupertinoIcons.plus,
          size: 18,
          color: AppTheme.on_surface_variant_color,
        ),
      ),
    );
  }

  Widget _buildMonthHeader() {
    final year_month = DateFormat('yyyy.MM', 'ko_KR').format(_focused_day);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: CupertinoButton(
                key: const ValueKey('group-preview-year-month-button'),
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(vertical: 6),
                onPressed: _showYearMonthPicker,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        year_month,
                        style: AppTheme.heading_medium.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.on_surface_color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        CupertinoIcons.chevron_down,
                        size: 18,
                        color: AppTheme.on_surface_variant_color,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _buildMonthNavigationButton(
            key: const ValueKey('group-preview-previous-month'),
            icon: CupertinoIcons.chevron_left,
            is_enabled: _canGoToPreviousMonth(),
            onPressed: _goToPreviousMonth,
          ),
          CupertinoButton(
            key: const ValueKey('group-preview-today-button'),
            minimumSize: const Size(54, 36),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: AppTheme.primary_color.withValues(alpha: 0.06),
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
          _buildMonthNavigationButton(
            key: const ValueKey('group-preview-next-month'),
            icon: CupertinoIcons.chevron_right,
            is_enabled: _canGoToNextMonth(),
            onPressed: _goToNextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigationButton({
    required Key key,
    required IconData icon,
    required bool is_enabled,
    required VoidCallback onPressed,
  }) {
    return CupertinoButton(
      key: key,
      minimumSize: const Size(44, 44),
      padding: EdgeInsets.zero,
      onPressed: is_enabled ? onPressed : null,
      child: Icon(
        icon,
        size: 22,
        color: is_enabled
            ? AppTheme.on_surface_color
            : AppTheme.outline_variant_color,
      ),
    );
  }

  Widget _buildCalendar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        key: const ValueKey('group-preview-calendar-card'),
        decoration: BoxDecoration(
          color: AppTheme.surface_color,
          borderRadius: BorderRadius.circular(AppTheme.input_radius),
          border: Border.all(color: AppTheme.outline_variant_color),
        ),
        clipBehavior: Clip.antiAlias,
        child: TableCalendar<void>(
          key: const ValueKey('group-preview-calendar'),
          firstDay: _first_day,
          lastDay: _last_day,
          focusedDay: _focused_day,
          calendarFormat: _calendar_format,
          locale: 'ko_KR',
          headerVisible: false,
          daysOfWeekHeight: 32,
          rowHeight: _calendar_row_height,
          availableGestures: AvailableGestures.horizontalSwipe,
          selectedDayPredicate: (day) => isSameDay(_selected_day, day),
          onDaySelected: (selected_day, focused_day) {
            setState(() {
              _selected_day = _normalizeDate(selected_day);
              _focused_day = focused_day;
            });
          },
          onPageChanged: (focused_day) {
            setState(() => _focused_day = focused_day);
          },
          calendarStyle: const CalendarStyle(
            tablePadding: EdgeInsets.zero,
            cellMargin: EdgeInsets.zero,
            outsideDaysVisible: true,
          ),
          calendarBuilders: CalendarBuilders<void>(
            dowBuilder: (context, day) => _buildDayOfWeekCell(day),
            defaultBuilder: (context, date, focused_day) =>
                _buildDayCell(date: date),
            outsideBuilder: (context, date, focused_day) =>
                _buildDayCell(date: date, is_outside: true),
            todayBuilder: (context, date, focused_day) =>
                _buildDayCell(date: date, is_today: true),
            selectedBuilder: (context, date, focused_day) => _buildDayCell(
              date: date,
              is_today: isSameDay(date, DateTime.now()),
              is_selected: true,
              is_outside:
                  date.year != focused_day.year ||
                  date.month != focused_day.month,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayOfWeekCell(DateTime day) {
    final text_color = day.weekday == DateTime.sunday
        ? AppTheme.accent_red_color
        : day.weekday == DateTime.saturday
        ? AppTheme.primary_dark_color
        : AppTheme.on_surface_variant_color;

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.outline_variant_color.withValues(alpha: 0.45),
          ),
        ),
      ),
      child: Text(
        DateFormat('E', 'ko_KR').format(day),
        style: AppTheme.body_small.copyWith(
          color: text_color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDayCell({
    required DateTime date,
    bool is_today = false,
    bool is_selected = false,
    bool is_outside = false,
  }) {
    final day_data = buildGroupPreviewDayData(date);
    final semantic_date_color = date.weekday == DateTime.sunday
        ? AppTheme.accent_red_color
        : date.weekday == DateTime.saturday
        ? AppTheme.primary_dark_color
        : AppTheme.on_surface_color;
    final date_color = is_selected
        ? AppTheme.primary_dark_color
        : semantic_date_color;
    final date_text = Text(
      '${date.day}',
      style: TextStyle(
        color: is_today && !is_selected ? AppTheme.surface_color : date_color,
        fontSize: 13,
        fontWeight: is_selected || is_today ? FontWeight.w700 : FontWeight.w500,
      ),
    );
    final date_indicator = is_today && !is_selected
        ? Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppTheme.primary_color,
              shape: BoxShape.circle,
            ),
            child: date_text,
          )
        : SizedBox(height: 24, child: Center(child: date_text));

    return Semantics(
      label:
          '${date.month}월 ${date.day}일, ${day_data.working_count}명 근무, '
          '개인 일정 ${day_data.personal_event_count}개',
      button: true,
      child: Opacity(
        opacity: is_outside ? 0.38 : 1,
        child: AnimatedContainer(
          key: ValueKey(
            'group-day-${date.year}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}',
          ),
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
          decoration: BoxDecoration(
            color: is_selected
                ? AppTheme.primary_color.withValues(alpha: 0.08)
                : AppTheme.surface_color,
            border: is_selected
                ? Border.all(color: AppTheme.primary_dark_color, width: 2)
                : Border(
                    right: BorderSide(
                      color: AppTheme.outline_variant_color.withValues(
                        alpha: 0.38,
                      ),
                    ),
                    bottom: BorderSide(
                      color: AppTheme.outline_variant_color.withValues(
                        alpha: 0.38,
                      ),
                    ),
                  ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              date_indicator,
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${day_data.working_count}명 근무',
                  style: TextStyle(
                    color: is_selected
                        ? AppTheme.primary_dark_color
                        : AppTheme.on_surface_variant_color,
                    fontSize: 10,
                    fontWeight: is_selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDayDetail(GroupPreviewDayData day_data) {
    return Column(
      key: const ValueKey('group-preview-selected-day-detail'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
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
              Text(
                '근무 ${day_data.working_count}명 · '
                '개인 일정 ${day_data.personal_event_count}개',
                key: const ValueKey('group-preview-day-summary'),
                style: AppTheme.body_small.copyWith(
                  color: AppTheme.on_surface_variant_color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            key: const ValueKey('group-preview-member-list'),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: day_data.members.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _buildMemberDayCard(day_data.members[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMemberDayCard(GroupPreviewMemberDay member_day) {
    final badge_text_color = AppTheme.readableForegroundColor(
      member_day.shift_color,
      preferred_color: AppTheme.surface_color,
    );

    return Container(
      key: ValueKey('group-preview-member-${member_day.member.id}'),
      decoration: BoxDecoration(
        color: AppTheme.surface_color,
        borderRadius: BorderRadius.circular(AppTheme.input_radius),
        border: Border.all(color: AppTheme.outline_variant_color),
      ),
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
            padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: member_day.shift_color.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: member_day.shift_color.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    member_day.member.initial,
                    style: TextStyle(
                      color: member_day.shift_color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  member_day.member.name,
                  style: AppTheme.body_large.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: member_day.shift_color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    member_day.shift_code,
                    style: AppTheme.body_small.copyWith(
                      color: badge_text_color,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SingleChildScrollView(
                    key: ValueKey(
                      'group-preview-schedule-scroll-'
                      '${member_day.member.id}',
                    ),
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      key: ValueKey(
                        'group-preview-schedule-row-'
                        '${member_day.member.id}',
                      ),
                      children: [
                        _buildShiftTimeChip(member_day),
                        for (final event in member_day.events) ...[
                          const SizedBox(width: 6),
                          _buildEventChip(event),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftTimeChip(GroupPreviewMemberDay member_day) {
    final label = member_day.is_working ? member_day.shift_time_text : '근무 없음';

    return Container(
      key: ValueKey('group-preview-shift-time-${member_day.member.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface_container_low_color,
        borderRadius: BorderRadius.circular(AppTheme.chip_radius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            member_day.is_working ? CupertinoIcons.clock : CupertinoIcons.moon,
            size: 13,
            color: AppTheme.on_surface_variant_color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
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
