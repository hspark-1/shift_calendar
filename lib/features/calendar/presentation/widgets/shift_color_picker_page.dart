// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_theme.dart';
import 'shift_custom_color_picker_page.dart';
import 'shift_color_selection.dart';

export 'shift_color_selection.dart';

class ShiftColorPickerPage extends StatefulWidget {
  final Color initial_color;
  final Color? initial_base_color;
  final int initial_color_intensity;

  const ShiftColorPickerPage({
    super.key,
    required this.initial_color,
    this.initial_base_color,
    this.initial_color_intensity = 100,
  });

  @override
  State<ShiftColorPickerPage> createState() => _ShiftColorPickerPageState();
}

class _ShiftColorPickerPageState extends State<ShiftColorPickerPage> {
  static const List<_ShiftColorPreset> _presets = [
    _ShiftColorPreset(color: Color(0xFFFF9500), name: '데이 오렌지'),
    _ShiftColorPreset(color: Color(0xFFE85F80), name: '이브닝 핑크'),
    _ShiftColorPreset(color: Color(0xFF4355B8), name: '나이트 인디고'),
    _ShiftColorPreset(color: Color(0xFF448F53), name: '오프 그린'),
    _ShiftColorPreset(color: Color(0xFF00B4D8), name: '스카이 블루'),
    _ShiftColorPreset(color: Color(0xFF9B51E0), name: '로얄 퍼플'),
    _ShiftColorPreset(color: Color(0xFFF2994A), name: '호박색'),
    _ShiftColorPreset(color: Color(0xFF27AE60), name: '에메랄드'),
    _ShiftColorPreset(color: Color(0xFFEB5757), name: '코랄 레드'),
    _ShiftColorPreset(color: Color(0xFF2D9CDB), name: '오션 블루'),
    _ShiftColorPreset(color: Color(0xFFF2C94C), name: '골드'),
    _ShiftColorPreset(color: Color(0xFF333333), name: '차콜'),
  ];

  late Color _base_color;
  late String _color_name;
  late int _color_intensity;

  Color get _selected_color {
    return calculateShiftColor(_base_color, _color_intensity);
  }

  String get _hex_value {
    final argb = _selected_color.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${argb.substring(2).toUpperCase()}';
  }

  int? get _selected_preset_index {
    if (_color_intensity != 100) return null;

    final selected_value = _base_color.toARGB32();
    final index = _presets.indexWhere(
      (preset) => preset.color.toARGB32() == selected_value,
    );
    return index < 0 ? null : index;
  }

  @override
  void initState() {
    super.initState();
    _base_color = (widget.initial_base_color ?? widget.initial_color)
        .withValues(alpha: 1);
    _color_intensity = widget.initial_color_intensity.clamp(0, 100).toInt();
    _color_name = _presetNameForColor(_base_color) ?? '커스텀 색상';
  }

  String? _presetNameForColor(Color color) {
    final color_value = color.toARGB32();
    for (final preset in _presets) {
      if (preset.color.toARGB32() == color_value) {
        return preset.name;
      }
    }
    return null;
  }

  void _selectPreset(int index) {
    final preset = _presets[index];
    setState(() {
      _base_color = preset.color;
      _color_name = preset.name;
      _color_intensity = 100;
    });
  }

  Future<void> _openCustomColorPicker() async {
    final custom_color = await Navigator.of(context).push<ShiftColorSelection>(
      CupertinoPageRoute(
        builder: (context) => ShiftCustomColorPickerPage(
          initial_color: _selected_color,
          initial_base_color: _base_color,
          initial_color_intensity: _color_intensity,
        ),
      ),
    );

    if (custom_color == null || !mounted) return;

    setState(() {
      _base_color = Color(custom_color.base_color);
      _color_name = _presetNameForColor(_base_color) ?? '커스텀 색상';
      _color_intensity = custom_color.color_intensity;
    });
  }

  void _completeSelection() {
    Navigator.of(context).pop(
      ShiftColorSelection(
        final_color: _selected_color.toARGB32(),
        base_color: _base_color.toARGB32(),
        color_intensity: _color_intensity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom_safe_area = MediaQuery.paddingOf(context).bottom;

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background_color,
      navigationBar: CupertinoNavigationBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.background_color,
        border: const Border(
          bottom: BorderSide(color: AppTheme.outline_variant_color, width: 1),
        ),
        leading: CupertinoButton(
          key: const Key('shift_color_back_button'),
          minimumSize: const Size(44, 44),
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(
            CupertinoIcons.chevron_back,
            color: AppTheme.primary_dark_color,
            size: 26,
          ),
        ),
        middle: Text(
          '색상 선택',
          style: AppTheme.heading_small.copyWith(
            color: AppTheme.on_surface_color,
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: CupertinoButton(
          key: const Key('shift_color_complete_button'),
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          onPressed: _completeSelection,
          child: Text(
            '완료',
            style: AppTheme.body_large.copyWith(
              color: AppTheme.primary_color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 32, 16, bottom_safe_area + 40),
          children: [
            _buildPreview(),
            SizedBox(height: 40),
            _buildPresetSection(),
            SizedBox(height: 24),
            _buildCustomColorButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final swatch = AnimatedContainer(
      key: const Key('shift_color_preview'),
      duration: const Duration(milliseconds: 180),
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: _selected_color,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.outline_variant_color),
      ),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '선택한 색상',
          key: const Key('shift_color_selected_label'),
          style: AppTheme.body_medium,
        ),
        const SizedBox(height: 4),
        ConstrainedBox(
          key: const Key('shift_color_name_slot'),
          constraints: const BoxConstraints(minHeight: 24),
          child: Text(
            _color_name,
            key: const Key('shift_color_name_label'),
            style: AppTheme.body_large.copyWith(
              color: AppTheme.primary_dark_color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$_hex_value · 농도 $_color_intensity%',
          key: const Key('shift_color_hex_label'),
          style: AppTheme.body_medium,
        ),
      ],
    );
    return Container(
      key: const Key('shift_color_preview_card'),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 280 ||
              MediaQuery.textScalerOf(context).scale(16) > 20) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [swatch, const SizedBox(height: 16), details],
            );
          }
          return Row(
            key: const Key('shift_color_preview_section'),
            children: [
              swatch,
              const SizedBox(width: 16),
              Container(
                key: const Key('shift_color_preview_divider'),
                width: 1,
                height: 56,
                color: AppTheme.outline_variant_color,
              ),
              const SizedBox(width: 16),
              Expanded(child: details),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPresetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '프리셋 색상',
          style: AppTheme.body_large.copyWith(
            color: AppTheme.on_surface_variant_color,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 16),
        Container(
          key: const Key('shift_color_preset_card'),
          padding: EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration(radius: AppTheme.card_radius),
          child: GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisExtent: 52,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: _presets.length,
            itemBuilder: (context, index) {
              final preset = _presets[index];
              final is_selected = _selected_preset_index == index;
              final check_color = preset.color.computeLuminance() > 0.58
                  ? AppTheme.on_surface_color
                  : AppTheme.surface_color;

              return Semantics(
                button: true,
                selected: is_selected,
                label: preset.name,
                child: GestureDetector(
                  key: Key('shift_color_preset_$index'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _selectPreset(index),
                  child: Center(
                    child: AnimatedContainer(
                      key: Key('shift_color_swatch_$index'),
                      duration: const Duration(milliseconds: 140),
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: preset.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: is_selected
                              ? AppTheme.primary_dark_color
                              : CupertinoColors.black.withValues(alpha: 0.06),
                          width: is_selected ? 3 : 1,
                        ),
                      ),
                      child: is_selected
                          ? Icon(
                              CupertinoIcons.check_mark,
                              color: check_color,
                              size: 22,
                            )
                          : null,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCustomColorButton() {
    return Container(
      decoration: AppTheme.cardDecoration(radius: AppTheme.card_radius),
      child: CupertinoButton(
        key: const Key('shift_color_custom_button'),
        minimumSize: const Size(double.infinity, 44),
        padding: EdgeInsets.symmetric(horizontal: 16),
        borderRadius: BorderRadius.circular(AppTheme.card_radius),
        onPressed: _openCustomColorPicker,
        child: Row(
          children: [
            Icon(
              CupertinoIcons.paintbrush,
              size: 24,
              color: AppTheme.on_surface_variant_color,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '선택한 색상 조절',
                style: AppTheme.body_large.copyWith(
                  color: AppTheme.on_surface_color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 18,
              color: AppTheme.outline_color,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShiftColorPreset {
  final Color color;
  final String name;

  const _ShiftColorPreset({required this.color, required this.name});
}
