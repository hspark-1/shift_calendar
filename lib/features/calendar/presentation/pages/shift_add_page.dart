// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/shift_types_provider.dart';
import '../widgets/shift_badge.dart';
import '../widgets/bottom_action_bar.dart';
import '../widgets/shift_type_button.dart';
import '../widgets/year_month_picker_sheet.dart';

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
  Future<void> _showYearMonthPicker() async {
    final selected_date = await showYearMonthPickerSheet(
      context: context,
      initial_date: _focused_day,
      first_year: 2020,
      last_year: 2030,
    );

    if (selected_date == null || !mounted) return;

    setState(() {
      _focused_day = selected_date;
    });
  }

  /// 다음 날로 이동
  void _moveToNextDay() {
    final nextDay = _selected_day.add(const Duration(days: 1));
    setState(() {
      _selected_day = nextDay;
      // 다음 달로 넘어가면 포커스도 변경
      if (nextDay.month != _focused_day.month) {
        _focused_day = nextDay;
      }
    });
  }

  /// 근무 유형 선택 처리
  void _onShiftSelected(String shiftCode) {
    setState(() {
      _schedules[_normalizeDate(_selected_day)] = shiftCode;
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
    final currentShift = _getScheduleForDay(_selected_day);

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
                  _buildShiftTypeSelector(currentShift),
                ],
              ),
            ),
          ),
          // 하단 간격
          const SizedBox(height: 8),
          // 하단 액션 바
          BottomActionBar(
            mode: BottomActionBarMode.add,
            onFriendTap: () {
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
    final yearMonth = DateFormat('yyyy.MM', 'ko_KR').format(_focused_day);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 이전 달 버튼
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _goToPreviousMonth,
            child: const Icon(
              CupertinoIcons.chevron_left,
              size: 20,
              color: AppTheme.on_surface_color,
            ),
          ),
          // 년/월 표시 및 선택 버튼
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
          // 다음 달 버튼
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _goToNextMonth,
            child: const Icon(
              CupertinoIcons.chevron_right,
              size: 20,
              color: AppTheme.on_surface_color,
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
          color: AppTheme.on_surface_color,
          fontWeight: FontWeight.w600,
        ),
        weekendStyle: AppTheme.body_small.copyWith(
          color: CupertinoColors.systemRed,
          fontWeight: FontWeight.w600,
        ),
      ),
      calendarStyle: CalendarStyle(
        outsideDaysVisible: true,
        outsideTextStyle: TextStyle(
          color: AppTheme.on_surface_color.withValues(alpha: 0.25),
        ),
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
        weekendTextStyle: const TextStyle(color: CupertinoColors.systemRed),
        defaultTextStyle: const TextStyle(color: AppTheme.on_surface_color),
      ),
      selectedDayPredicate: (day) {
        return isSameDay(_selected_day, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selected_day = selectedDay;
          _focused_day = focusedDay;
        });
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focused_day = focusedDay;
        });
      },
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          final shiftType = _getScheduleForDay(date);
          if (shiftType != null) {
            return Positioned(
              bottom: 2,
              child: ShiftBadge(shift_type: shiftType, size: 8),
            );
          }
          return null;
        },
      ),
    );
  }

  /// 선택된 날짜 정보 위젯
  Widget _buildSelectedDateInfo() {
    final dateFormat = DateFormat('M월 d일 (E)', 'ko_KR');
    final currentShift = _getScheduleForDay(_selected_day);
    final shiftTypesMap = ref.watch(shiftTypesMapProvider);
    final shiftInfo = currentShift != null ? shiftTypesMap[currentShift] : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.cardDecoration(radius: AppTheme.input_radius),
      child: Row(
        children: [
          Text(dateFormat.format(_selected_day), style: AppTheme.heading_small),
          const SizedBox(width: 12),
          if (currentShift != null && shiftInfo != null) ...[
            ShiftBadge(shift_type: currentShift, size: 20, show_label: true),
            const Spacer(),
            Text(
              shiftInfo.timeDisplay,
              style: AppTheme.body_small.copyWith(
                color: AppTheme.on_surface_variant_color,
              ),
            ),
          ] else ...[
            const Spacer(),
            Text(
              '근무를 선택하세요',
              style: AppTheme.body_medium.copyWith(
                color: AppTheme.on_surface_variant_color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 근무 유형 선택 버튼 영역
  Widget _buildShiftTypeSelector(String? currentShift) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        children: [
          Text(
            '근무 유형 선택',
            style: AppTheme.body_medium.copyWith(
              color: AppTheme.on_surface_variant_color,
            ),
          ),
          const SizedBox(height: 16),
          ShiftTypeButtonGroup(
            selected_shift: currentShift,
            onShiftSelected: _onShiftSelected,
          ),
          const SizedBox(height: 12),
          Text(
            '버튼을 누르면 다음 날로 자동 이동합니다',
            style: AppTheme.body_small.copyWith(
              color: AppTheme.on_surface_variant_color,
            ),
          ),
        ],
      ),
    );
  }
}
