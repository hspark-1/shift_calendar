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
                  ? const Center(
                      child: SingleChildScrollView(
                        child: CalendarEmptySchedule(),
                      ),
                    )
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

/// 날짜/공휴일/요약을 실제 가용 폭에 맞춰 통째로 다음 줄에 배치한다.
class CalendarScheduleHeader extends StatelessWidget {
  const CalendarScheduleHeader({
    super.key,
    required this.selected_date,
    this.holiday_name,
    this.total_count,
    this.trailing,
    this.summary_chips = const [],
    this.header_key = const ValueKey('selected-day-header'),
    this.summary_key,
  });

  final DateTime selected_date;
  final String? holiday_name;
  final int? total_count;
  final Widget? trailing;
  final List<CalendarScheduleSummaryChip> summary_chips;
  final Key header_key;
  final Key? summary_key;

  @override
  Widget build(BuildContext context) {
    final summaries = <Widget>[
      ...summary_chips,
      if (total_count != null)
        CalendarScheduleSummaryChip(
          key: const ValueKey('selected-day-schedule-count'),
          label: '일정 $total_count개',
        ),
      if (trailing != null) trailing!,
    ];
    return Container(
      key: header_key,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing_md,
        vertical: AppTheme.spacing_sm,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.outline_variant_color, width: 0.5),
        ),
      ),
      child: Wrap(
        key: const ValueKey('selected-day-header-content'),
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: AppTheme.spacing_sm,
        runSpacing: AppTheme.spacing_sm,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 28),
            child: Align(
              alignment: AlignmentDirectional.bottomStart,
              widthFactor: 1,
              heightFactor: 1,
              child: Wrap(
                key: const ValueKey('selected-day-title-content'),
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: AppTheme.spacing_sm,
                runSpacing: AppTheme.spacing_xs,
                children: [
                  Text(
                    DateFormat('M월 d일 EEEE', 'ko_KR').format(selected_date),
                    style: AppTheme.heading_small,
                  ),
                  if (holiday_name != null)
                    Text(
                      holiday_name!,
                      key: const ValueKey('selected-day-holiday-name'),
                      style: AppTheme.body_small.copyWith(
                        color: AppTheme.accent_red_color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (summaries.isNotEmpty)
            Wrap(
              key: summary_key,
              spacing: 6,
              runSpacing: AppTheme.spacing_sm,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: summaries,
            ),
        ],
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

/// 근무·개인 일정·그룹 구성원 행이 공유하는 색상과 간격.
class CalendarScheduleItem extends StatelessWidget {
  const CalendarScheduleItem({
    super.key,
    required this.color,
    required this.child,
    this.include_margin = true,
  });

  final Color color;
  final Widget child;
  final bool include_margin;

  @override
  Widget build(BuildContext context) {
    final item = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppTheme.input_border_radius,
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: child,
    );
    if (!include_margin) return item;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: item,
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
    return CalendarScheduleItem(
      color: color,
      include_margin: include_margin,
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

    return CalendarScheduleItem(
      color: AppTheme.primary_color,
      include_margin: include_margin,
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
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      time_text,
                      style: AppTheme.body_small.copyWith(
                        color: AppTheme.on_surface_variant_color,
                      ),
                    ),
                    if (event.place != null && event.place!.isNotEmpty) ...[
                      Text(
                        '• ${event.place}',
                        style: AppTheme.body_small.copyWith(
                          color: AppTheme.on_surface_variant_color,
                        ),
                        overflow: TextOverflow.ellipsis,
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
  return '${formatApiTime(work_shift.startTime!)} - ${formatApiTime(work_shift.endTime!)}';
}

String formatApiTime(String time) {
  return time.length >= 5 ? time.substring(0, 5) : time;
}
