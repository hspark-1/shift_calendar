// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_theme.dart';
import 'picker_sheet_frame.dart';
import 'picker_selection_summary.dart';

/// 시작시간·종료시간처럼 시/분 단위 시간을 선택하는 공용 하단 시트다.
class TimePickerSheet extends StatefulWidget {
  const TimePickerSheet({
    super.key,
    required this.title,
    required this.initial_time,
    this.selection_hint = '원하는 시간을 선택하세요',
  });

  final String title;
  final Duration initial_time;
  final String selection_hint;

  @override
  State<TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<TimePickerSheet> {
  late Duration _selected_time;
  int _picker_revision = 0;
  bool _closing = false;

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
    if (_closing) return;
    _closing = true;
    Navigator.of(context).pop(_selected_time);
  }

  void _cancel() {
    if (_closing) return;
    _closing = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final compact_actions = MediaQuery.textScalerOf(context).scale(16) > 20;
    return PickerSheetFrame(
      key_prefix: 'time-picker',
      height: 520 + MediaQuery.paddingOf(context).bottom,
      onDismiss: _cancel,
      body: Column(
        children: [
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
                      Text(widget.selection_hint, style: AppTheme.body_small),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  onPressed: _cancel,
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
              icon: CupertinoIcons.clock,
              value: _formatTime(_selected_time),
              action_label: '지금',
              onAction: _selectCurrentTime,
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
          SizedBox(
            height: 180,
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
        ],
      ),
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
        child: Row(
          children: [
            Expanded(
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 13),
                color: AppTheme.surface_container_color,
                borderRadius: AppTheme.input_border_radius,
                onPressed: _cancel,
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
                key: const ValueKey('time-picker-apply'),
                padding: const EdgeInsets.symmetric(vertical: 13),
                color: AppTheme.primary_color,
                borderRadius: AppTheme.input_border_radius,
                onPressed: _applySelection,
                child: Text(
                  compact_actions ? '적용' : '선택한 시간 적용',
                  semanticsLabel: '선택한 시간 적용',
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
    );
  }
}

Future<Duration?> showTimePickerSheet({
  required BuildContext context,
  required String title,
  required Duration initial_time,
  String selection_hint = '원하는 시간을 선택하세요',
}) async {
  final route = CupertinoModalPopupRoute<Duration>(
    barrierDismissible: true,
    builder: (context) => TimePickerSheet(
      title: title,
      initial_time: initial_time,
      selection_hint: selection_hint,
    ),
  );
  final result = await Navigator.of(context, rootNavigator: true).push(route);
  await route.completed;
  return result;
}
