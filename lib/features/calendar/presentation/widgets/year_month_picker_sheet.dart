// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final bottom_padding = MediaQuery.paddingOf(context).bottom;

    return Container(
      height: 438 + bottom_padding,
      decoration: const BoxDecoration(
        color: AppTheme.surface_color,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.outline_variant_color,
                borderRadius: BorderRadius.circular(AppTheme.chip_radius),
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
                        Text('원하는 연도와 월을 선택하세요', style: AppTheme.body_small),
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
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary_color.withValues(alpha: 0.08),
                  borderRadius: AppTheme.input_border_radius,
                  border: Border.all(
                    color: AppTheme.primary_color.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.primary_color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.calendar,
                        size: 20,
                        color: AppTheme.primary_color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$_selected_year년 $_selected_month월',
                        style: AppTheme.body_large.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary_dark_color,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      color: AppTheme.surface_color,
                      borderRadius: BorderRadius.circular(AppTheme.chip_radius),
                      onPressed: _canSelectCurrentMonth
                          ? _selectCurrentMonth
                          : null,
                      child: const Text(
                        '이번 달',
                        style: TextStyle(
                          color: AppTheme.primary_color,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: _buildPickerLabel('연도')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildPickerLabel('월')),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface_container_low_color,
                    borderRadius: AppTheme.card_border_radius,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildYearPicker()),
                      Container(
                        width: 1,
                        height: 118,
                        color: AppTheme.outline_variant_color.withValues(
                          alpha: 0.65,
                        ),
                      ),
                      Expanded(child: _buildMonthPicker()),
                    ],
                  ),
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
                    flex: 2,
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      color: AppTheme.primary_color,
                      borderRadius: AppTheme.input_border_radius,
                      onPressed: _applySelection,
                      child: const Text(
                        '선택한 달로 이동',
                        style: TextStyle(
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
      itemExtent: 44,
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
      itemExtent: 44,
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
