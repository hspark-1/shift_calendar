// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';

import 'calendar_month_view.dart';

/// 세 캘린더가 공유하는 연월 헤더와 수평 스와이프 경계.
///
/// 데이터 조회와 선택일 상세는 페이지 책임으로 남겨 화면별 기능을 분리한다.
class CalendarViewport extends StatelessWidget {
  const CalendarViewport({
    super.key,
    required this.focused_day,
    required this.can_go_to_previous_month,
    required this.can_go_to_next_month,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectYearMonth,
    required this.trailing,
    required this.month_view,
    this.grid_wrapper,
    this.header_key,
  });

  final DateTime focused_day;
  final bool can_go_to_previous_month;
  final bool can_go_to_next_month;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onSelectYearMonth;
  final Widget trailing;
  final Widget month_view;
  final Widget Function(Widget child)? grid_wrapper;
  final Key? header_key;

  @override
  Widget build(BuildContext context) {
    final horizontal_boundary = CalendarHorizontalScrollBoundary(
      child: month_view,
    );
    final calendar_grid =
        grid_wrapper?.call(horizontal_boundary) ?? horizontal_boundary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        KeyedSubtree(
          key: header_key,
          child: CalendarMonthHeader(
            focused_day: focused_day,
            can_go_to_previous_month: can_go_to_previous_month,
            can_go_to_next_month: can_go_to_next_month,
            onPreviousMonth: onPreviousMonth,
            onNextMonth: onNextMonth,
            onSelectYearMonth: onSelectYearMonth,
            trailing: trailing,
          ),
        ),
        calendar_grid,
      ],
    );
  }
}

class CalendarHorizontalScrollBoundary extends StatelessWidget {
  const CalendarHorizontalScrollBoundary({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final is_horizontal = notification.metrics.axis == Axis.horizontal;
        return is_horizontal &&
            (notification is ScrollStartNotification ||
                notification is ScrollUpdateNotification);
      },
      child: child,
    );
  }
}
