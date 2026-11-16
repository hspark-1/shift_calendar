// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_theme.dart';
import 'picker_selection_summary.dart';

/// 캘린더에서 이동할 연도와 월을 선택하는 공용 하단 시트다.
class YearMonthPickerSheet extends StatefulWidget {
  const YearMonthPickerSheet({
    super.key,
    required this.initial_date,
    required this.first_year,
    required this.last_year,
  });

  final DateTime initial_date;
  final int first_year;
  final int last_year;

  @override
  State<YearMonthPickerSheet> createState() => _YearMonthPickerSheetState();
}

class _YearMonthPickerSheetState extends State<YearMonthPickerSheet> {
  late int _selected_year;
  late int _selected_month;
  late final FixedExtentScrollController _year_controller;
  late final FixedExtentScrollController _month_controller;

  @override
  void initState() {
    super.initState();
    _selected_year = widget.initial_date.year.clamp(
      widget.first_year,
      widget.last_year,
    );
    _selected_month = widget.initial_date.month;
    _year_controller = FixedExtentScrollController(
      initialItem: _selected_year - widget.first_year,
    );
    _month_controller = FixedExtentScrollController(
      initialItem: _selected_month - 1,
    );
  }

  @override
  void dispose() {
    _year_controller.dispose();
    _month_controller.dispose();
    super.dispose();
  }

  bool get _canSelectCurrentMonth {
    final now = DateTime.now();
    return now.year >= widget.first_year && now.year <= widget.last_year;
  }

  Future<void> _selectCurrentMonth() async {
    if (!_canSelectCurrentMonth) return;

    final now = DateTime.now();
    setState(() {
      _selected_year = now.year;
      _selected_month = now.month;
    });

    if (MediaQuery.disableAnimationsOf(context)) {
      _year_controller.jumpToItem(now.year - widget.first_year);
      _month_controller.jumpToItem(now.month - 1);
      return;
    }
    await Future.wait([
      _year_controller.animateToItem(
        now.year - widget.first_year,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      ),
      _month_controller.animateToItem(
        now.month - 1,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      ),
    ]);
  }

  void _applySelection() {
    Navigator.of(context).pop(DateTime(_selected_year, _selected_month, 1));
  }

  double get _pickerItemExtent =>
      math.max(44, MediaQuery.textScalerOf(context).scale(16) * 1.5 + 8);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final compact_actions = media.textScaler.scale(16) > 20;
    return Container(
      constraints: const BoxConstraints(maxWidth: 560),
      width: double.infinity,
      height: math.min(
        438 + media.padding.bottom,
        math.max(0, media.size.height - media.padding.top - 12),
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface_color,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('year-month-picker-scroll'),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 38,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppTheme.outline_variant_color,
                        borderRadius: BorderRadius.circular(
                          AppTheme.chip_radius,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('날짜 이동', style: AppTheme.heading_small),
                                SizedBox(height: 2),
                                Text(
                                  '원하는 연도와 월을 선택하세요',
                                  style: AppTheme.body_small,
                                ),
                              ],
                            ),
                          ),
                          CupertinoButton(
                            padding: const EdgeInsets.all(8),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Icon(
                              CupertinoIcons.xmark,
                              size: 19,
                              color: AppTheme.on_surface_variant_color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: PickerSelectionSummary(
                        icon: CupertinoIcons.calendar,
                        value: '$_selected_year년 $_selected_month월',
                        action_label: '이번 달',
                        onAction: _canSelectCurrentMonth
                            ? _selectCurrentMonth
                            : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildWheelSection(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      color: AppTheme.surface_container_color,
                      borderRadius: AppTheme.input_border_radius,
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          color: AppTheme.on_surface_variant_color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: compact_actions ? 1 : 2,
                    child: CupertinoButton(
                      key: const ValueKey('year-month-picker-apply'),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      color: AppTheme.primary_color,
                      borderRadius: AppTheme.input_border_radius,
                      onPressed: _applySelection,
                      child: Text(
                        compact_actions ? '이동' : '선택한 달로 이동',
                        semanticsLabel: '선택한 달로 이동',
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w700,
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

  double _wheelTextWidth(Iterable<String> values) {
    final painter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    );
    var width = 0.0;
    for (final value in values) {
      painter.text = TextSpan(
        text: value,
        style: AppTheme.body_large.copyWith(
          fontWeight: MediaQuery.boldTextOf(context)
              ? FontWeight.bold
              : FontWeight.w600,
        ),
      );
      painter.layout();
      width = math.max(width, painter.width);
    }
    painter.dispose();
    return (width * 1.04 + 16).ceilToDouble();
  }

  Widget _wheelPanel(Widget child) => Container(
    decoration: BoxDecoration(
      color: AppTheme.surface_container_low_color,
      borderRadius: AppTheme.card_border_radius,
    ),
    child: child,
  );

  Widget _buildWheelSection() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final year_width = _wheelTextWidth([
          for (var year = widget.first_year; year <= widget.last_year; year++)
            '$year년',
        ]);
        final month_width = _wheelTextWidth([
          for (var month = 1; month <= 12; month++) '$month월',
        ]);
        final wheel_height = math.max(180.0, _pickerItemExtent * 3);
        if (year_width + month_width + 1 > constraints.maxWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPickerLabel('연도'),
              const SizedBox(height: 6),
              SizedBox(
                height: wheel_height,
                child: _wheelPanel(_buildYearPicker()),
              ),
              const SizedBox(height: 12),
              _buildPickerLabel('월'),
              const SizedBox(height: 6),
              SizedBox(
                height: wheel_height,
                child: _wheelPanel(_buildMonthPicker()),
              ),
            ],
          );
        }
        final year_flex = year_width.ceil();
        final month_flex = month_width.ceil();
        return Column(
          children: [
            Row(
              children: [
                Expanded(flex: year_flex, child: _buildPickerLabel('연도')),
                const SizedBox(width: 1),
                Expanded(flex: month_flex, child: _buildPickerLabel('월')),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: wheel_height,
              child: _wheelPanel(
                Row(
                  children: [
                    Expanded(flex: year_flex, child: _buildYearPicker()),
                    Container(
                      width: 1,
                      height: 118,
                      color: AppTheme.outline_variant_color.withValues(
                        alpha: 0.65,
                      ),
                    ),
                    Expanded(flex: month_flex, child: _buildMonthPicker()),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _buildPickerLabel(String label) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: AppTheme.body_small.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _buildYearPicker() {
    return CupertinoPicker.builder(
      scrollController: _year_controller,
      itemExtent: _pickerItemExtent,
      squeeze: 1,
      useMagnifier: true,
      magnification: 1.04,
      selectionOverlay: _buildSelectionOverlay(),
      onSelectedItemChanged: (index) {
        setState(() {
          _selected_year = widget.first_year + index;
        });
      },
      childCount: widget.last_year - widget.first_year + 1,
      itemBuilder: (context, index) {
        return Center(
          child: Text(
            '${widget.first_year + index}년',
            style: AppTheme.body_large.copyWith(fontWeight: FontWeight.w600),
          ),
        );
      },
    );
  }

  Widget _buildMonthPicker() {
    return CupertinoPicker.builder(
      scrollController: _month_controller,
      itemExtent: _pickerItemExtent,
      squeeze: 1,
      useMagnifier: true,
      magnification: 1.04,
      selectionOverlay: _buildSelectionOverlay(),
      onSelectedItemChanged: (index) {
        setState(() {
          _selected_month = index + 1;
        });
      },
      childCount: 12,
      itemBuilder: (context, index) {
        return Center(
          child: Text(
            '${index + 1}월',
            style: AppTheme.body_large.copyWith(fontWeight: FontWeight.w600),
          ),
        );
      },
    );
  }

  Widget _buildSelectionOverlay() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary_color.withValues(alpha: 0.09),
        borderRadius: AppTheme.input_border_radius,
        border: Border.all(
          color: AppTheme.primary_color.withValues(alpha: 0.18),
        ),
      ),
    );
  }
}

Future<DateTime?> showYearMonthPickerSheet({
  required BuildContext context,
  required DateTime initial_date,
  required int first_year,
  required int last_year,
}) {
  return showCupertinoModalPopup<DateTime>(
    context: context,
    barrierDismissible: true,
    builder: (context) => YearMonthPickerSheet(
      initial_date: initial_date,
      first_year: first_year,
      last_year: last_year,
    ),
  );
}
