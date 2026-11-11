// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_theme.dart';
import 'shift_color_selection.dart';

const String _recent_colors_storage_key = 'shift_custom_recent_colors_v1';
const String _recent_selections_storage_key =
    'shift_custom_recent_selections_v2';
const int _max_recent_colors = 6;

class ShiftCustomColorPickerPage extends StatefulWidget {
  final Color initial_color;

  final Color? initial_base_color;
  final int initial_color_intensity;

  const ShiftCustomColorPickerPage({
    super.key,
    required this.initial_color,
    this.initial_base_color,
    this.initial_color_intensity = 100,
  });

  @override
  State<ShiftCustomColorPickerPage> createState() =>
      _ShiftCustomColorPickerPageState();
}

class _ShiftCustomColorPickerPageState
    extends State<ShiftCustomColorPickerPage> {
  late Color _base_color;
  late int _color_intensity;

  Color get _selected_color =>
      calculateShiftColor(_base_color, _color_intensity);
  ShiftColorSelection get _selection => ShiftColorSelection(
    final_color: _selected_color.toARGB32(),
    base_color: _base_color.toARGB32(),
    color_intensity: _color_intensity,
  );
  late double _wheel_hue;
  late double _wheel_saturation;
  late TextEditingController _hex_controller;
  late FocusNode _hex_focus_node;
  late Future<void> _recent_colors_load;
  List<ShiftColorSelection> _recent_colors = [];
  bool _is_loading_recent_colors = true;
  bool _is_completing = false;
  String? _hex_error;

  int get _red => (_base_color.toARGB32() >> 16) & 0xff;
  int get _green => (_base_color.toARGB32() >> 8) & 0xff;
  int get _blue => _base_color.toARGB32() & 0xff;

  String get _hex_value {
    final rgb_value = _base_color.toARGB32() & 0x00ffffff;
    return '#${rgb_value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  @override
  void initState() {
    super.initState();
    _base_color = (widget.initial_base_color ?? widget.initial_color)
        .withValues(alpha: 1);
    _color_intensity = widget.initial_color_intensity.clamp(0, 100);
    final initial_hsv = HSVColor.fromColor(_base_color);
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
      _base_color = opaque_color;
      _hex_error = null;
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
    if (_hex_error != null) setState(() => _hex_error = null);
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
      _base_color = color;
      _hex_error = null;
      _wheel_hue = hue;
      _wheel_saturation = saturation;
      _syncHexController();
    });
  }

  Future<void> _loadRecentColors() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final stored_selections = preferences.getStringList(
        _recent_selections_storage_key,
      );
      final parsed_colors = <ShiftColorSelection>[];
      final seen_values = <int>{};
      if (stored_selections != null) {
        for (final stored in stored_selections) {
          try {
            final value = jsonDecode(stored);
            if (value is! Map<String, dynamic>) continue;
            final base = value['base_color'];
            final intensity = value['color_intensity'];
            if (base is! String ||
                intensity is! int ||
                intensity < 0 ||
                intensity > 100) {
              continue;
            }
            final color = _parseStoredColor(base);
            if (color == null) continue;
            final final_color = calculateShiftColor(
              color,
              intensity,
            ).toARGB32();
            if (!seen_values.add(final_color)) continue;
            parsed_colors.add(
              ShiftColorSelection(
                final_color: final_color,
                base_color: color.toARGB32(),
                color_intensity: intensity,
              ),
            );
            if (parsed_colors.length == _max_recent_colors) break;
          } on FormatException {
            continue;
          }
        }
      }
      // v1에는 최종 RGB만 있으므로 추정하지 않고 해당 색상/100%로 복원한다.
      if (parsed_colors.isEmpty) {
        for (final stored
            in preferences.getStringList(_recent_colors_storage_key) ??
                <String>[]) {
          final color = _parseStoredColor(stored);
          if (color == null || !seen_values.add(color.toARGB32())) continue;
          parsed_colors.add(
            ShiftColorSelection(
              final_color: color.toARGB32(),
              base_color: color.toARGB32(),
              color_intensity: 100,
            ),
          );
          if (parsed_colors.length == _max_recent_colors) break;
        }
      }
      if (!mounted) return;
      setState(() {
        _recent_colors = parsed_colors;
        _is_loading_recent_colors = false;
      });
    } catch (error) {
      debugPrint('최근 커스텀 색상 복원 실패: $error');
      if (!mounted) return;
      setState(() => _is_loading_recent_colors = false);
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

  Future<void> _saveRecentColor() async {
    final selected = _selection;
    final updated_colors = [
      selected,
      ..._recent_colors.where(
        (color) => color.final_color != selected.final_color,
      ),
    ].take(_max_recent_colors).toList(growable: false);
    final preferences = await SharedPreferences.getInstance();
    final did_save = await preferences.setStringList(
      _recent_selections_storage_key,
      updated_colors
          .map(
            (color) => jsonEncode({
              'base_color': _storageValueForColor(Color(color.base_color)),
              'color_intensity': color.color_intensity,
            }),
          )
          .toList(growable: false),
    );
    if (!did_save) throw StateError('최근 커스텀 색상을 로컬 저장소에 기록하지 못했습니다.');
    // 구버전으로 돌아가도 최근 최종 색상은 사용할 수 있게 v1도 유지한다.
    await preferences.setStringList(
      _recent_colors_storage_key,
      updated_colors
          .map((color) => _storageValueForColor(Color(color.final_color)))
          .toList(growable: false),
    );
    if (!mounted) return;
    setState(() => _recent_colors = updated_colors);
  }

  void _selectRecentColor(ShiftColorSelection selection) {
    _color_intensity = selection.color_intensity;
    _setSelectedColor(Color(selection.base_color));
  }

  Future<void> _completeSelection() async {
    if (_is_completing) return;
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(_hex_controller.text)) {
      setState(() => _hex_error = '색상 코드는 6자리로 입력해주세요.');
      _hex_focus_node.requestFocus();
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();

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
    Navigator.of(context).pop(_selection);
  }

  @override
  Widget build(BuildContext context) {
    final bottom_safe_area = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      canPop: !_is_completing,
      child: CupertinoPageScaffold(
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
            onPressed: _is_completing
                ? null
                : () => Navigator.of(context).pop(),
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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AbsorbPointer(
                absorbing: _is_completing,
                child: Column(
                  children: [
                    if (MediaQuery.viewInsetsOf(context).bottom == 0)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: _buildPreviewSection(),
                      ),
                    Expanded(
                      child: ListView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          16,
                          16,
                          16,
                          bottom_safe_area + 24,
                        ),
                        children: [
                          _buildColorControlsCard(),
                          const SizedBox(height: 24),
                          _buildRecentColorsSection(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Row(
        children: [
          Container(
            key: const Key('shift_custom_color_preview'),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _selected_color,
              borderRadius: BorderRadius.circular(AppTheme.input_radius),
              border: Border.all(color: AppTheme.outline_variant_color),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('적용될 색상', style: AppTheme.body_medium),
                const SizedBox(height: 4),
                Text(
                  '#${_storageValueForColor(_selected_color)}',
                  key: const Key('shift_custom_color_final_hex'),
                  style: AppTheme.body_large,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorControlsCard() {
    return Container(
      key: const Key('shift_custom_color_wheel_card'),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wheel_size = math.min(200.0, constraints.maxWidth - 24);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '기준 색상',
                style: AppTheme.body_large.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildHexSection(),
              const SizedBox(height: 20),
              Center(child: _buildColorWheel(wheel_size)),
              const SizedBox(height: 20),
              Container(height: 1, color: AppTheme.outline_variant_color),
              const SizedBox(height: 8),
              _buildRgbControls(),
              const SizedBox(height: 16),
              Container(height: 1, color: AppTheme.outline_variant_color),
              const SizedBox(height: 16),
              _buildColorIntensityControls(),
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
    const marker_size = 24.0;
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
        child: RawGestureDetector(
          key: const Key('shift_custom_color_wheel'),
          behavior: HitTestBehavior.opaque,
          gestures: {
            _ColorWheelPanGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<
                  _ColorWheelPanGestureRecognizer
                >(() => _ColorWheelPanGestureRecognizer(), (recognizer) {
                  recognizer
                    ..wheel_size = wheel_size
                    ..onStart = (details) {
                      _updateFromWheel(details.localPosition, wheel_size);
                    }
                    ..onUpdate = (details) {
                      _updateFromWheel(details.localPosition, wheel_size);
                    };
                }),
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(painter: const _ColorWheelPainter()),
              ),
              AnimatedPositioned(
                key: const Key('shift_custom_color_wheel_marker'),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 80),
                left: marker_left,
                top: marker_top,
                width: marker_size,
                height: marker_size,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _base_color,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.surface_color, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withValues(alpha: 0.18),
                        blurRadius: 4,
                        offset: Offset(0, 2),
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
          'HEX 코드',
          style: AppTheme.body_medium.copyWith(
            color: AppTheme.on_surface_variant_color,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            color: AppTheme.surface_container_low_color,
            borderRadius: BorderRadius.circular(AppTheme.input_radius),
            border: Border.all(
              color: _hex_focus_node.hasFocus
                  ? AppTheme.primary_color
                  : AppTheme.outline_variant_color,
              width: _hex_focus_node.hasFocus ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              SizedBox(width: 16),
              Text(
                '#',
                style: AppTheme.body_medium.copyWith(
                  color: AppTheme.outline_color,
                  fontFamily: AppTheme.default_font_family,
                ),
              ),
              SizedBox(width: 8),
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
                  style: AppTheme.body_large.copyWith(
                    color: AppTheme.on_surface_color,
                    fontFamily: AppTheme.default_font_family,
                    fontWeight: FontWeight.w500,
                  ),
                  padding: EdgeInsets.symmetric(vertical: 10),
                  decoration: null,
                  onChanged: _handleHexChanged,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _syncHexController(),
                ),
              ),
              SizedBox(width: 16),
            ],
          ),
        ),
        if (_hex_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _hex_error!,
            style: AppTheme.body_medium.copyWith(
              color: AppTheme.accent_red_color,
            ),
          ),
        ],
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
          channel: 'red',
          label: '빨강(R)',
          value: _red,
          onChanged: (value) {
            _updateFromRgb(red: value, green: _green, blue: _blue);
          },
        ),
        SizedBox(height: 8),
        _buildRgbSlider(
          key: const Key('shift_custom_color_green_slider'),
          channel: 'green',
          label: '초록(G)',
          value: _green,
          onChanged: (value) {
            _updateFromRgb(red: _red, green: value, blue: _blue);
          },
        ),
        SizedBox(height: 8),
        _buildRgbSlider(
          key: const Key('shift_custom_color_blue_slider'),
          channel: 'blue',
          label: '파랑(B)',
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
    required String channel,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    final channel_letter = channel.substring(0, 1).toUpperCase();
    final number_width = MediaQuery.textScalerOf(context).scale(16) * 2.1;
    return Row(
      children: [
        ExcludeSemantics(
          child: Text(
            channel_letter,
            style: AppTheme.body_large.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            label: label,
            child: SizedBox(
              height: 48,
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
        ),
        const SizedBox(width: 8),
        ExcludeSemantics(
          child: SizedBox(
            width: number_width,
            child: Text(
              '$value',
              key: Key('shift_custom_color_${channel}_value'),
              textAlign: TextAlign.end,
              style: AppTheme.body_large,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorIntensityControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '색상 농도',
                style: AppTheme.body_large.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$_color_intensity%',
              key: const Key('shift_color_intensity_label'),
              style: AppTheme.body_large,
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text('기준 색상에 흰색을 섞어 옅게 조절해요.', style: AppTheme.body_medium),
        LayoutBuilder(
          builder: (context, constraints) {
            void updateFromPosition(Offset position) {
              const track_inset = 22.0;
              final width = constraints.maxWidth - track_inset * 2;
              if (width <= 0) return;
              final value = ((position.dx - track_inset) / width).clamp(
                0.0,
                1.0,
              );
              setState(() => _color_intensity = (value * 100).round());
            }

            return GestureDetector(
              key: const Key('shift_color_intensity_gesture_area'),
              excludeFromSemantics: true,
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => updateFromPosition(details.localPosition),
              onHorizontalDragStart: (details) =>
                  updateFromPosition(details.localPosition),
              onHorizontalDragUpdate: (details) =>
                  updateFromPosition(details.localPosition),
              child: Semantics(
                label: '색상 농도',
                child: SizedBox(
                  height: 48,
                  child: IgnorePointer(
                    child: CupertinoSlider(
                      key: const Key('shift_color_intensity_slider'),
                      value: _color_intensity / 100,
                      divisions: 100,
                      activeColor: AppTheme.primary_color,
                      onChanged: (value) => setState(
                        () => _color_intensity = (value * 100).round(),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('옅게', style: AppTheme.body_medium),
            Text('원래 색', style: AppTheme.body_medium),
          ],
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
          style: AppTheme.body_large.copyWith(
            color: AppTheme.on_surface_variant_color,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        if (_is_loading_recent_colors)
          const SizedBox(
            height: 44,
            child: Align(
              alignment: Alignment.centerLeft,
              child: CupertinoActivityIndicator(radius: 8),
            ),
          )
        else if (_recent_colors.isEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '아직 사용한 색상이 없습니다.',
                key: const Key('shift_custom_color_recent_empty'),
                style: AppTheme.body_medium.copyWith(
                  color: AppTheme.on_surface_variant_color,
                ),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var index = 0; index < _recent_colors.length; index++)
                Semantics(
                  label:
                      '최근 색상 ${index + 1}, #${_storageValueForColor(Color(_recent_colors[index].final_color))}',
                  selected:
                      _recent_colors[index].final_color ==
                      _selected_color.toARGB32(),
                  child: CupertinoButton(
                    key: Key('shift_custom_color_recent_$index'),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(44, 44),
                    onPressed: () => _selectRecentColor(_recent_colors[index]),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Color(_recent_colors[index].final_color),
                        borderRadius: BorderRadius.circular(
                          AppTheme.input_radius,
                        ),
                        border: Border.all(
                          color: AppTheme.outline_variant_color,
                        ),
                      ),
                      child:
                          _recent_colors[index].final_color ==
                              _selected_color.toARGB32()
                          ? Icon(
                              CupertinoIcons.checkmark,
                              size: 20,
                              color:
                                  Color(
                                        _recent_colors[index].final_color,
                                      ).computeLuminance() >
                                      0.179
                                  ? CupertinoColors.black
                                  : CupertinoColors.white,
                            )
                          : null,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

// 휠 내부의 누름은 이동 임계값을 기다리지 않고 색상 조절이 소유한다.
// 원 밖 모서리/여백은 부모 스크롤에 남겨 두고, 종료/취소는 기본 recognizer가 처리한다.
class _ColorWheelPanGestureRecognizer extends PanGestureRecognizer {
  double wheel_size = 0;
  int? _primary_pointer;

  @override
  bool isPointerAllowed(PointerEvent event) {
    final center = Offset(wheel_size / 2, wheel_size / 2);
    return _primary_pointer == null &&
        (event.localPosition - center).distance <= wheel_size / 2 &&
        super.isPointerAllowed(event);
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _primary_pointer = event.pointer;
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    super.didStopTrackingLastPointer(pointer);
    _primary_pointer = null;
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
