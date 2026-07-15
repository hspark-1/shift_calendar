// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/korean_holidays.dart';
import '../../../calendar/data/models/event_api_model.dart';
import '../../../calendar/data/models/work_shift_api_model.dart';
import '../../../calendar/presentation/widgets/calendar_month_view.dart';
import '../../../calendar/presentation/widgets/calendar_schedule_card.dart';
import '../../../calendar/presentation/widgets/year_month_picker_sheet.dart';
import '../../data/models/friend_model.dart';
import '../../data/services/friend_service.dart';
import 'friend_detail_page.dart';

/// 친구 캘린더 조회 페이지
class FriendCalendarPage extends ConsumerStatefulWidget {
  final FriendModel friend;

  const FriendCalendarPage({super.key, required this.friend});

  @override
  ConsumerState<FriendCalendarPage> createState() => _FriendCalendarPageState();
}

class _FriendCalendarPageState extends ConsumerState<FriendCalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _isLoading = false;

  final Map<DateTime, WorkShiftApiModel> _workShifts = {};
  final Map<DateTime, List<EventApiModel>> _events = {};
  final Set<String> _loadedMonths = {};

  bool get _isShortScreen => MediaQuery.sizeOf(context).height < 750;

  CalendarFormat get _visibleCalendarFormat =>
      _isShortScreen ? CalendarFormat.twoWeeks : CalendarFormat.month;

  double get _calendarRowHeight {
    return _isShortScreen ? 52 : 56;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCalendarData(_focusedDay);
      _loadHolidays(_focusedDay);
    });
  }

  DateTime _normalizeDate(DateTime date) {
    return normalizeCalendarDate(date);
  }

  String _getMonthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
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

  ({DateTime startDate, DateTime endDate}) _calculateThreeMonthRange(
    DateTime focusedMonth,
  ) {
    final startDate = DateTime(focusedMonth.year, focusedMonth.month - 1, 1);
    final endDate = DateTime(focusedMonth.year, focusedMonth.month + 2, 0);
    return (startDate: startDate, endDate: endDate);
  }

  Future<void> _loadCalendarData(DateTime focusedMonth) async {
    final monthKey = _getMonthKey(focusedMonth);
    if (_loadedMonths.contains(monthKey) || _isLoading) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final range = _calculateThreeMonthRange(focusedMonth);
      final response = await ref
          .read(friendServiceProvider)
          .getFriendCalendarRange(
            friendUserId: widget.friend.userId,
            startDate: range.startDate,
            endDate: range.endDate,
          );

      if (!mounted) return;

      setState(() {
        for (final workShift in response.data.workShifts) {
          _workShifts[_normalizeDate(workShift.workDate)] = workShift;
        }

        for (final event in response.data.events) {
          addEventToCalendarDateMap(_events, event);
        }

        _loadedMonths.add(_getMonthKey(range.startDate));
        _loadedMonths.add(_getMonthKey(focusedMonth));
        _loadedMonths.add(_getMonthKey(range.endDate));
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      _showErrorDialog(_getErrorMessage(error));
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is ApiException) {
      return error.message;
    }
    return '캘린더를 불러오지 못했습니다.';
  }

  WorkShiftApiModel? _getWorkShiftForDay(DateTime day) {
    return _workShifts[_normalizeDate(day)];
  }

  List<EventApiModel> _getEventsForDay(DateTime day) {
    return _events[_normalizeDate(day)] ?? const [];
  }

  bool _canGoToPreviousMonth() {
    final previousMonth = DateTime(_focusedDay.year, _focusedDay.month - 1);
    return previousMonth.year > 2000 ||
        (previousMonth.year == 2000 && previousMonth.month >= 1);
  }

  bool _canGoToNextMonth() {
    final nextMonth = DateTime(_focusedDay.year, _focusedDay.month + 1);
    return nextMonth.year < 2050 ||
        (nextMonth.year == 2050 && nextMonth.month <= 12);
  }

  void _goToPreviousMonth() {
    if (!_canGoToPreviousMonth()) return;
    _moveToMonth(DateTime(_focusedDay.year, _focusedDay.month - 1, 1));
  }

  void _goToNextMonth() {
    if (!_canGoToNextMonth()) return;
    _moveToMonth(DateTime(_focusedDay.year, _focusedDay.month + 1, 1));
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
    final wasDeleted = await Navigator.of(context).push<bool>(
      CupertinoPageRoute<bool>(
        builder: (context) => FriendDetailPage(friend: widget.friend),
      ),
    );
    if (!mounted || wasDeleted != true) return;

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
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
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background_color,
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.friend.name),
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
            _buildCalendarSection(),
            const SizedBox(height: AppTheme.spacing_sm),
            Flexible(child: _buildSelectedDaySchedule()),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [_buildMonthHeader(), _buildCalendar()],
    );
  }

  Widget _buildMonthHeader() {
    return CalendarMonthHeader(
      focused_day: _focusedDay,
      can_go_to_previous_month: _canGoToPreviousMonth(),
      can_go_to_next_month: _canGoToNextMonth(),
      onPreviousMonth: _goToPreviousMonth,
      onNextMonth: _goToNextMonth,
      onSelectYearMonth: _showYearMonthPicker,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLoading) ...[
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
    );
  }

  Widget _buildCalendar() {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final is_horizontal = notification.metrics.axis == Axis.horizontal;
        return is_horizontal &&
            (notification is ScrollStartNotification ||
                notification is ScrollUpdateNotification);
      },
      child: CalendarMonthView(
        calendar_key: const ValueKey('friend-calendar'),
        focused_day: _focusedDay,
        selected_day: _selectedDay,
        calendar_format: _visibleCalendarFormat,
        row_height: _calendarRowHeight,
        date_color_builder: _getCalendarDateColor,
        day_badge_builder: (date) {
          final work_shift = _getWorkShiftForDay(date);
          if (work_shift == null) return null;
          return CalendarDayBadgeData(
            text: work_shift.shiftTypeCode,
            color: Color(work_shift.shiftTypeColor ?? 0xFF8E8E93),
          );
        },
        show_day_badge: true,
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
