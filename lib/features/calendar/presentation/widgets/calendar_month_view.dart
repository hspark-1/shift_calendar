// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_theme.dart';

class CalendarDayBadgeData {
  const CalendarDayBadgeData({required this.text, required this.color});

  final String text;
  final Color color;
}

class CalendarMonthHeader extends StatelessWidget {
  const CalendarMonthHeader({
    super.key,
    required this.focused_day,
    required this.can_go_to_previous_month,
    required this.can_go_to_next_month,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectYearMonth,
    required this.trailing,
  });

  final DateTime focused_day;
  final bool can_go_to_previous_month;
  final bool can_go_to_next_month;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onSelectYearMonth;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final year_month = DateFormat('yyyy.MM', 'ko_KR').format(focused_day);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: can_go_to_previous_month ? onPreviousMonth : null,
            child: Icon(
              CupertinoIcons.chevron_left,
              size: 20,
              color: can_go_to_previous_month
                  ? AppTheme.on_surface_color
                  : AppTheme.outline_variant_color,
            ),
          ),
          GestureDetector(
            onTap: onSelectYearMonth,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(year_month, style: AppTheme.heading_medium),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.surface_container_low_color,
                    borderRadius: BorderRadius.circular(AppTheme.radius_md),
                  ),
                  child: const Icon(
                    CupertinoIcons.chevron_down,
                    size: 12,
                    color: AppTheme.on_surface_variant_color,
                  ),
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: can_go_to_next_month ? onNextMonth : null,
            child: Icon(
              CupertinoIcons.chevron_right,
              size: 20,
              color: can_go_to_next_month
                  ? AppTheme.on_surface_color
                  : AppTheme.outline_variant_color,
            ),
          ),
          const Spacer(),
          trailing,
        ],
      ),
    );
  }
}

class CalendarMonthView extends StatelessWidget {
  const CalendarMonthView({
    super.key,
    required this.calendar_key,
    required this.focused_day,
    required this.selected_day,
    required this.calendar_format,
    required this.row_height,
    required this.date_color_builder,
    required this.day_badge_builder,
    required this.show_day_badge,
    required this.onDaySelected,
    required this.onPageChanged,
    this.holiday_predicate,
    this.onFormatChanged,
    this.available_calendar_formats = const {
      CalendarFormat.month: '월',
      CalendarFormat.twoWeeks: '2주',
      CalendarFormat.week: '주',
    },
    this.marker_builder,
  });

  final DateTime focused_day;
  final Key calendar_key;
  final DateTime? selected_day;
  final CalendarFormat calendar_format;
  final double row_height;
  final Color Function(DateTime date) date_color_builder;
  final CalendarDayBadgeData? Function(DateTime date) day_badge_builder;
  final bool show_day_badge;
  final bool Function(DateTime day)? holiday_predicate;
  final void Function(DateTime selected_day, DateTime focused_day)
  onDaySelected;
  final void Function(DateTime focused_day) onPageChanged;
  final void Function(CalendarFormat format)? onFormatChanged;
  final Map<CalendarFormat, String> available_calendar_formats;
  final MarkerBuilder<dynamic>? marker_builder;

  @override
  Widget build(BuildContext context) {
    return TableCalendar<dynamic>(
      key: calendar_key,
      firstDay: DateTime.utc(2000, 1, 1),
      lastDay: DateTime.utc(2050, 12, 31),
      focusedDay: focused_day,
      calendarFormat: calendar_format,
      locale: 'ko_KR',
      headerVisible: false,
      daysOfWeekHeight: 32,
      rowHeight: row_height,
      availableCalendarFormats: available_calendar_formats,
      availableGestures: AvailableGestures.horizontalSwipe,
      holidayPredicate: holiday_predicate,
      selectedDayPredicate: (day) => isSameDay(selected_day, day),
      onDaySelected: onDaySelected,
      onPageChanged: onPageChanged,
      onFormatChanged: onFormatChanged,
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: AppTheme.body_small.copyWith(
          color: AppTheme.on_surface_color,
          fontWeight: FontWeight.w600,
        ),
        weekendStyle: AppTheme.body_small.copyWith(
          color: AppTheme.accent_red_color,
          fontWeight: FontWeight.w600,
        ),
      ),
      calendarStyle: CalendarStyle(
        tablePadding: const EdgeInsets.only(bottom: AppTheme.spacing_sm),
        cellMargin: const EdgeInsets.all(2),
        markersAlignment: Alignment.bottomCenter,
        outsideDaysVisible: true,
        outsideTextStyle: TextStyle(
          color: AppTheme.on_surface_color.withValues(alpha: 0.25),
        ),
        defaultTextStyle: const TextStyle(color: AppTheme.on_surface_color),
      ),
      calendarBuilders: CalendarBuilders<dynamic>(
        dowBuilder: (context, day) {
          final text_color = day.weekday == DateTime.sunday
              ? AppTheme.accent_red_color
              : day.weekday == DateTime.saturday
              ? AppTheme.primary_color
              : AppTheme.on_surface_variant_color;
          return Center(
            child: Text(
              DateFormat('E', 'ko_KR').format(day),
              style: AppTheme.body_small.copyWith(
                color: text_color,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
        holidayBuilder: holiday_predicate == null
            ? null
            : (context, date, focused_day) => _buildDayCell(
                date: date,
                text_color: date_color_builder(date),
                is_outside:
                    date.year != focused_day.year ||
                    date.month != focused_day.month,
              ),
        defaultBuilder: (context, date, focused_day) =>
            _buildDayCell(date: date, text_color: date_color_builder(date)),
        outsideBuilder: (context, date, focused_day) => _buildDayCell(
          date: date,
          text_color: date_color_builder(date),
          is_outside: true,
        ),
        todayBuilder: (context, date, focused_day) => _buildDayCell(
          date: date,
          text_color: date_color_builder(date),
          is_today: true,
        ),
        selectedBuilder: (context, date, focused_day) => _buildDayCell(
          date: date,
          text_color: date_color_builder(date),
          is_today: isSameDay(date, DateTime.now()),
          is_selected: true,
        ),
        markerBuilder: marker_builder,
      ),
    );
  }

  Widget _buildDayCell({
    required DateTime date,
    required Color text_color,
    bool is_today = false,
    bool is_selected = false,
    bool is_outside = false,
  }) {
    final badge = show_day_badge ? day_badge_builder(date) : null;
    final selection_box_size = show_day_badge ? 58.0 : 48.0;
    final selection_box_offset_y = show_day_badge ? 4.0 : 8.0;
    final outside_alpha = is_outside ? 0.4 : 1.0;
    final date_text = Text(
      '${date.day}',
      style: TextStyle(
        color: text_color.withValues(alpha: outside_alpha),
        fontSize: 14,
        fontWeight: is_selected || is_today
            ? FontWeight.w700
            : FontWeight.normal,
      ),
    );
    final date_indicator = is_today
        ? SizedBox(
            width: 28,
            height: 28,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                date_text,
                const SizedBox(height: 1),
                Container(
                  width: 12,
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppTheme.primary_color,
                    borderRadius: BorderRadius.circular(AppTheme.radius_sm),
                  ),
                ),
              ],
            ),
          )
        : date_text;
    final cell_content = show_day_badge
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 28, child: Center(child: date_indicator)),
              const SizedBox(height: 2),
              SizedBox(
                height: 16,
                child: badge == null
                    ? null
                    : _CalendarDayBadge(badge: badge, opacity: outside_alpha),
              ),
            ],
          )
        : Center(child: date_indicator);

    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Transform.translate(
            offset: Offset(0, selection_box_offset_y),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOut,
              width: is_selected ? selection_box_size : 0,
              height: is_selected ? selection_box_size : 0,
              decoration: BoxDecoration(
                color: is_selected
                    ? AppTheme.primary_color.withValues(alpha: 0.08)
                    : null,
                borderRadius: BorderRadius.circular(AppTheme.radius_md),
                border: is_selected
                    ? Border.all(color: AppTheme.primary_dark_color, width: 2)
                    : null,
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: cell_content,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarDayBadge extends StatelessWidget {
  const _CalendarDayBadge({required this.badge, required this.opacity});

  final CalendarDayBadgeData badge;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 44),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: badge.color.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(AppTheme.radius_sm),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            badge.text,
            style: TextStyle(
              color: AppTheme.readableForegroundColor(
                badge.color,
              ).withValues(alpha: opacity),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
