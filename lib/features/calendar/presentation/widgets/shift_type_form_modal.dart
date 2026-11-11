// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/shift_type_api_model.dart';
import 'shift_color_picker_page.dart';
import 'time_picker_sheet.dart';

class _UpperCaseTextInputFormatter extends TextInputFormatter {
  const _UpperCaseTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.composing.isValid && !newValue.composing.isCollapsed) {
      return newValue;
    }

    final upper_case_text = newValue.text.toUpperCase();
    if (upper_case_text == newValue.text) {
      return newValue;
    }

    int normalizedOffset(int offset) {
      if (offset < 0) {
        return upper_case_text.length;
      }
      if (offset > upper_case_text.length) {
        return upper_case_text.length;
      }
      return offset;
    }

    return newValue.copyWith(
      text: upper_case_text,
      selection: TextSelection(
        baseOffset: normalizedOffset(newValue.selection.baseOffset),
        extentOffset: normalizedOffset(newValue.selection.extentOffset),
        affinity: newValue.selection.affinity,
        isDirectional: newValue.selection.isDirectional,
      ),
      composing: TextRange.empty,
    );
  }
}

/// 근무 타입 추가/편집 모달
class ShiftTypeFormModal extends StatefulWidget {
  final ShiftTypeApiModel? shiftType; // null이면 추가, 있으면 편집
  final List<ShiftTypeApiModel> existingTypes; // 코드 중복 체크용

  const ShiftTypeFormModal({
    super.key,
    this.shiftType,
    required this.existingTypes,
    this.onCreate,
    this.onUpdate,
  });

  final Future<String?> Function(CreateShiftTypeRequest request)? onCreate;
  final Future<String?> Function(UpdateShiftTypeRequest request)? onUpdate;

  @override
  State<ShiftTypeFormModal> createState() => _ShiftTypeFormModalState();
}

class _ShiftTypeFormModalState extends State<ShiftTypeFormModal> {
  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late FocusNode _code_focus_node;
  late FocusNode _name_focus_node;

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  Color _selectedColor = AppTheme.primary_color;
  Color _selectedBaseColor = AppTheme.primary_color;
  int _selectedColorIntensity = 100;
  bool _didChangeColor = false;
  bool _is_saving = false;
  bool _has_time = false;
  String? _name_error;
  String? _code_error;
  String? _time_error;
  final _name_section_key = GlobalKey();
  final _code_section_key = GlobalKey();
  final _time_section_key = GlobalKey();
  final _form_scroll = ScrollController();
  String? _input_error;
  final ValueNotifier<bool> _show_duplicate_code = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    final shiftType = widget.shiftType;
    _codeController = TextEditingController(text: shiftType?.code ?? '');
    _nameController = TextEditingController(text: shiftType?.name ?? '');
    _code_focus_node = FocusNode();
    _name_focus_node = FocusNode();

    if (shiftType != null) {
      final base_color = shiftType.baseColorValue;
      _selectedColorIntensity = shiftType.colorIntensity.clamp(0, 100).toInt();
      if (base_color != null) {
        _selectedBaseColor = base_color.withValues(alpha: 1);
      }
      if (shiftType.color != null) {
        _selectedColor = Color(shiftType.color!);
      } else if (base_color != null) {
        _selectedColor = calculateShiftColor(
          _selectedBaseColor,
          _selectedColorIntensity,
        );
      }
      if (shiftType.startTime != null) {
        final parts = shiftType.startTime!.split(':');
        _startTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
      if (shiftType.endTime != null) {
        final parts = shiftType.endTime!.split(':');
        _endTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }

    _has_time =
        widget.shiftType == null || _startTime != null || _endTime != null;
    _code_focus_node.addListener(_handleCodeFocusChanged);
    _name_focus_node.addListener(_handleNameFocusChanged);
  }

  @override
  void dispose() {
    _code_focus_node.removeListener(_handleCodeFocusChanged);
    _name_focus_node.removeListener(_handleNameFocusChanged);
    _codeController.dispose();
    _nameController.dispose();
    _code_focus_node.dispose();
    _name_focus_node.dispose();
    _show_duplicate_code.dispose();
    _form_scroll.dispose();
    super.dispose();
  }

  /// 텍스트 필드가 처음 포커스를 받을 때 기존 입력의 끝으로 커서를 이동
  void _handleCodeFocusChanged() {
    if (!_code_focus_node.hasFocus) {
      _setDuplicateCodeVisibility(_hasDuplicateCode());
    }
    _moveCursorToEnd(_codeController, _code_focus_node);
  }

  void _handleCodeChanged(String _) {
    _setDuplicateCodeVisibility(false);
    if (_code_error != null) setState(() => _code_error = null);
  }

  void _setDuplicateCodeVisibility(bool is_visible) {
    if (!mounted || _show_duplicate_code.value == is_visible) {
      return;
    }

    _show_duplicate_code.value = is_visible;
  }

  void _handleNameFocusChanged() {
    _moveCursorToEnd(_nameController, _name_focus_node);
  }

  void _moveCursorToEnd(
    TextEditingController controller,
    FocusNode focus_node,
  ) {
    if (!focus_node.hasFocus) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !focus_node.hasFocus) return;

      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
    });
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _handleCodeSubmitted(String _) {
    _dismissKeyboard();
  }

  void _handleNameSubmitted(String _) {
    _code_focus_node.requestFocus();
  }

  void _setHasTime(bool has_time) {
    _dismissKeyboard();
    setState(() {
      _has_time = has_time;
      _time_error = null;
    });
  }

  bool get _crosses_midnight =>
      _startTime != null &&
      _endTime != null &&
      _startTime!.hour * 60 + _startTime!.minute >
          _endTime!.hour * 60 + _endTime!.minute;

  String get _time_summary {
    if (!_has_time) return '시간 없음';
    if (_startTime == null || _endTime == null) return '시간을 선택해주세요';
    return '${_timeOfDayToDisplayString(_startTime!)} – '
        '${_crosses_midnight ? '다음 날 ' : ''}'
        '${_timeOfDayToDisplayString(_endTime!)}';
  }

  String get _duration_summary {
    final start_minutes = _startTime!.hour * 60 + _startTime!.minute;
    final end_minutes = _endTime!.hour * 60 + _endTime!.minute;
    final duration_minutes = (end_minutes - start_minutes + 1440) % 1440;
    final hours = duration_minutes ~/ 60;
    final minutes = duration_minutes % 60;
    final duration = minutes == 0
        ? '$hours시간'
        : hours == 0
        ? '$minutes분'
        : '$hours시간 $minutes분';
    return '${_crosses_midnight ? '다음 날 종료 · ' : ''}총 $duration';
  }

  /// 현재 템플릿의 다른 근무 타입과 코드가 중복되는지 확인
  bool _hasDuplicateCode() {
    final normalized_code = _codeController.text.trim().toUpperCase();
    if (normalized_code.isEmpty) {
      return false;
    }

    return widget.existingTypes.any((type) {
      if (widget.shiftType != null &&
          type.shiftTypeId == widget.shiftType!.shiftTypeId) {
        return false;
      }

      return type.code.trim().toUpperCase() == normalized_code;
    });
  }

  /// TimeOfDay를 "HH:mm:ss" 형식으로 변환
  String _timeOfDayToTimeString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:00';
  }

  /// TimeOfDay를 "HH:mm" 형식으로 표시
  String _timeOfDayToDisplayString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  /// 색상 선택
  Future<void> _selectColor() async {
    _dismissKeyboard();

    final selected_color = await Navigator.of(context)
        .push<ShiftColorSelection>(
          CupertinoPageRoute(
            builder: (context) => ShiftColorPickerPage(
              initial_color: _selectedColor,
              initial_base_color: _selectedBaseColor,
              initial_color_intensity: _selectedColorIntensity,
            ),
          ),
        );

    if (selected_color == null || !mounted) return;

    setState(() {
      _selectedColor = Color(selected_color.final_color);
      _selectedBaseColor = Color(selected_color.base_color);
      _selectedColorIntensity = selected_color.color_intensity;
      _didChangeColor = true;
    });
  }

  /// 시간 선택
  Future<void> _selectTime(bool isStartTime) async {
    _dismissKeyboard();

    final initial_time = isStartTime ? _startTime : _endTime;
    final selected_time = await showTimePickerSheet(
      context: context,
      title: isStartTime ? '시작시간 선택' : '종료시간 선택',
      initial_time: Duration(
        hours: initial_time?.hour ?? 0,
        minutes: initial_time?.minute ?? 0,
      ),
    );

    if (selected_time == null || !mounted) return;

    setState(() {
      _time_error = null;
      final time = TimeOfDay(
        hour: selected_time.inHours.remainder(24),
        minute: selected_time.inMinutes.remainder(60),
      );
      if (isStartTime) {
        _startTime = time;
      } else {
        _endTime = time;
      }
    });

    if (isStartTime && mounted) {
      await _selectTime(false);
    }
  }

  bool _validate() {
    setState(() {
      _name_error = _nameController.text.trim().isEmpty ? '이름을 입력해주세요.' : null;
      _code_error = _codeController.text.trim().isEmpty ? '코드를 입력해주세요.' : null;
      _time_error = _has_time && (_startTime == null || _endTime == null)
          ? '시작 시간과 종료 시간을 모두 선택해주세요.'
          : null;
    });
    final has_duplicate = _hasDuplicateCode();
    _setDuplicateCodeVisibility(has_duplicate);
    final error_key = _name_error != null
        ? _name_section_key
        : _code_error != null || has_duplicate
        ? _code_section_key
        : _time_error != null
        ? _time_section_key
        : null;
    if (error_key == null) return true;
    if (_name_error != null) {
      _name_focus_node.requestFocus();
    } else if (_code_error != null || has_duplicate) {
      _code_focus_node.requestFocus();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || error_key.currentContext == null) return;
      Scrollable.ensureVisible(error_key.currentContext!, alignment: 0.1);
    });
    return false;
  }

  /// 저장
  Future<void> _save() async {
    if (_is_saving) return;
    _dismissKeyboard();

    if (!_validate()) return;

    final code = _codeController.text.trim().toUpperCase();
    final name = _nameController.text.trim();
    final base_color = _selectedBaseColor.toARGB32();
    final startTime = _has_time && _startTime != null
        ? _timeOfDayToTimeString(_startTime!)
        : null;
    final endTime = _has_time && _endTime != null
        ? _timeOfDayToTimeString(_endTime!)
        : null;

    if (widget.shiftType == null) {
      // 추가 모드
      await _submit(
        CreateShiftTypeRequest(
          code: code,
          name: name,
          baseColor: base_color,
          colorIntensity: _selectedColorIntensity,
          startTime: startTime,
          endTime: endTime,
        ),
        widget.onCreate,
      );
    } else {
      // 편집 모드
      await _submit(
        UpdateShiftTypeRequest(
          code: code,
          name: name,
          baseColor: _didChangeColor ? base_color : null,
          colorIntensity: _didChangeColor ? _selectedColorIntensity : null,
          startTime: startTime,
          endTime: endTime,
        ),
        widget.onUpdate,
      );
    }
  }

  Future<void> _submit<T>(
    T request,
    Future<String?> Function(T)? onSave,
  ) async {
    if (onSave == null) {
      Navigator.pop(context, request);
      return;
    }
    setState(() {
      _is_saving = true;
      _input_error = null;
    });
    String? error;
    try {
      error = await onSave(request);
    } catch (_) {
      error = '근무 타입을 저장하지 못했습니다. 다시 시도해주세요.';
    }
    if (!mounted) return;
    setState(() => _is_saving = false);
    if (error != null) {
      setState(() => _input_error = error);
      return;
    }
    Navigator.pop(context, request);
  }

  @override
  Widget build(BuildContext context) {
    final is_edit = widget.shiftType != null;
    return PopScope(
      canPop: !_is_saving,
      child: CupertinoPageScaffold(
        backgroundColor: AppTheme.background_color,
        navigationBar: CupertinoNavigationBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppTheme.background_color,
          border: const Border(
            bottom: BorderSide(
              color: AppTheme.outline_variant_color,
              width: 0.5,
            ),
          ),
          middle: Text(
            is_edit ? '근무 타입 편집' : '근무 타입 추가',
            style: AppTheme.heading_small,
          ),
          leading: CupertinoButton(
            key: const Key('shift_type_back_button'),
            minimumSize: const Size(44, 44),
            padding: EdgeInsets.zero,
            onPressed: _is_saving ? null : () => Navigator.pop(context),
            child: Semantics(
              label: '뒤로가기',
              child: Icon(
                CupertinoIcons.chevron_back,
                size: 26,
                color: _is_saving
                    ? AppTheme.outline_color
                    : AppTheme.primary_dark_color,
              ),
            ),
          ),
        ),
        child: GestureDetector(
          key: const Key('shift_type_keyboard_dismiss_area'),
          behavior: HitTestBehavior.translucent,
          onTap: _dismissKeyboard,
          child: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  children: [
                    Expanded(
                      child: AbsorbPointer(
                        absorbing: _is_saving,
                        child: SingleChildScrollView(
                          controller: _form_scroll,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildPreviewSection(),
                              const SizedBox(height: 20),
                              _buildIdentityCard(),
                              const SizedBox(height: 16),
                              _buildColorRow(),
                              const SizedBox(height: 20),
                              _buildTimeCard(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildSaveFooter(is_edit),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveFooter(bool is_edit) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_input_error != null) ...[
            _buildError(
              _input_error!,
              key: const Key('shift-type-input-error'),
            ),
            const SizedBox(height: 12),
          ],
          ValueListenableBuilder<bool>(
            valueListenable: _show_duplicate_code,
            builder: (context, has_duplicate_code, child) => CupertinoButton(
              key: const Key('shift_type_complete_button'),
              minimumSize: const Size(44, 52),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              color: AppTheme.primary_color,
              disabledColor: AppTheme.surface_container_highest_color,
              borderRadius: AppTheme.input_border_radius,
              onPressed: has_duplicate_code || _is_saving ? null : _save,
              child: _is_saving
                  ? Semantics(
                      label: '근무 타입 저장 중',
                      child: const CupertinoActivityIndicator(),
                    )
                  : Text(
                      is_edit ? '변경사항 저장' : '근무 타입 추가',
                      textAlign: TextAlign.center,
                      style: AppTheme.body_large.copyWith(
                        color: has_duplicate_code
                            ? AppTheme.on_surface_variant_color
                            : AppTheme.surface_color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    return AnimatedBuilder(
      animation: Listenable.merge([_codeController, _nameController]),
      builder: (context, child) {
        final preview_code = _codeController.text.trim();
        final preview_name = _nameController.text.trim();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '캘린더에 표시될 모습',
              style: AppTheme.body_medium.copyWith(
                color: AppTheme.on_surface_variant_color,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  key: const Key('shift_type_code_preview'),
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.outline_variant_color.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        preview_code.isEmpty ? '–' : preview_code,
                        style: AppTheme.body_large.copyWith(
                          color: AppTheme.readableForegroundColor(
                            _selectedColor,
                          ),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preview_name.isEmpty ? '근무 이름' : preview_name,
                        key: const Key('shift_type_name_preview'),
                        style: AppTheme.body_large.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _time_summary,
                        key: const Key('shift_type_time_preview'),
                        style: AppTheme.body_medium.copyWith(
                          color: AppTheme.on_surface_variant_color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildIdentityCard() {
    final code_field = _buildTextField(
      label: '캘린더 표시 코드',
      controller: _codeController,
      placeholder: '예: D, N, OFF',
      focus_node: _code_focus_node,
      onSubmitted: _handleCodeSubmitted,
      is_code: true,
    );
    return Column(
      key: const Key('shift_type_identity_card'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          key: _name_section_key,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              label: '이름',
              controller: _nameController,
              placeholder: '예: 데이, 야간, 오프',
              focus_node: _name_focus_node,
              onSubmitted: _handleNameSubmitted,
            ),
            if (_name_error != null) _buildError(_name_error!),
          ],
        ),
        const SizedBox(height: 20),
        Column(
          key: _code_section_key,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            code_field,
            const SizedBox(height: 6),
            ValueListenableBuilder<bool>(
              valueListenable: _show_duplicate_code,
              builder: (context, has_duplicate_code, child) {
                if (has_duplicate_code) {
                  return _buildError(
                    '이미 사용 중인 코드입니다.',
                    key: const Key('shift_type_code_duplicate_message'),
                  );
                }
                if (_code_error != null) return _buildError(_code_error!);
                return Text(
                  '최대 3자 · 캘린더에 짧게 표시됩니다.',
                  style: AppTheme.body_medium.copyWith(
                    color: AppTheme.on_surface_variant_color,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required FocusNode focus_node,
    required ValueChanged<String> onSubmitted,
    bool is_code = false,
  }) {
    final field = Semantics(
      label: label,
      child: CupertinoTextField(
        key: Key(is_code ? 'shift_type_code_field' : 'shift_type_name_field'),
        controller: controller,
        focusNode: focus_node,
        placeholder: placeholder,
        maxLength: is_code ? 3 : null,
        textInputAction: is_code ? TextInputAction.done : TextInputAction.next,
        textCapitalization: is_code
            ? TextCapitalization.characters
            : TextCapitalization.none,
        onSubmitted: onSubmitted,
        onChanged: is_code
            ? _handleCodeChanged
            : (_) {
                if (_name_error != null) setState(() => _name_error = null);
              },
        inputFormatters: is_code
            ? const [_UpperCaseTextInputFormatter()]
            : null,
        style: AppTheme.body_large,
        placeholderStyle: AppTheme.body_large.copyWith(
          color: AppTheme.outline_color,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface_color,
          borderRadius: AppTheme.input_border_radius,
          border: Border.all(color: AppTheme.outline_variant_color),
        ),
      ),
    );
    return Column(
      key: is_code ? const Key('shift_type_code_row') : null,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.body_medium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (is_code)
          Stack(
            children: [
              field,
              Positioned.fill(
                child: IgnorePointer(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _show_duplicate_code,
                    builder: (context, has_duplicate_code, child) => Container(
                      key: Key(
                        has_duplicate_code
                            ? 'shift_type_code_error_border'
                            : 'shift_type_code_error_border_hidden',
                      ),
                      decoration: has_duplicate_code
                          ? BoxDecoration(
                              border: Border.all(
                                color: AppTheme.accent_red_color,
                                width: 2,
                              ),
                              borderRadius: AppTheme.input_border_radius,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          field,
      ],
    );
  }

  Widget _buildColorRow() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.outline_variant_color, width: 0.5),
          bottom: BorderSide(color: AppTheme.outline_variant_color, width: 0.5),
        ),
      ),
      child: CupertinoButton(
        key: const Key('shift_type_color_button'),
        minimumSize: const Size(44, 56),
        padding: const EdgeInsets.symmetric(vertical: 12),
        onPressed: _selectColor,
        child: Row(
          children: [
            Expanded(child: Text('표시 색상', style: AppTheme.body_large)),
            const SizedBox(width: 12),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _selectedColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.outline_variant_color),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: AppTheme.on_surface_variant_color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard() {
    return Column(
      key: _time_section_key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '근무 시간',
          style: AppTheme.body_large.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: Text('시간 지정', style: AppTheme.body_large)),
            const SizedBox(width: 12),
            Semantics(
              label: '시간 지정',
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 51, minHeight: 44),
                child: CupertinoSwitch(
                  key: const Key('shift_type_has_time_switch'),
                  value: _has_time,
                  activeTrackColor: AppTheme.primary_color,
                  onChanged: _setHasTime,
                ),
              ),
            ),
          ],
        ),
        if (_has_time) ...[
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final start_field = _buildTimeField(is_start: true);
              final end_field = _buildTimeField(is_start: false);
              final use_columns =
                  constraints.maxWidth >= 340 &&
                  MediaQuery.textScalerOf(context).scale(16) <= 20;
              return Container(
                key: const Key('shift_type_time_card'),
                child: use_columns
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: start_field),
                          const SizedBox(width: 12),
                          Expanded(child: end_field),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          start_field,
                          const SizedBox(height: 12),
                          end_field,
                        ],
                      ),
              );
            },
          ),
          if (_time_error != null) ...[
            const SizedBox(height: 8),
            _buildError(_time_error!, key: const Key('shift_type_time_error')),
          ],
          if (_startTime != null && _endTime != null) ...[
            const SizedBox(height: 12),
            Container(
              key: const Key('shift_type_duration_summary'),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surface_container_color,
                borderRadius: AppTheme.input_border_radius,
              ),
              child: Text(_duration_summary, style: AppTheme.body_medium),
            ),
            const SizedBox(height: 6),
            Text(
              '휴게시간을 제외하지 않은 시간입니다.',
              style: AppTheme.body_medium.copyWith(
                color: AppTheme.on_surface_variant_color,
              ),
            ),
          ],
        ] else ...[
          const SizedBox(height: 8),
          Text(
            '오프·휴가처럼 정해진 시간이 없는 타입입니다.',
            style: AppTheme.body_medium.copyWith(
              color: AppTheme.on_surface_variant_color,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeField({required bool is_start}) {
    final label = is_start ? '시작 시간' : '종료 시간';
    final time = is_start ? _startTime : _endTime;
    return CupertinoButton(
      key: Key(
        is_start ? 'shift_type_start_time_row' : 'shift_type_end_time_row',
      ),
      minimumSize: const Size(44, 56),
      padding: const EdgeInsets.all(14),
      color: AppTheme.surface_color,
      borderRadius: AppTheme.input_border_radius,
      onPressed: () => _selectTime(is_start),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTheme.body_medium.copyWith(
                color: AppTheme.on_surface_variant_color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              time == null ? '시간 선택' : _timeOfDayToDisplayString(time),
              key: Key(
                is_start
                    ? 'shift_type_start_time_value'
                    : 'shift_type_end_time_value',
              ),
              style: AppTheme.body_large.copyWith(fontWeight: FontWeight.w600),
            ),
            if (!is_start && _crosses_midnight) ...[
              const SizedBox(height: 4),
              Text(
                '다음 날',
                style: AppTheme.body_medium.copyWith(
                  color: AppTheme.primary_dark_color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message, {Key? key}) {
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          message,
          key: key,
          style: AppTheme.body_medium.copyWith(
            color: AppTheme.accent_red_color,
          ),
        ),
      ),
    );
  }
}
