// ignore_for_file: constant_identifier_names, non_constant_identifier_names

/// 앱 전역 상수
class AppConstants {
  AppConstants._();

  /// 앱 이름
  static const String app_name = 'ShiftMate';

  /// 앱 버전
  static const String app_version = '1.0.0';

  /// 카카오 Native App Key (--dart-define으로 전달)
  /// 실행: flutter run --dart-define=KAKAO_NATIVE_APP_KEY=실제키값
  static const String kakao_native_app_key = String.fromEnvironment(
    'KAKAO_NATIVE_APP_KEY',
    defaultValue: '',
  );

  /// Google iOS OAuth client ID (--dart-define으로 전달)
  static const String google_ios_client_id = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: '',
  );

  /// Google Web application OAuth client ID (--dart-define으로 전달)
  /// Android와 iOS ID Token의 서버 audience로 사용한다.
  static const String google_server_client_id = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  /// 기본 타임존
  static const String default_timezone = 'Asia/Seoul';

  /// 그룹 API 단계별 활성화 플래그.
  ///
  /// Stage 계약 검증이 끝나기 전에는 빌드 종류와 관계없이 기본 비활성화한다.
  static const bool group_api_enabled = bool.fromEnvironment(
    'GROUP_API_ENABLED',
    defaultValue: false,
  );
  static const bool group_p1_enabled = bool.fromEnvironment(
    'GROUP_P1_ENABLED',
    defaultValue: false,
  );

  /// Apple 로그인 기능 플래그.
  ///
  /// 서버의 challenge/login/callback 계약과 Apple Developer 설정이 모두
  /// 준비된 빌드에서만 true로 주입한다.
  static const bool apple_login_enabled = bool.fromEnvironment(
    'APPLE_LOGIN_ENABLED',
    defaultValue: false,
  );

  /// 로컬 저장소 키
  static const String storage_key_token = 'access_token';
  static const String storage_key_refresh_token = 'refresh_token';
  static const String storage_key_user = 'user_data';
  static const String storage_key_shift_pattern = 'shift_pattern';
}
