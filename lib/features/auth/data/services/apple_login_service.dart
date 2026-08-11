// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../models/apple_auth_models.dart';

/// Apple SDK 호출 경계.
abstract interface class AppleSignInSdk {
  Future<bool> isAvailable();

  Future<AuthorizationCredentialAppleID> getAppleIDCredential({
    required List<AppleIDAuthorizationScopes> scopes,
    WebAuthenticationOptions? webAuthenticationOptions,
    String? nonce,
    String? state,
  });
}

/// 실제 sign_in_with_apple 플러그인 구현.
class NativeAppleSignInSdk implements AppleSignInSdk {
  @override
  Future<bool> isAvailable() => SignInWithApple.isAvailable();

  @override
  Future<AuthorizationCredentialAppleID> getAppleIDCredential({
    required List<AppleIDAuthorizationScopes> scopes,
    WebAuthenticationOptions? webAuthenticationOptions,
    String? nonce,
    String? state,
  }) {
    return SignInWithApple.getAppleIDCredential(
      scopes: scopes,
      webAuthenticationOptions: webAuthenticationOptions,
      nonce: nonce,
      state: state,
    );
  }
}

/// Apple 네이티브/Android 웹 인증을 하나의 서버 요청 값으로 변환한다.
class AppleLoginService {
  final AppleSignInSdk _apple_sign_in_sdk;
  final TargetPlatform _target_platform;
  final Duration _android_login_timeout;

  AppleLoginService({
    AppleSignInSdk? apple_sign_in_sdk,
    TargetPlatform? target_platform,
    Duration android_login_timeout = const Duration(minutes: 2),
  }) : _apple_sign_in_sdk = apple_sign_in_sdk ?? NativeAppleSignInSdk(),
       _target_platform = target_platform ?? defaultTargetPlatform,
       _android_login_timeout = android_login_timeout;

  AppleLoginPlatform get platform {
    return switch (_target_platform) {
      TargetPlatform.iOS => AppleLoginPlatform.ios,
      TargetPlatform.android => AppleLoginPlatform.android,
      _ => throw const AppleLoginUnavailableException(
        'Apple 로그인은 iOS와 Android에서만 지원합니다.',
      ),
    };
  }

  Future<AppleLoginCredential> loginWithApple(
    AppleAuthChallenge challenge,
  ) async {
    final bool is_available;
    try {
      is_available = await _apple_sign_in_sdk.isAvailable();
    } on SignInWithAppleException {
      throw const AppleLoginUnavailableException(
        '이 기기에서는 Apple 로그인을 사용할 수 없습니다.',
      );
    }
    if (!is_available) {
      throw const AppleLoginUnavailableException(
        '이 기기에서는 Apple 로그인을 사용할 수 없습니다.',
      );
    }

    final current_platform = platform;
    WebAuthenticationOptions? web_authentication_options;
    if (current_platform == AppleLoginPlatform.android) {
      final redirect_uri = challenge.redirect_uri;
      if (redirect_uri == null ||
          !redirect_uri.hasScheme ||
          !redirect_uri.hasAuthority ||
          redirect_uri.scheme != 'https') {
        throw const AppleLoginUnavailableException(
          'Android Apple 로그인 callback 설정이 올바르지 않습니다.',
        );
      }
      web_authentication_options = WebAuthenticationOptions(
        clientId: challenge.client_id,
        redirectUri: redirect_uri,
      );
    }

    try {
      final credential_request = _apple_sign_in_sdk.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: web_authentication_options,
        nonce: challenge.nonce,
        state: challenge.state,
      );
      final credential = current_platform == AppleLoginPlatform.android
          ? await credential_request.timeout(_android_login_timeout)
          : await credential_request;

      final authorization_code = credential.authorizationCode.trim();
      final returned_state = credential.state?.trim();
      if (authorization_code.isEmpty) {
        throw const AppleLoginSecurityException('Apple 인증 코드를 받지 못했습니다.');
      }
      if (returned_state == null || returned_state != challenge.state) {
        throw const AppleLoginSecurityException('Apple 로그인 state 검증에 실패했습니다.');
      }

      return AppleLoginCredential(
        platform: current_platform,
        authorization_code: authorization_code,
        identity_token: _trimOrNull(credential.identityToken),
        state: returned_state,
        nonce: challenge.nonce,
        given_name: _trimOrNull(credential.givenName),
        family_name: _trimOrNull(credential.familyName),
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        throw const AppleLoginCanceledException();
      }
      throw const AppleLoginUnavailableException('Apple 로그인 인증에 실패했습니다.');
    } on SignInWithAppleNotSupportedException {
      throw const AppleLoginUnavailableException(
        '이 기기에서는 Apple 로그인을 사용할 수 없습니다.',
      );
    } on TimeoutException {
      throw const AppleLoginUnavailableException(
        'Apple 로그인 시간이 만료되었습니다. 다시 시도해주세요.',
      );
    } on SignInWithAppleException {
      throw const AppleLoginUnavailableException('Apple 로그인에 실패했습니다.');
    }
  }

  String? _trimOrNull(String? value) {
    final trimmed_value = value?.trim();
    return trimmed_value == null || trimmed_value.isEmpty
        ? null
        : trimmed_value;
  }
}
