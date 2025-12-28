import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../widgets/shift_badge.dart';
import '../widgets/bottom_action_bar.dart';
import '../widgets/shift_input_sheet.dart';

/// 캘린더 메인 페이지
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  CalendarFormat _calendar_format = CalendarFormat.month;
  DateTime _focused_day = DateTime.now();
  DateTime? _selected_day;

  // 임시 스케줄 데이터 (실제로는 Provider에서 관리)
  final Map<DateTime, String> _schedules = {};

  @override
  void initState() {
    super.initState();
    _selected_day = _focused_day;
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

  /// 개인 일정 추가 placeholder 표시
  void _showPersonalEventPlaceholder() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('개인 일정 추가'),
        content: const Text('개인 일정 추가 기능은 추후 업데이트 예정입니다.\n\n예: 친구 만남, 결혼식, 학원 등'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('캘린더'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            // TODO: 설정 페이지로 이동
          },
          child: const Icon(CupertinoIcons.gear),
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
                  // 선택된 날짜 정보 및 일정 목록
                  Expanded(
                    child: _buildSelectedDayInfo(),
                  ),
                ],
              ),
            ),
          ),
          // 하단 퀵메뉴와 간격
          const SizedBox(height: 8),
          // 하단 액션 바
          BottomActionBar(
            mode: BottomActionBarMode.main,
            onMemoTap: () {
              // TODO: 메모 기능
            },
            onCalendarTap: () {
              // 오늘 날짜로 이동
              setState(() {
                _focused_day = DateTime.now();
                _selected_day = DateTime.now();
              });
            },
            onNotificationTap: () {
              // TODO: 알림 기능
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
          // 근무 추가 버튼
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: _showShiftAddBottomSheet,
            child: const Icon(
              CupertinoIcons.add,
              color: AppTheme.primary_color,
            ),
          ),
        ],
      ),
    );
  }

  /// 근무 추가 바텀시트 표시
  void _showShiftAddBottomSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => ShiftInputSheet(
        initial_date: _selected_day ?? DateTime.now(),
        schedules: _schedules,
        onScheduleUpdated: (updated_schedules) {
          setState(() {
            _schedules.clear();
            _schedules.addAll(updated_schedules);
          });
        },
        onSelectedDateChanged: (date) {
          setState(() {
            _selected_day = date;
            // 월이 바뀌면 포커스도 변경
            if (date.month != _focused_day.month || date.year != _focused_day.year) {
              _focused_day = date;
            }
          });
        },
      ),
    );
  }

  /// 캘린더 위젯
  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focused_day,
      calendarFormat: _calendar_format,
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
      onFormatChanged: (format) {
        setState(() {
          _calendar_format = format;
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
  Widget _buildSelectedDayInfo() {
    final date_format = DateFormat('yyyy.MM.dd', 'ko_KR');
    final shift_type = _getScheduleForDay(_selected_day ?? DateTime.now());
    
    // 해당 날짜의 일정 목록 (현재는 단일 근무만 지원, 추후 확장 가능)
    final schedules = <MapEntry<String, ShiftTypeInfo>>[];
    if (shift_type != null) {
      final info = AppConstants.shift_types[shift_type];
      if (info != null) {
        schedules.add(MapEntry(shift_type, info));
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 200, // 고정 높이
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날짜 헤더
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
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
                Text(
                  date_format.format(_selected_day ?? DateTime.now()),
                  style: AppTheme.heading_small,
                ),
                const Spacer(),
                if (schedules.isNotEmpty)
                  Text(
                    '${schedules.length}개의 일정',
                    style: AppTheme.body_small.copyWith(
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
              ],
            ),
          ),
          // 일정 목록 (스크롤 가능)
          Expanded(
            child: schedules.isNotEmpty
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: schedules.length,
                    itemBuilder: (context, index) {
                      final entry = schedules[index];
                      return _buildScheduleItem(entry.key, entry.value);
                    },
                  )
                : _buildEmptySchedule(),
          ),
          // 개인 일정 추가하기 버튼
          GestureDetector(
            onTap: _showPersonalEventPlaceholder,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: CupertinoColors.systemGrey5,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.plus_circle,
                    size: 20,
                    color: AppTheme.primary_color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '일정 추가하기...',
                    style: AppTheme.body_medium.copyWith(
                      color: AppTheme.primary_color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 일정 아이템 위젯 (스택 형식)
  Widget _buildScheduleItem(String shift_type, ShiftTypeInfo shift_info) {
    final color = shift_info.color;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Dismissible(
        key: Key('${_selected_day}_$shift_type'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            CupertinoIcons.trash,
            color: CupertinoColors.systemRed,
          ),
        ),
        onDismissed: (_) {
          setState(() {
            _schedules.remove(_normalizeDate(_selected_day ?? DateTime.now()));
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(
                color: color,
                width: 4,
              ),
            ),
          ),
          child: Row(
            children: [
              // 색상 인디케이터
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              // 근무 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shift_info.name,
                      style: AppTheme.body_medium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      shift_info.timeDisplay,
                      style: AppTheme.body_small.copyWith(
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
              // 삭제 힌트 아이콘
              Icon(
                CupertinoIcons.chevron_left,
                size: 14,
                color: CupertinoColors.systemGrey3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 빈 일정 위젯
  Widget _buildEmptySchedule() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.calendar,
            size: 32,
            color: CupertinoColors.systemGrey4,
          ),
          const SizedBox(height: 8),
          Text(
            '등록된 일정이 없습니다',
            style: AppTheme.body_medium.copyWith(
              color: CupertinoColors.systemGrey2,
            ),
          ),
        ],
      ),
    );
  }
}
