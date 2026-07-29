// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';

/// 날짜 셀의 배치 규칙.
///
/// 캘린더 종류가 아니라 셀에 표시할 정보량을 기준으로 선택한다.
enum CalendarCellLayout { compact, badge, dots }

sealed class CalendarDayIndicator {
  const CalendarDayIndicator();
}

class CalendarBadgeIndicator extends CalendarDayIndicator {
  const CalendarBadgeIndicator({required this.text, required this.color});

  final String text;
  final Color color;
}

class CalendarDotsIndicator extends CalendarDayIndicator {
  const CalendarDotsIndicator({
    required this.colors,
    this.dot_size = 5,
    this.spacing = 3,
    this.key_prefix,
  });

  final List<Color> colors;
  final double dot_size;
  final double spacing;
  final String? key_prefix;
}

/// 도메인 데이터를 공용 날짜 셀이 이해할 수 있는 표시 정보로 변환한 값.
class CalendarDayPresentation {
  const CalendarDayPresentation({
    required this.date_color,
    this.indicator,
    this.semantic_label,
  });

  final Color date_color;
  final CalendarDayIndicator? indicator;
  final String? semantic_label;
}

typedef CalendarDayPresentationBuilder =
    CalendarDayPresentation Function(DateTime date);
