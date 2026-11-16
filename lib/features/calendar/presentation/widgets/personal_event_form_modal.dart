// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/event_api_model.dart';
import 'date_picker_sheet.dart';
import 'time_picker_sheet.dart';

enum EventEditSaveStatus { saved, failed, notFound }

class EventEditSaveResult {
  const EventEditSaveResult(this.status, {this.message});
  final EventEditSaveStatus status;
  final String? message;
}

/// 개인 일정 입력과 검증을 소유하며 저장 결과까지 폼을 유지한다.
class PersonalEventFormModal extends StatefulWidget {
  const PersonalEventFormModal({
    super.key,
    required this.initialDate,
    this.onSave,
    this.initial_event,
    this.onUpdate,
    this.onRefresh,
  });

  final DateTime initialDate;
  final Future<String?> Function(CreateEventRequest request)? onSave;
  final EventApiModel? initial_event;
  final Future<EventEditSaveResult> Function(UpdateEventRequest request)?
  onUpdate;
  final Future<String?> Function()? onRefresh;

  @override
  State<PersonalEventFormModal> createState() => _PersonalEventFormModalState();
}

class _PersonalEventFormModalState extends State<PersonalEventFormModal> {
  final _title_controller = TextEditingController();
  final _place_controller = TextEditingController();
  final _memo_controller = TextEditingController();
  final _title_focus = FocusNode();
  final _place_focus = FocusNode();
  final _memo_focus = FocusNode();
  final _form_scroll = ScrollController();
  final _title_key = GlobalKey();
  final _time_key = GlobalKey();
  final _time_error_key = GlobalKey();
  final _details_key = GlobalKey();
  final _visibility_key = GlobalKey();
  bool _picker_open = false;

  late DateTime _start_date;
  late DateTime _end_date;
  Duration _start_time = const Duration(hours: 9);
  Duration _end_time = const Duration(hours: 10);
  bool _all_day = false;
  bool _is_private = false;
  int _visibility_level = 1;
  double _visibility_slider_value = 1;
  bool _dragging_visibility = false;
  bool _details_expanded = true;
  bool _is_saving = false;
  bool _is_closing = false;
  double _sheet_drag_offset = 0;
  bool _dragging_sheet = false;
  bool _body_dragging_sheet = false;
  String? _title_error;
  String? _time_error;
  String? _save_error;

  @override
  void initState() {
    super.initState();
    final initial_date = _dateOnly(widget.initialDate);
    _start_date = initial_date;
    _end_date = initial_date;
    final event = widget.initial_event;
    if (event != null) {
      _title_controller.text = event.title;
      _place_controller.text = event.place ?? '';
      _memo_controller.text = event.memo ?? '';
      _start_date = _dateOnly(event.startAt);
      _end_date = event.allDay
          ? DateTime(event.endAt.year, event.endAt.month, event.endAt.day - 1)
          : _dateOnly(event.endAt);
      if (!event.allDay) {
        _start_time = Duration(
          hours: event.startAt.hour,
          minutes: event.startAt.minute,
        );
        _end_time = Duration(
          hours: event.endAt.hour,
          minutes: event.endAt.minute,
        );
      }
      _all_day = event.allDay;
      _is_private = event.isPrivate;
      _visibility_level = event.visibilityLevel.clamp(1, 5);
      _visibility_slider_value = _visibility_level.toDouble();
    }
    for (final controller in [
      _title_controller,
      _place_controller,
      _memo_controller,
    ]) {
      controller.addListener(_handleTextChanged);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _title_controller,
      _place_controller,
      _memo_controller,
    ]) {
      controller.removeListener(_handleTextChanged);
      controller.dispose();
    }
    _title_focus.dispose();
    _place_focus.dispose();
    _memo_focus.dispose();
    _form_scroll.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    setState(() {
      if (_title_controller.text.trim().isNotEmpty) _title_error = null;
      _save_error = null;
    });
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _combineDateTime(DateTime date, Duration time) => DateTime(
    date.year,
    date.month,
    date.day,
    time.inHours,
    time.inMinutes.remainder(60),
  );

  DateTime _buildStartAt() {
    final original = widget.initial_event;
    if (original != null &&
        _all_day == original.allDay &&
        _start_date == _dateOnly(original.startAt) &&
        (_all_day ||
            _start_time ==
                Duration(
                  hours: original.startAt.hour,
                  minutes: original.startAt.minute,
                ))) {
      return original.startAt;
    }
    return _all_day
        ? _dateOnly(_start_date)
        : _combineDateTime(_start_date, _start_time);
  }

  DateTime _buildEndAt() {
    final original = widget.initial_event;
    final original_date = original == null
        ? null
        : original.allDay
        ? DateTime(
            original.endAt.year,
            original.endAt.month,
            original.endAt.day - 1,
          )
        : _dateOnly(original.endAt);
    if (original != null &&
        _all_day == original.allDay &&
        _end_date == original_date &&
        (_all_day ||
            _end_time ==
                Duration(
                  hours: original.endAt.hour,
                  minutes: original.endAt.minute,
                ))) {
      return original.endAt;
    }
    return _all_day
        ? DateTime(_end_date.year, _end_date.month, _end_date.day + 1)
        : _combineDateTime(_end_date, _end_time);
  }

  CreateEventRequest _formValue() => CreateEventRequest(
    title: _title_controller.text.trim(),
    memo: _emptyToNull(_memo_controller.text),
    place: _emptyToNull(_place_controller.text),
    allDay: _all_day,
    startAt: _buildStartAt(),
    endAt: _buildEndAt(),
    visibilityLevel: _visibility_level,
    isPrivate: _is_private,
  );

  bool get _has_changes =>
      widget.initial_event == null ||
      !_formValue().matchesEvent(widget.initial_event!);

  String _formatDate(DateTime date) =>
      DateFormat('yyyy.MM.dd (E)', 'ko_KR').format(date);

  String _formatTime(Duration time) {
    final hour = time.inHours.remainder(24);
    final minute = time.inMinutes.remainder(60).toString().padLeft(2, '0');
    final display_hour = hour.remainder(12) == 0 ? 12 : hour.remainder(12);
    return '${hour < 12 ? '오전' : '오후'} $display_hour:$minute';
  }

  String _pickerDate(DateTime date) => DateFormat(
    _start_date.year == _end_date.year ? 'M월 d일 (E)' : 'yyyy.MM.dd',
    'ko_KR',
  ).format(date);

  double _pickerTextWidth(BuildContext context, String value) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: MediaQuery.boldTextOf(context)
            ? AppTheme.body_large.copyWith(fontWeight: FontWeight.bold)
            : AppTheme.body_large,
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = painter.width.ceilToDouble();
    painter.dispose();
    return width;
  }

  String get _visibility_description => _is_private
      ? '친구와 그룹에 공개되지 않아요.'
      : '내가 지정한 레벨이 $_visibility_level 이상인 친구에게 보여요.';

  String? _emptyToNull(String value) =>
      value.trim().isEmpty ? null : value.trim();

  void _reveal(GlobalKey section_key, {FocusNode? focus_node}) {
    focus_node?.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final field_context = section_key.currentContext;
      if (field_context == null) return;
      Scrollable.ensureVisible(
        field_context,
        alignment: 0.1,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
      );
    });
  }

  void _requestLeave() {
    if (_is_saving || _is_closing) return;
    _is_closing = true;
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop();
  }

  bool _handleBodyScroll(ScrollNotification notification) {
    if (_is_saving || _is_closing || notification.depth != 0) return false;
    if (notification is OverscrollNotification &&
        notification.dragDetails != null &&
        notification.overscroll < 0 &&
        notification.metrics.pixels <= notification.metrics.minScrollExtent) {
      setState(() {
        _dragging_sheet = true;
        _body_dragging_sheet = true;
        _sheet_drag_offset = (_sheet_drag_offset - notification.overscroll)
            .clamp(0.0, 180.0);
      });
    } else if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null &&
        _sheet_drag_offset > 0 &&
        (notification.scrollDelta ?? 0) > 0) {
      setState(() {
        _sheet_drag_offset = (_sheet_drag_offset - notification.scrollDelta!)
            .clamp(0.0, 180.0);
      });
    } else if (notification is ScrollEndNotification && _body_dragging_sheet) {
      _endSheetDrag(notification.dragDetails ?? DragEndDetails());
    }
    return false;
  }

  void _submitTitle(String value) {
    if (_is_saving || _is_closing || _picker_open) return;
    if (value.trim().isEmpty) {
      setState(() => _title_error = '일정 제목을 입력해주세요.');
      _reveal(_title_key, focus_node: _title_focus);
      return;
    }
    _selectDate(is_start: true, continue_flow: widget.initial_event == null);
  }

  Future<void> _selectDate({
    required bool is_start,
    bool continue_flow = false,
  }) async {
    if (_is_saving || _is_closing || _picker_open) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final current_date = is_start ? _start_date : _end_date;
    if (current_date.year < 2000 || current_date.year > 2050) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('날짜 선택 범위'),
          content: const Text('날짜 변경은 2000년부터 2050년까지 지원해요. 기존 날짜는 그대로 보존됩니다.'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      return;
    }
    _picker_open = true;
    DateTime? result;
    try {
      result = await showDatePickerSheet(
        context: context,
        title: is_start ? '시작일 선택' : '종료일 선택',
        initial_date: is_start ? _start_date : _end_date,
        minimum_date: DateTime(2000, 1, 1),
        maximum_date: DateTime(2050, 12, 31),
        selection_hint: _all_day
            ? '날짜를 고른 뒤 확인을 눌러주세요.'
            : '확인을 누르면 시간 선택으로 이어져요.',
      );
    } finally {
      _picker_open = false;
    }
    if (!mounted || _is_closing || result == null) return;
    final selected_date = result;
    setState(() {
      if (is_start) {
        _start_date = selected_date;
        if (_end_date.isBefore(_start_date)) _end_date = _start_date;
      } else {
        _end_date = selected_date;
        if (_end_date.isBefore(_start_date)) _start_date = _end_date;
      }
      _time_error = null;
      _save_error = null;
    });
    if (!_all_day) {
      await _selectTime(is_start: is_start, continue_flow: continue_flow);
    } else if (continue_flow) {
      if (is_start) {
        await _selectDate(is_start: false, continue_flow: true);
      } else {
        _reveal(_visibility_key);
      }
    }
  }

  Future<void> _selectTime({
    required bool is_start,
    bool continue_flow = false,
  }) async {
    if (_is_saving || _is_closing || _picker_open || _all_day) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _picker_open = true;
    Duration? result;
    try {
      result = await showTimePickerSheet(
        context: context,
        title: is_start ? '시작시간 선택' : '종료시간 선택',
        initial_time: is_start ? _start_time : _end_time,
        selection_hint: continue_flow
            ? is_start
                  ? '시작 시간을 정하면 종료 시간을 선택해요.'
                  : '시간을 적용하면 공개 범위를 확인해요.'
            : '원하는 시간을 선택하세요',
      );
    } finally {
      _picker_open = false;
    }
    if (!mounted || _is_closing || result == null) return;
    final selected_time = result;
    setState(() {
      if (is_start) {
        _start_time = selected_time;
        if (continue_flow && !_buildEndAt().isAfter(_buildStartAt())) {
          final suggested_end = _buildStartAt().add(const Duration(hours: 1));
          _end_date = _dateOnly(suggested_end);
          _end_time = Duration(
            hours: suggested_end.hour,
            minutes: suggested_end.minute,
          );
        }
      } else {
        _end_time = selected_time;
      }
      _time_error = null;
      _save_error = null;
    });
    if (continue_flow) {
      if (is_start) {
        await _selectTime(is_start: false, continue_flow: true);
      } else {
        _reveal(_visibility_key);
      }
    }
  }

  void _setPrivate(bool is_private) {
    if (_is_saving) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _is_private = is_private;
      _dragging_visibility = false;
      _visibility_slider_value = _visibility_level.toDouble();
      _save_error = null;
    });
  }

  void _setVisibilityLevel(int level) {
    if (_is_saving || _is_private) return;
    setState(() {
      _visibility_level = level.clamp(1, 5);
      _visibility_slider_value = _visibility_level.toDouble();
      _dragging_visibility = false;
      _save_error = null;
    });
  }

  void _updateVisibilitySlider(double value) {
    if (_is_saving || _is_private) return;
    setState(() {
      _visibility_slider_value = value.clamp(1.0, 5.0);
      _visibility_level = _visibility_slider_value.round();
      _save_error = null;
    });
  }

  void _endSheetDrag(DragEndDetails _) {
    final should_close = _sheet_drag_offset >= 120;
    setState(() {
      _sheet_drag_offset = 0;
      _dragging_sheet = false;
      _body_dragging_sheet = false;
    });
    if (should_close) _requestLeave();
  }

  Future<void> _save() async {
    if (_is_saving || _is_closing || !_has_changes) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final start_at = _buildStartAt();
    final end_at = _buildEndAt();
    setState(() {
      _title_error = _title_controller.text.trim().isEmpty
          ? '일정 제목을 입력해주세요.'
          : null;
      _time_error = !end_at.isAfter(start_at)
          ? '종료 시각은 시작 시각보다 늦어야 합니다.'
          : null;
      _save_error = null;
    });
    if (_title_error != null) {
      _reveal(_title_key, focus_node: _title_focus);
      return;
    }
    if (_time_error != null) {
      _reveal(_time_error_key);
      return;
    }
    final request = _formValue();
    setState(() => _is_saving = true);
    String? error;
    try {
      if (widget.initial_event != null) {
        final result = await widget.onUpdate?.call(
          UpdateEventRequest(
            title: request.title,
            memo: request.memo,
            place: request.place,
            allDay: request.allDay,
            startAt: request.startAt,
            endAt: request.endAt,
            visibilityLevel: request.visibilityLevel,
            isPrivate: request.isPrivate,
          ),
        );
        if (!mounted) return;
        if (result?.status == EventEditSaveStatus.notFound) {
          await showCupertinoDialog<void>(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('일정 수정'),
              content: Text(result?.message ?? '이미 삭제되었거나 수정할 수 없는 일정입니다.'),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
          if (mounted) {
            setState(() {
              _is_saving = false;
              _is_closing = true;
            });
            await WidgetsBinding.instance.endOfFrame;
            if (mounted) Navigator.of(context).pop();
          }
          return;
        }
        error = result?.status == EventEditSaveStatus.saved
            ? null
            : result?.message ?? '일정을 수정하지 못했습니다. 다시 시도해주세요.';
      } else {
        error = await widget.onSave?.call(request);
      }
    } catch (_) {
      error = '일정을 저장하지 못했습니다. 다시 시도해주세요.';
    }
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _is_saving = false;
        _save_error = error;
      });
      return;
    }
    setState(() {
      _is_closing = true;
      _is_saving = false;
    });
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop(request);
  }

  Future<void> _refreshSavedEvent() async {
    if (_is_saving || widget.onRefresh == null) return;
    setState(() => _is_saving = true);
    String? error;
    try {
      error = await widget.onRefresh!();
    } catch (_) {
      error = '목록을 불러오지 못했습니다. 다시 시도해주세요.';
    }
    if (!mounted) return;
    setState(() {
      _is_saving = false;
      _save_error = error;
    });
    if (error == null) _requestLeave();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final gutter = media.size.width < 360 ? 20.0 : 24.0;
    final keyboard_height = media.viewInsets.bottom;
    final max_height =
        (media.size.height - media.viewPadding.top - keyboard_height - 12)
            .clamp(0.0, media.size.height)
            .toDouble();
    final sheet_height = keyboard_height > 0
        ? max_height
        : (media.size.height * 0.88).clamp(0.0, max_height).toDouble();
    return PopScope<CreateEventRequest>(
      canPop: !_is_saving,
      onPopInvokedWithResult: (did_pop, _) {
        if (did_pop) _is_closing = true;
      },
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(bottom: keyboard_height),
          child: AnimatedContainer(
            duration: _dragging_sheet || media.disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 180),
            transform: Matrix4.translationValues(0, _sheet_drag_offset, 0),
            constraints: const BoxConstraints(maxWidth: 560),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: SizedBox(
                key: const Key('personal-event-sheet'),
                height: sheet_height,
                child: ColoredBox(
                  color: AppTheme.surface_color,
                  child: Column(
                    children: [
                      _buildSheetHeader(),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: Column(
                              children: [
                                Expanded(
                                  child: AbsorbPointer(
                                    absorbing: _is_saving,
                                    child: NotificationListener<ScrollNotification>(
                                      onNotification: _handleBodyScroll,
                                      child: SingleChildScrollView(
                                        key: const Key('personal-event-scroll'),
                                        physics: const ClampingScrollPhysics(
                                          parent:
                                              AlwaysScrollableScrollPhysics(),
                                        ),
                                        controller: _form_scroll,
                                        keyboardDismissBehavior:
                                            ScrollViewKeyboardDismissBehavior
                                                .onDrag,
                                        padding: EdgeInsets.fromLTRB(
                                          gutter,
                                          12,
                                          gutter,
                                          24,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            _buildTitle(),
                                            const SizedBox(height: 16),
                                            _buildDivider(),
                                            const SizedBox(height: 16),
                                            _buildTimeSection(),
                                            const SizedBox(height: 16),
                                            _buildDivider(),
                                            _buildVisibilitySection(),
                                            _buildDivider(),
                                            _buildDetailsSection(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                _buildSaveFooter(gutter),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetHeader() => GestureDetector(
    key: const Key('personal-event-sheet-handle'),
    behavior: HitTestBehavior.opaque,
    onVerticalDragStart: _is_saving
        ? null
        : (_) {
            FocusManager.instance.primaryFocus?.unfocus();
            setState(() => _dragging_sheet = true);
          },
    onVerticalDragUpdate: _is_saving
        ? null
        : (details) => setState(() {
            _sheet_drag_offset = (_sheet_drag_offset + details.delta.dy).clamp(
              0.0,
              180.0,
            );
          }),
    onVerticalDragEnd: _is_saving ? null : _endSheetDrag,
    onVerticalDragCancel: () => setState(() {
      _sheet_drag_offset = 0;
      _dragging_sheet = false;
    }),
    child: Column(
      children: [
        const SizedBox(height: 10),
        ExcludeSemantics(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.outline_variant_color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: Row(
            children: [
              const SizedBox(width: 48),
              Expanded(
                child: Text(
                  widget.initial_event == null ? '개인 일정 추가' : '개인 일정 수정',
                  textAlign: TextAlign.center,
                  style: AppTheme.body_large.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              CupertinoButton(
                key: const Key('personal-event-back-button'),
                minimumSize: const Size(48, 48),
                padding: EdgeInsets.zero,
                onPressed: _is_saving ? null : _requestLeave,
                child: Semantics(
                  label: widget.initial_event == null ? '일정 추가 닫기' : '일정 수정 닫기',
                  child: const Icon(
                    CupertinoIcons.xmark,
                    size: 20,
                    color: AppTheme.on_surface_variant_color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildTitle() => Column(
    key: _title_key,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        '일정 제목',
        style: AppTheme.body_medium.copyWith(
          color: AppTheme.on_surface_variant_color,
        ),
      ),
      const SizedBox(height: 4),
      Semantics(
        label: '일정 제목, 필수',
        child: _buildInput(
          field_key: const Key('personal-event-title-field'),
          controller: _title_controller,
          focus_node: _title_focus,
          placeholder: '어떤 일정인가요?',
          font_size: 26,
          on_submitted: _submitTitle,
        ),
      ),
      if (_title_error != null) _buildError(_title_error!),
    ],
  );

  Widget _buildDivider() =>
      Container(height: 0.5, color: AppTheme.outline_variant_color);

  Widget _buildTimeSection() => Column(
    key: _time_key,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        '날짜와 시간',
        style: AppTheme.body_medium.copyWith(
          color: AppTheme.on_surface_variant_color,
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(child: Text('종일', style: AppTheme.body_large)),
          CupertinoSwitch(
            key: const Key('personal-event-all-day'),
            value: _all_day,
            onChanged: (value) => setState(() {
              _all_day = value;
              _time_error = null;
              _save_error = null;
            }),
          ),
        ],
      ),
      const SizedBox(height: 8),
      _buildDateTimeRow(is_start: true),
      const SizedBox(height: 8),
      _buildDateTimeRow(is_start: false),
      if (_time_error != null) _buildError(_time_error!, key: _time_error_key),
    ],
  );

  Widget _buildDateTimeRow({required bool is_start}) {
    final label = is_start ? '시작' : '종료';
    final date = is_start ? _start_date : _end_date;
    final date_field = _buildPickerButton(
      key: ValueKey('event-date-$label'),
      value: _pickerDate(date),
      semantic_label: '$label일 ${_formatDate(date)}',
      on_pressed: () => _selectDate(is_start: is_start),
    );
    final time_field = _buildPickerButton(
      key: ValueKey('event-time-$label'),
      value: _formatTime(is_start ? _start_time : _end_time),
      semantic_label: '$label 시간',
      filled: true,
      on_pressed: () => _selectTime(is_start: is_start),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // 두 행에서 같은 폭을 예약해 9:00/10:00, 날짜 길이 차이로 정렬이 바뀌지 않는다.
        final label_width = math.max(
          _pickerTextWidth(context, '시작'),
          _pickerTextWidth(context, '종료'),
        );
        final date_width = math.max(
          48.0,
          math.max(
                _pickerTextWidth(context, _pickerDate(_start_date)),
                _pickerTextWidth(context, _pickerDate(_end_date)),
              ) +
              16,
        );
        final time_width = math.max(
          48.0,
          math.max(
                _pickerTextWidth(context, _formatTime(_start_time)),
                _pickerTextWidth(context, _formatTime(_end_time)),
              ) +
              16,
        );
        final values_width = date_width + (_all_day ? 0 : 8 + time_width);
        final inline_label =
            constraints.maxWidth >= label_width + 16 + values_width;
        final inline_values = constraints.maxWidth >= values_width;
        final label_widget = Text(
          label,
          style: AppTheme.body_large.copyWith(
            color: AppTheme.on_surface_variant_color,
          ),
        );
        final values = inline_values
            ? Row(
                children: [
                  Expanded(child: date_field),
                  if (!_all_day) ...[
                    const SizedBox(width: 8),
                    SizedBox(width: time_width, child: time_field),
                  ],
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  date_field,
                  if (!_all_day) ...[const SizedBox(height: 8), time_field],
                ],
              );
        return inline_label
            ? Row(
                children: [
                  SizedBox(width: label_width, child: label_widget),
                  const SizedBox(width: 16),
                  Expanded(child: values),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [label_widget, const SizedBox(height: 4), values],
              );
      },
    );
  }

  Widget _buildPickerButton({
    required Key key,
    required String value,
    required String semantic_label,
    bool filled = false,
    required VoidCallback on_pressed,
  }) => Semantics(
    label: semantic_label,
    child: CupertinoButton(
      key: key,
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      color: filled ? AppTheme.surface_container_low_color : null,
      borderRadius: AppTheme.input_border_radius,
      onPressed: on_pressed,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: AppTheme.body_large,
      ),
    ),
  );

  Widget _buildVisibilitySection() => Padding(
    key: const Key('personal-event-visibility'),
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Column(
      key: _visibility_key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '공개 범위',
          style: AppTheme.body_medium.copyWith(
            color: AppTheme.on_surface_variant_color,
          ),
        ),
        const SizedBox(height: 12),
        CupertinoSlidingSegmentedControl<bool>(
          key: const Key('personal-event-visibility-mode'),
          groupValue: _is_private,
          backgroundColor: AppTheme.surface_container_low_color,
          thumbColor: AppTheme.surface_color,
          padding: const EdgeInsets.all(4),
          children: {
            false: Padding(
              key: const Key('event-visibility-friends'),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Text('친구에게 공개', style: AppTheme.body_large),
            ),
            true: Padding(
              key: const Key('event-visibility-private'),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Text('나만 보기', style: AppTheme.body_large),
            ),
          },
          onValueChanged: (value) {
            if (value != null) _setPrivate(value);
          },
        ),
        if (!_is_private) ...[
          const SizedBox(height: 12),
          Semantics(
            excludeSemantics: true,
            slider: true,
            label: '친구 공개 최소 레벨',
            value: '$_visibility_level',
            increasedValue: _visibility_level < 5
                ? '${_visibility_level + 1}'
                : null,
            decreasedValue: _visibility_level > 1
                ? '${_visibility_level - 1}'
                : null,
            onIncrease: _visibility_level < 5
                ? () => _setVisibilityLevel(_visibility_level + 1)
                : null,
            onDecrease: _visibility_level > 1
                ? () => _setVisibilityLevel(_visibility_level - 1)
                : null,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: _visibility_slider_value),
              duration:
                  _dragging_visibility ||
                      MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CupertinoSlider(
                key: const Key('personal-event-level-slider'),
                value: value,
                min: 1,
                max: 5,
                activeColor: AppTheme.primary_color,
                onChangeStart: (_) =>
                    setState(() => _dragging_visibility = true),
                onChanged: _updateVisibilitySlider,
                onChangeEnd: (value) => _setVisibilityLevel(value.round()),
              ),
            ),
          ),
          Row(
            children: [
              for (var level = 1; level <= 5; level++)
                Expanded(
                  child: Semantics(
                    selected: level == _visibility_level,
                    label: '친구 공개 레벨 $level',
                    child: CupertinoButton(
                      key: ValueKey('event-visibility-$level'),
                      minimumSize: const Size(44, 44),
                      padding: EdgeInsets.zero,
                      onPressed: () => _setVisibilityLevel(level),
                      child: Container(
                        alignment: Alignment.center,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: level == _visibility_level
                              ? AppTheme.primary_color
                              : null,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '$level',
                          style: AppTheme.body_large.copyWith(
                            color: level == _visibility_level
                                ? AppTheme.surface_color
                                : AppTheme.on_surface_variant_color,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Semantics(
          liveRegion: true,
          child: Text(
            _visibility_description,
            style: AppTheme.body_medium.copyWith(
              color: AppTheme.on_surface_variant_color,
            ),
          ),
        ),
        if (widget.initial_event?.visibilityLevel == 0) ...[
          const SizedBox(height: 8),
          Text(
            '기존 레벨 0 일정은 저장할 때 레벨 1 이상으로 변경돼요.',
            style: AppTheme.body_small.copyWith(
              color: AppTheme.on_surface_variant_color,
            ),
          ),
        ],
      ],
    ),
  );

  Widget _buildDetailsSection() => Column(
    key: _details_key,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(
        expanded: _details_expanded,
        child: CupertinoButton(
          key: const Key('personal-event-details-toggle'),
          minimumSize: const Size(48, 64),
          padding: const EdgeInsets.symmetric(vertical: 16),
          onPressed: () {
            if (_details_expanded) {
              _place_focus.unfocus();
              _memo_focus.unfocus();
            }
            setState(() => _details_expanded = !_details_expanded);
          },
          child: Row(
            children: [
              const ExcludeSemantics(
                child: Icon(
                  CupertinoIcons.text_alignleft,
                  size: 22,
                  color: AppTheme.on_surface_variant_color,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text('장소·메모', style: AppTheme.body_large)),
              Text(
                '선택',
                style: AppTheme.body_medium.copyWith(
                  color: AppTheme.on_surface_variant_color,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                _details_expanded
                    ? CupertinoIcons.chevron_up
                    : CupertinoIcons.chevron_down,
                size: 16,
                color: AppTheme.on_surface_variant_color,
              ),
            ],
          ),
        ),
      ),
      if (_details_expanded) ...[
        _buildLabeledInput(
          label: '장소',
          child: _buildInput(
            field_key: const Key('personal-event-place-field'),
            controller: _place_controller,
            focus_node: _place_focus,
            placeholder: '장소를 입력하세요',
            on_submitted: (_) => _memo_focus.requestFocus(),
          ),
        ),
        const SizedBox(height: 16),
        _buildLabeledInput(
          label: '메모',
          child: _buildInput(
            field_key: const Key('personal-event-memo-field'),
            controller: _memo_controller,
            focus_node: _memo_focus,
            placeholder: '기억할 내용을 적어두세요',
            multiline: true,
          ),
        ),
      ],
    ],
  );

  Widget _buildLabeledInput({required String label, required Widget child}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: AppTheme.body_medium.copyWith(
              color: AppTheme.on_surface_variant_color,
            ),
          ),
          const SizedBox(height: 4),
          Semantics(label: label, child: child),
        ],
      );

  Widget _buildInput({
    required Key field_key,
    required TextEditingController controller,
    required FocusNode focus_node,
    required String placeholder,
    double font_size = 16,
    bool multiline = false,
    ValueChanged<String>? on_submitted,
  }) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 52),
    child: CupertinoTextField(
      key: field_key,
      controller: controller,
      focusNode: focus_node,
      placeholder: placeholder,
      padding: const EdgeInsets.symmetric(vertical: 12),
      minLines: multiline ? 3 : 1,
      maxLines: multiline ? null : 1,
      textInputAction: multiline
          ? TextInputAction.newline
          : focus_node == _place_focus
          ? TextInputAction.next
          : TextInputAction.done,
      onSubmitted: on_submitted,
      scrollPadding: const EdgeInsets.all(24),
      style: AppTheme.body_large.copyWith(fontSize: font_size),
      placeholderStyle: AppTheme.body_large.copyWith(
        fontSize: font_size,
        color: AppTheme.on_surface_variant_color,
      ),
      decoration: BoxDecoration(
        border: multiline || font_size == 26
            ? null
            : const Border(
                bottom: BorderSide(
                  color: AppTheme.outline_variant_color,
                  width: 0.5,
                ),
              ),
      ),
    ),
  );

  Widget _buildError(String message, {Key? key}) => Padding(
    key: key,
    padding: const EdgeInsets.only(top: 8),
    child: Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: AppTheme.body_medium.copyWith(color: AppTheme.error_text_color),
      ),
    ),
  );

  Widget _buildSaveFooter(double gutter) => Padding(
    padding: EdgeInsets.fromLTRB(
      gutter,
      12,
      gutter,
      MediaQuery.paddingOf(context).bottom + 16,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_save_error != null) ...[
          _buildError(_save_error!),
          if (widget.onRefresh != null)
            CupertinoButton(
              onPressed: _is_saving ? null : _refreshSavedEvent,
              child: const Text('목록 다시 확인'),
            ),
          const SizedBox(height: 12),
        ],
        CupertinoButton(
          key: const Key('personal-event-save-button'),
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          color: AppTheme.primary_color,
          disabledColor: _is_saving
              ? AppTheme.primary_color
              : AppTheme.surface_container_low_color,
          borderRadius: AppTheme.input_border_radius,
          onPressed: _is_saving || !_has_changes ? null : _save,
          child: _is_saving
              ? Semantics(
                  label: '일정 저장 중',
                  child: const CupertinoActivityIndicator(
                    color: AppTheme.surface_color,
                  ),
                )
              : Text(
                  _save_error != null
                      ? '다시 저장'
                      : widget.initial_event == null
                      ? '일정 저장'
                      : '변경사항 저장',
                  textAlign: TextAlign.center,
                  style: AppTheme.body_large.copyWith(
                    color: _has_changes
                        ? AppTheme.surface_color
                        : AppTheme.on_surface_variant_color,
                  ),
                ),
        ),
      ],
    ),
  );
}
