// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_theme.dart';
import '../models/calendar_day_presentation.dart';
import '../models/calendar_layout_policy.dart';

final _first_calendar_day = DateTime.utc(2000, 1, 1);

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
    this.onToday,
    this.today_key,
  });

  final DateTime focused_day;
  final bool can_go_to_previous_month;
  final bool can_go_to_next_month;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onSelectYearMonth;
  final Widget trailing;
  final VoidCallback? onToday;
  final Key? today_key;

  @override
  Widget build(BuildContext context) {
    final year_month = DateFormat('yyyy.MM', 'ko_KR').format(focused_day);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wrap_actions =
              constraints.maxWidth < 280 ||
              MediaQuery.textScalerOf(context).scale(16) > 20;
          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onToday != null)
                CupertinoButton(
                  key: today_key ?? const ValueKey('calendar-today-button'),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(44, 44),
                  onPressed: onToday,
                  child: Text(
                    '오늘',
                    style: AppTheme.body_medium.copyWith(
                      color: AppTheme.primary_color,
                    ),
                  ),
                ),
              trailing,
            ],
          );
          final previous_button = CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(44, 44),
            onPressed: can_go_to_previous_month ? onPreviousMonth : null,
            child: const Icon(CupertinoIcons.chevron_left, size: 20),
          );
          final next_button = CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(44, 44),
            onPressed: can_go_to_next_month ? onNextMonth : null,
            child: const Icon(CupertinoIcons.chevron_right, size: 20),
          );
          final month_button = CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onSelectYearMonth,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(year_month, style: AppTheme.heading_small),
                ),
                const SizedBox(width: 4),
                const Icon(CupertinoIcons.chevron_down, size: 12),
              ],
            ),
          );
          if (wrap_actions) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                month_button,
                Row(
                  children: [
                    previous_button,
                    next_button,
                    const Spacer(),
                    actions,
                  ],
                ),
              ],
            );
          }
          return Row(
            children: [
              previous_button,
              Expanded(child: month_button),
              next_button,
              actions,
            ],
          );
        },
      ),
    );
  }
}

class CalendarMonthView<T> extends StatelessWidget {
  const CalendarMonthView({
    super.key,
    required this.calendar_key,
    required this.focused_day,
    required this.selected_day,
    required this.calendar_format,
    required this.row_height,
    required this.day_presentation_builder,
    required this.cell_layout,
    required this.onDaySelected,
    required this.onPageChanged,
    this.holiday_predicate,
    this.onFormatChanged,
    this.available_calendar_formats = const {
      CalendarFormat.month: '월',
      CalendarFormat.threeWeeks: '3주',
      CalendarFormat.twoWeeks: '2주',
      CalendarFormat.week: '주',
    },
    this.day_key_prefix,
    this.selection_key_prefix,
    this.days_of_week_height = 32,
    this.is_month_overview = false,
    this.focus_revision = 0,
  });

  final DateTime focused_day;
  final Key calendar_key;
  final DateTime? selected_day;
  final CalendarFormat calendar_format;
  final double row_height;
  final CalendarDayPresentationBuilder day_presentation_builder;
  final CalendarCellLayout cell_layout;
  final bool Function(DateTime day)? holiday_predicate;
  final void Function(DateTime selected_day, DateTime focused_day)
  onDaySelected;
  final void Function(DateTime focused_day) onPageChanged;
  final void Function(CalendarFormat format)? onFormatChanged;
  final Map<CalendarFormat, String> available_calendar_formats;
  final String? day_key_prefix;
  final String? selection_key_prefix;
  final double days_of_week_height;
  final bool is_month_overview;
  final int focus_revision;

  @override
  Widget build(BuildContext context) {
    final weekday_style = AppTheme.body_small;
    final weekday_height =
        MediaQuery.textScalerOf(context).scale(weekday_style.fontSize!) *
        weekday_style.height!;
    final actual_weekday_height = weekday_height > days_of_week_height
        ? weekday_height
        : days_of_week_height;
    return _CalendarPageChangeBoundary(
      focused_day: focused_day,
      calendar_format: calendar_format,
      onPageChanged: onPageChanged,
      builder: (onUserPageChanged) {
        if (!is_month_overview) {
          return _buildCalendar(
            context,
            row_height,
            actual_weekday_height,
            onUserPageChanged,
          );
        }
        return _CalendarOverview(
          focused_day: focused_day,
          calendar_format: calendar_format,
          focus_revision: focus_revision,
          weekday_height: actual_weekday_height,
          scroll_key: ValueKey('$calendar_key-overview-scroll'),
          builder: (height) => _buildCalendar(
            context,
            height,
            actual_weekday_height,
            onUserPageChanged,
          ),
        );
      },
    );
  }

  Widget _buildCalendar(
    BuildContext context,
    double actual_row_height,
    double weekday_height,
    ValueChanged<DateTime> onUserPageChanged,
  ) {
    final week_segments = <DateTime, List<CalendarEventSegment>>{};
    final calendar = TableCalendar<T>(
      key: calendar_key,
      firstDay: _first_calendar_day,
      lastDay: DateTime.utc(2050, 12, 31),
      focusedDay: focused_day,
      calendarFormat: calendar_format,
      locale: 'ko_KR',
      headerVisible: false,
      daysOfWeekHeight: weekday_height,
      rowHeight: actual_row_height,
      formatAnimationDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 200),
      availableCalendarFormats: available_calendar_formats,
      availableGestures: AvailableGestures.horizontalSwipe,
      holidayPredicate: holiday_predicate,
      selectedDayPredicate: (day) => isSameDay(selected_day, day),
      onDaySelected: onDaySelected,
      onPageChanged: onUserPageChanged,
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
        tableBorder: is_month_overview
            ? const TableBorder(
                horizontalInside: BorderSide(
                  color: AppTheme.outline_variant_color,
                  width: 0.3,
                ),
              )
            : const TableBorder(),
        tablePadding: const EdgeInsets.only(bottom: AppTheme.spacing_sm),
        cellMargin: const EdgeInsets.all(2),
        markersAlignment: Alignment.bottomCenter,
        canMarkersOverflow: true,
        outsideDaysVisible: true,
        outsideTextStyle: TextStyle(
          color: AppTheme.on_surface_color.withValues(alpha: 0.25),
        ),
        defaultTextStyle: const TextStyle(color: AppTheme.on_surface_color),
      ),
      calendarBuilders: CalendarBuilders<T>(
        markerBuilder: (context, date, _) {
          if (!is_month_overview) return null;
          final week_start = DateTime(
            date.year,
            date.month,
            date.day - date.weekday % 7,
          );
          final segments = week_segments.putIfAbsent(
            week_start,
            () => calendarEventSegmentsForWeek(
              week_start,
              day_presentation_builder,
            ),
          );
          return _buildEventMarkers(context, date, actual_row_height, segments);
        },
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
                presentation: day_presentation_builder(date),
                is_outside:
                    date.year != focused_day.year ||
                    date.month != focused_day.month,
              ),
        defaultBuilder: (context, date, focused_day) => _buildDayCell(
          date: date,
          presentation: day_presentation_builder(date),
        ),
        outsideBuilder: (context, date, focused_day) => _buildDayCell(
          date: date,
          presentation: day_presentation_builder(date),
          is_outside: true,
        ),
        todayBuilder: (context, date, focused_day) => _buildDayCell(
          date: date,
          presentation: day_presentation_builder(date),
          is_today: true,
        ),
        selectedBuilder: (context, date, focused_day) => _buildDayCell(
          date: date,
          presentation: day_presentation_builder(date),
          is_today: isSameDay(date, DateTime.now()),
          is_selected: true,
          is_outside:
              date.year != focused_day.year || date.month != focused_day.month,
        ),
      ),
    );
    // AnimatedSize의 0초 전환은 자체 layout 중 listener를 호출하므로
    // 동작 줄이기에서 치수가 바뀌면 해당 subtree를 새 치수로 바로 구성한다.
    return MediaQuery.disableAnimationsOf(context)
        ? KeyedSubtree(
            key: ValueKey((calendar_format, actual_row_height, weekday_height)),
            child: calendar,
          )
        : calendar;
  }

  Widget _buildDayCell({
    required DateTime date,
    required CalendarDayPresentation presentation,
    bool is_today = false,
    bool is_selected = false,
    bool is_outside = false,
  }) {
    final layout = _CellLayoutMetrics.from(cell_layout);
    final outside_alpha = is_outside ? 0.4 : 1.0;
    final date_text = Text(
      '${date.day}',
      maxLines: 1,
      softWrap: false,
      style: TextStyle(
        color: presentation.date_color.withValues(alpha: outside_alpha),
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
                Flexible(
                  child: FittedBox(fit: BoxFit.scaleDown, child: date_text),
                ),
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
        : FittedBox(fit: BoxFit.scaleDown, child: date_text);
    final cell_content = _buildCellContent(
      date: date,
      date_indicator: date_indicator,
      indicator: presentation.indicator,
      outside_alpha: outside_alpha,
    );
    final cell = SizedBox.expand(
      key: _dateKey(day_key_prefix, date),
      child: ColoredBox(
        color: CupertinoColors.transparent,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Transform.translate(
              offset: Offset(0, layout.selection_box_offset_y),
              child: AnimatedContainer(
                key: _dateKey(selection_key_prefix, date),
                duration: Duration.zero,
                curve: Curves.easeInOut,
                width: is_selected ? layout.selection_box_size : 0,
                height: is_selected ? layout.selection_box_size : 0,
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
      ),
    );

    final semantic_label =
        presentation.semantic_label ??
        '${DateFormat('M월 d일 EEEE', 'ko_KR').format(date)}'
            '${is_today ? ', 오늘' : ''}'
            '${is_month_overview && presentation.events.isNotEmpty ? ', ${presentation.events.map((event) => event.title).join(', ')}' : ''}';
    return Semantics(
      label: semantic_label,
      selected: is_selected,
      button: true,
      child: cell,
    );
  }

  Widget _buildCellContent({
    required DateTime date,
    required Widget date_indicator,
    required CalendarDayIndicator? indicator,
    required double outside_alpha,
  }) {
    if (cell_layout == CalendarCellLayout.compact) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Center(child: date_indicator),
          if (indicator != null)
            Positioned(
              bottom: 0,
              child: _buildIndicator(date, indicator, outside_alpha),
            ),
        ],
      );
    }

    final indicator_height = cell_layout == CalendarCellLayout.badge
        ? 16.0
        : 8.0;
    final vertical_gap = cell_layout == CalendarCellLayout.badge ? 2.0 : 0.0;
    return Column(
      mainAxisAlignment: is_month_overview
          ? MainAxisAlignment.start
          : MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (is_month_overview) const SizedBox(height: 8),
        SizedBox(height: 28, child: Center(child: date_indicator)),
        SizedBox(height: vertical_gap),
        SizedBox(
          key: indicator is CalendarDotsIndicator
              ? _dateKey('${indicator.key_prefix}-dots', date)
              : null,
          height: indicator_height,
          child: indicator == null
              ? null
              : _buildIndicator(date, indicator, outside_alpha),
        ),
      ],
    );
  }

  Widget? _buildEventMarkers(
    BuildContext context,
    DateTime date,
    double actual_row_height,
    List<CalendarEventSegment> segments,
  ) {
    final area_top = cell_layout == CalendarCellLayout.dots ? 50.0 : 58.0;
    final lane_height = math.max(
      16.0,
      MediaQuery.textScalerOf(context).scale(10) * 1.1 + 4,
    );
    final capacity = math.max(
      0,
      ((actual_row_height - area_top) / lane_height).floor(),
    );
    final starts = segments
        .where(
          (segment) =>
              segment.start_column == date.weekday % 7 &&
              segment.lane < capacity,
        )
        .toList();
    if (starts.isEmpty) return null;
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          clipBehavior: Clip.none,
          children: [
            for (final segment in starts)
              Positioned(
                left: segment.continues_before ? 0 : 2,
                top: area_top + segment.lane * lane_height,
                width:
                    constraints.maxWidth *
                        (segment.end_column - segment.start_column + 1) -
                    (segment.continues_before ? 0 : 2) -
                    (segment.continues_after ? 0 : 2),
                height: lane_height - 2,
                child: Semantics(
                  label: segment.event.title,
                  child: Container(
                    key: ValueKey(
                      'calendar-event-bar-${segment.event.id}-${segment.week_start}',
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: AlignmentDirectional.centerStart,
                    decoration: BoxDecoration(
                      color: segment.event.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(segment.continues_before ? 0 : 4),
                        right: Radius.circular(segment.continues_after ? 0 : 4),
                      ),
                    ),
                    child: ExcludeSemantics(
                      child: Text(
                        segment.event.title,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.body_small.copyWith(
                          fontSize: 10,
                          height: 1.1,
                          color: AppTheme.readableForegroundColor(
                            segment.event.color.withValues(alpha: 0.12),
                            preferred_color: segment.event.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator(
    DateTime date,
    CalendarDayIndicator indicator,
    double opacity,
  ) {
    return switch (indicator) {
      CalendarBadgeIndicator() => _CalendarDayBadge(
        badge: indicator,
        opacity: opacity,
      ),
      CalendarDotsIndicator() => Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < indicator.colors.length; index++) ...[
            if (index > 0) SizedBox(width: indicator.spacing),
            Container(
              key: _dateIndexKey('${indicator.key_prefix}-dot', date, index),
              width: indicator.dot_size,
              height: indicator.dot_size,
              decoration: BoxDecoration(
                color: indicator.colors[index].withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    };
  }

  Key? _dateKey(String? prefix, DateTime date) {
    if (prefix == null) return null;
    return ValueKey(
      '$prefix-${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}',
    );
  }

  Key? _dateIndexKey(String? prefix, DateTime date, int index) {
    if (prefix == null) return null;
    return ValueKey(
      '$prefix-${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}-$index',
    );
  }
}

/// 프로그램의 기준 날짜/포맷 변경을 사용자의 월 스와이프로 처리하지 않는다.
class _CalendarPageChangeBoundary extends StatefulWidget {
  const _CalendarPageChangeBoundary({
    required this.builder,
    required this.onPageChanged,
    required this.focused_day,
    required this.calendar_format,
  });

  final DateTime focused_day;
  final CalendarFormat calendar_format;
  final Widget Function(ValueChanged<DateTime> onPageChanged) builder;
  final ValueChanged<DateTime> onPageChanged;

  @override
  State<_CalendarPageChangeBoundary> createState() =>
      _CalendarPageChangeBoundaryState();
}

class _CalendarPageChangeBoundaryState
    extends State<_CalendarPageChangeBoundary> {
  bool _is_user_paging = false;

  @override
  void didUpdateWidget(covariant _CalendarPageChangeBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focused_day != oldWidget.focused_day ||
        widget.calendar_format != oldWidget.calendar_format) {
      _is_user_paging = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis != Axis.horizontal) return false;
        if (notification is ScrollStartNotification &&
            notification.dragDetails != null) {
          _is_user_paging = true;
        } else if (notification is ScrollEndNotification) {
          _is_user_paging = false;
        }
        return false;
      },
      child: widget.builder((day) {
        if (_is_user_paging) widget.onPageChanged(day);
      }),
    );
  }
}

class _CalendarDayBadge extends StatelessWidget {
  const _CalendarDayBadge({required this.badge, required this.opacity});

  final CalendarBadgeIndicator badge;
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

class _CellLayoutMetrics {
  const _CellLayoutMetrics({
    required this.selection_box_size,
    required this.selection_box_offset_y,
  });

  factory _CellLayoutMetrics.from(CalendarCellLayout layout) {
    return switch (layout) {
      CalendarCellLayout.compact => const _CellLayoutMetrics(
        selection_box_size: 48,
        selection_box_offset_y: 8,
      ),
      CalendarCellLayout.badge ||
      CalendarCellLayout.dots => const _CellLayoutMetrics(
        selection_box_size: 58,
        selection_box_offset_y: 4,
      ),
    };
  }

  final double selection_box_size;
  final double selection_box_offset_y;
}

/// 카드 없는 달력의 스크롤을 분리하고 표시 형식에 맞춰 기준 주를 드러낸다.
class _CalendarOverview extends StatefulWidget {
  const _CalendarOverview({
    required this.focused_day,
    required this.calendar_format,
    required this.focus_revision,
    required this.weekday_height,
    required this.scroll_key,
    required this.builder,
  });

  final DateTime focused_day;
  final CalendarFormat calendar_format;
  final double weekday_height;
  final Key scroll_key;
  final int focus_revision;
  final Widget Function(double row_height) builder;

  @override
  State<_CalendarOverview> createState() => _CalendarOverviewState();
}

class _CalendarOverviewState extends State<_CalendarOverview> {
  final _scroll_controller = ScrollController(keepScrollOffset: false);
  bool _reveal_focus = true;

  @override
  void didUpdateWidget(covariant _CalendarOverview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focused_day != widget.focused_day ||
        oldWidget.calendar_format != widget.calendar_format ||
        oldWidget.focus_revision != widget.focus_revision) {
      _reveal_focus = true;
    }
  }

  @override
  void dispose() {
    _scroll_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final row_height = CalendarLayoutPolicy.overviewRowHeight(
        month: widget.focused_day,
        available_height: constraints.maxHeight,
        weekday_height: widget.weekday_height,
        text_height: MediaQuery.textScalerOf(context).scale(14),
        calendar_format: widget.calendar_format,
      );
      if (_reveal_focus) {
        _reveal_focus = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_scroll_controller.hasClients) return;
          final first_weekday =
              DateTime(
                widget.focused_day.year,
                widget.focused_day.month,
                1,
              ).weekday %
              7;
          final week_index = widget.calendar_format == CalendarFormat.month
              ? (first_weekday + widget.focused_day.day - 1) ~/ 7
              : _fixedFormatWeekIndex();
          final position = _scroll_controller.position;
          final offset =
              (week_index * row_height -
                      (position.viewportDimension - row_height) / 2)
                  .clamp(0.0, position.maxScrollExtent);
          position.jumpTo(offset);
        });
      }
      return SingleChildScrollView(
        key: widget.scroll_key,
        controller: _scroll_controller,
        primary: false,
        child: widget.builder(row_height),
      );
    },
  );

  int _fixedFormatWeekIndex() {
    final first_week = _first_calendar_day.subtract(
      Duration(days: _first_calendar_day.weekday % 7),
    );
    final focused = DateTime.utc(
      widget.focused_day.year,
      widget.focused_day.month,
      widget.focused_day.day,
    );
    return (focused.difference(first_week).inDays ~/ 7) %
        CalendarLayoutPolicy.weekCount(
          widget.calendar_format,
          widget.focused_day,
        );
  }
}
