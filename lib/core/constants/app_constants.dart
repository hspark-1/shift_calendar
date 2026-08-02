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

  /// 로컬 저장소 키
  static const String storage_key_token = 'access_token';
  static const String storage_key_refresh_token = 'refresh_token';
  static const String storage_key_user = 'user_data';
  static const String storage_key_shift_pattern = 'shift_pattern';
}
