// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_theme.dart';

/// 시작일·종료일처럼 일 단위 날짜를 선택하는 공용 하단 시트다.
class DatePickerSheet extends StatefulWidget {
  const DatePickerSheet({
    super.key,
    required this.title,
    required this.initial_date,
    required this.minimum_date,
    required this.maximum_date,
  });

  final String title;
  final DateTime initial_date;
  final DateTime minimum_date;
  final DateTime maximum_date;

  @override
  State<DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<DatePickerSheet> {
  late DateTime _selected_date;
  int _picker_revision = 0;

  @override
  void initState() {
    super.initState();
    _selected_date = _clampDate(_dateOnly(widget.initial_date));
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _clampDate(DateTime date) {
    final minimum_date = _dateOnly(widget.minimum_date);
    final maximum_date = _dateOnly(widget.maximum_date);
    if (date.isBefore(minimum_date)) return minimum_date;
    if (date.isAfter(maximum_date)) return maximum_date;
    return date;
  }

  bool get _canSelectToday {
    final today = _dateOnly(DateTime.now());
    return !today.isBefore(_dateOnly(widget.minimum_date)) &&
        !today.isAfter(_dateOnly(widget.maximum_date));
  }

  void _selectToday() {
    if (!_canSelectToday) return;

    setState(() {
      _selected_date = _dateOnly(DateTime.now());
      _picker_revision += 1;
    });
  }

  String _formatDate(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${date.year}년 ${date.month}월 ${date.day}일 '
        '(${weekdays[date.weekday - 1]})';
  }

  void _applySelection() {
    Navigator.of(context).pop(_selected_date);
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: AppTheme.heading_small),
                        const SizedBox(height: 2),
                        const Text('원하는 날짜를 선택하세요', style: AppTheme.body_small),
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
                        _formatDate(_selected_date),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                      onPressed: _canSelectToday ? _selectToday : null,
                      child: const Text(
                        '오늘',
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
                  for (final label in const ['연도', '월', '일'])
                    Expanded(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: AppTheme.body_small.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: AppTheme.card_border_radius,
                  child: ColoredBox(
                    color: AppTheme.surface_container_low_color,
                    child: CupertinoDatePicker(
                      key: ValueKey(_picker_revision),
                      mode: CupertinoDatePickerMode.date,
                      dateOrder: DatePickerDateOrder.ymd,
                      initialDateTime: _selected_date,
                      minimumDate: _dateOnly(widget.minimum_date),
                      maximumDate: _dateOnly(widget.maximum_date),
                      itemExtent: 44,
                      backgroundColor: AppTheme.surface_container_low_color,
                      onDateTimeChanged: (date) {
                        setState(() {
                          _selected_date = _dateOnly(date);
                        });
                      },
                    ),
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
                        '선택한 날짜 적용',
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
}

Future<DateTime?> showDatePickerSheet({
  required BuildContext context,
  required String title,
  required DateTime initial_date,
  required DateTime minimum_date,
  required DateTime maximum_date,
}) {
  return showCupertinoModalPopup<DateTime>(
    context: context,
    barrierDismissible: true,
    builder: (context) => DatePickerSheet(
      title: title,
      initial_date: initial_date,
      minimum_date: minimum_date,
      maximum_date: maximum_date,
    ),
  );
}
