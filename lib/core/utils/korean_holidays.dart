import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 한국 법정 공휴일 판단 유틸리티
class KoreanHolidays {
  KoreanHolidays._();

  /// 공휴일 캐시 (년도별)
  static final Map<int, Set<DateTime>> _holiday_cache = {};

  /// 공휴일 이름 캐시 (날짜 -> 공휴일 이름)
  static final Map<DateTime, String> _holiday_name_cache = {};

  /// 로드된 월 범위 추적 (연도별로 로드된 월 목록)
  /// 예: {2026: {1, 2, 3}} - 2026년의 1월, 2월, 3월 범위가 로드됨
  static final Map<int, Set<int>> _loaded_month_ranges = {};

  /// 현재 로딩 중인 요청 추적 (중복 호출 방지)
  static final Set<String> _loading_requests = {};

  /// 날짜 정규화 (시간 제거)
  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// 두 날짜가 같은 날인지 확인
  static bool isSameDay(DateTime date1, DateTime date2) {
    final normalized1 = _normalizeDate(date1);
    final normalized2 = _normalizeDate(date2);
    return normalized1.year == normalized2.year &&
        normalized1.month == normalized2.month &&
        normalized1.day == normalized2.day;
  }

  /// 공공데이터포털 API에서 공휴일 데이터 가져오기
  /// API 키가 없으면 null 반환
  /// 한국천문연구원 특일 정보 API 사용 (현재 월 기준 앞뒤 한 달씩 총 3개월만 조회)
  static Future<Set<DateTime>?> _fetchHolidaysForMonthRange(
    int year,
    int month,
  ) async {
    // .env 파일에서 API 키 가져오기
    final apiKey = dotenv.env['DATA_GO_KR_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      return null; // API 키가 없으면 null 반환
    }

    try {
      final dio = Dio();

      // 한국천문연구원 특일 정보 API
      // 요청주소: http://apis.data.go.kr/B090041/openapi/service/SpcdeInfoService/getRestDeInfo
      final url =
          'http://apis.data.go.kr/B090041/openapi/service/SpcdeInfoService/getRestDeInfo';

      final Set<DateTime> allHolidays = {};

      // 현재 월 기준으로 앞뒤 한 달씩 총 3개월만 조회
      final monthsToLoad = <Map<String, int>>[];
      print("$year $month");

      // 이전 달
      if (month == 1) {
        monthsToLoad.add({'year': year - 1, 'month': 12});
      } else {
        monthsToLoad.add({'year': year, 'month': month - 1});
      }

      // 현재 달
      monthsToLoad.add({'year': year, 'month': month});

      // 다음 달
      if (month == 12) {
        monthsToLoad.add({'year': year + 1, 'month': 1});
      } else {
        monthsToLoad.add({'year': year, 'month': month + 1});
      }

      for (final monthData in monthsToLoad) {
        final targetYear = monthData['year']!;
        final targetMonth = monthData['month']!;

        final response = await dio.get(
          url,
          queryParameters: {
            'serviceKey': apiKey,
            'solYear': targetYear.toString(),
            'solMonth': targetMonth.toString().padLeft(2, '0'),
            'numOfRows': '100',
            'pageNo': '1',
            '_type': 'json',
          },
          options: Options(
            // 모든 상태 코드를 받아서 처리
            validateStatus: (status) => true,
          ),
        );

        final data = response.data;

        // 응답이 문자열인 경우 먼저 체크 (에러 메시지일 수 있음)
        if (data is String) {
          // "Unauthorized" 같은 문자열 응답 처리
          if (data.contains('Unauthorized') ||
              data.contains('인증') ||
              data.contains('401') ||
              data.contains('403') ||
              data.trim().toLowerCase() == 'unauthorized') {
            // 인증 오류 - API 키 문제, 다음 월 시도
            continue;
          }
          // XML 응답인 경우 파싱 필요 (현재는 JSON만 처리)
          continue;
        }

        // 응답 상태 코드 확인
        if (response.statusCode == 200) {
          // 응답 구조 확인
          final responseData = data['response'];
          if (responseData == null) {
            // response가 없으면 에러 응답일 수 있음
            continue;
          }

          // 에러 체크
          final header = responseData['header'];
          if (header != null) {
            final resultCode = header['resultCode']?.toString();
            if (resultCode != null && resultCode != '00') {
              // resultCode '03', '04', '05'는 인증 오류 (API 키 문제)
              // 기타 에러도 스킵하고 다음 월 시도
              continue;
            }
          }

          final body = responseData['body'];
          if (body == null) {
            continue;
          }

          final itemsData = body['items'];
          // items가 null이거나 빈 문자열이면 스킵
          if (itemsData == null || itemsData == '' || itemsData is! Map) {
            continue;
          }

          final items = itemsData['item'];
          if (items == null) {
            continue;
          }

          // items가 Map인 경우 (단일 항목)와 List인 경우 (여러 항목) 처리
          final List<dynamic> itemsList;
          if (items is List) {
            itemsList = items;
          } else if (items is Map) {
            itemsList = [items];
          } else {
            // 예상치 못한 타입이면 스킵
            continue;
          }

          for (final item in itemsList) {
            // isHoliday가 "Y"인 것만 공휴일로 처리
            final isHoliday = item['isHoliday']?.toString();
            if (isHoliday != 'Y') {
              continue; // 공휴일이 아니면 스킵
            }

            // locdate 필드 사용 (YYYYMMDD 형식)
            // locdate는 int 또는 String으로 올 수 있음
            final locdateValue = item['locdate'];
            String? locdateStr;
            if (locdateValue is int) {
              locdateStr = locdateValue.toString();
            } else if (locdateValue is String) {
              locdateStr = locdateValue;
            }

            if (locdateStr != null && locdateStr.length == 8) {
              try {
                // YYYYMMDD 형식을 DateTime으로 변환
                final holidayYear = int.parse(locdateStr.substring(0, 4));
                final holidayMonth = int.parse(locdateStr.substring(4, 6));
                final day = int.parse(locdateStr.substring(6, 8));
                final holidayDate = DateTime(holidayYear, holidayMonth, day);
                allHolidays.add(holidayDate);

                // 공휴일 이름 저장 (dateName 필드)
                final dateName = item['dateName']?.toString();
                if (dateName != null && dateName.isNotEmpty) {
                  final normalizedDate = _normalizeDate(holidayDate);
                  _holiday_name_cache[normalizedDate] = dateName;
                }
              } catch (e) {
                print('날짜 파싱 에러: $locdateStr, $e');
              }
            }
          }
        }
        // 디버그 로그 제거 (성능 최적화)
      }

      if (allHolidays.isEmpty) {
        return null;
      }
      // 정규화된 날짜로 변환하여 반환 (시간 제거)
      final normalizedHolidays = allHolidays
          .map((date) => _normalizeDate(date))
          .toSet();
      return normalizedHolidays;
    } catch (e, stackTrace) {
      // API 호출 실패 시 null 반환
      print('공휴일 API 호출 에러: $e');
      print('스택 트레이스: $stackTrace');
    }

    return null;
  }

  /// 해당 연도의 공휴일 목록 가져오기 (캐시 사용)
  /// Public 메서드로 외부에서 호출 가능
  /// 현재는 월별 lazy loading을 위해 월 정보도 필요
  static Future<Set<DateTime>> getHolidaysForYear(
    int year, {
    int? month,
  }) async {
    // 캐시 키를 연도+월로 변경하거나, 연도별로 유지하되 필요한 월만 조회
    // 간단하게 연도별 캐시는 유지하되, 월 정보가 있으면 해당 월 범위만 조회
    if (month != null) {
      // 요청 키 생성 (중복 호출 방지)
      final requestKey = '$year-$month';

      // 이미 로딩 중인 요청이면 기다림
      if (_loading_requests.contains(requestKey)) {
        // 로딩이 완료될 때까지 대기 (최대 5초)
        int waitCount = 0;
        while (_loading_requests.contains(requestKey) && waitCount < 50) {
          await Future.delayed(const Duration(milliseconds: 100));
          waitCount++;
        }
        // 대기 후에도 캐시에 있으면 반환
        if (_holiday_cache.containsKey(year)) {
          return _holiday_cache[year]!;
        }
      }

      // 해당 월 범위가 이미 로드되었는지 확인
      final loadedMonths = _loaded_month_ranges[year];
      if (loadedMonths != null && loadedMonths.contains(month)) {
        // 이미 로드된 월 범위면 캐시에서 반환
        if (_holiday_cache.containsKey(year)) {
          return _holiday_cache[year]!;
        }
      }

      // 로딩 시작 표시
      _loading_requests.add(requestKey);

      try {
        // 월 정보가 있으면 해당 월 범위만 조회
        final apiHolidays = await _fetchHolidaysForMonthRange(year, month);
        final Set<DateTime> holidays = apiHolidays ?? {};

        // 기존 캐시에 병합
        if (_holiday_cache.containsKey(year)) {
          _holiday_cache[year]!.addAll(holidays);
        } else {
          _holiday_cache[year] = holidays;
        }

        // 로드된 월 범위 기록
        _loaded_month_ranges.putIfAbsent(year, () => <int>{}).add(month);
        // 이전/다음 달도 로드된 것으로 표시 (3개월 범위이므로)
        if (month > 1) {
          _loaded_month_ranges.putIfAbsent(year, () => <int>{}).add(month - 1);
        }
        if (month < 12) {
          _loaded_month_ranges.putIfAbsent(year, () => <int>{}).add(month + 1);
        }
        // 경계 월 처리
        if (month == 1) {
          _loaded_month_ranges.putIfAbsent(year - 1, () => <int>{}).add(12);
        }
        if (month == 12) {
          _loaded_month_ranges.putIfAbsent(year + 1, () => <int>{}).add(1);
        }

        return _holiday_cache[year]!;
      } finally {
        // 로딩 완료 표시
        _loading_requests.remove(requestKey);
      }
    }

    // 월 정보가 없으면 기존 로직 (하위 호환성)
    if (_holiday_cache.containsKey(year)) {
      return _holiday_cache[year]!;
    }

    // 월 정보가 없으면 빈 Set 반환 (lazy loading을 위해)
    _holiday_cache[year] = <DateTime>{};
    return _holiday_cache[year]!;
  }

  /// 해당 날짜가 한국 법정 공휴일인지 확인
  /// 비동기 메서드이므로 Future를 반환합니다
  static Future<bool> isHoliday(DateTime date) async {
    final normalized = _normalizeDate(date);
    final year = normalized.year;

    // 해당 연도의 공휴일 목록 가져오기 (캐시 사용)
    final holidays = await getHolidaysForYear(year);
    return holidays.any((holiday) => isSameDay(normalized, holiday));
  }

  /// 동기 버전 (캐시된 공휴일만 확인)
  /// 빠른 체크가 필요한 경우 사용 (캐시가 이미 로드된 경우에만 정확함)
  static bool isFixedHoliday(DateTime date) {
    final normalized = _normalizeDate(date);
    final year = normalized.year;

    // 캐시에 있는 경우만 확인
    if (_holiday_cache.containsKey(year)) {
      return _holiday_cache[year]!.any(
        (holiday) => isSameDay(normalized, holiday),
      );
    }

    return false;
  }

  /// 해당 날짜의 공휴일 이름 가져오기
  /// 공휴일이 아니면 null 반환
  static String? getHolidayName(DateTime date) {
    final normalized = _normalizeDate(date);
    return _holiday_name_cache[normalized];
  }

  /// 캐시 초기화
  static void clearCache() {
    _holiday_cache.clear();
    _holiday_name_cache.clear();
  }
}
