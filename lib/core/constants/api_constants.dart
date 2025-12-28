/// API 관련 상수
class ApiConstants {
  ApiConstants._();

  /// 기본 API URL (개발 환경)
  static const String base_url_dev = 'http://localhost:3000/api';

  /// 기본 API URL (운영 환경)
  static const String base_url_prod = 'https://api.shiftcalendar.com/api';

  /// 현재 사용 중인 base URL
  static const String base_url = base_url_dev;

  /// API 타임아웃 (초)
  static const int connection_timeout = 30;
  static const int receive_timeout = 30;

  /// API 엔드포인트
  static const String auth_login = '/auth/login';
  static const String auth_register = '/auth/register';
  static const String auth_refresh = '/auth/refresh';

  static const String schedules = '/schedules';
  static const String schedules_shared = '/schedules/shared';

  static const String users = '/users';
  static const String users_profile = '/users/profile';
}

