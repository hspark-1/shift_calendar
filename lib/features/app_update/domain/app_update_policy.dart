// ignore_for_file: non_constant_identifier_names

/// 스토어 버전과 독립적인 API 호환 정책. 최소값과 같은 앱은 허용한다.
class AppUpdatePolicy {
  final String platform;
  final int minimum_compatibility_version;
  final Uri? update_url;
  final String message;

  const AppUpdatePolicy({
    required this.platform,
    required this.minimum_compatibility_version,
    required this.update_url,
    required this.message,
  });

  factory AppUpdatePolicy.fromJson(
    Map<String, dynamic> json, {
    required String expected_platform,
  }) {
    final minimum = json['minimum_compatibility_version'];
    final raw_url = json['update_url'];
    final raw_message = json['message'];
    if (json['schema_version'] != 1 ||
        json['platform'] != expected_platform ||
        !const ['IOS', 'ANDROID'].contains(expected_platform) ||
        minimum is! int ||
        minimum < 0 ||
        minimum > 2147483647 ||
        (raw_message != null &&
            (raw_message is! String || raw_message.length > 300)) ||
        (raw_url != null && raw_url is! String)) {
      throw const FormatException('유효하지 않은 앱 호환 정책입니다.');
    }
    final url = raw_url is String ? Uri.tryParse(raw_url) : null;
    if ((raw_url != null && !isValidStoreUrl(url, expected_platform)) ||
        (minimum > 0 && url == null)) {
      throw const FormatException('유효하지 않은 업데이트 주소입니다.');
    }
    return AppUpdatePolicy(
      platform: expected_platform,
      minimum_compatibility_version: minimum,
      update_url: url,
      message: raw_message is String && raw_message.trim().isNotEmpty
          ? raw_message.trim()
          : '안정적인 서비스 이용을 위해 최신 앱으로 업데이트해 주세요.',
    );
  }

  bool requiresUpdate(int compatibility_version) =>
      compatibility_version < minimum_compatibility_version;

  Map<String, dynamic> toJson() => {
    'schema_version': 1,
    'platform': platform,
    'minimum_compatibility_version': minimum_compatibility_version,
    'update_url': update_url?.toString(),
    'message': message,
  };

  static bool isValidStoreUrl(Uri? url, String platform) {
    if (url == null ||
        url.scheme != 'https' ||
        url.userInfo.isNotEmpty ||
        (url.hasPort && url.port != 443) ||
        url.hasFragment) {
      return false;
    }
    if (platform == 'IOS') {
      return url.host == 'apps.apple.com' &&
          !url.hasQuery &&
          RegExp(
            r'^/(?:[a-z]{2}/)?app/(?:[^/]+/)?id6831957246/?$',
          ).hasMatch(url.path);
    }
    return platform == 'ANDROID' &&
        url.host == 'play.google.com' &&
        url.path == '/store/apps/details' &&
        url.queryParameters['id'] == 'com.hspark.shiftmate';
  }
}
