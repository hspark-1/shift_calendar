// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_theme.dart';
import 'shift_custom_color_picker_page.dart';

const double _body_scale = 0.8;
const double _cupertino_slider_track_inset = 22;

double _scaled(double value) => value * _body_scale;

TextStyle _scaledTextStyle(TextStyle style) {
  return style.copyWith(fontSize: (style.fontSize ?? 14) * _body_scale);
}

class ShiftColorPickerPage extends StatefulWidget {
  final Color initial_color;

  const ShiftColorPickerPage({super.key, required this.initial_color});

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
  double _color_intensity = 1;

  Color get _selected_color {
    return Color.lerp(
      AppTheme.surface_color,
      _base_color,
      _color_intensity,
    )!.withValues(alpha: 1);
  }

  String get _hex_value {
    final argb = _selected_color.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${argb.substring(2).toUpperCase()}';
  }

  int? get _selected_preset_index {
    if (_color_intensity != 1) return null;

    final selected_value = _base_color.toARGB32();
    final index = _presets.indexWhere(
      (preset) => preset.color.toARGB32() == selected_value,
    );
    return index < 0 ? null : index;
  }

  @override
  void initState() {
    super.initState();
    _base_color = widget.initial_color.withValues(alpha: 1);
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
      _color_intensity = 1;
    });
  }

  Future<void> _openCustomColorPicker() async {
    final custom_color = await Navigator.of(context).push<Color>(
      CupertinoPageRoute(
        builder: (context) =>
            ShiftCustomColorPickerPage(initial_color: _selected_color),
      ),
    );

    if (custom_color == null || !mounted) return;

    setState(() {
      _base_color = custom_color.withValues(alpha: 1);
      _color_name = '커스텀 색상';
      _color_intensity = 1;
    });
  }

  void _completeSelection() {
    Navigator.of(context).pop(_selected_color);
  }

  void _setColorIntensity(double value) {
    final next_intensity = value.clamp(0.0, 1.0);
    if (next_intensity == _color_intensity) return;

    setState(() {
      _color_intensity = next_intensity;
    });
  }

  void _updateColorIntensityFromPosition(
    Offset local_position,
    double slider_width,
  ) {
    final track_width = slider_width - (_cupertino_slider_track_inset * 2);
    if (track_width <= 0) return;

    final track_position = local_position.dx - _cupertino_slider_track_inset;
    _setColorIntensity(track_position / track_width);
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
            '적용',
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
          padding: EdgeInsets.fromLTRB(
            16,
            _scaled(32),
            16,
            bottom_safe_area + _scaled(40),
          ),
          children: [
            _buildPreview(),
            SizedBox(height: _scaled(40)),
            _buildPresetSection(),
            SizedBox(height: _scaled(24)),
            _buildColorIntensityCard(),
            SizedBox(height: _scaled(24)),
            _buildCustomColorButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      key: const Key('shift_color_preview_card'),
      padding: EdgeInsets.all(_scaled(20)),
      decoration: AppTheme.cardDecoration(
        radius: _scaled(AppTheme.card_radius),
      ),
      child: Row(
        key: const Key('shift_color_preview_section'),
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedContainer(
            key: const Key('shift_color_preview'),
            duration: const Duration(milliseconds: 180),
            width: _scaled(96),
            height: _scaled(96),
            decoration: BoxDecoration(
              color: _selected_color,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.outline_variant_color,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          SizedBox(width: _scaled(16)),
          Container(
            key: const Key('shift_color_preview_divider'),
            width: 1,
            height: _scaled(56),
            color: AppTheme.outline_variant_color,
          ),
          SizedBox(width: _scaled(16)),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '선택한 색상',
                  key: const Key('shift_color_selected_label'),
                  style: _scaledTextStyle(AppTheme.body_small).copyWith(
                    color: AppTheme.on_surface_variant_color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: _scaled(4)),
                SizedBox(
                  key: const Key('shift_color_name_slot'),
                  height: _scaled(24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _color_name,
                      key: const Key('shift_color_name_label'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _scaledTextStyle(AppTheme.body_large).copyWith(
                        color: AppTheme.primary_dark_color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: _scaled(6)),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.symmetric(
                    horizontal: _scaled(12),
                    vertical: _scaled(5),
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surface_container_low_color,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppTheme.outline_variant_color.withValues(
                        alpha: 0.45,
                      ),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _hex_value,
                    key: const Key('shift_color_hex_label'),
                    style: _scaledTextStyle(AppTheme.body_medium).copyWith(
                      fontFamily: 'Inter',
                      color: AppTheme.on_surface_variant_color,
                      fontWeight: FontWeight.w600,
                      letterSpacing: _scaled(1.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '프리셋 색상',
          style: _scaledTextStyle(AppTheme.body_large).copyWith(
            color: AppTheme.on_surface_variant_color,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: _scaled(16)),
        Container(
          key: const Key('shift_color_preset_card'),
          padding: EdgeInsets.all(_scaled(24)),
          decoration: AppTheme.cardDecoration(
            radius: _scaled(AppTheme.card_radius),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisExtent: 44,
              mainAxisSpacing: _scaled(24),
              crossAxisSpacing: _scaled(16),
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
                      width: _scaled(52),
                      height: _scaled(52),
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
                              size: _scaled(22),
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
      decoration: AppTheme.cardDecoration(
        radius: _scaled(AppTheme.card_radius),
      ),
      child: CupertinoButton(
        key: const Key('shift_color_custom_button'),
        minimumSize: const Size(double.infinity, 44),
        padding: EdgeInsets.symmetric(horizontal: _scaled(16)),
        borderRadius: BorderRadius.circular(_scaled(AppTheme.card_radius)),
        onPressed: _openCustomColorPicker,
        child: Row(
          children: [
            Icon(
              CupertinoIcons.paintbrush,
              size: _scaled(24),
              color: AppTheme.on_surface_variant_color,
            ),
            SizedBox(width: _scaled(12)),
            Expanded(
              child: Text(
                '커스텀 색상 선택',
                style: _scaledTextStyle(AppTheme.body_large).copyWith(
                  color: AppTheme.on_surface_color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: _scaled(18),
              color: AppTheme.outline_color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorIntensityCard() {
    final intensity_percentage = (_color_intensity * 100).round();

    return Container(
      key: const Key('shift_color_intensity_card'),
      padding: EdgeInsets.fromLTRB(
        _scaled(16),
        _scaled(16),
        _scaled(16),
        _scaled(14),
      ),
      decoration: AppTheme.cardDecoration(
        radius: _scaled(AppTheme.card_radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '색상 농도',
                      style: _scaledTextStyle(AppTheme.body_large).copyWith(
                        color: AppTheme.on_surface_color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: _scaled(2)),
                    Text(
                      '불투명하게 색을 옅게 조절해요',
                      style: _scaledTextStyle(AppTheme.body_small).copyWith(
                        color: AppTheme.on_surface_variant_color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: _scaled(12)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _scaled(10),
                  vertical: _scaled(5),
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surface_container_low_color,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppTheme.outline_variant_color,
                    width: 1,
                  ),
                ),
                child: Text(
                  '$intensity_percentage%',
                  key: const Key('shift_color_intensity_label'),
                  style: _scaledTextStyle(AppTheme.body_medium).copyWith(
                    color: AppTheme.primary_dark_color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: _scaled(12)),
          Row(
            children: [
              _buildIntensityEndpoint(
                key: const Key('shift_color_intensity_light_endpoint'),
                color: AppTheme.surface_color,
                semantics_label: '가장 옅은 색상',
              ),
              SizedBox(width: _scaled(8)),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      key: const Key('shift_color_intensity_gesture_area'),
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) {
                        _updateColorIntensityFromPosition(
                          details.localPosition,
                          constraints.maxWidth,
                        );
                      },
                      onHorizontalDragStart: (details) {
                        _updateColorIntensityFromPosition(
                          details.localPosition,
                          constraints.maxWidth,
                        );
                      },
                      onHorizontalDragUpdate: (details) {
                        _updateColorIntensityFromPosition(
                          details.localPosition,
                          constraints.maxWidth,
                        );
                      },
                      child: SizedBox(
                        height: 44,
                        child: IgnorePointer(
                          child: CupertinoSlider(
                            key: const Key('shift_color_intensity_slider'),
                            value: _color_intensity,
                            min: 0,
                            max: 1,
                            activeColor: AppTheme.primary_color,
                            onChanged: _setColorIntensity,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: _scaled(8)),
              _buildIntensityEndpoint(
                key: const Key('shift_color_intensity_original_endpoint'),
                color: _base_color,
                semantics_label: '원본 색상',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntensityEndpoint({
    required Key key,
    required Color color,
    required String semantics_label,
  }) {
    return Semantics(
      label: semantics_label,
      child: AnimatedContainer(
        key: key,
        duration: const Duration(milliseconds: 140),
        width: _scaled(28),
        height: _scaled(28),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.outline_variant_color, width: 1),
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
