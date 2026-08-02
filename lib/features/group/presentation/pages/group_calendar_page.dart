// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../calendar/presentation/controllers/calendar_viewport_controller.dart';
import '../../../calendar/presentation/models/calendar_day_presentation.dart';
import '../../../calendar/presentation/models/calendar_layout_policy.dart';
import '../../../calendar/presentation/widgets/calendar_month_view.dart';
import '../../../calendar/presentation/widgets/calendar_schedule_card.dart';
import '../../../calendar/presentation/widgets/calendar_viewport.dart';
import '../../../calendar/presentation/widgets/year_month_picker_sheet.dart';
import '../../application/group_calendar_provider.dart';
import '../../application/group_calendar_range_state.dart';
import '../../application/group_providers.dart';
import '../../domain/entities/group_models.dart';
import 'group_management_page.dart';

class GroupCalendarPage extends ConsumerStatefulWidget {
  const GroupCalendarPage({
    super.key,
    required this.group_id,
    this.initial_date,
  });

  final String group_id;
  final DateTime? initial_date;

  @override
  ConsumerState<GroupCalendarPage> createState() => _GroupCalendarPageState();
}

class _GroupCalendarPageState extends ConsumerState<GroupCalendarPage> {
  static const _viewport_controller = CalendarViewportController();

  late DateTime _focused_day;
  late DateTime _selected_day;
  int _shown_error_revision = 0;
  bool _handled_group_not_found = false;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(groupDetailProvider(widget.group_id).notifier).load();
      ref
          .read(groupCalendarRangeProvider(widget.group_id).notifier)
          .ensureMonthLoaded(_focused_day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupCalendarRangeProvider(widget.group_id));
    final detail_state = ref.watch(groupDetailProvider(widget.group_id));
    _handleGroupNotFound(detail_state.error ?? state.last_error);
    _showNewErrorIfNeeded(state);

    final title = state.group?.name ?? detail_state.group?.name ?? '그룹 캘린더';
    final member_count = state.members.isNotEmpty
        ? state.members.length
        : detail_state.group?.member_count ?? 0;

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background_color,
      navigationBar: CupertinoNavigationBar(
        middle: Text(title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              key: const ValueKey('group-calendar-member-count'),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primary_color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.chip_radius),
              ),
              child: Text(
                '$member_count명',
                style: AppTheme.body_small.copyWith(
                  color: AppTheme.primary_dark_color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            CupertinoButton(
              key: const ValueKey('group-calendar-management-button'),
              padding: const EdgeInsets.only(left: 6),
              minimumSize: const Size(34, 34),
              onPressed: _openManagement,
              child: const Icon(CupertinoIcons.ellipsis_circle, size: 21),
            ),
          ],
        ),
      ),
      child: SafeArea(
        minimum: const EdgeInsets.only(bottom: AppTheme.spacing_md),
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(GroupCalendarRangeState state) {
    if (state.group == null && state.is_loading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (state.group == null && state.last_error != null) {
      return _buildInitialError(state.last_error);
    }
    if (state.group == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _buildCalendar(state),
        const SizedBox(height: AppTheme.spacing_sm),
        Expanded(child: _buildSelectedDayDetail(state)),
      ],
    );
  }

  Widget _buildInitialError(Object? error) {
    final message = error is ApiException
        ? error.message
        : '그룹 캘린더를 불러오지 못했습니다.';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, textAlign: TextAlign.center),
          CupertinoButton(
            onPressed: () => ref
                .read(groupCalendarRangeProvider(widget.group_id).notifier)
                .ensureMonthLoaded(_focused_day),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(GroupCalendarRangeState state) {
    return CalendarViewport(
      focused_day: _focused_day,
      can_go_to_previous_month: _viewport_controller.canMoveMonth(
        _focused_day,
        -1,
      ),
      can_go_to_next_month: _viewport_controller.canMoveMonth(_focused_day, 1),
      onPreviousMonth: () => _moveMonth(-1),
      onNextMonth: () => _moveMonth(1),
      onSelectYearMonth: _showYearMonthPicker,
      header_key: const ValueKey('group-calendar-month-header'),
      trailing: CupertinoButton(
        key: const ValueKey('group-calendar-today-button'),
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
        calendar_key: const ValueKey('group-calendar'),
        focused_day: _focused_day,
        selected_day: _selected_day,
        calendar_format: _calendar_format,
        row_height: _calendar_row_height,
        days_of_week_height: 30,
        cell_layout: CalendarCellLayout.dots,
        day_key_prefix: 'group-day',
        selection_key_prefix: 'group-selection',
        day_presentation_builder: (date) {
          final shifts = state.shiftsFor(date);
          final events = state.eventsFor(date);
          final visible_colors = shifts
              .where(
                (shift) => shift.start_time != null && shift.end_time != null,
              )
              .map((shift) => shift.shift_type_color)
              .whereType<int>()
              .take(4)
              .map(Color.new)
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
                '${shifts.length}명 근무, 일정 ${events.length}개',
            indicator: visible_colors.isEmpty
                ? null
                : CalendarDotsIndicator(
                    colors: visible_colors,
                    key_prefix: 'group-shift',
                  ),
          );
        },
        onDaySelected: (selected_day, focused_day) {
          setState(() {
            _selected_day = _normalizeDate(selected_day);
            _focused_day = focused_day;
          });
        },
        onPageChanged: (focused_day) {
          setState(() => _focused_day = focused_day);
          ref
              .read(groupCalendarRangeProvider(widget.group_id).notifier)
              .ensureMonthLoaded(focused_day);
        },
      ),
    );
  }

  Widget _buildSelectedDayDetail(GroupCalendarRangeState state) {
    final shifts = state.shiftsFor(_selected_day);
    final events = state.eventsFor(_selected_day);
    return Container(
      key: const ValueKey('group-calendar-selected-day-detail'),
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing_md),
      decoration: AppTheme.cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
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
                      DateFormat('M월 d일 EEEE', 'ko_KR').format(_selected_day),
                      style: AppTheme.heading_small.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  CalendarScheduleSummaryChip(
                    label: '근무 ${shifts.length}명',
                    is_primary: true,
                  ),
                  const SizedBox(width: 6),
                  CalendarScheduleSummaryChip(label: '일정 ${events.length}개'),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              key: const ValueKey('group-calendar-member-list'),
              padding: const EdgeInsets.all(AppTheme.spacing_sm),
              itemCount: state.members.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final member = state.members[index];
                final member_shift = _shiftForMember(shifts, member.user_id);
                final member_events = events
                    .where((event) => event.owner_user_id == member.user_id)
                    .toList(growable: false);
                return _MemberDayCard(
                  member: member,
                  shift: member_shift,
                  events: member_events,
                  timezone: state.group!.timezone,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  GroupCalendarWorkShift? _shiftForMember(
    List<GroupCalendarWorkShift> shifts,
    String user_id,
  ) {
    for (final shift in shifts) {
      if (shift.owner_user_id == user_id) return shift;
    }
    return null;
  }

  void _moveMonth(int offset) {
    final month = _viewport_controller.monthAt(_focused_day, offset);
    if (month == null) return;
    setState(() => _focused_day = month);
    ref
        .read(groupCalendarRangeProvider(widget.group_id).notifier)
        .ensureMonthLoaded(month);
  }

  void _goToToday() {
    final today = _normalizeDate(DateTime.now());
    setState(() {
      _focused_day = today;
      _selected_day = today;
    });
    ref
        .read(groupCalendarRangeProvider(widget.group_id).notifier)
        .ensureMonthLoaded(today);
  }

  Future<void> _showYearMonthPicker() async {
    final selected = await showYearMonthPickerSheet(
      context: context,
      initial_date: _focused_day,
      first_year: _viewport_controller.first_year,
      last_year: _viewport_controller.last_year,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _focused_day = selected;
      _selected_day = selected;
    });
    ref
        .read(groupCalendarRangeProvider(widget.group_id).notifier)
        .ensureMonthLoaded(selected);
  }

  Future<void> _openManagement() async {
    final result = await Navigator.of(context).push<GroupManagementResult>(
      CupertinoPageRoute<GroupManagementResult>(
        builder: (context) => GroupManagementPage(group_id: widget.group_id),
      ),
    );
    if (!mounted) return;
    if (result == GroupManagementResult.membership_ended) {
      Navigator.of(context).pop();
      return;
    }
    await ref.read(groupDetailProvider(widget.group_id).notifier).load();
    await ref
        .read(groupCalendarRangeProvider(widget.group_id).notifier)
        .refreshMonth(_focused_day);
  }

  void _showNewErrorIfNeeded(GroupCalendarRangeState state) {
    if (state.last_error is ApiException &&
        (state.last_error! as ApiException).code == 'GROUP_NOT_FOUND') {
      return;
    }
    if (state.error_revision <= _shown_error_revision ||
        state.last_error == null ||
        state.group == null) {
      return;
    }
    _shown_error_revision = state.error_revision;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final error = state.last_error;
      final message = error is ApiException
          ? error.message
          : '그룹 캘린더를 불러오지 못했습니다.';
      showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('오류'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    });
  }

  void _handleGroupNotFound(Object? error) {
    if (_handled_group_not_found ||
        error is! ApiException ||
        error.code != 'GROUP_NOT_FOUND') {
      return;
    }
    _handled_group_not_found = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showCupertinoDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialog_context) => CupertinoAlertDialog(
          title: const Text('그룹을 열 수 없습니다'),
          content: const Text('그룹 정보를 확인할 수 없어 목록으로 돌아갑니다.'),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(dialog_context).pop();
                ref
                    .read(groupListProvider.notifier)
                    .removeGroup(widget.group_id);
                ref.read(groupListProvider.notifier).loadGroups();
                Navigator.of(context).maybePop();
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
    });
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

class _MemberDayCard extends StatelessWidget {
  const _MemberDayCard({
    required this.member,
    required this.shift,
    required this.events,
    required this.timezone,
  });

  final GroupCalendarMember member;
  final GroupCalendarWorkShift? shift;
  final List<GroupCalendarEvent> events;
  final String timezone;

  @override
  Widget build(BuildContext context) {
    final denied =
        member.calendar_access == CalendarAccess.denied ||
        member.calendar_access == CalendarAccess.unknown;
    final shift_color = shift?.shift_type_color == null
        ? AppTheme.surface_container_color
        : Color(shift!.shift_type_color!);
    return Container(
      key: ValueKey('group-calendar-member-${member.user_id}'),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(),
      child: denied ? _buildDenied() : _buildVisible(shift_color: shift_color),
    );
  }

  Widget _buildDenied() {
    return Row(
      children: [
        _avatar(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.name,
                style: AppTheme.body_medium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '캘린더 공개 안 함',
                style: AppTheme.body_small.copyWith(
                  color: AppTheme.on_surface_variant_color,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          CupertinoIcons.lock_fill,
          size: 18,
          color: AppTheme.outline_color,
        ),
      ],
    );
  }

  Widget _buildVisible({required Color shift_color}) {
    final description = shift == null
        ? '근무 없음'
        : '${shift!.shift_type_name} · ${_shiftTime(shift!)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _avatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body_medium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body_small.copyWith(
                      color: AppTheme.on_surface_variant_color,
                    ),
                  ),
                ],
              ),
            ),
            if (shift != null)
              Container(
                constraints: const BoxConstraints(minWidth: 36),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: shift_color,
                  borderRadius: BorderRadius.circular(AppTheme.radius_md),
                ),
                child: Text(
                  shift!.shift_type_code,
                  textAlign: TextAlign.center,
                  style: AppTheme.body_small.copyWith(
                    color: AppTheme.readableForegroundColor(
                      shift_color,
                      preferred_color: AppTheme.surface_color,
                    ),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        if (events.isNotEmpty) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var index = 0; index < events.length; index++) ...[
                  if (index > 0) const SizedBox(width: 6),
                  _eventChip(events[index]),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _avatar() {
    final color = _memberColor(member.user_id);
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        member.name.isEmpty ? '?' : member.name[0],
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _eventChip(GroupCalendarEvent event) {
    final location = tz.getLocation(timezone);
    final local_start = tz.TZDateTime.from(event.start_at, location);
    final time = event.all_day ? '종일' : DateFormat('HH:mm').format(local_start);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface_container_low_color,
        borderRadius: BorderRadius.circular(AppTheme.chip_radius),
      ),
      child: Text(
        '$time ${event.title}',
        style: AppTheme.body_small.copyWith(
          color: AppTheme.on_surface_variant_color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _shiftTime(GroupCalendarWorkShift value) {
    final start = value.start_time;
    final end = value.end_time;
    if (start == null || end == null) return '시간 없음';
    return '${start.substring(0, 5)}–${end.substring(0, 5)}';
  }

  Color _memberColor(String user_id) {
    const colors = [
      Color(0xFFFF9500),
      Color(0xFFE85F80),
      Color(0xFF4355B8),
      Color(0xFF448F53),
      Color(0xFF717782),
    ];
    return colors[user_id.hashCode.abs() % colors.length];
  }
}
