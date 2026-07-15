// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 한국 법정 공휴일 조회와 앱 공용 캐시를 관리한다.
class KoreanHolidays {
  KoreanHolidays._();

  static const _cache_storage_key = 'korean_holidays_cache_v1';
  static const _cache_version = 1;

  /// 공휴일 캐시 (연도 -> 날짜 집합)
  static final Map<int, Set<DateTime>> _holiday_cache = {};

  /// 공휴일 이름 캐시 (날짜 -> 공휴일 이름)
  static final Map<DateTime, String> _holiday_name_cache = {};

  /// API 조회를 완료한 월 (연도 -> 월 집합)
  static final Map<int, Set<int>> _loaded_month_ranges = {};

  /// 같은 월의 중복 API 요청을 하나의 Future로 합친다.
  static final Map<String, Future<void>> _loading_requests = {};

  static SharedPreferences? _preferences;
  static Future<void>? _initialization;

  static Future<Map<DateTime, String>> Function(int year, int month)?
  _holiday_fetcher_override;

  /// 앱 시작 시 로컬에 저장된 공휴일 캐시를 메모리로 복원한다.
  static Future<void> initialize() {
    return _initialization ??= _restoreCache();
  }

  static Future<void> _restoreCache() async {
    final preferences = await SharedPreferences.getInstance();
    _preferences = preferences;

    final raw_cache = preferences.getString(_cache_storage_key);
    if (raw_cache == null || raw_cache.isEmpty) return;

    try {
      final decoded_cache = jsonDecode(raw_cache);
      if (decoded_cache is! Map<String, dynamic> ||
          decoded_cache['version'] != _cache_version) {
        return;
      }

      final holidays = decoded_cache['holidays'];
      if (holidays is List) {
        for (final holiday in holidays) {
          if (holiday is! Map) continue;

          final date_value = holiday['date'];
          if (date_value is! String) continue;

          final parsed_date = DateTime.tryParse(date_value);
          if (parsed_date == null) continue;

          final normalized_date = _normalizeDate(parsed_date);
          _holiday_cache
              .putIfAbsent(normalized_date.year, () => <DateTime>{})
              .add(normalized_date);

          final name_value = holiday['name'];
          if (name_value is String && name_value.isNotEmpty) {
            _holiday_name_cache[normalized_date] = name_value;
          }
        }
      }

      final loaded_months = decoded_cache['loaded_months'];
      if (loaded_months is Map) {
        for (final entry in loaded_months.entries) {
          final year = int.tryParse(entry.key.toString());
          final months = entry.value;
          if (year == null || months is! List) continue;

          _loaded_month_ranges[year] = months
              .whereType<num>()
              .map((month) => month.toInt())
              .where((month) => month >= 1 && month <= 12)
              .toSet();
        }
      }
    } on FormatException catch (error) {
      debugPrint('저장된 공휴일 캐시 형식 오류: $error');
    } catch (error) {
      debugPrint('저장된 공휴일 캐시 복원 실패: $error');
    }
  }

  static Future<void> _persistCache() async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    _preferences = preferences;

    final holidays = <Map<String, String?>>[];
    final years = _holiday_cache.keys.toList()..sort();
    for (final year in years) {
      final dates = _holiday_cache[year]!.toList()..sort();
      for (final date in dates) {
        holidays.add({
          'date': _dateStorageKey(date),
          'name': _holiday_name_cache[date],
        });
      }
    }

    final loaded_months = <String, List<int>>{};
    final loaded_years = _loaded_month_ranges.keys.toList()..sort();
    for (final year in loaded_years) {
      loaded_months['$year'] = _loaded_month_ranges[year]!.toList()..sort();
    }

    await preferences.setString(
      _cache_storage_key,
      jsonEncode({
        'version': _cache_version,
        'holidays': holidays,
        'loaded_months': loaded_months,
      }),
    );
  }

  static String _dateStorageKey(DateTime date) {
    final normalized_date = _normalizeDate(date);
    final month = normalized_date.month.toString().padLeft(2, '0');
    final day = normalized_date.day.toString().padLeft(2, '0');
    return '${normalized_date.year}-$month-$day';
  }

  /// 날짜 정규화 (시간 제거)
  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// 두 날짜가 같은 날인지 확인한다.
  static bool isSameDay(DateTime date1, DateTime date2) {
    return _normalizeDate(date1) == _normalizeDate(date2);
  }

  /// 한국천문연구원 특일 정보 API에서 요청 월 앞뒤 1개월을 조회한다.
  static Future<Map<DateTime, String>> _fetchHolidaysForMonthRange(
    int year,
    int month,
  ) async {
    final override = _holiday_fetcher_override;
    if (override != null) {
      return override(year, month);
    }

    if (!dotenv.isInitialized) return {};

    final api_key = dotenv.env['DATA_GO_KR_API_KEY'];
    if (api_key == null || api_key.isEmpty) return {};

    final holidays = <DateTime, String>{};
    final months_to_load = [
      DateTime(year, month - 1),
      DateTime(year, month),
      DateTime(year, month + 1),
    ];

    try {
      final dio = Dio();
      const url =
          'http://apis.data.go.kr/B090041/openapi/service/SpcdeInfoService/getRestDeInfo';

      for (final target_month in months_to_load) {
        final response = await dio.get(
          url,
          queryParameters: {
            'serviceKey': api_key,
            'solYear': target_month.year.toString(),
            'solMonth': target_month.month.toString().padLeft(2, '0'),
            'numOfRows': '100',
            'pageNo': '1',
            '_type': 'json',
          },
          options: Options(validateStatus: (status) => true),
        );

        final data = response.data;
        if (response.statusCode != 200 || data is! Map) continue;

        final response_data = data['response'];
        if (response_data is! Map) continue;

        final header = response_data['header'];
        if (header is Map) {
          final result_code = header['resultCode']?.toString();
          if (result_code != null && result_code != '00') continue;
        }

        final body = response_data['body'];
        if (body is! Map) continue;

        final items_data = body['items'];
        if (items_data is! Map) continue;

        final items = items_data['item'];
        final List<dynamic> item_list;
        if (items is List) {
          item_list = items;
        } else if (items is Map) {
          item_list = [items];
        } else {
          continue;
        }

        for (final item in item_list) {
          if (item is! Map || item['isHoliday']?.toString() != 'Y') continue;

          final locdate = item['locdate']?.toString();
          if (locdate == null || locdate.length != 8) continue;

          try {
            final holiday_date = DateTime(
              int.parse(locdate.substring(0, 4)),
              int.parse(locdate.substring(4, 6)),
              int.parse(locdate.substring(6, 8)),
            );
            holidays[_normalizeDate(holiday_date)] =
                item['dateName']?.toString() ?? '';
          } on FormatException catch (error) {
            debugPrint('공휴일 날짜 파싱 실패 ($locdate): $error');
          }
        }
      }
    } catch (error, stack_trace) {
      debugPrint('공휴일 API 호출 실패: $error');
      debugPrintStack(stackTrace: stack_trace);
    }

    return holidays;
  }

  /// 해당 연도의 공휴일을 반환하고, 월이 있으면 앞뒤 1개월까지 조회한다.
  static Future<Set<DateTime>> getHolidaysForYear(
    int year, {
    int? month,
  }) async {
    await initialize();

    if (month == null) {
      return _holiday_cache.putIfAbsent(year, () => <DateTime>{});
    }

    if (_loaded_month_ranges[year]?.contains(month) ?? false) {
      return _holiday_cache.putIfAbsent(year, () => <DateTime>{});
    }

    final request_key = '$year-$month';
    final active_request = _loading_requests[request_key];
    if (active_request != null) {
      await active_request;
      return _holiday_cache.putIfAbsent(year, () => <DateTime>{});
    }

    final request = _loadAndPersistMonthRange(year, month);
    _loading_requests[request_key] = request;
    try {
      await request;
    } finally {
      _loading_requests.remove(request_key);
    }

    return _holiday_cache.putIfAbsent(year, () => <DateTime>{});
  }

  static Future<void> _loadAndPersistMonthRange(int year, int month) async {
    final holidays = await _fetchHolidaysForMonthRange(year, month);
    for (final entry in holidays.entries) {
      final normalized_date = _normalizeDate(entry.key);
      _holiday_cache
          .putIfAbsent(normalized_date.year, () => <DateTime>{})
          .add(normalized_date);
      if (entry.value.isNotEmpty) {
        _holiday_name_cache[normalized_date] = entry.value;
      }
    }

    for (final loaded_month in [
      DateTime(year, month - 1),
      DateTime(year, month),
      DateTime(year, month + 1),
    ]) {
      _loaded_month_ranges
          .putIfAbsent(loaded_month.year, () => <int>{})
          .add(loaded_month.month);
    }

    await _persistCache();
  }

  /// 해당 날짜가 한국 법정 공휴일인지 비동기로 확인한다.
  static Future<bool> isHoliday(DateTime date) async {
    final normalized_date = _normalizeDate(date);
    final holidays = await getHolidaysForYear(normalized_date.year);
    return holidays.contains(normalized_date);
  }

  /// 메모리에 복원되거나 조회된 공휴일인지 동기 방식으로 확인한다.
  static bool isFixedHoliday(DateTime date) {
    final normalized_date = _normalizeDate(date);
    return _holiday_cache[normalized_date.year]?.contains(normalized_date) ??
        false;
  }

  /// 해당 날짜의 공휴일 이름을 반환한다.
  static String? getHolidayName(DateTime date) {
    return _holiday_name_cache[_normalizeDate(date)];
  }

  /// 메모리와 로컬에 저장된 공휴일 캐시를 모두 삭제한다.
  static Future<void> clearCache() async {
    await initialize();
    _holiday_cache.clear();
    _holiday_name_cache.clear();
    _loaded_month_ranges.clear();
    _loading_requests.clear();
    await _preferences?.remove(_cache_storage_key);
  }

  @visibleForTesting
  static void setHolidayFetcherForTesting(
    Future<Map<DateTime, String>> Function(int year, int month)? fetcher,
  ) {
    _holiday_fetcher_override = fetcher;
  }

  @visibleForTesting
  static void resetForTesting() {
    _holiday_cache.clear();
    _holiday_name_cache.clear();
    _loaded_month_ranges.clear();
    _loading_requests.clear();
    _preferences = null;
    _initialization = null;
    _holiday_fetcher_override = null;
  }
}
