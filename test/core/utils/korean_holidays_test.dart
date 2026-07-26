// ignore_for_file: non_constant_identifier_names

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shift_mate/core/utils/korean_holidays.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    KoreanHolidays.resetForTesting();
  });

  tearDown(KoreanHolidays.resetForTesting);

  test('API 공휴일을 로컬에 저장하고 앱 재시작 상태에서 복원한다', () async {
    final year_end_holiday = DateTime(2026, 12, 31);
    final next_year_holiday = DateTime(2027, 1, 1);
    var fetch_count = 0;

    KoreanHolidays.setHolidayFetcherForTesting((year, month) async {
      fetch_count++;
      return {year_end_holiday: '연말 공휴일', next_year_holiday: '새해 공휴일'};
    });

    final holidays = await KoreanHolidays.getHolidaysForYear(2027, month: 1);

    expect(fetch_count, 1);
    expect(holidays, contains(next_year_holiday));
    expect(KoreanHolidays.isFixedHoliday(year_end_holiday), isTrue);
    expect(KoreanHolidays.getHolidayName(next_year_holiday), '새해 공휴일');

    KoreanHolidays.resetForTesting();
    await KoreanHolidays.initialize();

    expect(KoreanHolidays.isFixedHoliday(year_end_holiday), isTrue);
    expect(KoreanHolidays.isFixedHoliday(next_year_holiday), isTrue);
    expect(KoreanHolidays.getHolidayName(year_end_holiday), '연말 공휴일');

    await KoreanHolidays.getHolidaysForYear(2027, month: 1);
    expect(fetch_count, 1);
  });
}
