// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/event_api_model.dart';
import '../../data/models/work_shift_api_model.dart';

typedef WorkShiftItemBuilder =
    Widget Function(WorkShiftApiModel work_shift, int index);
typedef EventItemBuilder = Widget Function(EventApiModel event, int index);

/// 헤더 드래그/목록 최상단 overscroll을 따라 움직이고 임계점에서 아래로 닫는다.
class CalendarScheduleDismissible extends StatefulWidget {
  const CalendarScheduleDismissible({
    super.key,
    required this.onClose,
    required this.child,
  });

  final VoidCallback onClose;
  final Widget child;

  @override
  State<CalendarScheduleDismissible> createState() =>
      _CalendarScheduleDismissibleState();
}

class _CalendarScheduleDismissibleState
    extends State<CalendarScheduleDismissible>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 240),
        )..addListener(() {
          setState(
            () => _offset =
                _animation_start +
                (_animation_end - _animation_start) *
                    Curves.easeOutCubic.transform(_controller.value),
          );
        });
  }

  double _offset = 0;
  double _animation_start = 0;
  double _animation_end = 0;
  bool _is_dismissing = false;
  bool _scroll_drag_active = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _start(DragStartDetails details) {
    if (!_is_dismissing) _controller.stop();
  }

  void _update(DragUpdateDetails details) {
    if (_is_dismissing) return;
    setState(() => _offset = math.max(0, _offset + details.delta.dy));
  }

  void _end(DragEndDetails details) => _settle(details.primaryVelocity ?? 0);
  void _cancel() => _animateTo(0, close: false);

  void _settle(double velocity) {
    if (_is_dismissing || _offset == 0) return;
    final height = context.size!.height;
    final should_close =
        _offset >= math.min(96, height * 0.25) ||
        (_offset > 16 && velocity > 700);
    _animateTo(should_close ? height : 0, close: should_close);
  }

  Future<void> _animateTo(double target, {required bool close}) async {
    if (_is_dismissing) return;
    _is_dismissing = close;
    if (MediaQuery.disableAnimationsOf(context)) {
      if (close) {
        widget.onClose();
      } else {
        setState(() => _offset = 0);
      }
      return;
    }
    _controller.stop();
    _animation_start = _offset;
    _animation_end = target;
    try {
      await _controller.forward(from: 0).orCancel;
      if (mounted && close) widget.onClose();
    } on TickerCanceled {
      // 날짜 전환/dispose 또는 새 드래그가 이전 정착 애니메이션을 취소한다.
    }
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 ||
        notification.metrics.axis != Axis.vertical ||
        _is_dismissing) {
      return false;
    }
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _scroll_drag_active = true;
      _controller.stop();
    } else if (_scroll_drag_active &&
        notification is OverscrollNotification &&
        notification.overscroll < 0) {
      setState(() => _offset -= notification.overscroll);
      return true;
    } else if (_scroll_drag_active &&
        notification is ScrollUpdateNotification &&
        notification.metrics.pixels < notification.metrics.minScrollExtent) {
      setState(
        () => _offset =
            notification.metrics.minScrollExtent - notification.metrics.pixels,
      );
    } else if (notification is ScrollEndNotification && _scroll_drag_active) {
      _scroll_drag_active = false;
      _settle(0);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => Transform.translate(
    key: const ValueKey('calendar-schedule-drag-transform'),
    offset: Offset(0, _offset),
    child: _CalendarScheduleDragScope(
      onStart: _start,
      onUpdate: _update,
      onEnd: _end,
      onCancel: _cancel,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: _start,
          onVerticalDragUpdate: _update,
          onVerticalDragEnd: _end,
          onVerticalDragCancel: _cancel,
          child: widget.child,
        ),
      ),
    ),
  );
}

class _CalendarScheduleDragScope extends InheritedWidget {
  const _CalendarScheduleDragScope({
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.onCancel,
    required super.child,
  });

  final GestureDragStartCallback onStart;
  final GestureDragUpdateCallback onUpdate;
  final GestureDragEndCallback onEnd;
  final VoidCallback onCancel;

  static _CalendarScheduleDragScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_CalendarScheduleDragScope>();

  @override
  bool updateShouldNotify(_CalendarScheduleDragScope oldWidget) => false;
}

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
    this.is_content_hidden = false,
    this.onClose,
    this.is_loading = false,
    this.load_error,
    this.onRetry,
  });

  final DateTime selected_date;
  final WorkShiftApiModel? work_shift;
  final List<EventApiModel> events;
  final String? holiday_name;
  final WorkShiftItemBuilder? work_shift_item_builder;
  final EventItemBuilder? event_item_builder;
  final Widget? footer;
  final bool is_content_hidden;
  final VoidCallback? onClose;
  final bool is_loading;
  final String? load_error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final total_count = (work_shift == null ? 0 : 1) + events.length;

    final card = Container(
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
              total_count: is_content_hidden || is_loading || load_error != null
                  ? null
                  : total_count,
              onClose: onClose,
            ),
            Expanded(
              child: is_content_hidden
                  ? const SizedBox.expand(
                      key: ValueKey('calendar-hidden-schedule-content'),
                    )
                  : is_loading || load_error != null
                  ? CalendarScheduleLoadState(
                      error: load_error,
                      onRetry: onRetry,
                    )
                  : total_count == 0
                  ? const Center(
                      child: SingleChildScrollView(
                        physics: ClampingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        child: CalendarEmptySchedule(),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const ClampingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      key: ValueKey('schedule-list-$selected_date'),
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
            if (!is_content_hidden && footer != null) footer!,
          ],
        ),
      ),
    );
    return onClose == null
        ? card
        : CalendarScheduleDismissible(
            key: ValueKey(selected_date),
            onClose: onClose!,
            child: card,
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
    this.onClose,
  });

  final DateTime selected_date;
  final String? holiday_name;
  final int? total_count;
  final Widget? trailing;
  final List<CalendarScheduleSummaryChip> summary_chips;
  final Key header_key;
  final Key? summary_key;
  final VoidCallback? onClose;

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
    final content = Wrap(
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
    );
    final header = Container(
      key: header_key,
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing_md,
        vertical: onClose == null ? AppTheme.spacing_sm : 0,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.outline_variant_color, width: 0.5),
        ),
      ),
      child: onClose == null
          ? content
          : Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacing_sm,
                    ),
                    child: content,
                  ),
                ),
                CupertinoButton(
                  key: const ValueKey('calendar-schedule-close'),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 44),
                  onPressed: onClose,
                  child: Semantics(
                    label: '일정 카드 닫기',
                    child: ExcludeSemantics(
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: AppTheme.surface_container_low_color,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.xmark,
                          size: 14,
                          color: AppTheme.on_surface_variant_color,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
    final scope = _CalendarScheduleDragScope.maybeOf(context);
    return scope == null
        ? header
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragStart: scope.onStart,
            onVerticalDragUpdate: scope.onUpdate,
            onVerticalDragEnd: scope.onEnd,
            onVerticalDragCancel: scope.onCancel,
            child: header,
          );
  }
}

class CalendarScheduleLoadState extends StatelessWidget {
  const CalendarScheduleLoadState({super.key, this.error, this.onRetry});

  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: error == null
        ? const CupertinoActivityIndicator()
        : SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error!, textAlign: TextAlign.center),
                if (onRetry != null)
                  CupertinoButton(
                    onPressed: onRetry,
                    child: const Text('다시 시도'),
                  ),
              ],
            ),
          ),
  );
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

  String? _dateRangeLabel() {
    final start = event.startAt;
    final end = event.allDay && event.endAt.isAfter(start)
        ? event.endAt.subtract(const Duration(microseconds: 1))
        : event.endAt;
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return null;
    }
    final format = DateFormat(
      start.year == end.year ? 'M.d' : 'yyyy.M.d',
      'ko_KR',
    );
    return '${format.format(start)} ~ ${format.format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final time_text = event.allDay
        ? '종일'
        : '${DateFormat('HH:mm', 'ko_KR').format(event.startAt)} - ${DateFormat('HH:mm', 'ko_KR').format(event.endAt)}';
    final date_range = _dateRangeLabel();

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
                if (date_range != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    date_range,
                    style: AppTheme.body_small.copyWith(
                      color: AppTheme.on_surface_variant_color,
                    ),
                  ),
                ],
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
