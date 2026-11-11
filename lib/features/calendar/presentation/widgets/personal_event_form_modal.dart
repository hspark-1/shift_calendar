// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/event_api_model.dart';
import 'date_picker_sheet.dart';
import 'time_picker_sheet.dart';

/// 개인 일정 입력과 검증을 소유하며 저장 결과까지 폼을 유지한다.
class PersonalEventFormModal extends StatefulWidget {
  const PersonalEventFormModal({
    super.key,
    required this.initialDate,
    this.onSave,
  });

  final DateTime initialDate;
  final Future<String?> Function(CreateEventRequest request)? onSave;

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

  late DateTime _start_date;
  late DateTime _end_date;
  Duration _start_time = const Duration(hours: 9);
  Duration _end_time = const Duration(hours: 10);
  bool _all_day = false;
  bool _is_private = false;
  int _visibility_level = 0;
  bool _details_expanded = false;
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

  DateTime _buildStartAt() => _all_day
      ? _dateOnly(_start_date)
      : _combineDateTime(_start_date, _start_time);

  DateTime _buildEndAt() => _all_day
      ? DateTime(_end_date.year, _end_date.month, _end_date.day + 1)
      : _combineDateTime(_end_date, _end_time);

  String _formatDate(DateTime date) =>
      DateFormat('yyyy.MM.dd (E)', 'ko_KR').format(date);

  String _formatTime(Duration time) {
    final hour = time.inHours.remainder(24);
    final minute = time.inMinutes.remainder(60).toString().padLeft(2, '0');
    final display_hour = hour.remainder(12) == 0 ? 12 : hour.remainder(12);
    return '${hour < 12 ? '오전' : '오후'} $display_hour:$minute';
  }

  String get _visibility_description => _is_private
      ? '친구와 그룹에 공개되지 않아요.'
      : _visibility_level == 0
      ? '내 캘린더 열람을 허용한 친구에게 보여요.'
      : '열람을 허용한 친구 중, 내가 지정한 레벨이 $_visibility_level 이상인 친구에게 보여요.';

  String get _duration_summary {
    if (_all_day) {
      final days = DateTime.utc(_end_date.year, _end_date.month, _end_date.day)
          .difference(
            DateTime.utc(_start_date.year, _start_date.month, _start_date.day),
          )
          .inDays;
      return '종일 · ${days + 1}일';
    }
    final minutes = _buildEndAt().difference(_buildStartAt()).inMinutes;
    if (minutes <= 0) return '종료 시각은 시작 시각보다 늦게 선택해주세요.';
    final hours = minutes ~/ 60;
    final remainder = minutes.remainder(60);
    final duration = [
      if (hours > 0) '$hours시간',
      if (remainder > 0) '$remainder분',
    ].join(' ');
    final day_difference =
        DateTime.utc(_end_date.year, _end_date.month, _end_date.day)
            .difference(
              DateTime.utc(
                _start_date.year,
                _start_date.month,
                _start_date.day,
              ),
            )
            .inDays;
    return '${day_difference == 1
        ? '다음 날 종료 · '
        : day_difference > 1
        ? '$day_difference일 뒤 종료 · '
        : ''}$duration';
  }

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

  Future<void> _selectDate({required bool is_start}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final result = await showDatePickerSheet(
      context: context,
      title: is_start ? '시작일 선택' : '종료일 선택',
      initial_date: is_start ? _start_date : _end_date,
      minimum_date: DateTime(2000, 1, 1),
      maximum_date: DateTime(2050, 12, 31),
    );
    if (!mounted || result == null) return;
    setState(() {
      if (is_start) {
        _start_date = result;
        if (_end_date.isBefore(_start_date)) _end_date = _start_date;
      } else {
        _end_date = result;
        if (_end_date.isBefore(_start_date)) _start_date = _end_date;
      }
      _time_error = null;
      _save_error = null;
    });
  }

  Future<void> _selectTime({required bool is_start}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final result = await showTimePickerSheet(
      context: context,
      title: is_start ? '시작시간 선택' : '종료시간 선택',
      initial_time: is_start ? _start_time : _end_time,
    );
    if (!mounted || result == null) return;
    setState(() {
      if (is_start) {
        _start_time = result;
      } else {
        _end_time = result;
      }
      _time_error = null;
      _save_error = null;
    });
  }

  void _setPrivate(bool is_private) {
    if (_is_saving) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _is_private = is_private;
      _save_error = null;
    });
  }

  void _setVisibilityLevel(int level) {
    if (_is_saving || _is_private) return;
    setState(() {
      _visibility_level = level.clamp(0, 5);
      _save_error = null;
    });
  }

  void _endSheetDrag(DragEndDetails details) {
    final should_close =
        _sheet_drag_offset > 64 || (details.primaryVelocity ?? 0) > 700;
    setState(() {
      _sheet_drag_offset = 0;
      _dragging_sheet = false;
      _body_dragging_sheet = false;
    });
    if (should_close) _requestLeave();
  }

  Future<void> _save() async {
    if (_is_saving || _is_closing) return;
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
    final request = CreateEventRequest(
      title: _title_controller.text.trim(),
      memo: _emptyToNull(_memo_controller.text),
      place: _emptyToNull(_place_controller.text),
      allDay: _all_day,
      startAt: start_at,
      endAt: end_at,
      visibilityLevel: _visibility_level,
      isPrivate: _is_private,
    );
    setState(() => _is_saving = true);
    String? error;
    try {
      error = await widget.onSave?.call(request);
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
                  '개인 일정 추가',
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
                  label: '일정 추가 닫기',
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
          on_submitted: (_) => _title_focus.unfocus(),
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
      Row(
        children: [
          Expanded(
            child: Text(
              '날짜와 시간',
              style: AppTheme.body_medium.copyWith(
                color: AppTheme.on_surface_variant_color,
              ),
            ),
          ),
          Text(
            '${_start_date.year}년',
            style: AppTheme.body_medium.copyWith(
              color: AppTheme.on_surface_variant_color,
            ),
          ),
        ],
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
      const SizedBox(height: 8),
      Semantics(
        liveRegion: true,
        child: Text(
          _duration_summary,
          key: const Key('personal-event-duration'),
          textAlign: TextAlign.right,
          style: AppTheme.body_medium.copyWith(color: AppTheme.primary_color),
        ),
      ),
      if (_time_error != null) _buildError(_time_error!, key: _time_error_key),
    ],
  );

  Widget _buildDateTimeRow({required bool is_start}) {
    final label = is_start ? '시작' : '종료';
    final date = is_start ? _start_date : _end_date;
    final date_field = _buildPickerButton(
      key: ValueKey('event-date-$label'),
      value: DateFormat(
        _start_date.year == _end_date.year ? 'M월 d일 (E)' : 'yyyy.MM.dd',
        'ko_KR',
      ).format(date),
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
        final stacked =
            constraints.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(16) > 20;
        return Row(
          crossAxisAlignment: stacked
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                label,
                style: AppTheme.body_large.copyWith(
                  color: AppTheme.on_surface_variant_color,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: stacked
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        date_field,
                        if (!_all_day) ...[
                          const SizedBox(height: 8),
                          time_field,
                        ],
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(flex: 3, child: date_field),
                        if (!_all_day) ...[
                          const SizedBox(width: 8),
                          Expanded(flex: 2, child: time_field),
                        ],
                      ],
                    ),
            ),
          ],
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
            label: '친구 공개 최소 레벨',
            value: '$_visibility_level',
            child: CupertinoSlider(
              key: const Key('personal-event-level-slider'),
              value: _visibility_level.toDouble(),
              min: 0,
              max: 5,
              divisions: 5,
              activeColor: AppTheme.primary_color,
              onChanged: (value) => _setVisibilityLevel(value.round()),
            ),
          ),
          Row(
            children: [
              for (var level = 0; level <= 5; level++)
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
          const SizedBox(height: 12),
        ],
        CupertinoButton(
          key: const Key('personal-event-save-button'),
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          color: AppTheme.primary_color,
          borderRadius: AppTheme.input_border_radius,
          onPressed: _is_saving ? null : _save,
          child: _is_saving
              ? Semantics(
                  label: '일정 저장 중',
                  child: const CupertinoActivityIndicator(
                    color: AppTheme.surface_color,
                  ),
                )
              : Text(
                  _save_error == null ? '일정 저장' : '다시 저장',
                  textAlign: TextAlign.center,
                  style: AppTheme.body_large.copyWith(
                    color: AppTheme.surface_color,
                  ),
                ),
        ),
      ],
    ),
  );
}
