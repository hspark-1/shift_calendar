// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_theme.dart';
import 'calendar_month_view.dart';

/// 달력 뒤 남은 공간을 일정에 배정하고 좁은 높이·확대 글자를 처리한다.
class CalendarPageBody extends StatelessWidget {
  const CalendarPageBody({
    super.key,
    required this.calendar,
    this.schedule,
    required this.key_prefix,
  });

  final Widget calendar;
  final Widget? schedule;
  final String key_prefix;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      key: ValueKey('$key_prefix-layout'),
      builder: (context, constraints) {
        if (schedule == null) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacing_md),
            child: calendar,
          );
        }
        final text_scaler = MediaQuery.textScalerOf(context);
        final calendar_max_height =
            constraints.maxHeight -
            text_scaler.scale(144) -
            AppTheme.spacing_xs -
            AppTheme.spacing_md;
        final needs_scroll =
            calendar_max_height < 100 || text_scaler.scale(16) > 20;
        if (needs_scroll) {
          return SingleChildScrollView(
            key: ValueKey('$key_prefix-scroll'),
            child: Column(
              children: [
                calendar,
                const SizedBox(height: AppTheme.spacing_sm),
                SizedBox(height: text_scaler.scale(280), child: schedule),
                const SizedBox(height: AppTheme.spacing_md),
              ],
            ),
          );
        }
        return Column(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: calendar_max_height),
              child: SingleChildScrollView(
                key: ValueKey('$key_prefix-grid-scroll'),
                child: calendar,
              ),
            ),
            const SizedBox(height: AppTheme.spacing_xs),
            Expanded(child: schedule!),
            const SizedBox(height: AppTheme.spacing_md),
          ],
        );
      },
    );
  }
}

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
    this.onToday,
    this.today_key,
    this.is_month_overview = false,
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
  final VoidCallback? onToday;
  final Key? today_key;
  final bool is_month_overview;

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
            onToday: onToday,
            today_key: today_key,
          ),
        ),
        if (is_month_overview)
          Expanded(child: calendar_grid)
        else
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
