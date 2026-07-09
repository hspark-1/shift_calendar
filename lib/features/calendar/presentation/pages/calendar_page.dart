import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/korean_holidays.dart';
import '../../../auth/presentation/pages/settings_page.dart';
import '../../../friend/presentation/pages/friend_list_page.dart';
import '../../../friend/presentation/pages/notification_page.dart';
import '../../../friend/presentation/providers/notification_provider.dart';
import '../providers/shift_types_provider.dart';
import '../widgets/shift_badge.dart';
import '../widgets/bottom_action_bar.dart';
import '../widgets/personal_event_form_modal.dart';
import '../widgets/shift_type_button.dart';
import '../../data/services/work_shift_service.dart';
import '../../data/services/calendar_service.dart';
import '../../data/models/event_api_model.dart';
import '../../data/models/work_shift_api_model.dart';
import '../../../../core/network/api_exception.dart';

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

  // 확장 보기 모드 (날짜 밑에 근무 코드 표시)
  bool _is_expanded_view = false;

  // 포인터 시작 위치 (Listener용)
  double? _pointer_start_y;

  // 임시 스케줄 데이터 (하루에 하나의 근무만 저장)
  final Map<DateTime, String?> _schedules = {};

  // 서버가 반환한 근무표 표시 데이터: 날짜 -> 근무표 스냅샷
  final Map<DateTime, WorkShiftApiModel> _workShifts = {};

  // 일정(Events) 데이터: Map<DateTime, List<EventApiModel>> (날짜 -> 일정 목록)
  final Map<DateTime, List<EventApiModel>> _events = {};

  // 근무표 ID 데이터: Map<DateTime, String> (날짜 -> work_shift_id)
  // 서버 삭제 API 호출 시 필요
  final Map<DateTime, String> _work_shift_ids = {};

  // 근무 추가 모드 시작 시 초기 스케줄 상태 저장 (변경사항 추적용)
  Map<DateTime, String?>? _initial_schedules;

  // 로딩 상태
  bool _isLoading = false;

  // 로드된 월 추적: Set<String> (예: "2026-01")
  final Set<String> _loadedMonths = {};

  // 공휴일 목록 (년도별)
  final Map<int, Set<DateTime>> _holidays = {};

  // 확장 모드 시 행 높이
  double get _calendarRowHeight {
    if (_is_expanded_view) {
      return 60.0; // 확장 모드: 더 높은 행 (날짜 + 근무 코드)
    }
    return 48.0; // 기본 모드
  }

  @override
  void initState() {
    super.initState();
    _selected_day = _focused_day;
    // 초기 데이터 로딩
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCalendarData(_focused_day);
      _loadHolidays(_focused_day.year, month: _focused_day.month);
      // 미읽음 알림 개수 조회
      ref.read(notificationProvider.notifier).fetchUnreadCount();
    });
  }

  /// 날짜 정규화 (시간 제거)
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// 월 키 생성 (예: "2026-01")
  String _getMonthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  /// 공휴일 데이터 로딩 (Lazy Loading - 필요한 연도만 로드)
  Future<void> _loadHolidays(int year, {int? month}) async {
    // 월 정보가 없으면 로드하지 않음 (lazy loading을 위해 필수)
    if (month == null) {
      return;
    }

    try {
      // 현재 연도만 먼저 로드 (월 정보 포함하여 3개월만 조회)
      final holidays = await _fetchHolidaysForYear(year, month: month);

      // 기존 데이터와 병합 (같은 연도의 다른 월로 이동할 때도 데이터 누적)
      final existingHolidays = _holidays[year];
      if (existingHolidays != null) {
        existingHolidays.addAll(holidays);
        _holidays[year] = existingHolidays;
      } else {
        _holidays[year] = holidays;
      }

      // UI 업데이트를 위해 setState 호출
      if (mounted) {
        setState(() {});
      }

      // 경계 월인 경우에만 인접 연도도 미리 로드
      // 12월이면 다음 연도 1월도 미리 로드
      if (month == 12 && !_holidays.containsKey(year + 1)) {
        _loadHolidaysForYearAsync(year + 1, month: 1);
      }
      // 1월이면 이전 연도 12월도 미리 로드
      if (month == 1 && !_holidays.containsKey(year - 1)) {
        _loadHolidaysForYearAsync(year - 1, month: 12);
      }
    } catch (e) {
      // 에러 발생 시 빈 Set 사용
      print('공휴일 로딩 실패: $e');
    }
  }

  /// 공휴일 데이터 비동기 로딩 (UI 업데이트 없이 백그라운드에서 로드)
  void _loadHolidaysForYearAsync(int year, {int? month}) {
    if (_holidays.containsKey(year)) {
      return;
    }

    // 월 정보가 없으면 현재 월로 가정 (하위 호환성)
    final targetMonth = month ?? DateTime.now().month;
    _fetchHolidaysForYear(year, month: targetMonth)
        .then((holidays) {
          if (mounted && !_holidays.containsKey(year)) {
            _holidays[year] = holidays;
            if (mounted) {
              setState(() {});
            }
          }
        })
        .catchError((e) {
          print('공휴일 비동기 로딩 실패 ($year년): $e');
        });
  }

  /// 해당 연도의 공휴일 목록 가져오기 (월 정보 포함)
  Future<Set<DateTime>> _fetchHolidaysForYear(int year, {int? month}) async {
    // KoreanHolidays의 public 메서드 사용 (월 정보 전달)
    return await KoreanHolidays.getHolidaysForYear(year, month: month);
  }

  /// 해당 날짜가 공휴일인지 확인 (동기, 최적화된 검색)
  bool _isHoliday(DateTime date) {
    final normalized = _normalizeDate(date);
    final year = normalized.year;

    // 해당 연도의 공휴일 목록 확인
    final holidaysForYear = _holidays[year];
    if (holidaysForYear == null || holidaysForYear.isEmpty) {
      // 아직 로드되지 않은 경우 비동기로 로드 시도 (UI 블로킹 없음)
      if (!_holidays.containsKey(year)) {
        _loadHolidaysForYearAsync(year, month: normalized.month);
      }
      return false;
    }

    // Set의 any를 사용하여 효율적으로 검색
    return holidaysForYear.any((holiday) {
      final normalizedHoliday = _normalizeDate(holiday);
      return normalized.year == normalizedHoliday.year &&
          normalized.month == normalizedHoliday.month &&
          normalized.day == normalizedHoliday.day;
    });
  }

  /// 3달 데이터 로딩 (전월, 현재월, 다음월)
  Future<void> _loadCalendarData(DateTime focusedMonth) async {
    // 이미 로드된 월이면 스킵
    final monthKey = _getMonthKey(focusedMonth);
    if (_loadedMonths.contains(monthKey)) {
      return;
    }

    // 로딩 중이면 스킵
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final calendarService = ref.read(calendarServiceProvider);

      // 3달 범위 계산
      final range = calendarService.calculateThreeMonthRange(focusedMonth);

      // 통합 캘린더 API로 한 번에 데이터 조회
      final response = await calendarService.getCalendarRange(
        startDate: range.startDate,
        endDate: range.endDate,
      );

      if (mounted) {
        setState(() {
          // 근무표 데이터 병합
          for (final workShift in response.data.workShifts) {
            final normalizedDate = _normalizeDate(workShift.workDate);
            _workShifts[normalizedDate] = workShift;
            _schedules[normalizedDate] = workShift.shiftTypeCode;
            _work_shift_ids[normalizedDate] = workShift.workShiftId;
          }

          // 일정 데이터 병합
          for (final event in response.data.events) {
            _addEventToDateMap(event);
          }

          // 로드된 월 추가
          final prevMonthKey = _getMonthKey(range.startDate);
          final currentMonthKey = _getMonthKey(focusedMonth);
          final nextMonthKey = _getMonthKey(range.endDate);
          _loadedMonths.add(prevMonthKey);
          _loadedMonths.add(currentMonthKey);
          _loadedMonths.add(nextMonthKey);

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(_getErrorMessage(e));
      }
    }
  }

  /// 일정 기간을 날짜별 맵에 반영한다. end_at은 DB/API 계약상 exclusive로 해석한다.
  void _addEventToDateMap(EventApiModel event) {
    final startDate = _normalizeDate(event.startAt);
    var endDate = _normalizeDate(event.endAt);
    final endAtMidnight =
        event.endAt.hour == 0 &&
        event.endAt.minute == 0 &&
        event.endAt.second == 0 &&
        event.endAt.millisecond == 0 &&
        event.endAt.microsecond == 0;

    if (endAtMidnight) {
      endDate = endDate.subtract(const Duration(days: 1));
    }
    if (endDate.isBefore(startDate)) {
      endDate = startDate;
    }

    var currentDate = startDate;
    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      final eventList = _events.putIfAbsent(currentDate, () => []);
      eventList.removeWhere((e) => e.eventId == event.eventId);
      eventList.add(event);
      eventList.sort((a, b) => a.startAt.compareTo(b.startAt));
      currentDate = currentDate.add(const Duration(days: 1));
    }
  }

  /// 선택된 날짜의 스케줄 반환 (하루에 하나의 근무만 반환)
  String? _getScheduleForDay(DateTime day) {
    final normalizedDate = _normalizeDate(day);
    return _schedules[normalizedDate] ??
        _workShifts[normalizedDate]?.shiftTypeCode;
  }

  /// 선택된 날짜의 서버 근무표 반환
  WorkShiftApiModel? _getWorkShiftForDay(DateTime day) {
    return _workShifts[_normalizeDate(day)];
  }

  Color _getWorkShiftColor(WorkShiftApiModel workShift) {
    return Color(workShift.shiftTypeColor ?? 0xFF8E8E93);
  }

  String _formatWorkShiftTime(WorkShiftApiModel workShift) {
    if (workShift.startTime == null || workShift.endTime == null) {
      return '근무없음';
    }

    return '${_formatApiTime(workShift.startTime!)} ~ ${_formatApiTime(workShift.endTime!)}';
  }

  String _formatApiTime(String time) {
    if (time.length >= 5) {
      return time.substring(0, 5);
    }
    return time;
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
        // 월 변경 시 데이터 로딩
        _loadCalendarData(newFocusedDay);
        // 공휴일도 함께 로드 (lazy loading)
        _loadHolidays(newFocusedDay.year, month: newFocusedDay.month);
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
        // 월 변경 시 데이터 로딩
        _loadCalendarData(newFocusedDay);
        // 공휴일도 함께 로드 (lazy loading)
        _loadHolidays(newFocusedDay.year, month: newFocusedDay.month);
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
          color: AppTheme.surface_color,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.card_radius),
          ),
        ),
        child: Column(
          children: [
            // 헤더
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
                          // 월 변경 시 데이터 로딩
                          _loadCalendarData(newFocusedDay);
                          // 공휴일도 함께 로드
                          _loadHolidays(
                            newFocusedDay.year,
                            month: newFocusedDay.month,
                          );
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

  /// 개인 일정 추가 모달 표시
  Future<void> _showPersonalEventModal() async {
    final initialDate = _normalizeDate(_selected_day ?? DateTime.now());
    final request = await showCupertinoModalPopup<CreateEventRequest>(
      context: context,
      barrierDismissible: true,
      builder: (context) => PersonalEventFormModal(initialDate: initialDate),
    );

    if (request == null || !mounted) return;

    showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const CupertinoAlertDialog(content: CupertinoActivityIndicator()),
    );

    try {
      final calendarService = ref.read(calendarServiceProvider);
      final event = await calendarService.createEvent(request);

      if (mounted) {
        Navigator.pop(context);
        final eventDate = _normalizeDate(event.startAt);
        setState(() {
          _addEventToDateMap(event);
          _selected_day = eventDate;
          _focused_day = eventDate;
        });
        _loadCalendarData(eventDate);
        _loadHolidays(eventDate.year, month: eventDate.month);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorDialog(_getErrorMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: false,
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
        color: AppTheme.background_color,
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
              unreadNotificationCount: ref.watch(
                unreadNotificationCountProvider,
              ),
              onFriendTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (context) => const FriendListPage(),
                  ),
                );
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
                      // 월 변경 시 데이터 로딩
                      _loadCalendarData(normalizedNow);
                      // 공휴일도 함께 로드
                      _loadHolidays(
                        normalizedNow.year,
                        month: normalizedNow.month,
                      );
                    }
                  }
                });
              },
              onNotificationTap: () {
                Navigator.of(context)
                    .push(
                      CupertinoPageRoute<void>(
                        builder: (context) => const NotificationPage(),
                      ),
                    )
                    .then((_) {
                      // 알림 페이지에서 돌아오면 미읽음 개수 새로고침
                      ref
                          .read(notificationProvider.notifier)
                          .fetchUnreadCount();
                    });
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
                  ? AppTheme.on_surface_color
                  : AppTheme.outline_variant_color,
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
          // 다음 달 버튼 (항상 표시, 이동 불가능할 때는 비활성화)
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
                    : AppTheme.surface_container_low_color,
                borderRadius: BorderRadius.circular(AppTheme.input_radius),
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
      _initial_schedules = Map.from(_schedules);
      _is_shift_add_mode = true;
    });
  }

  /// 날짜를 YYYY-MM-DD 형식으로 변환
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 서버 요청 형식으로 변환 (변경된 데이터만)
  /// _initial_schedules와 _schedules를 비교하여 변경된 항목만 반환
  List<Map<String, dynamic>> _convertToRequestFormat() {
    final List<Map<String, dynamic>> workShifts = [];

    // _initial_schedules가 없으면 모든 항목을 변경된 것으로 간주
    if (_initial_schedules == null) {
      for (final entry in _schedules.entries) {
        final date = entry.key;
        final shiftTypeCode = entry.value;

        // 값이 있는 경우만 추가
        if (shiftTypeCode != null && shiftTypeCode.isNotEmpty) {
          workShifts.add({
            'work_date': _formatDate(date), // YYYY-MM-DD
            'shift_type_code': shiftTypeCode,
          });
        }
      }
      return workShifts;
    }

    // 변경된 항목만 추출
    for (final entry in _schedules.entries) {
      final date = entry.key;
      final normalizedDate = _normalizeDate(date);
      final currentShiftTypeCode = entry.value;
      final initialShiftTypeCode = _initial_schedules![normalizedDate];

      // 변경사항이 있는 경우만 추가
      // 1. 새로 추가된 항목 (초기에는 없었음)
      // 2. 값이 변경된 항목 (초기와 현재가 다름)
      if (currentShiftTypeCode != initialShiftTypeCode) {
        // 값이 있는 경우만 추가 (null이면 삭제된 것으로 간주하지만, 서버 전송은 하지 않음)
        if (currentShiftTypeCode != null && currentShiftTypeCode.isNotEmpty) {
          workShifts.add({
            'work_date': _formatDate(date), // YYYY-MM-DD
            'shift_type_code': currentShiftTypeCode,
          });
        }
      }
    }

    // 초기에는 있었지만 현재는 없는 경우 (삭제)
    // 서버에서 null을 받으면 삭제로 처리하는지 확인 필요
    // 현재는 삭제는 별도 API 호출이 필요할 수 있으므로 제외

    return workShifts;
  }

  /// 에러 메시지 추출
  String _getErrorMessage(dynamic error) {
    if (error is ApiException) {
      // 서버에서 전달받은 message를 그대로 반환
      return error.message;
    }
    // ApiException이 아닌 경우 기본 메시지 반환
    return '알 수 없는 오류가 발생했습니다.';
  }

  /// 에러 다이얼로그 표시
  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('확인'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// 근무 추가 모드 종료 (변경사항 저장)
  /// 기존에 저장되어 있는 데이터는 신경쓰지 않고, 현재 _schedules만 서버로 전송
  Future<void> _completeShiftAddMode() async {
    // 1. 데이터 변환 (현재 상태만 전송)
    // Map<DateTime, String?> 형태이므로 이미 하루에 하나만 보장됨
    final workShifts = _convertToRequestFormat();

    if (workShifts.isEmpty) {
      // 저장할 근무가 없으면 모드만 종료
      setState(() {
        _is_shift_add_mode = false;
        _initial_schedules = null;
      });
      return;
    }

    // 2. 로딩 표시
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const CupertinoAlertDialog(content: CupertinoActivityIndicator()),
    );

    try {
      // 3. API 호출
      final workShiftService = ref.read(workShiftServiceProvider);
      final response = await workShiftService.batchUpsertWorkShifts(
        workShifts: workShifts,
      );

      // 4. 성공 처리
      if (mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기

        setState(() {
          _is_shift_add_mode = false;
          _initial_schedules = null;
          for (final workShift in response.data.workShifts) {
            final normalizedDate = _normalizeDate(workShift.workDate);
            _workShifts[normalizedDate] = workShift;
            _schedules[normalizedDate] = workShift.shiftTypeCode;
            _work_shift_ids[normalizedDate] = workShift.workShiftId;
          }
        });

        // 성공 메시지 (선택사항)
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('저장 완료'),
            content: Text('${workShifts.length}개의 근무가 저장되었습니다.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('확인'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // 5. 에러 처리
      if (mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        _showErrorDialog(_getErrorMessage(e));
      }
    }
  }

  /// 근무 추가 모드 취소 (변경사항 되돌리기)
  void _cancelShiftAddMode() {
    setState(() {
      if (_initial_schedules != null) {
        // 초기 상태로 되돌리기
        _schedules.clear();
        _schedules.addAll(_initial_schedules!);
      }
      _is_shift_add_mode = false;
      _initial_schedules = null;
    });
  }

  /// 근무표 삭제 확인 및 서버 API 호출
  ///
  /// Dismissible의 confirmDismiss에서 호출됨
  /// 성공 시 true 반환 (삭제 진행), 실패 시 false 반환 (삭제 취소)
  Future<bool> _confirmDeleteWorkShift(DateTime? selectedDay) async {
    if (selectedDay == null) return false;

    final normalizedDate = _normalizeDate(selectedDay);
    final workShiftId = _work_shift_ids[normalizedDate];

    // work_shift_id가 없으면 로컬에만 있는 데이터 (서버에 저장 안 됨)
    if (workShiftId == null) {
      // 로컬에서만 삭제
      setState(() {
        _schedules.remove(normalizedDate);
        _workShifts.remove(normalizedDate);
      });
      return true;
    }

    try {
      // 서버 API 호출
      final workShiftService = ref.read(workShiftServiceProvider);
      await workShiftService.deleteWorkShift(workShiftId);

      // 성공 시 로컬 상태에서도 삭제
      setState(() {
        _schedules.remove(normalizedDate);
        _workShifts.remove(normalizedDate);
        _work_shift_ids.remove(normalizedDate);
      });

      return true;
    } catch (e) {
      // 실패 시 에러 표시
      if (mounted) {
        _showErrorDialog(_getErrorMessage(e));
      }
      return false;
    }
  }

  /// 변경사항이 있는지 확인
  bool _hasChanges() {
    if (_initial_schedules == null) return false;

    // 스케줄 개수가 다르면 변경사항 있음
    if (_schedules.length != _initial_schedules!.length) return true;

    // 각 날짜의 스케줄이 다른지 확인
    for (final entry in _schedules.entries) {
      final normalized = _normalizeDate(entry.key);
      final initialValue = _initial_schedules![normalized];
      if (initialValue != entry.value) {
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

  /// 근무 유형 선택 처리 (같은 날짜에 여러 번 클릭해도 마지막 것만 저장)
  void _onShiftSelected(String shiftCode) {
    setState(() {
      final normalizedDate = _normalizeDate(_selected_day ?? DateTime.now());
      // 같은 날짜에 이미 값이 있어도 덮어쓰기 (마지막 선택만 유지)
      _schedules[normalizedDate] = shiftCode;
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
            // 월 변경 시 데이터 로딩
            _loadCalendarData(nextDay);
            // 공휴일도 함께 로드
            _loadHolidays(nextDay.year, month: nextDay.month);
          }
        });
      }
    });
  }

  /// 확장 모드용 날짜 셀 빌더 (날짜 + 근무 코드 표시)
  Widget _buildExpandedDayCell({
    required DateTime date,
    required Color textColor,
    bool isToday = false,
    bool isSelected = false,
    bool isOutside = false,
  }) {
    final workShift = _getWorkShiftForDay(date);
    final shiftType = _getScheduleForDay(date);
    final shiftTypesMap = _is_shift_add_mode
        ? ref.watch(shiftTypesMapProvider)
        : null;
    final editShiftInfo = _is_shift_add_mode && shiftType != null
        ? shiftTypesMap == null
              ? null
              : shiftTypesMap[shiftType]
        : null;
    final badgeText = _is_shift_add_mode ? shiftType : workShift?.shiftTypeCode;
    final badgeColor = _is_shift_add_mode
        ? editShiftInfo?.color ??
              (workShift == null ? null : _getWorkShiftColor(workShift))
        : (workShift == null ? null : _getWorkShiftColor(workShift));

    // 외부 날짜(이전/다음 달)는 투명도 적용
    final outsideAlpha = isOutside ? 0.4 : 1.0;

    return SizedBox(
      height: 56, // 고정 높이로 모든 셀이 동일한 높이 유지
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 날짜 숫자 (고정 높이 28)
          SizedBox(
            height: 28,
            child: Center(
              child: (isToday || isSelected)
                  ? Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary_color
                            : AppTheme.primary_color.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      '${date.day}',
                      style: TextStyle(
                        color: textColor.withValues(alpha: outsideAlpha),
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 2),
          // 근무 코드 표시 (고정 높이 16)
          SizedBox(
            height: 16,
            child: badgeText != null && badgeColor != null
                ? ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 44),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: outsideAlpha),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: CupertinoColors.white.withValues(
                              alpha: outsideAlpha,
                            ),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  /// 포인터 다운 이벤트 처리
  void _onPointerDown(PointerDownEvent event) {
    _pointer_start_y = event.position.dy;
  }

  /// 포인터 이동 이벤트 처리 (확장/축소 모드 전환)
  void _onPointerMove(PointerMoveEvent event) {
    if (_pointer_start_y == null) return;

    final currentY = event.position.dy;
    final deltaY = currentY - _pointer_start_y!;

    // 임계값 (50픽셀 이상 드래그 시 모드 전환)
    const threshold = 50.0;

    if (deltaY > threshold && !_is_expanded_view) {
      // 아래로 드래그 - 확장 모드 활성화
      setState(() {
        _is_expanded_view = true;
        _calendar_format = CalendarFormat.month; // 확장 모드는 항상 월 보기
      });
      _pointer_start_y = currentY; // 시작점 리셋
    } else if (deltaY < -threshold && _is_expanded_view) {
      // 위로 드래그 - 확장 모드 비활성화
      setState(() {
        _is_expanded_view = false;
      });
      _pointer_start_y = currentY; // 시작점 리셋
    }
  }

  /// 포인터 업 이벤트 처리
  void _onPointerUp(PointerUpEvent event) {
    _pointer_start_y = null;
  }

  /// 캘린더 위젯
  Widget _buildCalendar() {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      child: NotificationListener<ScrollNotification>(
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: TableCalendar(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2050, 12, 31),
            focusedDay: _focused_day,
            calendarFormat: _calendar_format,
            locale: 'ko_KR',
            headerVisible: false,
            daysOfWeekHeight: 32,
            rowHeight: _calendarRowHeight,
            availableCalendarFormats: _is_expanded_view
                ? const {CalendarFormat.month: '월'}
                : const {
                    CalendarFormat.month: '월',
                    CalendarFormat.twoWeeks: '2주',
                    CalendarFormat.week: '주',
                  },
            // 수평 스와이프만 허용하여 수직 드래그가 GestureDetector로 전달되도록 함
            availableGestures: AvailableGestures.horizontalSwipe,
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
              // 공휴일 텍스트 색상 (빨간색)
              holidayTextStyle: const TextStyle(
                color: CupertinoColors.systemRed,
              ),
              // 주말 텍스트 색상 제거 (토요일은 평일 색상으로 처리하기 위해)
              // weekendTextStyle은 제거하고 defaultBuilder에서 처리
              defaultTextStyle: const TextStyle(
                color: AppTheme.on_surface_color,
              ),
            ),
            // 공휴일 판단
            holidayPredicate: (day) {
              return _isHoliday(day);
            },
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
                      // 월 변경 시 데이터 로딩
                      _loadCalendarData(focusedDay);
                      // 공휴일도 함께 로드 (월 정보 포함)
                      _loadHolidays(focusedDay.year, month: focusedDay.month);
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
                  // 월 변경 시 데이터 로딩
                  _loadCalendarData(focusedDay);
                  // 공휴일도 함께 로드 (lazy loading)
                  _loadHolidays(focusedDay.year, month: focusedDay.month);
                }
              });
            },
            calendarBuilders: CalendarBuilders(
              // 요일 헤더 커스터마이징 (토요일과 일요일은 빨간색)
              dowBuilder: (context, day) {
                final weekday = day.weekday;
                final isWeekend =
                    weekday == DateTime.saturday || weekday == DateTime.sunday;
                TextStyle textStyle;
                if (isWeekend) {
                  textStyle = AppTheme.body_small.copyWith(
                    color: CupertinoColors.systemRed,
                    fontWeight: FontWeight.w600,
                  );
                } else {
                  textStyle = AppTheme.body_small.copyWith(
                    color: AppTheme.on_surface_color,
                    fontWeight: FontWeight.w600,
                  );
                }
                return Center(
                  child: Text(
                    DateFormat('E', 'ko_KR').format(day),
                    style: textStyle,
                  ),
                );
              },
              // 공휴일 빌더 (holidayPredicate가 true인 경우)
              holidayBuilder: (context, date, focused) {
                // 확장 모드일 때는 근무 코드도 함께 표시
                if (_is_expanded_view) {
                  return _buildExpandedDayCell(
                    date: date,
                    textColor: CupertinoColors.systemRed,
                  );
                }
                // 공휴일은 항상 빨간색
                return Center(
                  child: Text(
                    '${date.day}',
                    style: const TextStyle(color: CupertinoColors.systemRed),
                  ),
                );
              },
              // 날짜 셀 커스터마이징 (토요일과 일요일은 빨간색)
              // 공휴일은 holidayBuilder에서 처리되므로 여기서는 주말만 처리
              defaultBuilder: (context, date, focused) {
                final weekday = date.weekday;
                final isWeekend =
                    weekday == DateTime.saturday || weekday == DateTime.sunday;
                // 주말이면 빨간색, 그 외는 평일 색상
                final textColor = isWeekend
                    ? CupertinoColors.systemRed
                    : AppTheme.on_surface_color;

                // 확장 모드일 때는 근무 코드도 함께 표시
                if (_is_expanded_view) {
                  return _buildExpandedDayCell(
                    date: date,
                    textColor: textColor,
                  );
                }

                return Center(
                  child: Text(
                    '${date.day}',
                    style: TextStyle(color: textColor),
                  ),
                );
              },
              // 이전/다음 달 날짜 (outside days)
              outsideBuilder: (context, date, focused) {
                final weekday = date.weekday;
                final isWeekend =
                    weekday == DateTime.saturday || weekday == DateTime.sunday;
                // 주말이면 빨간색, 그 외는 평일 색상 (투명도 적용)
                final textColor = isWeekend
                    ? CupertinoColors.systemRed
                    : AppTheme.on_surface_color;

                // 확장 모드일 때는 근무 코드도 함께 표시
                if (_is_expanded_view) {
                  return _buildExpandedDayCell(
                    date: date,
                    textColor: textColor,
                    isOutside: true,
                  );
                }

                return Center(
                  child: Text(
                    '${date.day}',
                    style: TextStyle(color: textColor.withValues(alpha: 0.4)),
                  ),
                );
              },
              // 오늘 날짜 스타일 (공휴일이거나 주말이면 빨간색, 아니면 primary color)
              todayBuilder: (context, date, focused) {
                final weekday = date.weekday;
                final isHoliday = _isHoliday(date);
                final isWeekend =
                    weekday == DateTime.saturday || weekday == DateTime.sunday;

                // 주말이거나 공휴일이면 빨간색, 그 외는 primary color
                final textColor = (isWeekend || isHoliday)
                    ? CupertinoColors.systemRed
                    : AppTheme.primary_color;

                // 확장 모드일 때는 근무 코드도 함께 표시
                if (_is_expanded_view) {
                  return _buildExpandedDayCell(
                    date: date,
                    textColor: textColor,
                    isToday: true,
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primary_color.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
              // 선택된 날짜 스타일
              selectedBuilder: (context, date, focused) {
                // 확장 모드일 때는 근무 코드도 함께 표시
                if (_is_expanded_view) {
                  return _buildExpandedDayCell(
                    date: date,
                    textColor: CupertinoColors.white,
                    isSelected: true,
                  );
                }

                return Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.primary_color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
              // 마커 (근무 배지) - 확장 모드에서는 날짜 셀에 이미 표시되므로 숨김
              markerBuilder: (context, date, events) {
                // 확장 모드에서는 마커 숨김
                if (_is_expanded_view) {
                  return null;
                }

                if (_is_shift_add_mode) {
                  final shiftType = _getScheduleForDay(date);
                  if (shiftType != null && shiftType.isNotEmpty) {
                    return Positioned(
                      bottom: 2,
                      child: ShiftBadge(shift_type: shiftType, size: 8),
                    );
                  }
                  return null;
                }

                final workShift = _getWorkShiftForDay(date);
                if (workShift != null) {
                  return Positioned(
                    bottom: 2,
                    child: _buildWorkShiftDot(workShift, size: 8),
                  );
                }
                return null;
              },
            ),
          ), // TableCalendar
        ), // AnimatedContainer
      ), // NotificationListener
    ); // Listener
  }

  /// 근무표 색상 점 위젯
  Widget _buildWorkShiftDot(WorkShiftApiModel workShift, {double size = 16}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getWorkShiftColor(workShift),
        shape: BoxShape.circle,
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
    final selectedDate = _selected_day ?? DateTime.now();
    final normalizedDate = _normalizeDate(selectedDate);
    final workShift = _getWorkShiftForDay(selectedDate);

    // 해당 날짜의 일정(Events) 목록
    final dayEvents = _events[normalizedDate] ?? [];

    // 총 일정 개수 (근무표 + Events)
    final totalCount = (workShift != null ? 1 : 0) + dayEvents.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: AppTheme.cardDecoration(),
      child: ClipRRect(
        borderRadius: AppTheme.card_border_radius,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 날짜 헤더
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        dateFormat.format(selectedDate),
                        style: AppTheme.heading_small,
                      ),
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
                  // 공휴일 이름 표시
                  if (_isHoliday(selectedDate))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        KoreanHolidays.getHolidayName(selectedDate) ?? '공휴일',
                        style: AppTheme.body_small.copyWith(
                          color: CupertinoColors.systemRed,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // 일정 목록
            Expanded(
              child: totalCount > 0
                  ? SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 근무표 표시
                          if (workShift != null)
                            _buildWorkShiftItem(workShift, 0),
                          // Events 표시
                          ...dayEvents.asMap().entries.map((entry) {
                            return _buildEventItem(entry.value, entry.key);
                          }),
                        ],
                      ),
                    )
                  : _buildEmptySchedule(),
            ),
            // 개인 일정 추가하기 버튼
            GestureDetector(
              onTap: _showPersonalEventModal,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppTheme.outline_variant_color,
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
    final currentShift = _getScheduleForDay(_selected_day ?? DateTime.now());
    final shiftTypesMap = ref.watch(shiftTypesMapProvider);
    final shiftInfo = currentShift != null ? shiftTypesMap[currentShift] : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: AppTheme.cardDecoration(),
      child: ClipRRect(
        borderRadius: AppTheme.card_border_radius,
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
                    color: AppTheme.outline_variant_color,
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
                  if (currentShift != null && shiftInfo != null)
                    ShiftBadge(
                      shift_type: currentShift,
                      size: 16,
                      show_label: true,
                    ),
                ],
              ),
            ),
            // 근무 유형 선택 버튼
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShiftTypeButtonGroup(
                    selected_shift: currentShift,
                    onShiftSelected: _onShiftSelected,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '버튼을 누르면 다음 날로 자동 이동합니다',
                    style: AppTheme.body_small.copyWith(
                      color: AppTheme.on_surface_variant_color,
                    ),
                  ),
                ],
              ),
            ),
            // 완료 버튼
            Container(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: AppTheme.primary_color,
                  borderRadius: AppTheme.input_border_radius,
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

  /// 근무표 아이템 위젯
  Widget _buildWorkShiftItem(WorkShiftApiModel workShift, int index) {
    final color = _getWorkShiftColor(workShift);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Dismissible(
        key: Key('${workShift.workShiftId}_$index'),
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
        confirmDismiss: (_) => _confirmDeleteWorkShift(_selected_day),
        onDismissed: (_) {
          // confirmDismiss에서 이미 처리됨
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
                      workShift.shiftTypeName,
                      style: AppTheme.body_medium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.on_surface_color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatWorkShiftTime(workShift),
                      style: AppTheme.body_small.copyWith(
                        color: AppTheme.on_surface_variant_color,
                      ),
                    ),
                  ],
                ),
              ),
              // 삭제 힌트 아이콘
              Icon(
                CupertinoIcons.chevron_left,
                size: 14,
                color: AppTheme.outline_variant_color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 일정(Event) 아이템 위젯
  Widget _buildEventItem(EventApiModel event, int index) {
    // 시간 표시 형식 결정
    String timeDisplay;
    if (event.allDay) {
      timeDisplay = '종일';
    } else {
      final startTime = DateFormat('HH:mm', 'ko_KR').format(event.startAt);
      final endTime = DateFormat('HH:mm', 'ko_KR').format(event.endAt);
      timeDisplay = '$startTime - $endTime';
    }

    // 일정 색상 (기본값: primary color)
    final eventColor = AppTheme.primary_color;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: eventColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: eventColor, width: 4)),
        ),
        child: Row(
          children: [
            // 색상 인디케이터
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: eventColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            // 일정 정보
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
                        timeDisplay,
                        style: AppTheme.body_small.copyWith(
                          color: AppTheme.on_surface_variant_color,
                        ),
                      ),
                      if (event.place != null && event.place!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• ${event.place}',
                          style: AppTheme.body_small.copyWith(
                            color: AppTheme.on_surface_variant_color,
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
      ),
    );
  }

  /// 빈 일정 위젯
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
