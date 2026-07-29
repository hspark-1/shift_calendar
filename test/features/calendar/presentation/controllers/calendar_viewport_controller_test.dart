// ignore_for_file: non_constant_identifier_names

import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/features/calendar/presentation/controllers/calendar_viewport_controller.dart';

void main() {
  const controller = CalendarViewportController();

  test('월 이동은 월의 첫날로 정규화하고 연도 경계를 넘는다', () {
    expect(
      controller.monthAt(DateTime(2026, 1, 20), -1),
      DateTime(2025, 12, 1),
    );
    expect(controller.monthAt(DateTime(2026, 12, 20), 1), DateTime(2027, 1, 1));
  });

  test('2000년 1월부터 2050년 12월까지만 이동을 허용한다', () {
    expect(controller.canMoveMonth(DateTime(2000, 1), -1), isFalse);
    expect(controller.monthAt(DateTime(2000, 1), -1), isNull);
    expect(controller.canMoveMonth(DateTime(2050, 12), 1), isFalse);
    expect(controller.monthAt(DateTime(2050, 12), 1), isNull);
  });

  test('날짜 정규화는 로컬 연월일만 유지한다', () {
    expect(
      controller.normalizeDay(DateTime(2026, 7, 29, 17, 30)),
      DateTime(2026, 7, 29),
    );
  });
}
