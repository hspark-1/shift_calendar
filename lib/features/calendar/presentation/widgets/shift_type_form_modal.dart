// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/shift_type_api_model.dart';
import 'shift_color_picker_page.dart';
import 'time_picker_sheet.dart';

const double _body_scale = 0.8;
const double _trailing_content_inset = 21;

double _scaled(double value) => value * _body_scale;

TextStyle _scaledTextStyle(TextStyle style) {
  return style.copyWith(fontSize: (style.fontSize ?? 14) * _body_scale);
}

/// 근무 타입 추가/편집 모달
class ShiftTypeFormModal extends StatefulWidget {
  final ShiftTypeApiModel? shiftType; // null이면 추가, 있으면 편집
  final List<ShiftTypeApiModel> existingTypes; // 코드 중복 체크용

  const ShiftTypeFormModal({
    super.key,
    this.shiftType,
    required this.existingTypes,
  });

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

  @override
  void initState() {
    super.initState();
    final shiftType = widget.shiftType;
    _codeController = TextEditingController(text: shiftType?.code ?? '');
    _nameController = TextEditingController(text: shiftType?.name ?? '');
    _code_focus_node = FocusNode();
    _name_focus_node = FocusNode();

    if (shiftType != null) {
      if (shiftType.color != null) {
        _selectedColor = Color(shiftType.color!);
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

    _codeController.addListener(_handleCodeChanged);
    _code_focus_node.addListener(_handleCodeFocusChanged);
    _name_focus_node.addListener(_handleNameFocusChanged);
  }

  @override
  void dispose() {
    _codeController.removeListener(_handleCodeChanged);
    _code_focus_node.removeListener(_handleCodeFocusChanged);
    _name_focus_node.removeListener(_handleNameFocusChanged);
    _codeController.dispose();
    _nameController.dispose();
    _code_focus_node.dispose();
    _name_focus_node.dispose();
    super.dispose();
  }

  /// 코드 입력값을 대문자로 정규화하고 중복 표시를 즉시 갱신
  void _handleCodeChanged() {
    final normalized_code = _codeController.text.toUpperCase();
    if (_codeController.text != normalized_code) {
      _codeController.value = TextEditingValue(
        text: normalized_code,
        selection: TextSelection.collapsed(offset: normalized_code.length),
      );
      return;
    }

    if (mounted) {
      setState(() {});
    }
  }

  /// 텍스트 필드가 처음 포커스를 받을 때 기존 입력의 끝으로 커서를 이동
  void _handleCodeFocusChanged() {
    _moveCursorToEnd(_codeController, _code_focus_node);
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
    _name_focus_node.requestFocus();
  }

  Future<void> _handleNameSubmitted(String _) async {
    await _selectTime(true);
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
    final selected_color = await Navigator.of(context).push<Color>(
      CupertinoPageRoute(
        builder: (context) =>
            ShiftColorPickerPage(initial_color: _selectedColor),
      ),
    );

    if (selected_color == null || !mounted) return;

    setState(() {
      _selectedColor = selected_color;
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

  /// 시간 제거
  void _clearTime(bool is_start_time) {
    setState(() {
      if (is_start_time) {
        _startTime = null;
      } else {
        _endTime = null;
      }
    });
  }

  /// 유효성 검사
  String? _validate() {
    if (_codeController.text.trim().isEmpty) {
      return '코드를 입력해주세요.';
    }
    if (_nameController.text.trim().isEmpty) {
      return '이름을 입력해주세요.';
    }

    if (_hasDuplicateCode()) {
      return '이미 사용 중인 코드입니다.';
    }

    // 시간 검증: 둘 다 있거나 둘 다 없어야 함
    if ((_startTime != null && _endTime == null) ||
        (_startTime == null && _endTime != null)) {
      return '시작시간과 종료시간을 모두 입력하거나 모두 비워주세요.';
    }

    return null;
  }

  /// 저장
  void _save() {
    _dismissKeyboard();

    final error = _validate();
    if (error != null) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('입력 오류'),
          content: Text(error),
          actions: [
            CupertinoDialogAction(
              child: const Text('확인'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    final code = _codeController.text.trim().toUpperCase();
    final name = _nameController.text.trim();
    final color = _selectedColor.toARGB32();
    final startTime = _startTime != null
        ? _timeOfDayToTimeString(_startTime!)
        : null;
    final endTime = _endTime != null ? _timeOfDayToTimeString(_endTime!) : null;

    if (widget.shiftType == null) {
      // 추가 모드
      Navigator.pop(
        context,
        CreateShiftTypeRequest(
          code: code,
          name: name,
          color: color,
          startTime: startTime,
          endTime: endTime,
        ),
      );
    } else {
      // 편집 모드
      Navigator.pop(
        context,
        UpdateShiftTypeRequest(
          code: code,
          name: name,
          color: color,
          startTime: startTime,
          endTime: endTime,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.shiftType != null;
    final has_duplicate_code = _hasDuplicateCode();
    final bottomPadding = MediaQuery.of(context).padding.bottom + _scaled(32);

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background_color,
      navigationBar: CupertinoNavigationBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.background_color,
        border: const Border(
          bottom: BorderSide(color: AppTheme.outline_variant_color, width: 1),
        ),
        middle: Text(
          isEdit ? '근무 타입 편집' : '근무 타입 추가',
          style: AppTheme.heading_small.copyWith(
            color: AppTheme.on_surface_color,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: CupertinoButton(
          key: const Key('shift_type_back_button'),
          minimumSize: const Size(44, 44),
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(
            CupertinoIcons.chevron_back,
            color: AppTheme.primary_dark_color,
            size: 26,
          ),
        ),
        trailing: CupertinoButton(
          key: const Key('shift_type_complete_button'),
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          onPressed: has_duplicate_code ? null : _save,
          child: Text(
            '완료',
            style: AppTheme.body_large.copyWith(
              color: has_duplicate_code
                  ? AppTheme.outline_color
                  : AppTheme.primary_color,
              fontWeight: FontWeight.w700,
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
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(16, _scaled(28), 16, bottomPadding),
            children: [
              _buildPreviewSection(),
              SizedBox(height: _scaled(28)),
              _buildIdentityCard(),
              SizedBox(height: _scaled(24)),
              Padding(
                padding: EdgeInsets.only(left: _scaled(16), bottom: _scaled(8)),
                child: Text(
                  '근무 시간',
                  style: _scaledTextStyle(AppTheme.body_large).copyWith(
                    color: AppTheme.on_surface_variant_color.withValues(
                      alpha: 0.62,
                    ),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              _buildTimeCard(),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  _scaled(28),
                  _scaled(24),
                  _scaled(28),
                  0,
                ),
                child: Text(
                  '시간을 입력하지 않으면 휴가, 오프 등 시간이 없는 타입으로 설정됩니다.',
                  style: _scaledTextStyle(AppTheme.body_medium).copyWith(
                    color: AppTheme.on_surface_variant_color.withValues(
                      alpha: 0.62,
                    ),
                    height: 1.65,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _codeController,
          builder: (context, child) {
            final previewCode = _codeController.text.trim();

            return Container(
              key: const Key('shift_type_code_preview'),
              width: _scaled(96),
              height: _scaled(96),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _selectedColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.surface_color,
                  width: _scaled(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withValues(alpha: 0.08),
                    blurRadius: _scaled(12),
                    offset: Offset(0, _scaled(4)),
                  ),
                ],
              ),
              child: Text(
                previewCode.isEmpty ? '-' : previewCode,
                style: AppTheme.heading_large.copyWith(
                  color: AppTheme.surface_color,
                  fontSize: _scaled(28),
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
                maxLines: 1,
              ),
            );
          },
        ),
        SizedBox(height: _scaled(16)),
        CupertinoButton(
          key: const Key('shift_type_color_button'),
          minimumSize: const Size(0, 0),
          padding: EdgeInsets.symmetric(
            horizontal: _scaled(14),
            vertical: _scaled(8),
          ),
          color: AppTheme.surface_container_color,
          borderRadius: BorderRadius.circular(999),
          onPressed: _selectColor,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.paintbrush,
                size: _scaled(18),
                color: AppTheme.on_surface_variant_color,
              ),
              SizedBox(width: _scaled(6)),
              Text(
                '색상 변경',
                style: _scaledTextStyle(AppTheme.body_medium).copyWith(
                  color: AppTheme.on_surface_variant_color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: _scaled(4)),
              Icon(
                CupertinoIcons.chevron_right,
                size: _scaled(14),
                color: AppTheme.outline_variant_color,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIdentityCard() {
    final has_duplicate_code = _hasDuplicateCode();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          key: const Key('shift_type_identity_card'),
          decoration: AppTheme.cardDecoration(
            radius: _scaled(AppTheme.card_radius),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                key: const Key('shift_type_code_row'),
                foregroundDecoration: has_duplicate_code
                    ? BoxDecoration(
                        border: Border.all(
                          color: AppTheme.accent_red_color,
                          width: _scaled(2),
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(_scaled(AppTheme.card_radius)),
                        ),
                      )
                    : null,
                child: _buildTextFieldRow(
                  label: '코드',
                  controller: _codeController,
                  placeholder: '최대 3자',
                  maxLength: 3,
                  textCapitalization: TextCapitalization.characters,
                  focus_node: _code_focus_node,
                  text_input_action: TextInputAction.done,
                  onSubmitted: _handleCodeSubmitted,
                ),
              ),
              const Divider(
                height: 0.5,
                thickness: 0.5,
                color: AppTheme.outline_variant_color,
              ),
              _buildTextFieldRow(
                label: '이름',
                controller: _nameController,
                placeholder: '근무 이름',
                focus_node: _name_focus_node,
                text_input_action: TextInputAction.done,
                onSubmitted: _handleNameSubmitted,
              ),
            ],
          ),
        ),
        if (has_duplicate_code)
          Padding(
            padding: EdgeInsets.fromLTRB(
              _scaled(16),
              _scaled(8),
              _scaled(16),
              0,
            ),
            child: Text(
              key: const Key('shift_type_code_duplicate_message'),
              '이미 사용 중인 코드입니다.',
              style: _scaledTextStyle(AppTheme.body_small).copyWith(
                color: AppTheme.accent_red_color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextFieldRow({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required FocusNode focus_node,
    required TextInputAction text_input_action,
    required ValueChanged<String> onSubmitted,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return SizedBox(
      height: _scaled(56),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(left: _scaled(16)),
            child: Text(
              label,
              style: _scaledTextStyle(AppTheme.body_large).copyWith(
                color: AppTheme.on_surface_variant_color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: _scaled(16)),
          Expanded(
            child: CupertinoTextField(
              key: Key('shift_type_${label == '코드' ? 'code' : 'name'}_field'),
              controller: controller,
              focusNode: focus_node,
              placeholder: placeholder,
              maxLength: maxLength,
              textInputAction: text_input_action,
              onSubmitted: onSubmitted,
              textAlign: TextAlign.right,
              textCapitalization: textCapitalization,
              style: _scaledTextStyle(AppTheme.body_large).copyWith(
                color: AppTheme.on_surface_color,
                fontWeight: FontWeight.w500,
              ),
              placeholderStyle: _scaledTextStyle(
                AppTheme.body_medium,
              ).copyWith(color: AppTheme.outline_color),
              padding: EdgeInsets.fromLTRB(
                _scaled(8),
                _scaled(12),
                _scaled(_trailing_content_inset),
                _scaled(12),
              ),
              decoration: null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard() {
    return Container(
      key: const Key('shift_type_time_card'),
      decoration: AppTheme.cardDecoration(
        radius: _scaled(AppTheme.card_radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildTimeRow(
            key: const Key('shift_type_start_time_row'),
            label: '시작 시간',
            time: _startTime,
            onTap: () => _selectTime(true),
            onClear: () => _clearTime(true),
          ),
          const Divider(
            height: 0.5,
            thickness: 0.5,
            color: AppTheme.outline_variant_color,
          ),
          _buildTimeRow(
            key: const Key('shift_type_end_time_row'),
            label: '종료 시간',
            time: _endTime,
            onTap: () => _selectTime(false),
            onClear: () => _clearTime(false),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow({
    required Key key,
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return GestureDetector(
      key: key,
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: _scaled(56),
        child: Row(
          children: [
            SizedBox(width: _scaled(16)),
            Icon(
              CupertinoIcons.clock,
              size: _scaled(21),
              color: AppTheme.on_surface_variant_color,
            ),
            SizedBox(width: _scaled(10)),
            Text(
              label,
              style: _scaledTextStyle(AppTheme.body_large).copyWith(
                color: AppTheme.on_surface_variant_color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              key: Key(
                label == '시작 시간'
                    ? 'shift_type_start_time_value'
                    : 'shift_type_end_time_value',
              ),
              time == null ? '시간 선택' : _timeOfDayToDisplayString(time),
              style: _scaledTextStyle(AppTheme.body_large).copyWith(
                color: time == null
                    ? AppTheme.outline_color
                    : AppTheme.on_surface_color,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (time != null) ...[
              CupertinoButton(
                key: Key(
                  label == '시작 시간'
                      ? 'shift_type_start_time_clear'
                      : 'shift_type_end_time_clear',
                ),
                minimumSize: Size(_scaled(36), 44),
                padding: EdgeInsets.zero,
                onPressed: onClear,
                child: Icon(
                  CupertinoIcons.xmark_circle_fill,
                  size: _scaled(18),
                  color: AppTheme.accent_red_color,
                ),
              ),
            ],
            SizedBox(
              width: _scaled(time == null ? _trailing_content_inset : 12),
            ),
          ],
        ),
      ),
    );
  }
}
