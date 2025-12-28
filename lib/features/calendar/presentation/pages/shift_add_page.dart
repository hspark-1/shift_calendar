import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../widgets/shift_badge.dart';
import '../widgets/bottom_action_bar.dart';
import '../widgets/shift_type_button.dart';

/// 근무 추가 페이지
class ShiftAddPage extends ConsumerStatefulWidget {
  const ShiftAddPage({
    super.key,
    required this.initial_date,
    this.existing_schedules,
  });

  final DateTime initial_date;
  final Map<DateTime, String>? existing_schedules;

  @override
  ConsumerState<ShiftAddPage> createState() => _ShiftAddPageState();
}

class _ShiftAddPageState extends ConsumerState<ShiftAddPage> {
  late DateTime _focused_day;
  late DateTime _selected_day;
  late Map<DateTime, String> _schedules;

  @override
  void initState() {
    super.initState();
    _focused_day = widget.initial_date;
    _selected_day = widget.initial_date;
    _schedules = Map.from(widget.existing_schedules ?? {});
  }

  /// 날짜 정규화 (시간 제거)
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// 선택된 날짜의 스케줄 반환
  String? _getScheduleForDay(DateTime day) {
    return _schedules[_normalizeDate(day)];
  }

  /// 이전 달로 이동
  void _goToPreviousMonth() {
    setState(() {
      _focused_day = DateTime(_focused_day.year, _focused_day.month - 1, 1);
    });
  }

  /// 다음 달로 이동
  void _goToNextMonth() {
    setState(() {
      _focused_day = DateTime(_focused_day.year, _focused_day.month + 1, 1);
    });
  }

  /// 연/월 선택 피커 표시
  void _showYearMonthPicker() {
    int selected_year = _focused_day.year;
    int selected_month = _focused_day.month;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // 헤더
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Text('취소'),
                  ),
                  const Text(
                    '연도/월 선택',
                    style: AppTheme.heading_small,
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        _focused_day = DateTime(selected_year, selected_month, 1);
                      });
                      Navigator.pop(context);
                    },
                    child: const Text(
                      '확인',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            // 피커
            Expanded(
              child: Row(
                children: [
                  // 연도 피커
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                        initialItem: selected_year - 2020,
                      ),
                      itemExtent: 40,
                      onSelectedItemChanged: (index) {
                        selected_year = 2020 + index;
                      },
                      children: List.generate(
                        21, // 2020 ~ 2040
                        (index) => Center(
                          child: Text(
                            '${2020 + index}년',
                            style: AppTheme.body_large,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 월 피커
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                        initialItem: selected_month - 1,
                      ),
                      itemExtent: 40,
                      onSelectedItemChanged: (index) {
                        selected_month = index + 1;
                      },
                      children: List.generate(
                        12,
                        (index) => Center(
                          child: Text(
                            '${index + 1}월',
                            style: AppTheme.body_large,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 다음 날로 이동
  void _moveToNextDay() {
    final next_day = _selected_day.add(const Duration(days: 1));
    setState(() {
      _selected_day = next_day;
      // 다음 달로 넘어가면 포커스도 변경
      if (next_day.month != _focused_day.month) {
        _focused_day = next_day;
      }
    });
  }

  /// 근무 유형 선택 처리
  void _onShiftSelected(String shift_code) {
    setState(() {
      _schedules[_normalizeDate(_selected_day)] = shift_code;
    });
    // 선택 후 자동으로 다음 날로 이동
    _moveToNextDay();
  }

  /// 완료 버튼 처리
  void _onComplete() {
    Navigator.pop(context, _schedules);
  }

  @override
  Widget build(BuildContext context) {
    final current_shift = _getScheduleForDay(_selected_day);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('캘린더'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _onComplete,
          child: const Text(
            '완료',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // 년/월 헤더
                  _buildMonthHeader(),
                  // 캘린더 위젯
                  _buildCalendar(),
                  const SizedBox(height: 12),
                  // 선택된 날짜 정보
                  _buildSelectedDateInfo(),
                  const SizedBox(height: 12),
                  // 근무 유형 선택 버튼
                  _buildShiftTypeSelector(current_shift),
                ],
              ),
            ),
          ),
          // 하단 간격
          const SizedBox(height: 8),
          // 하단 액션 바
          BottomActionBar(
            mode: BottomActionBarMode.add,
            onMemoTap: () {
              // TODO: 시간 설정 기능
            },
            onCalendarTap: () {
              // 오늘 날짜로 이동
              setState(() {
                _focused_day = DateTime.now();
                _selected_day = DateTime.now();
              });
            },
            onNotificationTap: () {
              // TODO: 알림 설정 기능
            },
          ),
        ],
      ),
    );
  }

  /// 년/월 헤더 위젯
  Widget _buildMonthHeader() {
    final year_month = DateFormat('yyyy.M', 'ko_KR').format(_focused_day);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _goToPreviousMonth,
            child: const Icon(
              CupertinoIcons.chevron_left,
              size: 20,
              color: CupertinoColors.label,
            ),
          ),
          GestureDetector(
            onTap: _showYearMonthPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    year_month,
                    style: AppTheme.heading_medium,
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    CupertinoIcons.chevron_down,
                    size: 16,
                    color: CupertinoColors.label,
                  ),
                ],
              ),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _goToNextMonth,
            child: const Icon(
              CupertinoIcons.chevron_right,
              size: 20,
              color: CupertinoColors.label,
            ),
          ),
          const Spacer(),
          // + 버튼 (현재 선택된 날짜부터 추가 모드 시작)
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: () {
              // 현재 선택된 날짜에서 연속 입력 시작
              // 이미 연속 입력 모드이므로 별도 동작 없음
            },
            child: const Icon(
              CupertinoIcons.add,
              color: AppTheme.primary_color,
            ),
          ),
        ],
      ),
    );
  }

  /// 캘린더 위젯
  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focused_day,
      calendarFormat: CalendarFormat.month,
      locale: 'ko_KR',
      headerVisible: false,
      daysOfWeekHeight: 32,
      rowHeight: 48,
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
        outsideDaysVisible: false,
        todayDecoration: BoxDecoration(
          color: AppTheme.primary_color.withValues(alpha: 0.25),
          shape: BoxShape.circle,
        ),
        todayTextStyle: const TextStyle(
          color: AppTheme.primary_color,
          fontWeight: FontWeight.bold,
        ),
        selectedDecoration: const BoxDecoration(
          color: AppTheme.primary_color,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: const TextStyle(
          color: CupertinoColors.white,
          fontWeight: FontWeight.bold,
        ),
        weekendTextStyle: const TextStyle(
          color: CupertinoColors.systemRed,
        ),
        defaultTextStyle: const TextStyle(
          color: CupertinoColors.label,
        ),
      ),
      selectedDayPredicate: (day) {
        return isSameDay(_selected_day, day);
      },
      onDaySelected: (selected_day, focused_day) {
        setState(() {
          _selected_day = selected_day;
          _focused_day = focused_day;
        });
      },
      onPageChanged: (focused_day) {
        setState(() {
          _focused_day = focused_day;
        });
      },
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          final shift_type = _getScheduleForDay(date);
          if (shift_type != null) {
            return Positioned(
              bottom: 2,
              child: ShiftBadge(shift_type: shift_type, size: 8),
            );
          }
          return null;
        },
      ),
    );
  }

  /// 선택된 날짜 정보 위젯
  Widget _buildSelectedDateInfo() {
    final date_format = DateFormat('M월 d일 (E)', 'ko_KR');
    final current_shift = _getScheduleForDay(_selected_day);
    final shift_info = current_shift != null
        ? AppConstants.shift_types[current_shift]
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            date_format.format(_selected_day),
            style: AppTheme.heading_small,
          ),
          const SizedBox(width: 12),
          if (current_shift != null && shift_info != null) ...[
            ShiftBadge(shift_type: current_shift, size: 20, show_label: true),
            const Spacer(),
            Text(
              shift_info.timeDisplay,
              style: AppTheme.body_small.copyWith(
                color: CupertinoColors.systemGrey,
              ),
            ),
          ] else ...[
            const Spacer(),
            Text(
              '근무를 선택하세요',
              style: AppTheme.body_medium.copyWith(
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 근무 유형 선택 버튼 영역
  Widget _buildShiftTypeSelector(String? current_shift) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '근무 유형 선택',
            style: AppTheme.body_medium.copyWith(
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 16),
          ShiftTypeButtonGroup(
            selected_shift: current_shift,
            onShiftSelected: _onShiftSelected,
          ),
          const SizedBox(height: 12),
          Text(
            '버튼을 누르면 다음 날로 자동 이동합니다',
            style: AppTheme.body_small.copyWith(
              color: CupertinoColors.systemGrey2,
            ),
          ),
        ],
      ),
    );
  }
}
