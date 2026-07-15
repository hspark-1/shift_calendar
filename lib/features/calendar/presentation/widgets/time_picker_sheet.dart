// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_theme.dart';

/// 시작시간·종료시간처럼 시/분 단위 시간을 선택하는 공용 하단 시트다.
class TimePickerSheet extends StatefulWidget {
  const TimePickerSheet({
    super.key,
    required this.title,
    required this.initial_time,
  });

  final String title;
  final Duration initial_time;

  @override
  State<TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<TimePickerSheet> {
  late Duration _selected_time;
  int _picker_revision = 0;

  @override
  void initState() {
    super.initState();
    _selected_time = _normalizeTime(widget.initial_time);
  }

  Duration _normalizeTime(Duration time) {
    final total_minutes = time.inMinutes.remainder(24 * 60);
    return Duration(
      hours: total_minutes ~/ 60,
      minutes: total_minutes.remainder(60),
    );
  }

  DateTime _toPickerDateTime(Duration time) {
    return DateTime(
      2026,
      1,
      1,
      time.inHours.remainder(24),
      time.inMinutes.remainder(60),
    );
  }

  void _selectCurrentTime() {
    final now = DateTime.now();
    setState(() {
      _selected_time = Duration(hours: now.hour, minutes: now.minute);
      _picker_revision += 1;
    });
  }

  String _formatTime(Duration time) {
    final hour24 = time.inHours.remainder(24);
    final minute = time.inMinutes.remainder(60).toString().padLeft(2, '0');
    final period = hour24 < 12 ? '오전' : '오후';
    final hour12_value = hour24.remainder(12);
    final hour12 = hour12_value == 0 ? 12 : hour12_value;
    return '$period ${hour12.toString().padLeft(2, '0')}:$minute';
  }

  void _applySelection() {
    Navigator.of(context).pop(_selected_time);
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
                        const Text('원하는 시간을 선택하세요', style: AppTheme.body_small),
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
                        CupertinoIcons.clock,
                        size: 21,
                        color: AppTheme.primary_color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _formatTime(_selected_time),
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
                      onPressed: _selectCurrentTime,
                      child: const Text(
                        '지금',
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
                  for (final label in const ['시', '분'])
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
                      mode: CupertinoDatePickerMode.time,
                      initialDateTime: _toPickerDateTime(_selected_time),
                      use24hFormat: true,
                      itemExtent: 44,
                      backgroundColor: AppTheme.surface_container_low_color,
                      onDateTimeChanged: (date) {
                        setState(() {
                          _selected_time = Duration(
                            hours: date.hour,
                            minutes: date.minute,
                          );
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
                        '선택한 시간 적용',
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

Future<Duration?> showTimePickerSheet({
  required BuildContext context,
  required String title,
  required Duration initial_time,
}) {
  return showCupertinoModalPopup<Duration>(
    context: context,
    barrierDismissible: true,
    builder: (context) =>
        TimePickerSheet(title: title, initial_time: initial_time),
  );
}
