// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_theme.dart';

const double _body_scale = 0.8;
const String _recent_colors_storage_key = 'shift_custom_recent_colors_v1';
const int _max_recent_colors = 6;

double _scaled(double value) => value * _body_scale;

TextStyle _scaledTextStyle(TextStyle style) {
  return style.copyWith(fontSize: (style.fontSize ?? 14) * _body_scale);
}

class ShiftCustomColorPickerPage extends StatefulWidget {
  final Color initial_color;

  const ShiftCustomColorPickerPage({super.key, required this.initial_color});

  @override
  State<ShiftCustomColorPickerPage> createState() =>
      _ShiftCustomColorPickerPageState();
}

class _ShiftCustomColorPickerPageState
    extends State<ShiftCustomColorPickerPage> {
  late Color _selected_color;
  late double _wheel_hue;
  late double _wheel_saturation;
  late TextEditingController _hex_controller;
  late FocusNode _hex_focus_node;
  late Future<void> _recent_colors_load;
  List<Color> _recent_colors = [];
  bool _is_loading_recent_colors = true;
  bool _is_completing = false;

  int get _red => (_selected_color.toARGB32() >> 16) & 0xff;
  int get _green => (_selected_color.toARGB32() >> 8) & 0xff;
  int get _blue => _selected_color.toARGB32() & 0xff;

  String get _hex_value {
    final rgb_value = _selected_color.toARGB32() & 0x00ffffff;
    return '#${rgb_value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  @override
  void initState() {
    super.initState();
    _selected_color = widget.initial_color.withValues(alpha: 1);
    final initial_hsv = HSVColor.fromColor(_selected_color);
    _wheel_hue = initial_hsv.hue;
    _wheel_saturation = initial_hsv.saturation;
    _hex_controller = TextEditingController(text: _hex_value.substring(1));
    _hex_focus_node = FocusNode()..addListener(_handleHexFocusChange);
    _recent_colors_load = _loadRecentColors();
  }

  @override
  void dispose() {
    _hex_focus_node
      ..removeListener(_handleHexFocusChange)
      ..dispose();
    _hex_controller.dispose();
    super.dispose();
  }

  void _handleHexFocusChange() {
    if (mounted) setState(() {});
  }

  void _setSelectedColor(Color color) {
    final opaque_color = color.withValues(alpha: 1);
    final hsv_color = HSVColor.fromColor(opaque_color);

    setState(() {
      _selected_color = opaque_color;
      _wheel_hue = hsv_color.hue;
      _wheel_saturation = hsv_color.saturation;
      _syncHexController();
    });
  }

  void _syncHexController() {
    final hex_text = _hex_value.substring(1);
    if (_hex_controller.text == hex_text) return;

    _hex_controller.value = TextEditingValue(
      text: hex_text,
      selection: TextSelection.collapsed(offset: hex_text.length),
    );
  }

  void _handleHexChanged(String value) {
    if (value.length != 6) return;

    final rgb_value = int.tryParse(value, radix: 16);
    if (rgb_value == null) return;

    _setSelectedColor(Color(0xff000000 | rgb_value));
  }

  void _updateFromRgb({
    required int red,
    required int green,
    required int blue,
  }) {
    _setSelectedColor(Color.fromARGB(255, red, green, blue));
  }

  void _updateFromWheel(Offset local_position, double wheel_size) {
    if (wheel_size <= 0) return;

    final center = Offset(wheel_size / 2, wheel_size / 2);
    final offset = local_position - center;
    final radius = wheel_size / 2;
    final distance = offset.distance.clamp(0.0, radius);
    final saturation = distance / radius;
    final radians = math.atan2(offset.dx, -offset.dy);
    final hue = ((radians * 180 / math.pi) + 360) % 360;
    final color = HSVColor.fromAHSV(1, hue, saturation, 1).toColor();

    setState(() {
      _selected_color = color;
      _wheel_hue = hue;
      _wheel_saturation = saturation;
      _syncHexController();
    });
  }

  Future<void> _loadRecentColors() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final stored_colors =
          preferences.getStringList(_recent_colors_storage_key) ?? const [];
      final parsed_colors = <Color>[];
      final seen_values = <int>{};

      for (final stored_color in stored_colors) {
        final color = _parseStoredColor(stored_color);
        if (color == null || !seen_values.add(color.toARGB32())) continue;

        parsed_colors.add(color);
        if (parsed_colors.length == _max_recent_colors) break;
      }

      final normalized_colors = parsed_colors
          .map(_storageValueForColor)
          .toList(growable: false);
      if (!_stringListsEqual(stored_colors, normalized_colors)) {
        await preferences.setStringList(
          _recent_colors_storage_key,
          normalized_colors,
        );
      }

      if (!mounted) return;
      setState(() {
        _recent_colors = parsed_colors;
        _is_loading_recent_colors = false;
      });
    } catch (error) {
      debugPrint('최근 커스텀 색상 복원 실패: $error');
      if (!mounted) return;
      setState(() {
        _is_loading_recent_colors = false;
      });
    }
  }

  Color? _parseStoredColor(String value) {
    final normalized_value = value.replaceFirst('#', '').toUpperCase();
    if (!RegExp(r'^[0-9A-F]{6}$').hasMatch(normalized_value)) return null;

    final rgb_value = int.tryParse(normalized_value, radix: 16);
    return rgb_value == null ? null : Color(0xff000000 | rgb_value);
  }

  String _storageValueForColor(Color color) {
    final rgb_value = color.toARGB32() & 0x00ffffff;
    return rgb_value.toRadixString(16).padLeft(6, '0').toUpperCase();
  }

  bool _stringListsEqual(List<String> first, List<String> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }

  Future<void> _saveRecentColor() async {
    final selected_value = _selected_color.toARGB32();
    final updated_colors = [
      _selected_color,
      ..._recent_colors.where((color) => color.toARGB32() != selected_value),
    ].take(_max_recent_colors).toList(growable: false);
    final preferences = await SharedPreferences.getInstance();
    final did_save = await preferences.setStringList(
      _recent_colors_storage_key,
      updated_colors.map(_storageValueForColor).toList(growable: false),
    );
    if (!did_save) {
      throw StateError('최근 커스텀 색상을 로컬 저장소에 기록하지 못했습니다.');
    }

    if (!mounted) return;
    setState(() {
      _recent_colors = updated_colors;
    });
  }

  Future<void> _completeSelection() async {
    if (_is_completing) return;

    setState(() {
      _is_completing = true;
    });

    await _recent_colors_load;
    try {
      await _saveRecentColor();
    } catch (error) {
      debugPrint('최근 커스텀 색상 저장 실패: $error');
    }

    if (!mounted) return;
    Navigator.of(context).pop(_selected_color);
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
          key: const Key('shift_custom_color_back_button'),
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
          '커스텀 색상 선택',
          style: AppTheme.heading_small.copyWith(
            color: AppTheme.on_surface_color,
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: CupertinoButton(
          key: const Key('shift_custom_color_complete_button'),
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          onPressed: _is_completing ? null : _completeSelection,
          child: _is_completing
              ? const CupertinoActivityIndicator(radius: 8)
              : Text(
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
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            16,
            _scaled(32),
            16,
            bottom_safe_area + _scaled(40),
          ),
          children: [
            _buildPreviewSection(),
            SizedBox(height: _scaled(28)),
            _buildColorControlsCard(),
            SizedBox(height: _scaled(24)),
            _buildHexSection(),
            SizedBox(height: _scaled(24)),
            _buildRecentColorsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Column(
      children: [
        AnimatedContainer(
          key: const Key('shift_custom_color_preview'),
          duration: const Duration(milliseconds: 140),
          width: _scaled(128),
          height: _scaled(128),
          decoration: BoxDecoration(
            color: _selected_color,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.surface_color,
              width: _scaled(4),
            ),
            boxShadow: const [
              BoxShadow(
                color: AppTheme.outline_variant_color,
                spreadRadius: 1,
                blurRadius: 0,
              ),
            ],
          ),
        ),
        SizedBox(height: _scaled(16)),
        Text(
          'SELECTED COLOR',
          style: _scaledTextStyle(AppTheme.body_small).copyWith(
            color: AppTheme.on_surface_variant_color,
            letterSpacing: _scaled(1.4),
          ),
        ),
        SizedBox(height: _scaled(4)),
        Text(
          _hex_value,
          key: const Key('shift_custom_color_hex_display'),
          style: _scaledTextStyle(AppTheme.heading_small).copyWith(
            color: AppTheme.on_surface_color,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildColorControlsCard() {
    return Container(
      key: const Key('shift_custom_color_wheel_card'),
      padding: EdgeInsets.all(_scaled(24)),
      decoration: AppTheme.cardDecoration(
        radius: _scaled(AppTheme.card_radius),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final controls_gap = _scaled(16);
          final available_width = math.max(
            0.0,
            constraints.maxWidth - controls_gap,
          );
          final wheel_size = math.min(176.0, available_width * 0.56);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildColorWheel(wheel_size),
              SizedBox(width: controls_gap),
              Expanded(child: _buildRgbControls()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildColorWheel(double wheel_size) {
    final radius = wheel_size / 2;
    final hue_radians = _wheel_hue * math.pi / 180;
    final marker_radius = radius * _wheel_saturation;
    final marker_size = _scaled(24);
    final marker_left =
        radius + (math.sin(hue_radians) * marker_radius) - (marker_size / 2);
    final marker_top =
        radius - (math.cos(hue_radians) * marker_radius) - (marker_size / 2);

    return SizedBox(
      width: wheel_size,
      height: wheel_size,
      child: Semantics(
        label: '색상 휠',
        value: _hex_value,
        child: GestureDetector(
          key: const Key('shift_custom_color_wheel'),
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            _updateFromWheel(details.localPosition, wheel_size);
          },
          onPanStart: (details) {
            _updateFromWheel(details.localPosition, wheel_size);
          },
          onPanUpdate: (details) {
            _updateFromWheel(details.localPosition, wheel_size);
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(painter: const _ColorWheelPainter()),
              ),
              AnimatedPositioned(
                key: const Key('shift_custom_color_wheel_marker'),
                duration: const Duration(milliseconds: 80),
                left: marker_left,
                top: marker_top,
                width: marker_size,
                height: marker_size,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _selected_color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.surface_color,
                      width: _scaled(2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withValues(alpha: 0.18),
                        blurRadius: _scaled(4),
                        offset: Offset(0, _scaled(2)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHexSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hex Code',
          style: _scaledTextStyle(AppTheme.body_medium).copyWith(
            color: AppTheme.on_surface_variant_color,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: _scaled(8)),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.surface_color,
            borderRadius: BorderRadius.circular(_scaled(AppTheme.input_radius)),
            border: Border.all(
              color: _hex_focus_node.hasFocus
                  ? AppTheme.primary_color
                  : AppTheme.outline_variant_color,
              width: _hex_focus_node.hasFocus ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              SizedBox(width: _scaled(16)),
              Text(
                '#',
                style: _scaledTextStyle(
                  AppTheme.body_medium,
                ).copyWith(color: AppTheme.outline_color, fontFamily: 'Inter'),
              ),
              SizedBox(width: _scaled(8)),
              Expanded(
                child: CupertinoTextField(
                  key: const Key('shift_custom_color_hex_field'),
                  controller: _hex_controller,
                  focusNode: _hex_focus_node,
                  maxLength: 6,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  enableSuggestions: false,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]')),
                    LengthLimitingTextInputFormatter(6),
                    const _UpperCaseTextFormatter(),
                  ],
                  style: _scaledTextStyle(AppTheme.body_large).copyWith(
                    color: AppTheme.on_surface_color,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                  padding: EdgeInsets.symmetric(vertical: _scaled(10)),
                  decoration: null,
                  onChanged: _handleHexChanged,
                  onSubmitted: (_) => _syncHexController(),
                ),
              ),
              SizedBox(width: _scaled(16)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRgbControls() {
    return Column(
      key: const Key('shift_custom_color_rgb_controls'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRgbSlider(
          key: const Key('shift_custom_color_red_slider'),
          label: 'Red',
          value: _red,
          onChanged: (value) {
            _updateFromRgb(red: value, green: _green, blue: _blue);
          },
        ),
        SizedBox(height: _scaled(8)),
        _buildRgbSlider(
          key: const Key('shift_custom_color_green_slider'),
          label: 'Green',
          value: _green,
          onChanged: (value) {
            _updateFromRgb(red: _red, green: value, blue: _blue);
          },
        ),
        SizedBox(height: _scaled(8)),
        _buildRgbSlider(
          key: const Key('shift_custom_color_blue_slider'),
          label: 'Blue',
          value: _blue,
          onChanged: (value) {
            _updateFromRgb(red: _red, green: _green, blue: value);
          },
        ),
      ],
    );
  }

  Widget _buildRgbSlider({
    required Key key,
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: _scaledTextStyle(AppTheme.body_medium).copyWith(
                color: AppTheme.on_surface_variant_color,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$value',
              key: Key('shift_custom_color_${label.toLowerCase()}_value'),
              style: _scaledTextStyle(AppTheme.body_medium).copyWith(
                color: AppTheme.on_surface_color,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: _scaled(4)),
        SizedBox(
          height: 24,
          child: Transform.scale(
            key: Key(
              'shift_custom_color_${label.toLowerCase()}_slider_transform',
            ),
            scaleX: 1,
            scaleY: _body_scale,
            child: CupertinoSlider(
              key: key,
              value: value.toDouble(),
              min: 0,
              max: 255,
              activeColor: AppTheme.primary_color,
              onChanged: (next_value) => onChanged(next_value.round()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentColorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '최근 사용한 색상',
          style: _scaledTextStyle(AppTheme.body_large).copyWith(
            color: AppTheme.on_surface_variant_color,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: _scaled(8)),
        if (_is_loading_recent_colors)
          const SizedBox(
            height: 44,
            child: Align(
              alignment: Alignment.centerLeft,
              child: CupertinoActivityIndicator(radius: 8),
            ),
          )
        else if (_recent_colors.isEmpty)
          SizedBox(
            height: 44,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '아직 사용한 색상이 없습니다.',
                key: const Key('shift_custom_color_recent_empty'),
                style: _scaledTextStyle(
                  AppTheme.body_medium,
                ).copyWith(color: AppTheme.outline_color),
              ),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var index = 0; index < _recent_colors.length; index++) ...[
                  if (index > 0) SizedBox(width: _scaled(8)),
                  Semantics(
                    button: true,
                    label: '최근 색상 ${index + 1}',
                    child: GestureDetector(
                      key: Key('shift_custom_color_recent_$index'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _setSelectedColor(_recent_colors[index]),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: Container(
                            width: _scaled(40),
                            height: _scaled(40),
                            decoration: BoxDecoration(
                              color: _recent_colors[index],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.outline_variant_color,
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ColorWheelPainter extends CustomPainter {
  const _ColorWheelPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final bounds = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()..isAntiAlias = true;

    paint.shader = const SweepGradient(
      colors: [
        Color(0xFFFF0000),
        Color(0xFFFFFF00),
        Color(0xFF00FF00),
        Color(0xFF00FFFF),
        Color(0xFF0000FF),
        Color(0xFFFF00FF),
        Color(0xFFFF0000),
      ],
      transform: GradientRotation(-math.pi / 2),
    ).createShader(bounds);
    canvas.drawCircle(center, radius, paint);

    paint.shader = RadialGradient(
      colors: [
        AppTheme.surface_color,
        AppTheme.surface_color.withValues(alpha: 0),
      ],
    ).createShader(bounds);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _ColorWheelPainter old_delegate) => false;
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  const _UpperCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old_value,
    TextEditingValue new_value,
  ) {
    return new_value.copyWith(text: new_value.text.toUpperCase());
  }
}
