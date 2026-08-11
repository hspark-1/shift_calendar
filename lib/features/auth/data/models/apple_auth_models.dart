// ignore_for_file: non_constant_identifier_names

/// Apple 로그인을 실행하는 모바일 플랫폼.
enum AppleLoginPlatform {
  ios,
  android;

  String get api_value => name;
}

/// 서버가 Apple 인증 시작 전에 발급하는 일회성 challenge.
class AppleAuthChallenge {
  final String nonce;
  final String state;
  final String client_id;
  final Uri? redirect_uri;
  final DateTime? expires_at;

  const AppleAuthChallenge({
    required this.nonce,
    required this.state,
    required this.client_id,
    this.redirect_uri,
    this.expires_at,
  });

  factory AppleAuthChallenge.fromJson(Map<String, dynamic> json) {
    final nonce = (json['nonce'] as String?)?.trim() ?? '';
    final state = (json['state'] as String?)?.trim() ?? '';
    final client_id = (json['client_id'] as String?)?.trim() ?? '';
    final redirect_uri_value = (json['redirect_uri'] as String?)?.trim();
    final expires_at_value = json['expires_at'];

    if (nonce.isEmpty || state.isEmpty || client_id.isEmpty) {
      throw const FormatException('Apple 로그인 challenge 응답이 올바르지 않습니다.');
    }

    return AppleAuthChallenge(
      nonce: nonce,
      state: state,
      client_id: client_id,
      redirect_uri: redirect_uri_value == null || redirect_uri_value.isEmpty
          ? null
          : Uri.tryParse(redirect_uri_value),
      expires_at: expires_at_value == null
          ? null
          : DateTime.tryParse(expires_at_value.toString()),
    );
  }
}

/// Apple SDK 인증 결과를 서버 로그인 계약으로 정규화한 값.
class AppleLoginCredential {
  final AppleLoginPlatform platform;
  final String authorization_code;
  final String? identity_token;
  final String state;
  final String nonce;
  final String? given_name;
  final String? family_name;

  const AppleLoginCredential({
    required this.platform,
    required this.authorization_code,
    required this.state,
    required this.nonce,
    this.identity_token,
    this.given_name,
    this.family_name,
  });

  Map<String, dynamic> toJson() {
    return {
      'platform': platform.api_value,
      'authorization_code': authorization_code,
      if (identity_token != null) 'identity_token': identity_token,
      'state': state,
      'nonce': nonce,
      if (given_name != null) 'given_name': given_name,
      if (family_name != null) 'family_name': family_name,
    };
  }
}

/// 사용자가 Apple 인증 화면을 명시적으로 닫은 경우.
class AppleLoginCanceledException implements Exception {
  const AppleLoginCanceledException();
}

/// Apple 로그인을 현재 플랫폼 또는 설정에서 사용할 수 없는 경우.
class AppleLoginUnavailableException implements Exception {
  final String message;

  const AppleLoginUnavailableException(this.message);

  @override
  String toString() => message;
}

/// Apple 인증 결과가 요청한 challenge와 일치하지 않는 경우.
class AppleLoginSecurityException implements Exception {
  final String message;

  const AppleLoginSecurityException(this.message);

  @override
  String toString() => message;
}
