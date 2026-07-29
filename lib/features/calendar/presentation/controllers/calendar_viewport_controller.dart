// ignore_for_file: non_constant_identifier_names

/// 페이지가 소유한 focused/selected 상태를 일관된 월 경계로 이동시키는 컨트롤러.
///
/// 상태 변경 시점과 데이터 조회 여부는 각 페이지가 결정한다.
class CalendarViewportController {
  const CalendarViewportController({
    this.first_year = 2000,
    this.first_month = 1,
    this.last_year = 2050,
    this.last_month = 12,
  });

  final int first_year;
  final int first_month;
  final int last_year;
  final int last_month;

  DateTime normalizeDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool canMoveMonth(DateTime focused_day, int month_delta) {
    return monthAt(focused_day, month_delta) != null;
  }

  DateTime? monthAt(DateTime focused_day, int month_delta) {
    final candidate = DateTime(
      focused_day.year,
      focused_day.month + month_delta,
      1,
    );
    final is_before_first =
        candidate.year < first_year ||
        (candidate.year == first_year && candidate.month < first_month);
    final is_after_last =
        candidate.year > last_year ||
        (candidate.year == last_year && candidate.month > last_month);
    return is_before_first || is_after_last ? null : candidate;
  }
}
