/// 앱 전역 상수
class AppConstants {
  AppConstants._();

  /// 앱 이름
  static const String app_name = 'Shift Calendar';

  /// 앱 버전
  static const String app_version = '1.0.0';

  /// 카카오 Native App Key (--dart-define으로 전달)
  /// 실행: flutter run --dart-define=KAKAO_NATIVE_APP_KEY=실제키값
  static const String kakao_native_app_key = String.fromEnvironment(
    'KAKAO_NATIVE_APP_KEY',
    defaultValue: '',
  );

  /// 네이버 Client ID (--dart-define으로 전달)
  /// 실행: flutter run --dart-define=NAVER_CLIENT_ID=실제키값
  static const String naver_client_id = String.fromEnvironment(
    'NAVER_CLIENT_ID',
    defaultValue: '',
  );

  /// 네이버 Redirect URI
  /// 네이버 개발자 센터에 등록된 URL Scheme 사용
  static const String naver_redirect_uri =
      'com.hspark.shiftCalendar://naver/callback';

  /// 기본 타임존
  static const String default_timezone = 'Asia/Seoul';

  /// 로컬 저장소 키
  static const String storage_key_token = 'access_token';
  static const String storage_key_refresh_token = 'refresh_token';
  static const String storage_key_user = 'user_data';
  static const String storage_key_shift_pattern = 'shift_pattern';
}
