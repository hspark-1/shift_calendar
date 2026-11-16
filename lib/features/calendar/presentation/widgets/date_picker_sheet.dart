// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_theme.dart';
import 'year_month_picker_sheet.dart';
import 'picker_sheet_frame.dart';

/// 월간 달력에서 날짜를 고른 뒤 확인으로 확정하는 시트다.
class DatePickerSheet extends StatefulWidget {
  const DatePickerSheet({
    super.key,
    required this.title,
    required this.initial_date,
    required this.minimum_date,
    required this.maximum_date,
    this.selection_hint = '날짜를 고른 뒤 확인을 눌러주세요.',
  });

  final String title;
  final DateTime initial_date;
  final DateTime minimum_date;
  final DateTime maximum_date;
  final String selection_hint;

  @override
  State<DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<DatePickerSheet> {
  late DateTime _selected_date;
  late DateTime _focused_date;
  bool _choosing_month = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _selected_date = _clampDate(widget.initial_date);
    _focused_date = _selected_date;
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _clampDate(DateTime date) {
    final day = _dateOnly(date);
    final minimum_date = _dateOnly(widget.minimum_date);
    final maximum_date = _dateOnly(widget.maximum_date);
    if (day.isBefore(minimum_date)) return minimum_date;
    if (day.isAfter(maximum_date)) return maximum_date;
    return day;
  }

  bool _canSelect(DateTime date) =>
      !date.isBefore(_dateOnly(widget.minimum_date)) &&
      !date.isAfter(_dateOnly(widget.maximum_date));

  bool _canMoveMonth(int offset) {
    final month = DateTime(_focused_date.year, _focused_date.month + offset);
    return !DateTime(
          month.year,
          month.month + 1,
          0,
        ).isBefore(_dateOnly(widget.minimum_date)) &&
        !month.isAfter(_dateOnly(widget.maximum_date));
  }

  void _moveMonth(int offset) {
    if (!_canMoveMonth(offset)) return;
    setState(
      () => _focused_date = _clampDate(
        DateTime(_focused_date.year, _focused_date.month + offset),
      ),
    );
  }

  Future<void> _chooseMonth() async {
    if (_choosing_month || _closing) return;
    _choosing_month = true;
    try {
      final month = await showYearMonthPickerSheet(
        context: context,
        initial_date: _focused_date,
        first_year: widget.minimum_date.year,
        last_year: widget.maximum_date.year,
      );
      if (!mounted || month == null) return;
      setState(() => _focused_date = _clampDate(month));
    } finally {
      _choosing_month = false;
    }
  }

  String _formatDate(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${date.year}년 ${date.month}월 ${date.day}일 (${weekdays[date.weekday - 1]})';
  }

  void _selectDate(DateTime date) {
    final day = _dateOnly(date);
    if (_closing || !_canSelect(day)) return;
    setState(() => _selected_date = day);
  }

  void _selectToday() {
    final today = _dateOnly(DateTime.now());
    if (_closing || !_canSelect(today)) return;
    setState(() {
      _selected_date = today;
      _focused_date = today;
    });
  }

  void _confirm() {
    if (_closing) return;
    _closing = true;
    Navigator.of(context).pop(_selected_date);
  }

  void _cancel() {
    if (_closing) return;
    _closing = true;
    Navigator.of(context).pop();
  }

  Widget _buildDay(BuildContext context, DateTime day, DateTime focused_day) {
    final date = _dateOnly(day);
    final selected = isSameDay(day, _selected_date);
    final enabled = _canSelect(date);
    final color = !enabled
        ? AppTheme.outline_color
        : selected
        ? AppTheme.surface_color
        : day.weekday == DateTime.sunday
        ? AppTheme.accent_red_color
        : day.weekday == DateTime.saturday
        ? AppTheme.primary_color
        : AppTheme.on_surface_color;
    return Semantics(
      key: ValueKey('date-picker-day-${day.year}-${day.month}-${day.day}'),
      label: _formatDate(day),
      selected: selected,
      enabled: enabled,
      button: enabled,
      excludeSemantics: true,
      onTap: enabled ? () => _selectDate(day) : null,
      child: Container(
        margin: const EdgeInsets.all(2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary_color : null,
          borderRadius: AppTheme.input_border_radius,
          border: isSameDay(day, DateTime.now()) && !selected
              ? Border.all(color: AppTheme.primary_color)
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${day.day}',
            maxLines: 1,
            softWrap: false,
            style: AppTheme.body_large.copyWith(
              color: color,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthNavigation() {
    final month_label = '${_focused_date.year}년 ${_focused_date.month}월';
    final month_style = AppTheme.body_large.copyWith(
      fontWeight: FontWeight.w700,
    );
    final painter = TextPainter(
      text: TextSpan(text: month_label, style: month_style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final month_width = painter.width.ceilToDouble();
    painter.text = TextSpan(
      text: '오늘',
      style: MediaQuery.boldTextOf(context)
          ? AppTheme.body_medium.copyWith(fontWeight: FontWeight.bold)
          : AppTheme.body_medium,
    );
    painter.layout();
    final today_width = math.max(48.0, painter.width.ceilToDouble() + 16);
    painter.dispose();
    final previous = CupertinoButton(
      key: const ValueKey('date-picker-previous-month'),
      minimumSize: const Size(48, 48),
      padding: EdgeInsets.zero,
      onPressed: _canMoveMonth(-1) ? () => _moveMonth(-1) : null,
      child: const Icon(CupertinoIcons.chevron_left, semanticLabel: '이전 달'),
    );
    final next = CupertinoButton(
      key: const ValueKey('date-picker-next-month'),
      minimumSize: const Size(48, 48),
      padding: EdgeInsets.zero,
      onPressed: _canMoveMonth(1) ? () => _moveMonth(1) : null,
      child: const Icon(CupertinoIcons.chevron_right, semanticLabel: '다음 달'),
    );
    final month = CupertinoButton(
      key: const ValueKey('date-picker-month'),
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(vertical: 8),
      onPressed: _chooseMonth,
      child: Text(month_label, style: month_style),
    );
    final today = CupertinoButton(
      key: const ValueKey('date-picker-today'),
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.all(8),
      onPressed: _canSelect(_dateOnly(DateTime.now())) ? _selectToday : null,
      child: Text(
        '오늘',
        style: AppTheme.body_medium.copyWith(
          color: _canSelect(_dateOnly(DateTime.now()))
              ? AppTheme.primary_color
              : AppTheme.outline_color,
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // 오늘 버튼도 글자 배율에 맞춰 커지므로 텍스트 높이만으로 분기하지 않는다.
        if (constraints.maxWidth >= 96 + month_width + 8 + today_width) {
          return Row(
            children: [
              previous,
              Expanded(child: month),
              next,
              const SizedBox(width: 8),
              today,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            month,
            Row(
              children: [previous, const Spacer(), today, const Spacer(), next],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final row_height = math.max(44.0, media.textScaler.scale(20) + 12);
    return PickerSheetFrame(
      key_prefix: 'date-picker',
      height: 288 + row_height * 6 + media.padding.bottom,
      onDismiss: _cancel,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: AppTheme.heading_small),
                        const SizedBox(height: 4),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _formatDate(_selected_date),
                            key: const ValueKey('date-picker-selected-date'),
                            style: AppTheme.body_medium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    minimumSize: const Size(48, 48),
                    padding: EdgeInsets.zero,
                    onPressed: _cancel,
                    child: const Icon(
                      CupertinoIcons.xmark,
                      semanticLabel: '날짜 선택 닫기',
                      color: AppTheme.on_surface_variant_color,
                    ),
                  ),
                ],
              ),
            ),
            _buildMonthNavigation(),
            TableCalendar<dynamic>(
              key: const ValueKey('date-picker-calendar'),
              locale: 'ko_KR',
              firstDay: _dateOnly(widget.minimum_date),
              lastDay: _dateOnly(widget.maximum_date),
              focusedDay: _focused_date,
              selectedDayPredicate: (day) => isSameDay(day, _selected_date),
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              availableGestures: AvailableGestures.horizontalSwipe,
              headerVisible: false,
              sixWeekMonthsEnforced: true,
              rowHeight: row_height,
              daysOfWeekHeight: math.max(28, media.textScaler.scale(14) + 8),
              pageAnimationEnabled: !media.disableAnimations,
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: AppTheme.body_small,
                weekendStyle: AppTheme.body_small.copyWith(
                  color: AppTheme.primary_color,
                ),
              ),
              calendarStyle: const CalendarStyle(outsideDaysVisible: false),
              calendarBuilders: CalendarBuilders(
                dowBuilder: (context, day) {
                  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
                  return Center(
                    child: Text(
                      weekdays[day.weekday - 1],
                      style: AppTheme.body_small.copyWith(
                        color: day.weekday == DateTime.sunday
                            ? AppTheme.accent_red_color
                            : day.weekday == DateTime.saturday
                            ? AppTheme.primary_color
                            : AppTheme.on_surface_variant_color,
                      ),
                    ),
                  );
                },
                defaultBuilder: _buildDay,
                selectedBuilder: _buildDay,
                todayBuilder: _buildDay,
                disabledBuilder: _buildDay,
              ),
              onDaySelected: (day, focused_day) => _selectDate(day),
              onPageChanged: (day) =>
                  setState(() => _focused_date = _dateOnly(day)),
            ),
          ],
        ),
      ),
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Row(
          children: [
            Expanded(
              child: CupertinoButton(
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                color: AppTheme.surface_container_color,
                borderRadius: AppTheme.input_border_radius,
                onPressed: _cancel,
                child: Text(
                  '취소',
                  style: AppTheme.body_large.copyWith(
                    color: AppTheme.on_surface_variant_color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: media.textScaler.scale(16) > 20 ? 1 : 2,
              child: CupertinoButton(
                key: const ValueKey('date-picker-confirm'),
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                color: AppTheme.primary_color,
                borderRadius: AppTheme.input_border_radius,
                onPressed: _confirm,
                child: Text(
                  '확인',
                  style: AppTheme.body_large.copyWith(
                    color: AppTheme.surface_color,
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

Future<DateTime?> showDatePickerSheet({
  required BuildContext context,
  required String title,
  required DateTime initial_date,
  required DateTime minimum_date,
  required DateTime maximum_date,
  String selection_hint = '날짜를 고른 뒤 확인을 눌러주세요.',
}) async {
  final route = CupertinoModalPopupRoute<DateTime>(
    builder: (context) => DatePickerSheet(
      title: title,
      initial_date: initial_date,
      minimum_date: minimum_date,
      maximum_date: maximum_date,
      selection_hint: selection_hint,
    ),
    barrierDismissible: true,
  );
  final result = await Navigator.of(context, rootNavigator: true).push(route);
  await route.completed;
  return result;
}
