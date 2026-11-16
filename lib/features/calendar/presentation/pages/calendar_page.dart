// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/korean_holidays.dart';
import '../../../auth/presentation/pages/settings_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../group/application/group_calendar_provider.dart';
import '../../../friend/presentation/providers/notification_provider.dart';
import '../../application/calendar_range_state.dart';
import '../controllers/calendar_viewport_controller.dart';
import '../models/calendar_day_presentation.dart';
import '../models/calendar_layout_policy.dart';
import '../providers/calendar_range_provider.dart';
import '../providers/shift_types_provider.dart';
import '../widgets/calendar_month_view.dart';
import '../widgets/calendar_schedule_card.dart';
import '../widgets/calendar_delete_toast.dart';
import '../widgets/calendar_viewport.dart';
import '../widgets/personal_event_form_modal.dart';
import '../widgets/shift_type_button.dart';
import '../widgets/year_month_picker_sheet.dart';
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

class _CalendarPageState extends ConsumerState<CalendarPage>
    with WidgetsBindingObserver {
  static final _viewport_controller = const CalendarViewportController();

  CalendarFormat _calendar_format = CalendarFormat.month;
  DateTime _focused_day = DateTime.now();
  DateTime? _selected_day;

  // 근무 추가 모드 상태
  bool _is_shift_add_mode = false;

  // 확장 보기 모드 (날짜 밑에 근무 코드 표시)
  bool _is_expanded_view = true;

  // 포인터 시작 위치 (Listener용)
  double? _pointer_start_y;

  // 임시 스케줄 데이터 (하루에 하나의 근무만 저장)
  final Map<DateTime, String?> _schedules = {};

  // 근무 추가 모드 시작 시 초기 스케줄 상태 저장 (변경사항 추적용)
  Map<DateTime, String?>? _initial_schedules;

  // 개인 일정 삭제 요청 중복 실행 방지
  final Set<String> _deleting_event_ids = {};
  final Set<String> _deleting_work_shift_ids = {};
  final Map<String, EventApiModel> _pending_event_deletions = {};
  final Map<String, WorkShiftApiModel> _pending_work_shift_deletions = {};
  Timer? _delete_timer;
  int _deletion_revision = 0;
  int _delete_toast_revision = 0;
  int? _hidden_delete_toast_revision;
  bool _personal_event_modal_open = false;

  int get _pendingDeletionCount =>
      _pending_event_deletions.length + _pending_work_shift_deletions.length;

  bool get _isShortScreen => MediaQuery.sizeOf(context).height < 750;

  CalendarFormat get _visibleCalendarFormat =>
      CalendarLayoutPolicy.visibleFormat(
        screen_height: MediaQuery.sizeOf(context).height,
        preferred_format: _calendar_format,
      );

  // 확장 모드 시 행 높이
  double get _calendarRowHeight => CalendarLayoutPolicy.rowHeight(
    screen_height: MediaQuery.sizeOf(context).height,
    layout_mode: _is_expanded_view
        ? CalendarCellLayoutMode.detailed
        : CalendarCellLayoutMode.compact,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selected_day = _focused_day;
    // 초기 데이터 로딩
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCalendarData(_focused_day);
      _loadHolidays(_focused_day.year, month: _focused_day.month);
      // 미읽음 알림 개수 조회
      ref.read(notificationProvider.notifier).fetchUnreadCount();
    });
  }

  @override
  void dispose() {
    _delete_timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 사용자가 되돌리기를 누를 수 없는 동안에는 서버 삭제를 예약하지 않는다.
    if (state != AppLifecycleState.resumed) _undoPendingDeletes();
  }

  void _undoPendingDeletes() {
    _delete_timer?.cancel();
    _delete_timer = null;
    if (!mounted || _pendingDeletionCount == 0) return;
    setState(() {
      _pending_event_deletions.clear();
      _pending_work_shift_deletions.clear();
    });
  }

  void _schedulePendingDeletes() {
    _delete_timer?.cancel();
    setState(() => _delete_toast_revision++);
    final account_id = ref.read(authProvider).user?.id;
    final revision = _deletion_revision;
    _delete_timer = Timer(
      Duration(seconds: MediaQuery.accessibleNavigationOf(context) ? 10 : 3),
      () => _commitPendingDeletes(account_id, revision),
    );
  }

  void _dismissDeleteToast(int revision) {
    if (!mounted || revision != _delete_toast_revision) return;
    setState(() => _hidden_delete_toast_revision = revision);
  }

  bool _canApplyDeletion(String? account_id, int revision) =>
      _isSameAccount(account_id) && revision == _deletion_revision;

  Future<void> _commitPendingDeletes(String? account_id, int revision) async {
    _delete_timer = null;
    if (!_canApplyDeletion(account_id, revision)) return;
    final events = _pending_event_deletions.values.toList();
    final work_shifts = _pending_work_shift_deletions.values.toList();
    final errors = <String>{};
    final notices = <String>{};
    setState(() {
      _deleting_event_ids.addAll(_pending_event_deletions.keys);
      _deleting_work_shift_ids.addAll(_pending_work_shift_deletions.keys);
      _pending_event_deletions.clear();
      _pending_work_shift_deletions.clear();
    });
    await Future.wait([
      for (final event in events)
        _deleteEvent(event, account_id, revision, errors, notices),
      for (final work_shift in work_shifts)
        _deleteWorkShift(work_shift, account_id, revision, errors),
    ]);
    if (!_canApplyDeletion(account_id, revision)) return;
    if (errors.isNotEmpty) {
      _showErrorDialog(errors.join('\n'));
    } else if (notices.isNotEmpty) {
      _showInformationDialog(title: '일정 삭제', message: notices.join('\n'));
    }
  }

  /// 날짜 정규화 (시간 제거)
  DateTime _normalizeDate(DateTime date) {
    return normalizeCalendarDate(date);
  }

  /// 공용 공휴일 캐시를 필요한 월 기준으로 갱신한다.
  Future<void> _loadHolidays(int year, {int? month}) async {
    if (month == null) return;

    try {
      await KoreanHolidays.getHolidaysForYear(year, month: month);
      if (mounted) setState(() {});
    } catch (error) {
      debugPrint('공휴일 로딩 실패: $error');
    }
  }

  /// 복원되거나 조회된 공용 캐시에서 공휴일 여부를 확인한다.
  bool _isHoliday(DateTime date) {
    return KoreanHolidays.isFixedHoliday(date);
  }

  /// 3달 데이터 로딩 (전월, 현재월, 다음월)
  Future<void> _loadCalendarData(DateTime focusedMonth) async {
    await ref
        .read(calendarRangeProvider.notifier)
        .ensureMonthLoaded(focusedMonth);
    if (!mounted) return;

    final loaded_work_shifts = ref
        .read(calendarRangeProvider)
        .work_shifts_by_date;
    setState(() {
      for (final entry in loaded_work_shifts.entries) {
        if (!_is_shift_add_mode || !_schedules.containsKey(entry.key)) {
          _schedules[entry.key] = entry.value.shiftTypeCode;
        }
      }
    });
  }

  void _showCalendarRangeError(CalendarRangeState next) {
    final error = next.last_error;
    if (error == null || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showErrorDialog(_getErrorMessage(error));
    });
  }

  void _syncSchedulesFromRange(CalendarRangeState next) {
    if (!mounted) return;
    setState(() {
      for (final entry in next.work_shifts_by_date.entries) {
        if (!_is_shift_add_mode || !_schedules.containsKey(entry.key)) {
          _schedules[entry.key] = entry.value.shiftTypeCode;
        }
      }
    });
  }

  bool _hasRangeChanged(CalendarRangeState? previous, CalendarRangeState next) {
    return !identical(previous?.work_shifts_by_date, next.work_shifts_by_date);
  }

  bool _hasRangeErrorChanged(
    CalendarRangeState? previous,
    CalendarRangeState next,
  ) {
    return next.last_error != null &&
        previous?.error_revision != next.error_revision;
  }

  void _onCalendarRangeChanged(
    CalendarRangeState? previous,
    CalendarRangeState next,
  ) {
    if (_hasRangeChanged(previous, next)) {
      _syncSchedulesFromRange(next);
    }
    if (_hasRangeErrorChanged(previous, next)) {
      _showCalendarRangeError(next);
    }
  }

  /// 선택된 날짜의 스케줄 반환 (하루에 하나의 근무만 반환)
  String? _getScheduleForDay(DateTime day) {
    final normalizedDate = _normalizeDate(day);
    final work_shift = ref.read(calendarRangeProvider).workShiftFor(day);
    if (work_shift != null && _isWorkShiftHidden(work_shift)) return null;
    return _schedules[normalizedDate] ??
        ref
            .read(calendarRangeProvider)
            .workShiftFor(normalizedDate)
            ?.shiftTypeCode;
  }

  /// 선택된 날짜의 서버 근무표 반환
  WorkShiftApiModel? _getWorkShiftForDay(DateTime day) {
    final work_shift = ref.read(calendarRangeProvider).workShiftFor(day);
    return work_shift != null && _isWorkShiftHidden(work_shift)
        ? null
        : work_shift;
  }

  bool _isWorkShiftHidden(WorkShiftApiModel work_shift) =>
      _pending_work_shift_deletions.containsKey(work_shift.workShiftId) ||
      _deleting_work_shift_ids.contains(work_shift.workShiftId);

  void _applyShiftTypeDisplayUpdate(ShiftTypeDisplayUpdate update) {
    final affected_work_shifts = ref
        .read(calendarRangeProvider)
        .work_shifts_by_date
        .entries
        .where((entry) => entry.value.shiftTypeCode == update.previous_code)
        .toList();
    if (affected_work_shifts.isEmpty || !mounted) return;

    final updated_type = update.updated_type;
    final updated_work_shifts = [
      for (final entry in affected_work_shifts)
        entry.value.copyWithShiftType(
          shift_type_code: updated_type.code,
          shift_type_name: updated_type.name,
          shift_type_color: updated_type.color,
          start_time: updated_type.startTime,
          end_time: updated_type.endTime,
        ),
    ];
    ref
        .read(calendarRangeProvider.notifier)
        .upsertWorkShifts(updated_work_shifts);
    setState(() {
      for (final entry in affected_work_shifts) {
        _schedules[entry.key] = updated_type.code;
      }
    });
  }

  Color _getWorkShiftColor(WorkShiftApiModel workShift) {
    return Color(workShift.shiftTypeColor ?? 0xFF8E8E93);
  }

  /// 이전 달로 이동 가능한지 확인
  bool _canGoToPreviousMonth() {
    return _viewport_controller.canMoveMonth(_focused_day, -1);
  }

  /// 다음 달로 이동 가능한지 확인
  bool _canGoToNextMonth() {
    return _viewport_controller.canMoveMonth(_focused_day, 1);
  }

  /// 이전 달로 이동
  void _goToPreviousMonth() {
    final newFocusedDay = _viewport_controller.monthAt(_focused_day, -1);
    if (newFocusedDay == null) return;
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
    final newFocusedDay = _viewport_controller.monthAt(_focused_day, 1);
    if (newFocusedDay == null) return;
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
  Future<void> _showYearMonthPicker() async {
    final selected_date = await showYearMonthPickerSheet(
      context: context,
      initial_date: _focused_day,
      first_year: 2000,
      last_year: 2050,
    );

    if (selected_date == null || !mounted) return;

    setState(() {
      _focused_day = selected_date;
    });
    _loadCalendarData(selected_date);
    _loadHolidays(selected_date.year, month: selected_date.month);
  }

  /// 개인 일정 추가 모달 표시
  Future<void> _showPersonalEventModal({EventApiModel? initial_event}) async {
    if (_personal_event_modal_open ||
        (initial_event != null &&
            _deleting_event_ids.contains(initial_event.eventId))) {
      return;
    }
    _personal_event_modal_open = true;
    final account_id = ref.read(authProvider).user?.id;
    final initialDate = _normalizeDate(_selected_day ?? DateTime.now());
    try {
      await showCupertinoModalPopup<CreateEventRequest>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PersonalEventFormModal(
          initialDate: initialDate,
          initial_event: initial_event,
          onUpdate: initial_event == null
              ? null
              : (request) async {
                  try {
                    final event = await ref
                        .read(calendarServiceProvider)
                        .updateEvent(initial_event.eventId, request);
                    if (!_isSameAccount(account_id)) {
                      return const EventEditSaveResult(
                        EventEditSaveStatus.failed,
                        message: '계정이 변경되어 저장 결과를 표시할 수 없습니다.',
                      );
                    }
                    ref
                        .read(calendarRangeProvider.notifier)
                        .replaceEvent(event);
                    ref.invalidate(groupCalendarRangeProvider);
                    final selected_date = _normalizeDate(
                      _selected_day ?? event.startAt,
                    );
                    final last_date = _normalizeDate(
                      event.endAt.subtract(const Duration(microseconds: 1)),
                    );
                    if (selected_date.isBefore(_normalizeDate(event.startAt)) ||
                        selected_date.isAfter(last_date)) {
                      final event_date = _normalizeDate(event.startAt);
                      setState(() {
                        _selected_day = event_date;
                        _focused_day = event_date;
                      });
                      _loadCalendarData(event_date);
                      _loadHolidays(event_date.year, month: event_date.month);
                    }
                    return const EventEditSaveResult(EventEditSaveStatus.saved);
                  } on ApiException catch (error) {
                    if (!_isSameAccount(account_id)) {
                      return const EventEditSaveResult(
                        EventEditSaveStatus.failed,
                        message: '계정이 변경되었습니다.',
                      );
                    }
                    if (error.code == 'EVENT_NOT_FOUND') {
                      ref
                          .read(calendarRangeProvider.notifier)
                          .removeEvent(initial_event.eventId);
                      ref.invalidate(groupCalendarRangeProvider);
                      return const EventEditSaveResult(
                        EventEditSaveStatus.notFound,
                        message: '이미 삭제되었거나 수정할 수 없는 일정입니다.',
                      );
                    }
                    return EventEditSaveResult(
                      EventEditSaveStatus.failed,
                      message:
                          error.statusCode == null ||
                              (error.statusCode ?? 0) >= 500
                          ? '저장 결과를 확인하지 못했어요. 다시 저장하거나 목록을 다시 확인해주세요.'
                          : error.message,
                    );
                  } catch (error) {
                    return EventEditSaveResult(
                      EventEditSaveStatus.failed,
                      message: _getErrorMessage(error),
                    );
                  }
                },
          onRefresh: initial_event == null
              ? null
              : () async {
                  if (!_isSameAccount(account_id)) return '계정이 변경되었습니다.';
                  final notifier = ref.read(calendarRangeProvider.notifier);
                  await notifier.refreshMonth(_focused_day);
                  if (!_isSameAccount(account_id)) return '계정이 변경되었습니다.';
                  ref.invalidate(groupCalendarRangeProvider);
                  final error = ref.read(calendarRangeProvider).last_error;
                  return error == null ? null : _getErrorMessage(error);
                },
          onSave: (request) async {
            try {
              final event = await ref
                  .read(calendarServiceProvider)
                  .createEvent(request);
              if (!_isSameAccount(account_id)) return '계정이 변경되었습니다.';
              final event_date = _normalizeDate(event.startAt);
              ref.read(calendarRangeProvider.notifier).addEvent(event);
              setState(() {
                _selected_day = event_date;
                _focused_day = event_date;
              });
              _loadCalendarData(event_date);
              _loadHolidays(event_date.year, month: event_date.month);
              return null;
            } catch (error) {
              return _getErrorMessage(error);
            }
          },
        ),
      );
    } finally {
      _personal_event_modal_open = false;
    }
  }

  bool _isSameAccount(String? account_id) =>
      mounted && ref.read(authProvider).user?.id == account_id;

  @override
  Widget build(BuildContext context) {
    final delete_toast_revision = _delete_toast_revision;
    ref.watch(calendarRangeProvider);
    ref.listen(authProvider.select((state) => state.user?.id), (
      previous,
      next,
    ) {
      if (previous == next) return;
      _delete_timer?.cancel();
      _delete_timer = null;
      setState(() {
        _deletion_revision++;
        _pending_event_deletions.clear();
        _pending_work_shift_deletions.clear();
        _deleting_event_ids.clear();
        _deleting_work_shift_ids.clear();
        _schedules.clear();
      });
    });
    ref.listen<CalendarRangeState>(
      calendarRangeProvider,
      _onCalendarRangeChanged,
    );
    ref.listen(shiftTypeDisplayUpdatesProvider, (previous, next) {
      for (final entry in next.entries) {
        if (previous?[entry.key] == entry.value) continue;
        _applyShiftTypeDisplayUpdate(entry.value);
      }
    });

    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: false,
      navigationBar: CupertinoNavigationBar(
        // 달력 아래 일정 목록의 스크롤과 헤더 배경을 분리한다.
        automaticBackgroundVisibility: false,
        backgroundColor: AppTheme.background_color,
        border: null,
        middle: const Text('캘린더'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            Navigator.of(context, rootNavigator: true).push(
              CupertinoPageRoute(builder: (context) => const SettingsPage()),
            );
          },
          child: const Icon(CupertinoIcons.gear),
        ),
      ),
      child: ColoredBox(
        color: AppTheme.background_color,
        child: SafeArea(
          bottom: false,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CalendarPageBody(
                key_prefix: 'main-calendar',
                calendar: _buildCalendarViewport(),
                schedule: _buildSelectedDayInfo(),
              ),
              if (_pendingDeletionCount > 0 &&
                  _hidden_delete_toast_revision != delete_toast_revision)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: SafeArea(
                    top: false,
                    child: CalendarDeleteToast(
                      key: ValueKey(
                        'calendar-delete-notice-$delete_toast_revision',
                      ),
                      count: _pendingDeletionCount,
                      onUndo: _undoPendingDeletes,
                      onDismiss: () =>
                          _dismissDeleteToast(delete_toast_revision),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _goToToday() {
    final today = _normalizeDate(DateTime.now());
    setState(() {
      _focused_day = today;
      _selected_day = today;
    });
    _loadCalendarData(today);
    _loadHolidays(today.year, month: today.month);
  }

  Widget _buildCalendarViewport() {
    return CalendarViewport(
      focused_day: _focused_day,
      can_go_to_previous_month: _canGoToPreviousMonth(),
      can_go_to_next_month: _canGoToNextMonth(),
      onPreviousMonth: _goToPreviousMonth,
      onNextMonth: _goToNextMonth,
      onSelectYearMonth: _showYearMonthPicker,
      onToday: _goToToday,
      trailing: CupertinoButton(
        minimumSize: const Size(44, 44),
        padding: EdgeInsets.zero,
        onPressed: _is_shift_add_mode
            ? _onCancelShiftAddMode
            : _pending_work_shift_deletions.isNotEmpty ||
                  _deleting_work_shift_ids.isNotEmpty
            ? null
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
      grid_wrapper: (child) => Listener(
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: child,
        ),
      ),
      month_view: CalendarMonthView<dynamic>(
        calendar_key: const ValueKey('main-calendar'),
        focused_day: _focused_day,
        selected_day: _selected_day,
        calendar_format: _visibleCalendarFormat,
        row_height: _calendarRowHeight,
        cell_layout: _is_expanded_view
            ? CalendarCellLayout.badge
            : CalendarCellLayout.compact,
        day_presentation_builder: _getDayPresentation,
        holiday_predicate: _isHoliday,
        available_calendar_formats: const {
          CalendarFormat.month: '월',
          CalendarFormat.twoWeeks: '2주',
          CalendarFormat.week: '주',
        },
        onDaySelected: (selected_day, focused_day) {
          setState(() {
            _selected_day = selected_day;
            if (focused_day.month != _focused_day.month ||
                focused_day.year != _focused_day.year) {
              SchedulerBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() => _focused_day = focused_day);
                  _loadCalendarData(focused_day);
                  _loadHolidays(focused_day.year, month: focused_day.month);
                }
              });
            }
          });
        },
        onFormatChanged: _isShortScreen
            ? null
            : (format) {
                setState(() {
                  _calendar_format = format;
                });
              },
        onPageChanged: (focused_day) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _focused_day = focused_day);
              _loadCalendarData(focused_day);
              _loadHolidays(focused_day.year, month: focused_day.month);
            }
          });
        },
      ),
    );
  }

  /// 근무 추가 모드 시작
  void _startShiftAddMode() {
    // 삭제가 끝나기 전에 같은 근무를 다시 저장하는 경합을 막는다.
    if (_pending_work_shift_deletions.isNotEmpty ||
        _deleting_work_shift_ids.isNotEmpty) {
      return;
    }
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

  void _showInformationDialog({
    required String title,
    required String message,
  }) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
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
        Navigator.of(context, rootNavigator: true).pop(); // 로딩 다이얼로그 닫기

        setState(() {
          _is_shift_add_mode = false;
          _initial_schedules = null;
          for (final workShift in response.data.workShifts) {
            final normalizedDate = _normalizeDate(workShift.workDate);
            _schedules[normalizedDate] = workShift.shiftTypeCode;
          }
        });
        ref
            .read(calendarRangeProvider.notifier)
            .upsertWorkShifts(response.data.workShifts);

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
        Navigator.of(context, rootNavigator: true).pop(); // 로딩 다이얼로그 닫기
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

  /// 목록에서만 숨긴다. 원본 캐시는 삭제 성공 전까지 보존한다.
  Future<bool> _confirmDeleteWorkShift(WorkShiftApiModel work_shift) async {
    if (_isWorkShiftHidden(work_shift)) return false;
    setState(() {
      _pending_work_shift_deletions[work_shift.workShiftId] = work_shift;
    });
    _schedulePendingDeletes();
    return false;
  }

  Future<bool> _confirmDeleteEvent(EventApiModel event) async {
    if (_personal_event_modal_open ||
        _pending_event_deletions.containsKey(event.eventId) ||
        _deleting_event_ids.contains(event.eventId)) {
      return false;
    }
    setState(() => _pending_event_deletions[event.eventId] = event);
    _schedulePendingDeletes();
    return false;
  }

  Future<void> _deleteWorkShift(
    WorkShiftApiModel work_shift,
    String? account_id,
    int revision,
    Set<String> errors,
  ) async {
    final work_shift_id = work_shift.workShiftId;
    try {
      await ref.read(workShiftServiceProvider).deleteWorkShift(work_shift_id);
      if (!_canApplyDeletion(account_id, revision)) return;
      final date = _normalizeDate(work_shift.workDate);
      // 대기 중 새로 조회된 다른 근무를 지우지 않는다.
      if (ref.read(calendarRangeProvider).workShiftFor(date)?.workShiftId ==
          work_shift_id) {
        _schedules.remove(date);
        ref.read(calendarRangeProvider.notifier).removeWorkShift(date);
      }
      ref.invalidate(groupCalendarRangeProvider);
    } catch (error) {
      if (_canApplyDeletion(account_id, revision)) {
        errors.add(_getErrorMessage(error));
      }
    } finally {
      if (_canApplyDeletion(account_id, revision)) {
        setState(() => _deleting_work_shift_ids.remove(work_shift_id));
      }
    }
  }

  Future<void> _deleteEvent(
    EventApiModel event,
    String? account_id,
    int revision,
    Set<String> errors,
    Set<String> notices,
  ) async {
    final event_id = event.eventId;
    try {
      final deleted_event_id = await ref
          .read(calendarServiceProvider)
          .deleteEvent(event_id);
      if (!_canApplyDeletion(account_id, revision)) return;
      ref.read(calendarRangeProvider.notifier).removeEvent(deleted_event_id);
      ref.invalidate(groupCalendarRangeProvider);
    } on ApiException catch (error) {
      if (!_canApplyDeletion(account_id, revision)) return;
      if (error.code == 'EVENT_NOT_FOUND') {
        ref.read(calendarRangeProvider.notifier).removeEvent(event_id);
        ref.invalidate(groupCalendarRangeProvider);
        notices.add('이미 삭제된 일정입니다.');
      } else if (error.code == 'INVALID_EVENT_ID') {
        errors.add('일정 정보가 올바르지 않습니다.');
        ref.invalidate(calendarRangeProvider);
        await _loadCalendarData(_focused_day);
      } else {
        errors.add(_getErrorMessage(error));
      }
    } catch (error) {
      if (_canApplyDeletion(account_id, revision)) {
        errors.add(_getErrorMessage(error));
      }
    } finally {
      if (_canApplyDeletion(account_id, revision)) {
        setState(() => _deleting_event_ids.remove(event_id));
      }
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
                Navigator.of(context, rootNavigator: true).pop();
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
    final next_day = (_selected_day ?? DateTime.now()).add(
      const Duration(days: 1),
    );
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final is_month_changed =
            next_day.month != _focused_day.month ||
            next_day.year != _focused_day.year;
        setState(() {
          _selected_day = next_day;
          _focused_day = next_day;
        });
        // 월이 바뀌면 데이터도 함께 로딩
        if (is_month_changed) {
          _loadCalendarData(next_day);
          _loadHolidays(next_day.year, month: next_day.month);
        }
      }
    });
  }

  CalendarDayPresentation _getDayPresentation(DateTime date) {
    final work_shift = _getWorkShiftForDay(date);
    final shift_type = _getScheduleForDay(date);
    final shift_types_map = _is_shift_add_mode
        ? ref.watch(shiftTypesMapProvider)
        : null;
    final edit_shift_info = _is_shift_add_mode && shift_type != null
        ? shift_types_map == null
              ? null
              : shift_types_map[shift_type]
        : null;
    final badge_text = _is_shift_add_mode
        ? shift_type
        : work_shift?.shiftTypeCode;
    final badge_color = _is_shift_add_mode
        ? edit_shift_info?.color ??
              (work_shift == null ? null : _getWorkShiftColor(work_shift))
        : (work_shift == null ? null : _getWorkShiftColor(work_shift));
    final indicator = badge_text == null || badge_color == null
        ? null
        : _is_expanded_view
        ? CalendarBadgeIndicator(text: badge_text, color: badge_color)
        : CalendarDotsIndicator(colors: [badge_color], dot_size: 8);
    return CalendarDayPresentation(
      date_color: _getCalendarDateColor(date),
      indicator: indicator,
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

  /// 포인터 다운 이벤트 처리
  void _onPointerDown(PointerDownEvent event) {
    _pointer_start_y = event.position.dy;
  }

  /// 포인터 이동 이벤트 처리 (확장/축소 모드 전환)
  void _onPointerMove(PointerMoveEvent event) {
    if (_pointer_start_y == null || _is_shift_add_mode) return;

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
    final selectedDate = _selected_day ?? DateTime.now();
    final normalizedDate = _normalizeDate(selectedDate);
    final workShift = _getWorkShiftForDay(selectedDate);
    final holiday_name = _isHoliday(selectedDate)
        ? KoreanHolidays.getHolidayName(selectedDate) ?? '공휴일'
        : null;

    final dayEvents = ref
        .read(calendarRangeProvider)
        .eventsFor(normalizedDate)
        .where(
          (event) =>
              !_pending_event_deletions.containsKey(event.eventId) &&
              !_deleting_event_ids.contains(event.eventId),
        )
        .toList(growable: false);

    return CalendarScheduleCard(
      key: const ValueKey('calendar-schedule-card'),
      selected_date: selectedDate,
      work_shift: workShift,
      events: dayEvents,
      holiday_name: holiday_name,
      work_shift_item_builder: _buildWorkShiftItem,
      event_item_builder: _buildEventItem,
      footer: _buildAddPersonalEventButton(),
    );
  }

  /// 선택일 카드 내부의 개인 일정 추가 액션
  Widget _buildAddPersonalEventButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacing_sm,
        AppTheme.spacing_xs,
        AppTheme.spacing_sm,
        AppTheme.spacing_sm,
      ),
      child: CupertinoButton(
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing_sm,
          vertical: AppTheme.spacing_sm,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radius_md),
        pressedOpacity: 0.65,
        onPressed: _showPersonalEventModal,
        child: Row(
          children: [
            const Icon(
              CupertinoIcons.plus_circle,
              size: 24,
              color: AppTheme.primary_color,
            ),
            const SizedBox(width: AppTheme.spacing_sm),
            Text(
              '일정 추가하기...',
              style: AppTheme.body_medium.copyWith(
                color: AppTheme.primary_color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 근무 설정 모드 overlay
  Widget _buildShiftAddOverlay() {
    final selectedDate = _selected_day ?? DateTime.now();
    final currentShift = _getScheduleForDay(selectedDate);
    final shiftTypesAsync = ref.watch(effectiveShiftTypesProvider);
    final holiday_name = _isHoliday(selectedDate)
        ? KoreanHolidays.getHolidayName(selectedDate) ?? '공휴일'
        : null;

    return Container(
      key: const ValueKey('shift-add-card'),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: AppTheme.cardDecoration(
        color: AppTheme.surface_container_low_color,
      ),
      child: ClipRRect(
        borderRadius: AppTheme.card_border_radius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CalendarScheduleHeader(
              selected_date: selectedDate,
              holiday_name: holiday_name,
              trailing: _buildShiftAddCompleteButton(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: shiftTypesAsync.when(
                        data: (shiftTypes) {
                          if (shiftTypes.isEmpty) {
                            return _buildShiftTypeEmptyState();
                          }

                          final sortedShiftTypes = [...shiftTypes]
                            ..sort(
                              (a, b) => a.sort_order.compareTo(b.sort_order),
                            );

                          return ShiftTypeSelectionGrid(
                            shift_types: sortedShiftTypes,
                            selected_shift: currentShift,
                            onShiftSelected: _onShiftSelected,
                          );
                        },
                        loading: () =>
                            const Center(child: CupertinoActivityIndicator()),
                        error: (error, stackTrace) =>
                            _buildShiftTypeErrorState(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '버튼을 누르면 다음 날로 자동 이동합니다',
                      textAlign: TextAlign.center,
                      style: AppTheme.body_small.copyWith(
                        color: AppTheme.outline_color,
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

  Widget _buildShiftTypeEmptyState() {
    return Center(
      child: Text(
        '등록된 근무 타입이 없습니다',
        style: AppTheme.body_medium.copyWith(
          color: AppTheme.on_surface_variant_color,
        ),
      ),
    );
  }

  Widget _buildShiftTypeErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '근무 타입을 불러오지 못했습니다',
            style: AppTheme.body_medium.copyWith(
              color: AppTheme.on_surface_variant_color,
            ),
          ),
          const SizedBox(height: 8),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.primary_color,
            borderRadius: AppTheme.input_border_radius,
            onPressed: () => ref.invalidate(shiftTypesProvider),
            child: const Text(
              '다시 시도',
              style: TextStyle(color: CupertinoColors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftAddCompleteButton() {
    return SizedBox(
      height: 28,
      child: CupertinoButton(
        minimumSize: const Size(44, 28),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        color: AppTheme.primary_color,
        borderRadius: BorderRadius.circular(AppTheme.radius_md),
        onPressed: _completeShiftAddMode,
        child: const Text(
          '완료',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: CupertinoColors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// 근무표 아이템 위젯
  Widget _buildWorkShiftItem(WorkShiftApiModel workShift, int index) {
    return Container(
      key: ValueKey('calendar-work-shift-row-${workShift.workShiftId}'),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: _RoundedDeleteDismissible(
        dismissible_key: Key('${workShift.workShiftId}_$index'),
        delete_background_key: const ValueKey('work-shift-delete-background'),
        confirm_dismiss: (_) => _confirmDeleteWorkShift(workShift),
        show_delete_label: true,
        child: CalendarWorkShiftItem(
          work_shift: workShift,
          include_margin: false,
          trailing: Icon(
            CupertinoIcons.chevron_left,
            size: 14,
            color: AppTheme.outline_variant_color,
          ),
        ),
      ),
    );
  }

  /// 개인 일정 아이템 위젯
  Widget _buildEventItem(EventApiModel event, int index) {
    final is_deleting = _deleting_event_ids.contains(event.eventId);
    final semantic_label = [
      event.title,
      event.allDay
          ? '종일'
          : '${DateFormat('HH:mm').format(event.startAt)}부터 ${DateFormat('HH:mm').format(event.endAt)}까지',
      event.place,
      event.memo,
      '일정 수정',
    ].whereType<String>().where((value) => value.isNotEmpty).join(', ');
    void openEdit() => _showPersonalEventModal(initial_event: event);
    return Container(
      key: ValueKey('calendar-event-row-${event.eventId}'),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: _RoundedDeleteDismissible(
        dismissible_key: ValueKey('event-${event.eventId}-$index'),
        delete_background_key: const ValueKey('event-delete-background'),
        confirm_dismiss: (_) => _confirmDeleteEvent(event),
        show_delete_label: true,
        is_processing: is_deleting,
        child: Semantics(
          excludeSemantics: true,
          button: true,
          enabled: !is_deleting,
          label: is_deleting ? '${event.title}, 삭제 중' : semantic_label,
          onTap: is_deleting ? null : openEdit,
          customSemanticsActions: is_deleting
              ? null
              : {
                  const CustomSemanticsAction(label: '삭제'): () =>
                      _confirmDeleteEvent(event),
                },
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(48, 48),
            onPressed: is_deleting ? null : openEdit,
            child: CalendarEventItem(
              event,
              include_margin: false,
              trailing: ExcludeSemantics(
                child: is_deleting
                    ? const CupertinoActivityIndicator()
                    : Icon(
                        CupertinoIcons.chevron_left,
                        size: 14,
                        color: AppTheme.outline_variant_color,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundedDeleteDismissible extends StatefulWidget {
  const _RoundedDeleteDismissible({
    required this.dismissible_key,
    required this.delete_background_key,
    required this.confirm_dismiss,
    required this.child,
    this.show_delete_label = false,
    this.is_processing = false,
  });

  final Key dismissible_key;
  final Key delete_background_key;
  final Future<bool> Function(DismissDirection direction) confirm_dismiss;
  final Widget child;
  final bool show_delete_label;
  final bool is_processing;

  @override
  State<_RoundedDeleteDismissible> createState() =>
      _RoundedDeleteDismissibleState();
}

class _RoundedDeleteDismissibleState extends State<_RoundedDeleteDismissible> {
  double _dismiss_progress = 0;

  void _handleDismissUpdate(DismissUpdateDetails details) {
    final next_progress = details.progress.clamp(0.0, 1.0).toDouble();
    if ((_dismiss_progress - next_progress).abs() < 0.0001) return;

    setState(() {
      _dismiss_progress = next_progress;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final reveal_width = constraints.maxWidth * _dismiss_progress;

        return Dismissible(
          key: widget.dismissible_key,
          direction: DismissDirection.endToStart,
          onUpdate: _handleDismissUpdate,
          background: Align(
            alignment: Alignment.centerRight,
            child: Container(
              key: widget.delete_background_key,
              width: reveal_width,
              height: double.infinity,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: AppTheme.spacing_md),
              decoration: BoxDecoration(
                color: CupertinoColors.systemRed.withValues(alpha: 0.1),
                borderRadius: AppTheme.input_border_radius,
              ),
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.centerRight,
                  minWidth: 0,
                  maxWidth: double.infinity,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.is_processing)
                        const CupertinoActivityIndicator(
                          color: CupertinoColors.systemRed,
                        )
                      else
                        const Icon(
                          CupertinoIcons.trash,
                          color: CupertinoColors.systemRed,
                        ),
                      if (widget.show_delete_label && reveal_width >= 88) ...[
                        const SizedBox(width: 6),
                        Text(
                          widget.is_processing ? '삭제 중' : '삭제',
                          style: AppTheme.body_small.copyWith(
                            color: AppTheme.error_text_color,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          confirmDismiss: widget.confirm_dismiss,
          onDismissed: (_) {
            // confirmDismiss에서 이미 처리됨
          },
          child: widget.child,
        );
      },
    );
  }
}
