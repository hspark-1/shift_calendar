import 'package:flutter/foundation.dart';

/// API 관련 상수
class ApiConstants {
  ApiConstants._();

  /// 기본 API URL (개발 환경)
  // static const String base_url_dev = 'http://localhost:3000/api';
  static const String base_url_dev = 'http://172.30.1.49:3000/api/v1';

  /// 기본 API URL (운영 환경)
  static const String base_url_prod = 'https://shiftmate.co.kr/api/v1';

  /// 현재 사용 중인 base URL
  /// Debug 모드에서는 개발 환경, Release 모드에서는 운영 환경 사용
  static String get base_url => kDebugMode ? base_url_dev : base_url_prod;

  /// API 타임아웃 (초)
  static const int connection_timeout = 30;
  static const int receive_timeout = 30;

  /// API 엔드포인트
  static const String auth_login = '/auth/login';
  static const String auth_register = '/auth/register';
  static const String auth_refresh = '/auth/refresh';
  static const String auth_kakao_token = '/auth/kakao/token';
  static const String auth_naver_token = '/auth/naver/token';
  static const String auth_profile = '/auth/profile';
  static const String auth_logout = '/auth/logout';
  static const String auth_logout_all = '/auth/logout-all';

  static const String schedules = '/schedules';
  static const String schedules_shared = '/schedules/shared';

  static const String users = '/users';
  static const String users_profile = '/users/profile';

  // 근무표 관련 엔드포인트
  static const String shift_templates_current = '/shift-templates/current';
  static const String shift_types = '/shift-types';
  static const String work_shifts = '/work-shifts';
  static const String calendar_day = '/calendar/day';
  static const String calendar_range = '/calendar/range';

  // 일정 관련 엔드포인트
  static const String events = '/events';

  // 친구 관련 엔드포인트
  static const String friends = '/friends';
  static const String users_search = '/users/search';

  // 친구 요청 관련 엔드포인트
  static const String friend_requests = '/friend-requests';
  static const String friend_requests_received = '/friend-requests/received';
  static const String friend_requests_sent = '/friend-requests/sent';

  // 알림 관련 엔드포인트
  static const String notifications = '/notifications';
  static const String notifications_unread_count =
      '/notifications/unread-count';
}
