// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/event_api_model.dart';
import '../../data/models/work_shift_api_model.dart';

typedef WorkShiftItemBuilder =
    Widget Function(WorkShiftApiModel work_shift, int index);
typedef EventItemBuilder = Widget Function(EventApiModel event, int index);

class CalendarScheduleCard extends StatelessWidget {
  const CalendarScheduleCard({
    super.key,
    required this.selected_date,
    required this.work_shift,
    required this.events,
    this.holiday_name,
    this.work_shift_item_builder,
    this.event_item_builder,
    this.footer,
  });

  final DateTime selected_date;
  final WorkShiftApiModel? work_shift;
  final List<EventApiModel> events;
  final String? holiday_name;
  final WorkShiftItemBuilder? work_shift_item_builder;
  final EventItemBuilder? event_item_builder;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final total_count = (work_shift == null ? 0 : 1) + events.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: AppTheme.cardDecoration(),
      child: ClipRRect(
        borderRadius: AppTheme.card_border_radius,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CalendarScheduleHeader(
              selected_date: selected_date,
              holiday_name: holiday_name,
              total_count: total_count,
            ),
            Expanded(
              child: total_count == 0
                  ? const CalendarEmptySchedule()
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (work_shift != null)
                            work_shift_item_builder?.call(work_shift!, 0) ??
                                CalendarWorkShiftItem(work_shift: work_shift!),
                          ...List.generate(
                            events.length,
                            (index) =>
                                event_item_builder?.call(
                                  events[index],
                                  index,
                                ) ??
                                CalendarEventItem(events[index]),
                          ),
                        ],
                      ),
                    ),
            ),
            if (footer != null) footer!,
          ],
        ),
      ),
    );
  }
}

class CalendarScheduleHeader extends StatelessWidget {
  const CalendarScheduleHeader({
    super.key,
    required this.selected_date,
    this.holiday_name,
    this.total_count,
    this.trailing,
  });

  final DateTime selected_date;
  final String? holiday_name;
  final int? total_count;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('selected-day-header'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing_md,
        vertical: AppTheme.spacing_sm,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.outline_variant_color, width: 0.5),
        ),
      ),
      child: SizedBox(
        height: 28,
        child: Row(
          key: const ValueKey('selected-day-header-content'),
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: SizedBox(
                height: 28,
                child: Row(
                  key: const ValueKey('selected-day-title-content'),
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('M월 d일 EEEE', 'ko_KR').format(selected_date),
                      style: AppTheme.heading_small,
                    ),
                    if (holiday_name != null) ...[
                      const SizedBox(width: AppTheme.spacing_sm),
                      Flexible(
                        child: Text(
                          holiday_name!,
                          key: const ValueKey('selected-day-holiday-name'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.body_small.copyWith(
                            color: AppTheme.accent_red_color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (total_count != null) ...[
              const SizedBox(width: AppTheme.spacing_sm),
              CalendarScheduleSummaryChip(
                key: const ValueKey('selected-day-schedule-count'),
                label: '일정 $total_count개',
              ),
            ],
            if (trailing != null) ...[
              const SizedBox(width: AppTheme.spacing_sm),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class CalendarScheduleSummaryChip extends StatelessWidget {
  const CalendarScheduleSummaryChip({
    super.key,
    required this.label,
    this.is_primary = false,
  });

  final String label;
  final bool is_primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: is_primary
            ? AppTheme.primary_color.withValues(alpha: 0.08)
            : AppTheme.surface_container_low_color,
        borderRadius: BorderRadius.circular(AppTheme.chip_radius),
      ),
      child: Text(
        label,
        style: AppTheme.body_small.copyWith(
          color: is_primary
              ? AppTheme.primary_dark_color
              : AppTheme.on_surface_variant_color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class CalendarWorkShiftItem extends StatelessWidget {
  const CalendarWorkShiftItem({
    super.key,
    required this.work_shift,
    this.trailing,
    this.include_margin = true,
  });

  final WorkShiftApiModel work_shift;
  final Widget? trailing;
  final bool include_margin;

  @override
  Widget build(BuildContext context) {
    final color = Color(work_shift.shiftTypeColor ?? 0xFF8E8E93);
    final item = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppTheme.input_border_radius,
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  work_shift.shiftTypeName,
                  style: AppTheme.body_medium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.on_surface_color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatWorkShiftTime(work_shift),
                  style: AppTheme.body_small.copyWith(
                    color: AppTheme.on_surface_variant_color,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );

    if (!include_margin) return item;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: item,
    );
  }
}

class CalendarEventItem extends StatelessWidget {
  const CalendarEventItem(
    this.event, {
    super.key,
    this.trailing,
    this.include_margin = true,
  });

  final EventApiModel event;
  final Widget? trailing;
  final bool include_margin;

  @override
  Widget build(BuildContext context) {
    final time_text = event.allDay
        ? '종일'
        : '${DateFormat('HH:mm', 'ko_KR').format(event.startAt)} - ${DateFormat('HH:mm', 'ko_KR').format(event.endAt)}';

    final item = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primary_color.withValues(alpha: 0.08),
        borderRadius: AppTheme.input_border_radius,
        border: const Border(
          left: BorderSide(color: AppTheme.primary_color, width: 4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppTheme.primary_color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: AppTheme.body_medium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.on_surface_color,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      time_text,
                      style: AppTheme.body_small.copyWith(
                        color: AppTheme.on_surface_variant_color,
                      ),
                    ),
                    if (event.place != null && event.place!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '• ${event.place}',
                          style: AppTheme.body_small.copyWith(
                            color: AppTheme.on_surface_variant_color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                if (event.memo != null && event.memo!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    event.memo!,
                    style: AppTheme.body_small.copyWith(
                      color: AppTheme.on_surface_variant_color,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );

    if (!include_margin) return item;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: item,
    );
  }
}

class CalendarEmptySchedule extends StatelessWidget {
  const CalendarEmptySchedule({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.calendar,
            size: 32,
            color: AppTheme.outline_variant_color,
          ),
          const SizedBox(height: 6),
          Text(
            '등록된 일정이 없습니다',
            style: AppTheme.body_medium.copyWith(
              color: AppTheme.on_surface_variant_color,
            ),
          ),
        ],
      ),
    );
  }
}

String formatWorkShiftTime(WorkShiftApiModel work_shift) {
  if (work_shift.startTime == null || work_shift.endTime == null) {
    return '근무없음';
  }
  return '${formatApiTime(work_shift.startTime!)} ~ ${formatApiTime(work_shift.endTime!)}';
}

String formatApiTime(String time) {
  return time.length >= 5 ? time.substring(0, 5) : time;
}
