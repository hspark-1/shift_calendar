// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/korean_holidays.dart';
import '../../../calendar/application/calendar_range_state.dart';
import '../../../calendar/data/models/event_api_model.dart';
import '../../../calendar/data/models/work_shift_api_model.dart';
import '../../../calendar/presentation/controllers/calendar_viewport_controller.dart';
import '../../../calendar/presentation/models/calendar_day_presentation.dart';
import '../../../calendar/presentation/models/calendar_layout_policy.dart';
import '../../../calendar/presentation/widgets/calendar_month_view.dart';
import '../../../calendar/presentation/widgets/calendar_schedule_card.dart';
import '../../../calendar/presentation/widgets/calendar_viewport.dart';
import '../../../calendar/presentation/widgets/year_month_picker_sheet.dart';
import '../../data/models/friend_model.dart';
import '../providers/friend_calendar_range_provider.dart';
import '../providers/friend_provider.dart';
import 'friend_detail_page.dart';

/// 친구 캘린더 조회 페이지
class FriendCalendarPage extends ConsumerStatefulWidget {
  final FriendModel friend;

  const FriendCalendarPage({super.key, required this.friend});

  @override
  ConsumerState<FriendCalendarPage> createState() => _FriendCalendarPageState();
}

class _FriendCalendarPageState extends ConsumerState<FriendCalendarPage> {
  static final _viewport_controller = const CalendarViewportController();

  late FriendModel _friend;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  CalendarFormat get _visibleCalendarFormat =>
      CalendarLayoutPolicy.visibleFormat(
        screen_height: MediaQuery.sizeOf(context).height,
        preferred_format: CalendarFormat.month,
      );

  double get _calendarRowHeight => CalendarLayoutPolicy.rowHeight(
    screen_height: MediaQuery.sizeOf(context).height,
    layout_mode: CalendarCellLayoutMode.detailed,
  );

  @override
  void initState() {
    super.initState();
    _friend = widget.friend;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCalendarData(_focusedDay);
      _loadHolidays(_focusedDay);
    });
  }

  DateTime _normalizeDate(DateTime date) {
    return normalizeCalendarDate(date);
  }

  Future<void> _loadHolidays(DateTime focused_day) async {
    try {
      await KoreanHolidays.getHolidaysForYear(
        focused_day.year,
        month: focused_day.month,
      );
      if (mounted) setState(() {});
    } catch (error) {
      debugPrint('친구 캘린더 공휴일 로딩 실패: $error');
    }
  }

  bool _isHoliday(DateTime date) {
    return KoreanHolidays.isFixedHoliday(date);
  }

  Future<void> _loadCalendarData(DateTime focusedMonth) {
    return ref
        .read(friendCalendarRangeProvider(_friend.userId).notifier)
        .ensureMonthLoaded(focusedMonth);
  }

  String _getErrorMessage(dynamic error) {
    if (error is ApiException) {
      return error.message;
    }
    return '캘린더를 불러오지 못했습니다.';
  }

  WorkShiftApiModel? _getWorkShiftForDay(DateTime day) {
    return ref
        .read(friendCalendarRangeProvider(_friend.userId))
        .workShiftFor(day);
  }

  List<EventApiModel> _getEventsForDay(DateTime day) {
    return ref.read(friendCalendarRangeProvider(_friend.userId)).eventsFor(day);
  }

  bool _canGoToPreviousMonth() {
    return _viewport_controller.canMoveMonth(_focusedDay, -1);
  }

  bool _canGoToNextMonth() {
    return _viewport_controller.canMoveMonth(_focusedDay, 1);
  }

  void _goToPreviousMonth() {
    final previous_month = _viewport_controller.monthAt(_focusedDay, -1);
    if (previous_month == null) return;
    _moveToMonth(previous_month);
  }

  void _goToNextMonth() {
    final next_month = _viewport_controller.monthAt(_focusedDay, 1);
    if (next_month == null) return;
    _moveToMonth(next_month);
  }

  void _goToToday() {
    final today = _normalizeDate(DateTime.now());
    setState(() {
      _selectedDay = today;
      _focusedDay = today;
    });
    _loadCalendarData(today);
    _loadHolidays(today);
  }

  void _moveToMonth(DateTime focusedMonth) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _focusedDay = focusedMonth);
      _loadCalendarData(focusedMonth);
      _loadHolidays(focusedMonth);
    });
  }

  Future<void> _showYearMonthPicker() async {
    final selected_date = await showYearMonthPickerSheet(
      context: context,
      initial_date: _focusedDay,
      first_year: 2000,
      last_year: 2050,
    );

    if (selected_date == null || !mounted) return;
    _moveToMonth(selected_date);
  }

  Future<void> _navigateToSettings() async {
    final result = await Navigator.of(context).push<FriendDetailResult>(
      CupertinoPageRoute<FriendDetailResult>(
        builder: (context) => FriendDetailPage(friend: _friend),
      ),
    );
    if (!mounted || result == null) return;

    if (result == FriendDetailResult.deleted) {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      }
      return;
    }

    await _refreshFriend();
  }

  Future<void> _refreshFriend() async {
    await ref.read(friendListProvider.notifier).loadFriends();
    if (!mounted) return;

    final friends = ref.read(friendListProvider).friends;
    for (final friend in friends) {
      if (friend.userId == _friend.userId) {
        setState(() => _friend = friend);
        return;
      }
    }
  }

  void _showErrorDialog(String message) {
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
  }

  @override
  Widget build(BuildContext context) {
    final calendar_range_state = ref.watch(
      friendCalendarRangeProvider(_friend.userId),
    );
    ref.listen<CalendarRangeState>(
      friendCalendarRangeProvider(_friend.userId),
      (previous, next) {
        if (next.last_error == null ||
            previous?.error_revision == next.error_revision) {
          return;
        }
        _showErrorDialog(_getErrorMessage(next.last_error));
      },
    );

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background_color,
      navigationBar: CupertinoNavigationBar(
        middle: Text(_friend.name),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _navigateToSettings,
          child: const Icon(CupertinoIcons.gear),
        ),
      ),
      child: SafeArea(
        minimum: const EdgeInsets.only(bottom: AppTheme.spacing_md),
        child: Column(
          children: [
            _buildCalendarSection(calendar_range_state),
            const SizedBox(height: AppTheme.spacing_sm),
            Flexible(child: _buildSelectedDaySchedule()),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarSection(CalendarRangeState calendar_range_state) {
    return CalendarViewport(
      focused_day: _focusedDay,
      can_go_to_previous_month: _canGoToPreviousMonth(),
      can_go_to_next_month: _canGoToNextMonth(),
      onPreviousMonth: _goToPreviousMonth,
      onNextMonth: _goToNextMonth,
      onSelectYearMonth: _showYearMonthPicker,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (calendar_range_state.is_loading) ...[
            const CupertinoActivityIndicator(radius: 8),
            const SizedBox(width: AppTheme.spacing_sm),
          ],
          CupertinoButton(
            key: const ValueKey('friend-calendar-today-button'),
            minimumSize: const Size(44, 32),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: AppTheme.primary_color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppTheme.chip_radius),
            onPressed: _goToToday,
            child: Text(
              '오늘',
              style: AppTheme.body_small.copyWith(
                color: AppTheme.primary_color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      month_view: CalendarMonthView<dynamic>(
        calendar_key: const ValueKey('friend-calendar'),
        focused_day: _focusedDay,
        selected_day: _selectedDay,
        calendar_format: _visibleCalendarFormat,
        row_height: _calendarRowHeight,
        cell_layout: CalendarCellLayout.badge,
        day_presentation_builder: (date) {
          final work_shift = _getWorkShiftForDay(date);
          return CalendarDayPresentation(
            date_color: _getCalendarDateColor(date),
            indicator: work_shift == null
                ? null
                : CalendarBadgeIndicator(
                    text: work_shift.shiftTypeCode,
                    color: Color(work_shift.shiftTypeColor ?? 0xFF8E8E93),
                  ),
          );
        },
        holiday_predicate: _isHoliday,
        onDaySelected: (selected_day, focused_day) {
          setState(() {
            _selectedDay = selected_day;
            _focusedDay = focused_day;
          });
          _loadCalendarData(focused_day);
          _loadHolidays(focused_day);
        },
        onPageChanged: (focused_day) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _focusedDay = focused_day);
            _loadCalendarData(focused_day);
            _loadHolidays(focused_day);
          });
        },
      ),
    );
  }

  Color _getCalendarDateColor(DateTime date) {
    if (_isHoliday(date) || date.weekday == DateTime.sunday) {
      return AppTheme.accent_red_color;
    }
    if (date.weekday == DateTime.saturday) {
      return AppTheme.primary_color;
    }
    return AppTheme.on_surface_color;
  }

  Widget _buildSelectedDaySchedule() {
    final selectedDate = _normalizeDate(_selectedDay);
    final workShift = _getWorkShiftForDay(selectedDate);
    final events = _getEventsForDay(selectedDate);
    final holiday_name = _isHoliday(selectedDate)
        ? KoreanHolidays.getHolidayName(selectedDate) ?? '공휴일'
        : null;

    return CalendarScheduleCard(
      key: const ValueKey('friend-selected-day-schedule-card'),
      selected_date: selectedDate,
      work_shift: workShift,
      events: events,
      holiday_name: holiday_name,
    );
  }
}
