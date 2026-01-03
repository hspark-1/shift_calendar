import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/pages/settings_page.dart';
import '../../domain/entities/shift_type_info.dart';
import '../providers/shift_types_provider.dart';
import '../widgets/shift_badge.dart';
import '../widgets/bottom_action_bar.dart';
import '../widgets/shift_type_button.dart';

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

  // 근무 추가 모드 상태
  bool _is_shift_add_mode = false;

  // 임시 스케줄 데이터 (실제로는 Provider에서 관리)
  final Map<DateTime, List<String>> _schedules = {};

  // 근무 추가 모드 시작 시 초기 스케줄 상태 저장 (변경사항 추적용)
  Map<DateTime, List<String>>? _initial_schedules;

  @override
  void initState() {
    super.initState();
    _selected_day = _focused_day;

    // 2025.12.29에 더미 데이터 5개 추가
    final dummyDate = DateTime(2025, 12, 29);
    _schedules[dummyDate] = ['D', 'E', 'N', 'OFF', 'D'];
  }

  /// 날짜 정규화 (시간 제거)
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// 선택된 날짜의 스케줄 반환
  List<String>? _getScheduleForDay(DateTime day) {
    return _schedules[_normalizeDate(day)];
  }

  /// 이전 달로 이동 가능한지 확인
  bool _canGoToPreviousMonth() {
    const firstYear = 2000;
    const firstMonth = 1;
    final previousMonth = DateTime(
      _focused_day.year,
      _focused_day.month - 1,
      1,
    );
    return previousMonth.year > firstYear ||
        (previousMonth.year == firstYear && previousMonth.month >= firstMonth);
  }

  /// 다음 달로 이동 가능한지 확인
  bool _canGoToNextMonth() {
    const lastYear = 2050;
    const lastMonth = 12;
    final nextMonth = DateTime(_focused_day.year, _focused_day.month + 1, 1);
    return nextMonth.year < lastYear ||
        (nextMonth.year == lastYear && nextMonth.month <= lastMonth);
  }

  /// 이전 달로 이동
  void _goToPreviousMonth() {
    if (!_canGoToPreviousMonth()) return;
    final newFocusedDay = DateTime(
      _focused_day.year,
      _focused_day.month - 1,
      1,
    );
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _focused_day = newFocusedDay;
        });
      }
    });
  }

  /// 다음 달로 이동
  void _goToNextMonth() {
    if (!_canGoToNextMonth()) return;
    final newFocusedDay = DateTime(
      _focused_day.year,
      _focused_day.month + 1,
      1,
    );
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _focused_day = newFocusedDay;
        });
      }
    });
  }

  /// 연/월 선택 피커 표시
  void _showYearMonthPicker() {
    int selectedYear = _focused_day.year;
    int selectedMonth = _focused_day.month;

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
                  const Text('연도/월 선택', style: AppTheme.heading_small),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      final newFocusedDay = DateTime(
                        selectedYear,
                        selectedMonth,
                        1,
                      );
                      Navigator.pop(context);
                      SchedulerBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _focused_day = newFocusedDay;
                          });
                        }
                      });
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
                        initialItem: selectedYear - 2000,
                      ),
                      itemExtent: 40,
                      onSelectedItemChanged: (index) {
                        selectedYear = 2000 + index;
                      },
                      children: List.generate(
                        51, // 2000 ~ 2050
                        (index) => Center(
                          child: Text(
                            '${2000 + index}년',
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
                        initialItem: selectedMonth - 1,
                      ),
                      itemExtent: 40,
                      onSelectedItemChanged: (index) {
                        selectedMonth = index + 1;
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
        content: const Text(
          '개인 일정 추가 기능은 추후 업데이트 예정입니다.\n\n예: 친구 만남, 결혼식, 학원 등',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 미구현 기능 placeholder 표시
  void _showNotImplementedPlaceholder(String title, String description) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text('$description\n\n해당 기능은 추후 업데이트 예정입니다.'),
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
            Navigator.of(context).push(
              CupertinoPageRoute(builder: (context) => const SettingsPage()),
            );
          },
          child: const Icon(CupertinoIcons.gear),
        ),
      ),
      child: Container(
        color: CupertinoColors.systemGroupedBackground,
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
                    Flexible(child: _buildSelectedDayInfo()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 하단 액션 바
            BottomActionBar(
              mode: BottomActionBarMode.main,
              onMemoTap: () {
                _showNotImplementedPlaceholder('메모', '메모 기능');
              },
              onCalendarTap: () {
                // 오늘 날짜로 이동
                final now = DateTime.now();
                final normalizedNow = _normalizeDate(now);
                // focusedDay와 selectedDay를 동시에 업데이트
                // TableCalendar는 focusedDay 변경 시 자동으로 페이지를 변경하지만,
                // NotificationListener가 스크롤 알림을 차단하면 onPageChanged가 호출되지 않을 수 있음
                // 따라서 focusedDay 변경 후 명시적으로 onPageChanged 로직을 실행
                setState(() {
                  _focused_day = normalizedNow;
                  _selected_day = normalizedNow;
                });
                // onPageChanged가 호출되지 않을 수 있으므로,
                // 페이지 변경이 완료된 후 상태를 확실히 업데이트
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    // focusedDay가 변경되었는지 확인하고, 필요시 다시 업데이트
                    final currentNormalized = _normalizeDate(_focused_day);
                    if (!isSameDay(currentNormalized, normalizedNow)) {
                      setState(() {
                        _focused_day = normalizedNow;
                        _selected_day = normalizedNow;
                      });
                    }
                  }
                });
              },
              onNotificationTap: () {
                _showNotImplementedPlaceholder('알림', '알림 기능');
              },
            ),
          ],
        ),
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
          // 이전 달 버튼 (항상 표시, 이동 불가능할 때는 비활성화)
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
          // 년/월 표시 및 선택 버튼
          GestureDetector(
            onTap: _showYearMonthPicker,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  yearMonth,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: CupertinoColors.label,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey5,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    CupertinoIcons.chevron_down,
                    size: 12,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
          // 다음 달 버튼 (항상 표시, 이동 불가능할 때는 비활성화)
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
          const Spacer(),
          // 근무 추가 버튼 (X 버튼)
          GestureDetector(
            onTap: _is_shift_add_mode
                ? _onCancelShiftAddMode
                : _startShiftAddMode,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _is_shift_add_mode
                    ? AppTheme.primary_color.withValues(alpha: 0.15)
                    : CupertinoColors.systemGrey6.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _is_shift_add_mode ? CupertinoIcons.xmark : CupertinoIcons.add,
                size: 20,
                color: AppTheme.primary_color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 근무 추가 모드 시작
  void _startShiftAddMode() {
    setState(() {
      // 초기 상태 저장 (깊은 복사)
      _initial_schedules = _schedules.map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      );
      _is_shift_add_mode = true;
    });
  }

  /// 근무 추가 모드 종료 (변경사항 저장)
  void _completeShiftAddMode() {
    setState(() {
      _is_shift_add_mode = false;
      _initial_schedules = null;
      // 변경사항은 이미 _schedules에 반영되어 있음
    });
  }

  /// 근무 추가 모드 취소 (변경사항 되돌리기)
  void _cancelShiftAddMode() {
    setState(() {
      if (_initial_schedules != null) {
        // 초기 상태로 되돌리기
        _schedules.clear();
        _schedules.addAll(
          _initial_schedules!.map(
            (key, value) => MapEntry(key, List<String>.from(value)),
          ),
        );
      }
      _is_shift_add_mode = false;
      _initial_schedules = null;
    });
  }

  /// 변경사항이 있는지 확인
  bool _hasChanges() {
    if (_initial_schedules == null) return false;

    // 스케줄 개수가 다르면 변경사항 있음
    if (_schedules.length != _initial_schedules!.length) return true;

    // 각 날짜의 스케줄이 다른지 확인
    for (final entry in _schedules.entries) {
      final normalized = _normalizeDate(entry.key);
      final initialList = _initial_schedules![normalized];
      if (initialList == null ||
          initialList.length != entry.value.length ||
          !_listEquals(initialList, entry.value)) {
        return true;
      }
    }

    // 초기에는 있었지만 현재는 없는 경우
    for (final entry in _initial_schedules!.entries) {
      final normalized = _normalizeDate(entry.key);
      if (!_schedules.containsKey(normalized)) {
        return true;
      }
    }

    return false;
  }

  /// 리스트 비교 헬퍼
  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// X 버튼 클릭 처리 (취소 확인)
  void _onCancelShiftAddMode() {
    if (_hasChanges()) {
      // 변경사항이 있으면 확인 다이얼로그 표시
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('변경사항 취소'),
          content: const Text('변경사항을 취소하시겠습니까?\n입력한 근무 정보가 저장되지 않습니다.'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: false,
              onPressed: () => Navigator.pop(context),
              child: const Text('아니오'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                _cancelShiftAddMode();
              },
              child: const Text('취소'),
            ),
          ],
        ),
      );
    } else {
      // 변경사항이 없으면 바로 종료
      _cancelShiftAddMode();
    }
  }

  /// 근무 유형 선택 처리
  void _onShiftSelected(String shiftCode) {
    setState(() {
      final normalizedDate = _normalizeDate(_selected_day ?? DateTime.now());
      final schedules = _schedules[normalizedDate] ?? [];
      schedules.add(shiftCode);
      _schedules[normalizedDate] = schedules;
    });
    // 다음 날로 자동 이동
    _moveToNextDay();
  }

  /// 다음 날로 이동
  void _moveToNextDay() {
    final nextDay = (_selected_day ?? DateTime.now()).add(
      const Duration(days: 1),
    );
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _selected_day = nextDay;
          // 월이 바뀌면 포커스도 변경
          if (nextDay.month != _focused_day.month ||
              nextDay.year != _focused_day.year) {
            _focused_day = nextDay;
          }
        });
      }
    });
  }

  /// 캘린더 위젯
  Widget _buildCalendar() {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // TableCalendar의 내부 스크롤 알림(페이지 점프로 인한)만 차단
        // ScrollUpdateNotification과 ScrollStartNotification만 차단하여
        // 다른 알림은 정상적으로 전파되도록 함
        // ScrollEndNotification은 전파 허용하여 onPageChanged가 정상 작동하도록 함
        if (notification is ScrollUpdateNotification ||
            notification is ScrollStartNotification) {
          return true; // 차단
        }
        return false; // 전파 허용 (ScrollEndNotification 포함)
      },
      child: TableCalendar(
        firstDay: DateTime.utc(2000, 1, 1),
        lastDay: DateTime.utc(2050, 12, 31),
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
          outsideDaysVisible: true,
          outsideTextStyle: TextStyle(
            color: CupertinoColors.label.withValues(alpha: 0.25),
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
          defaultTextStyle: const TextStyle(color: CupertinoColors.label),
        ),
        selectedDayPredicate: (day) {
          return isSameDay(_selected_day, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          // 날짜 선택은 즉시 반영되어야 하므로 addPostFrameCallback 사용하지 않음
          setState(() {
            _selected_day = selectedDay;
            // focusedDay 변경은 빌드 중 setState를 방지하기 위해 지연
            if (focusedDay.month != _focused_day.month ||
                focusedDay.year != _focused_day.year) {
              SchedulerBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _focused_day = focusedDay;
                  });
                }
              });
            }
          });
        },
        onFormatChanged: (format) {
          setState(() {
            _calendar_format = format;
          });
        },
        onPageChanged: (focusedDay) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _focused_day = focusedDay;
              });
            }
          });
        },
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            final shiftList = _getScheduleForDay(date);
            if (shiftList != null && shiftList.isNotEmpty) {
              return Positioned(
                bottom: 2,
                child: ShiftBadge(shift_type: shiftList.first, size: 8),
              );
            }
            return null;
          },
        ),
      ),
    );
  }

  /// 선택된 날짜 정보 위젯 (스케줄 화면 + 근무 설정 overlay)
  Widget _buildSelectedDayInfo() {
    // 스케줄 화면 (근무 추가 모드가 아닐 때만 표시)
    if (!_is_shift_add_mode) {
      return _buildScheduleCard();
    }
    // 근무 설정 모드 overlay (근무 추가 모드일 때만 표시)
    return _buildShiftAddOverlay();
  }

  /// 스케줄 카드 (항상 표시되는 일정 목록)
  Widget _buildScheduleCard() {
    final dateFormat = DateFormat('yyyy.MM.dd', 'ko_KR');
    final shiftList = _getScheduleForDay(_selected_day ?? DateTime.now());
    final shiftTypesMap = ref.watch(shiftTypesMapProvider);

    // 해당 날짜의 일정 목록
    final schedules = <MapEntry<String, ShiftTypeInfo>>[];
    if (shiftList != null) {
      for (final shift_type in shiftList) {
        final info = shiftTypesMap[shift_type];
        if (info != null) {
          schedules.add(MapEntry(shift_type, info));
        }
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 날짜 헤더
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    dateFormat.format(_selected_day ?? DateTime.now()),
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
                  ? SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: schedules
                            .asMap()
                            .entries
                            .map(
                              (entry) => _buildScheduleItem(
                                entry.value.key,
                                entry.value.value,
                                entry.key,
                              ),
                            )
                            .toList(),
                      ),
                    )
                  : _buildEmptySchedule(),
            ),
            // 개인 일정 추가하기 버튼
            GestureDetector(
              onTap: _showPersonalEventPlaceholder,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
      ),
    );
  }

  /// 근무 설정 모드 overlay
  Widget _buildShiftAddOverlay() {
    final dateFormat = DateFormat('yyyy.MM.dd', 'ko_KR');
    final shiftList = _getScheduleForDay(_selected_day ?? DateTime.now());
    final currentShift = shiftList != null && shiftList.isNotEmpty
        ? shiftList.first
        : null;
    final shiftTypesMap = ref.watch(shiftTypesMapProvider);
    final shiftInfo = currentShift != null ? shiftTypesMap[currentShift] : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 날짜 헤더
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.primary_color.withValues(alpha: 0.05),
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
                    dateFormat.format(_selected_day ?? DateTime.now()),
                    style: AppTheme.heading_small,
                  ),
                  const SizedBox(width: 12),
                  if (currentShift != null && shiftInfo != null) ...[
                    ShiftBadge(
                      shift_type: currentShift,
                      size: 16,
                      show_label: true,
                    ),
                  ],
                ],
              ),
            ),
            // 근무 유형 선택 버튼
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShiftTypeButtonGroup(
                    selected_shift: currentShift,
                    onShiftSelected: _onShiftSelected,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '버튼을 누르면 다음 날로 자동 이동합니다',
                    style: AppTheme.body_small.copyWith(
                      color: CupertinoColors.systemGrey2,
                    ),
                  ),
                ],
              ),
            ),
            // 완료 버튼
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: AppTheme.primary_color,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: _completeShiftAddMode,
                  child: const Text(
                    '완료',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 일정 아이템 위젯 (스택 형식)
  Widget _buildScheduleItem(
    String shiftType,
    ShiftTypeInfo shiftInfo,
    int index,
  ) {
    final color = shiftInfo.color;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Dismissible(
        key: Key('${_selected_day}_${shiftType}_$index'),
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
            final normalizedDate = _normalizeDate(
              _selected_day ?? DateTime.now(),
            );
            final schedules = _schedules[normalizedDate];
            if (schedules != null) {
              schedules.remove(shiftType);
              if (schedules.isEmpty) {
                _schedules.remove(normalizedDate);
              }
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          child: Row(
            children: [
              // 색상 인디케이터
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              // 근무 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shiftInfo.name,
                      style: AppTheme.body_medium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      shiftInfo.timeDisplay,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.calendar,
            size: 32,
            color: CupertinoColors.systemGrey4,
          ),
          const SizedBox(height: 6),
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
