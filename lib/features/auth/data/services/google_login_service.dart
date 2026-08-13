// ignore_for_file: non_constant_identifier_names

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/constants/app_constants.dart';

/// Google SDK 호출을 테스트 가능한 경계로 분리한다.
abstract interface class GoogleSignInSdk {
  Future<void> initialize({String? clientId, String? serverClientId});

  bool supportsAuthenticate();

  Future<String?> authenticateAndGetIdToken();

  Future<void> signOut();

  Future<void> disconnect();
}

/// google_sign_in의 앱 전역 singleton을 사용하는 실제 구현.
class NativeGoogleSignInSdk implements GoogleSignInSdk {
  NativeGoogleSignInSdk._() : _google_sign_in = GoogleSignIn.instance;

  static final NativeGoogleSignInSdk _instance = NativeGoogleSignInSdk._();

  factory NativeGoogleSignInSdk() => _instance;

  final GoogleSignIn _google_sign_in;
  Future<void>? _initialization_future;

  @override
  Future<void> initialize({String? clientId, String? serverClientId}) {
    return _initialization_future ??= _google_sign_in.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
    );
  }

  @override
  bool supportsAuthenticate() => _google_sign_in.supportsAuthenticate();

  @override
  Future<String?> authenticateAndGetIdToken() async {
    final account = await _google_sign_in.authenticate();
    return account.authentication.idToken;
  }

  @override
  Future<void> signOut() => _google_sign_in.signOut();

  @override
  Future<void> disconnect() => _google_sign_in.disconnect();
}

/// 사용자 액션으로 Google 인증을 시작해 서버 검증용 ID Token만 반환한다.
class GoogleLoginService {
  final GoogleSignInSdk _google_sign_in_sdk;
  final TargetPlatform _target_platform;
  final String _ios_client_id;
  final String _server_client_id;
  Future<void>? _initialization_future;

  GoogleLoginService({
    GoogleSignInSdk? google_sign_in_sdk,
    TargetPlatform? target_platform,
    String ios_client_id = AppConstants.google_ios_client_id,
    String server_client_id = AppConstants.google_server_client_id,
  }) : _google_sign_in_sdk = google_sign_in_sdk ?? NativeGoogleSignInSdk(),
       _target_platform = target_platform ?? defaultTargetPlatform,
       _ios_client_id = ios_client_id.trim(),
       _server_client_id = server_client_id.trim();

  Future<String> loginWithGoogle() async {
    _validateConfiguration();

    try {
      await _ensureInitialized();
      if (!_google_sign_in_sdk.supportsAuthenticate()) {
        throw const GoogleLoginUnavailableException(
          '이 기기에서는 Google 로그인을 사용할 수 없습니다.',
        );
      }

      final id_token = (await _google_sign_in_sdk.authenticateAndGetIdToken())
          ?.trim();
      if (id_token == null || id_token.isEmpty) {
        throw const GoogleLoginUnavailableException(
          'Google ID Token을 받지 못했습니다. 다시 시도해주세요.',
        );
      }
      return id_token;
    } on GoogleLoginCanceledException {
      rethrow;
    } on GoogleLoginUnavailableException {
      rethrow;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const GoogleLoginCanceledException();
      }
      if (error.code == GoogleSignInExceptionCode.clientConfigurationError ||
          error.code == GoogleSignInExceptionCode.providerConfigurationError) {
        throw const GoogleLoginUnavailableException(
          'Google 로그인 설정이 올바르지 않습니다. 앱 관리자에게 문의해주세요.',
        );
      }
      if (error.code == GoogleSignInExceptionCode.uiUnavailable) {
        throw const GoogleLoginUnavailableException(
          '현재 Google 로그인 화면을 열 수 없습니다. 잠시 후 다시 시도해주세요.',
        );
      }
      throw const GoogleLoginUnavailableException(
        'Google 로그인에 실패했습니다. 다시 시도해주세요.',
      );
    } on UnsupportedError {
      throw const GoogleLoginUnavailableException(
        '이 기기에서는 Google 로그인을 사용할 수 없습니다.',
      );
    }
  }

  /// 앱 로그아웃 또는 서버 토큰 교환 실패 시 Google 로컬 세션을 해제한다.
  Future<void> logout() async {
    _validateConfiguration();
    await _ensureInitialized();
    await _google_sign_in_sdk.signOut();
  }

  /// 회원 탈퇴 전 Google 앱 연결과 로컬 세션을 해제한다.
  Future<void> disconnect() async {
    _validateConfiguration();
    await _ensureInitialized();
    await _google_sign_in_sdk.disconnect();
  }

  void _validateConfiguration() {
    if (_target_platform != TargetPlatform.android &&
        _target_platform != TargetPlatform.iOS) {
      throw const GoogleLoginUnavailableException(
        'Google 로그인은 iOS와 Android에서만 지원합니다.',
      );
    }
    if (_server_client_id.isEmpty ||
        (_target_platform == TargetPlatform.iOS && _ios_client_id.isEmpty)) {
      throw const GoogleLoginUnavailableException(
        'Google 로그인 설정이 누락되었습니다. 앱 관리자에게 문의해주세요.',
      );
    }
  }

  Future<void> _ensureInitialized() {
    return _initialization_future ??= _google_sign_in_sdk.initialize(
      clientId: _target_platform == TargetPlatform.iOS ? _ios_client_id : null,
      serverClientId: _server_client_id,
    );
  }
}

/// 사용자가 Google 계정 선택 화면을 명시적으로 닫은 경우.
class GoogleLoginCanceledException implements Exception {
  const GoogleLoginCanceledException();
}

/// Google SDK를 현재 플랫폼 또는 빌드 설정에서 사용할 수 없는 경우.
class GoogleLoginUnavailableException implements Exception {
  final String message;

  const GoogleLoginUnavailableException(this.message);

  @override
  String toString() => message;
}
