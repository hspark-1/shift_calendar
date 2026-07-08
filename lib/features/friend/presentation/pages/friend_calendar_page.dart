import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../calendar/data/models/event_api_model.dart';
import '../../../calendar/data/models/work_shift_api_model.dart';
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

  void _moveToMonth(DateTime focusedMonth) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _focusedDay = focusedMonth);
      _loadCalendarData(focusedMonth);
    });
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
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.friend.name),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _navigateToSettings,
          child: const Icon(CupertinoIcons.gear),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildFriendHeader(),
            _buildMonthHeader(),
            _buildCalendar(),
            const SizedBox(height: 12),
            Flexible(child: _buildSelectedDaySchedule()),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CupertinoColors.systemGrey5,
              image: widget.friend.profileImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(widget.friend.profileImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: widget.friend.profileImageUrl == null
                ? const Icon(
                    CupertinoIcons.person_fill,
                    size: 22,
                    color: CupertinoColors.systemGrey2,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.friend.name,
                  style: AppTheme.body_medium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: CupertinoColors.label,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.friend.email,
                  style: AppTheme.body_small.copyWith(
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    final yearMonth = DateFormat('yyyy.MM', 'ko_KR').format(_focusedDay);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _canGoToPreviousMonth() ? _goToPreviousMonth : null,
            child: Icon(
              CupertinoIcons.chevron_left,
              size: 20,
              color: _canGoToPreviousMonth()
                  ? CupertinoColors.label
                  : CupertinoColors.systemGrey3,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                yearMonth,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: CupertinoColors.label,
                ),
              ),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _canGoToNextMonth() ? _goToNextMonth : null,
            child: Icon(
              CupertinoIcons.chevron_right,
              size: 20,
              color: _canGoToNextMonth()
                  ? CupertinoColors.label
                  : CupertinoColors.systemGrey3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Stack(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2000, 1, 1),
          lastDay: DateTime.utc(2050, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.month,
          locale: 'ko_KR',
          headerVisible: false,
          daysOfWeekHeight: 32,
          rowHeight: 62,
          availableGestures: AvailableGestures.horizontalSwipe,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            _loadCalendarData(focusedDay);
          },
          onPageChanged: (focusedDay) {
            setState(() => _focusedDay = focusedDay);
            _loadCalendarData(focusedDay);
          },
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: AppTheme.body_small.copyWith(
              color: CupertinoColors.label,
              fontWeight: FontWeight.w600,
            ),
            weekendStyle: AppTheme.body_small.copyWith(
              color: CupertinoColors.systemRed,
              fontWeight: FontWeight.w600,
            ),
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: true,
            selectedDecoration: const BoxDecoration(
              color: AppTheme.primary_color,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: const TextStyle(
              color: CupertinoColors.white,
              fontWeight: FontWeight.bold,
            ),
            todayDecoration: BoxDecoration(
              color: AppTheme.primary_color.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            todayTextStyle: const TextStyle(
              color: AppTheme.primary_color,
              fontWeight: FontWeight.bold,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            dowBuilder: (context, day) {
              final isWeekend =
                  day.weekday == DateTime.saturday ||
                  day.weekday == DateTime.sunday;
              return Center(
                child: Text(
                  DateFormat('E', 'ko_KR').format(day),
                  style: AppTheme.body_small.copyWith(
                    color: isWeekend
                        ? CupertinoColors.systemRed
                        : CupertinoColors.label,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
            defaultBuilder: (context, date, focusedDay) {
              return _buildDayCell(date: date);
            },
            outsideBuilder: (context, date, focusedDay) {
              return _buildDayCell(date: date, isOutside: true);
            },
            todayBuilder: (context, date, focusedDay) {
              return _buildDayCell(date: date, isToday: true);
            },
            selectedBuilder: (context, date, focusedDay) {
              return _buildDayCell(date: date, isSelected: true);
            },
          ),
        ),
        if (_isLoading)
          const Positioned(
            top: 4,
            right: 16,
            child: CupertinoActivityIndicator(radius: 8),
          ),
      ],
    );
  }

  Widget _buildDayCell({
    required DateTime date,
    bool isToday = false,
    bool isSelected = false,
    bool isOutside = false,
  }) {
    final workShift = _getWorkShiftForDay(date);
    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    final outsideAlpha = isOutside ? 0.35 : 1.0;
    final textColor = isSelected
        ? CupertinoColors.white
        : isWeekend
        ? CupertinoColors.systemRed
        : isToday
        ? AppTheme.primary_color
        : CupertinoColors.label;

    return SizedBox(
      height: 58,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary_color
                  : isToday
                  ? AppTheme.primary_color.withValues(alpha: 0.25)
                  : null,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: textColor.withValues(alpha: outsideAlpha),
                  fontSize: 14,
                  fontWeight: isToday || isSelected ? FontWeight.bold : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 18,
            child: workShift == null
                ? null
                : _buildShiftCodeBadge(workShift, outsideAlpha),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftCodeBadge(WorkShiftApiModel workShift, double alpha) {
    final color = Color(workShift.shiftTypeColor ?? 0xFF8E8E93);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 48),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: alpha),
          borderRadius: BorderRadius.circular(4),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            workShift.shiftTypeCode,
            style: TextStyle(
              color: CupertinoColors.white.withValues(alpha: alpha),
              fontSize: 10,
              fontWeight: FontWeight.w700,
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.systemGrey5,
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
                        color: CupertinoColors.systemGrey,
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
        borderRadius: BorderRadius.circular(8),
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
                    color: CupertinoColors.label,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeText,
                  style: AppTheme.body_small.copyWith(
                    color: CupertinoColors.secondaryLabel,
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
      return workShift.shiftTypeCode;
    }
    return '${workShift.startTime} - ${workShift.endTime}';
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
        borderRadius: BorderRadius.circular(8),
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
                    color: CupertinoColors.label,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      timeText,
                      style: AppTheme.body_small.copyWith(
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                    if (event.place != null && event.place!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          event.place!,
                          style: AppTheme.body_small.copyWith(
                            color: CupertinoColors.secondaryLabel,
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
                      color: CupertinoColors.secondaryLabel,
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
    return Center(
      child: Text(
        '등록된 일정이 없습니다',
        style: AppTheme.body_medium.copyWith(
          color: CupertinoColors.systemGrey2,
        ),
      ),
    );
  }
}
