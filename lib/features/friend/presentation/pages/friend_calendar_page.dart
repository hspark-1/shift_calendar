// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../calendar/data/models/event_api_model.dart';
import '../../../calendar/data/models/work_shift_api_model.dart';
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
    });
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _getMonthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
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
          final startDate = _normalizeDate(event.startAt);
          final endDate = _normalizeDate(event.endAt);
          var currentDate = startDate;

          while (currentDate.isBefore(endDate) ||
              currentDate.isAtSameMomentAs(endDate)) {
            final eventList = _events.putIfAbsent(currentDate, () => []);
            if (!eventList.any((item) => item.eventId == event.eventId)) {
              eventList.add(event);
            }
            currentDate = currentDate.add(const Duration(days: 1));
          }
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
  }

  void _moveToMonth(DateTime focusedMonth) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _focusedDay = focusedMonth);
      _loadCalendarData(focusedMonth);
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
    final yearMonth = DateFormat('yyyy.MM', 'ko_KR').format(_focusedDay);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _canGoToPreviousMonth() ? _goToPreviousMonth : null,
            child: Icon(
              CupertinoIcons.chevron_left,
              size: 20,
              color: _canGoToPreviousMonth()
                  ? AppTheme.on_surface_color
                  : AppTheme.outline_variant_color,
            ),
          ),
          GestureDetector(
            onTap: _showYearMonthPicker,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(yearMonth, style: AppTheme.heading_medium),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.surface_container_low_color,
                    borderRadius: BorderRadius.circular(AppTheme.radius_md),
                  ),
                  child: const Icon(
                    CupertinoIcons.chevron_down,
                    size: 12,
                    color: AppTheme.on_surface_variant_color,
                  ),
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _canGoToNextMonth() ? _goToNextMonth : null,
            child: Icon(
              CupertinoIcons.chevron_right,
              size: 20,
              color: _canGoToNextMonth()
                  ? AppTheme.on_surface_color
                  : AppTheme.outline_variant_color,
            ),
          ),
          const Spacer(),
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
      child: TableCalendar(
        key: const ValueKey('friend-calendar'),
        firstDay: DateTime.utc(2000, 1, 1),
        lastDay: DateTime.utc(2050, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _visibleCalendarFormat,
        locale: 'ko_KR',
        headerVisible: false,
        daysOfWeekHeight: 32,
        rowHeight: _calendarRowHeight,
        availableGestures: AvailableGestures.horizontalSwipe,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selected_day, focused_day) {
          setState(() {
            _selectedDay = selected_day;
            _focusedDay = focused_day;
          });
          _loadCalendarData(focused_day);
        },
        onPageChanged: (focused_day) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _focusedDay = focused_day);
            _loadCalendarData(focused_day);
          });
        },
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: AppTheme.body_small.copyWith(
            color: AppTheme.on_surface_color,
            fontWeight: FontWeight.w600,
          ),
          weekendStyle: AppTheme.body_small.copyWith(
            color: AppTheme.accent_red_color,
            fontWeight: FontWeight.w600,
          ),
        ),
        calendarStyle: CalendarStyle(
          tablePadding: const EdgeInsets.only(bottom: AppTheme.spacing_sm),
          cellMargin: const EdgeInsets.all(2),
          markersAlignment: Alignment.bottomCenter,
          outsideDaysVisible: true,
          outsideTextStyle: TextStyle(
            color: AppTheme.on_surface_color.withValues(alpha: 0.25),
          ),
          defaultTextStyle: const TextStyle(color: AppTheme.on_surface_color),
        ),
        calendarBuilders: CalendarBuilders(
          dowBuilder: (context, day) {
            final text_color = day.weekday == DateTime.sunday
                ? AppTheme.accent_red_color
                : day.weekday == DateTime.saturday
                ? AppTheme.primary_color
                : AppTheme.on_surface_variant_color;
            return Center(
              child: Text(
                DateFormat('E', 'ko_KR').format(day),
                style: AppTheme.body_small.copyWith(
                  color: text_color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
          defaultBuilder: (context, date, focused_day) {
            return _buildDayCell(
              date: date,
              text_color: _getCalendarDateColor(date),
            );
          },
          outsideBuilder: (context, date, focused_day) {
            return _buildDayCell(
              date: date,
              text_color: _getCalendarDateColor(date),
              is_outside: true,
            );
          },
          todayBuilder: (context, date, focused_day) {
            return _buildDayCell(
              date: date,
              text_color: _getCalendarDateColor(date),
              is_today: true,
            );
          },
          selectedBuilder: (context, date, focused_day) {
            return _buildDayCell(
              date: date,
              text_color: _getCalendarDateColor(date),
              is_today: isSameDay(date, DateTime.now()),
              is_selected: true,
            );
          },
        ),
      ),
    );
  }

  Widget _buildDayCell({
    required DateTime date,
    required Color text_color,
    bool is_today = false,
    bool is_selected = false,
    bool is_outside = false,
  }) {
    final work_shift = _getWorkShiftForDay(date);
    final outside_alpha = is_outside ? 0.4 : 1.0;
    final date_text_color = is_selected || is_today
        ? AppTheme.primary_color
        : text_color.withValues(alpha: outside_alpha);
    final date_text = Text(
      '${date.day}',
      style: TextStyle(
        color: date_text_color,
        fontSize: 14,
        fontWeight: is_selected || is_today
            ? FontWeight.w700
            : FontWeight.normal,
      ),
    );
    final date_indicator = is_today
        ? SizedBox(
            width: 28,
            height: 28,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                date_text,
                const SizedBox(height: 1),
                Container(
                  width: 12,
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppTheme.primary_color,
                    borderRadius: BorderRadius.circular(AppTheme.radius_sm),
                  ),
                ),
              ],
            ),
          )
        : date_text;

    final cell_content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 28, child: Center(child: date_indicator)),
        const SizedBox(height: 2),
        SizedBox(
          height: 16,
          child: work_shift == null
              ? null
              : _buildShiftCodeBadge(work_shift, outside_alpha),
        ),
      ],
    );

    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Transform.translate(
            offset: const Offset(0, 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOut,
              width: is_selected ? 58 : 0,
              height: is_selected ? 58 : 0,
              decoration: BoxDecoration(
                color: is_selected
                    ? AppTheme.primary_color.withValues(alpha: 0.08)
                    : null,
                borderRadius: BorderRadius.circular(AppTheme.radius_md),
                border: is_selected
                    ? Border.all(
                        color: AppTheme.primary_color.withValues(alpha: 0.24),
                      )
                    : null,
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: cell_content,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCalendarDateColor(DateTime date) {
    if (date.weekday == DateTime.sunday) {
      return AppTheme.accent_red_color;
    }
    if (date.weekday == DateTime.saturday) {
      return AppTheme.primary_color;
    }
    return AppTheme.on_surface_color;
  }

  Widget _buildShiftCodeBadge(WorkShiftApiModel workShift, double alpha) {
    final color = Color(workShift.shiftTypeColor ?? 0xFF8E8E93);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 44),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: alpha),
          borderRadius: BorderRadius.circular(AppTheme.radius_sm),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            workShift.shiftTypeCode,
            style: TextStyle(
              color: CupertinoColors.white.withValues(alpha: alpha),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDaySchedule() {
    final selectedDate = _normalizeDate(_selectedDay);
    final dateText = DateFormat('yyyy.MM.dd', 'ko_KR').format(selectedDate);
    final workShift = _getWorkShiftForDay(selectedDate);
    final events = _getEventsForDay(selectedDate);
    final totalCount = (workShift == null ? 0 : 1) + events.length;

    return Container(
      key: const ValueKey('friend-selected-day-schedule-card'),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: AppTheme.cardDecoration(),
      child: ClipRRect(
        borderRadius: AppTheme.card_border_radius,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.outline_variant_color,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(dateText, style: AppTheme.heading_small),
                  const Spacer(),
                  if (totalCount > 0)
                    Text(
                      '$totalCount개의 일정',
                      style: AppTheme.body_small.copyWith(
                        color: AppTheme.on_surface_variant_color,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: totalCount == 0
                  ? _buildEmptySchedule()
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          if (workShift != null) _buildWorkShiftItem(workShift),
                          ...events.map(_buildEventItem),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkShiftItem(WorkShiftApiModel workShift) {
    final color = Color(workShift.shiftTypeColor ?? 0xFF8E8E93);
    final timeText = _formatShiftTime(workShift);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppTheme.input_border_radius,
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workShift.shiftTypeName,
                  style: AppTheme.body_medium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.on_surface_color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeText,
                  style: AppTheme.body_small.copyWith(
                    color: AppTheme.on_surface_variant_color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatShiftTime(WorkShiftApiModel workShift) {
    if (workShift.startTime == null || workShift.endTime == null) {
      return '근무없음';
    }
    return '${_formatApiTime(workShift.startTime!)} ~ ${_formatApiTime(workShift.endTime!)}';
  }

  String _formatApiTime(String time) {
    return time.length >= 5 ? time.substring(0, 5) : time;
  }

  Widget _buildEventItem(EventApiModel event) {
    final timeText = event.allDay
        ? '종일'
        : '${DateFormat('HH:mm', 'ko_KR').format(event.startAt)} - ${DateFormat('HH:mm', 'ko_KR').format(event.endAt)}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primary_color.withValues(alpha: 0.08),
        borderRadius: AppTheme.input_border_radius,
        border: const Border(
          left: BorderSide(color: AppTheme.primary_color, width: 4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppTheme.primary_color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: AppTheme.body_medium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.on_surface_color,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      timeText,
                      style: AppTheme.body_small.copyWith(
                        color: AppTheme.on_surface_variant_color,
                      ),
                    ),
                    if (event.place != null && event.place!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '• ${event.place}',
                          style: AppTheme.body_small.copyWith(
                            color: AppTheme.on_surface_variant_color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                if (event.memo != null && event.memo!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    event.memo!,
                    style: AppTheme.body_small.copyWith(
                      color: AppTheme.on_surface_variant_color,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySchedule() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.calendar,
            size: 32,
            color: AppTheme.outline_variant_color,
          ),
          const SizedBox(height: 6),
          Text(
            '등록된 일정이 없습니다',
            style: AppTheme.body_medium.copyWith(
              color: AppTheme.on_surface_variant_color,
            ),
          ),
        ],
      ),
    );
  }
}
