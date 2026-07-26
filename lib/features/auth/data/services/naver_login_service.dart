// ignore_for_file: non_constant_identifier_names

import 'package:flutter/services.dart';
import 'package:naver_login_flutter/naver_login_flutter.dart';

/// 네이버 네이티브 SDK 호출 경계
abstract interface class NaverLoginSdk {
  Future<NaverLoginResult> logIn();
  Future<NaverToken> getCurrentAccessToken();
  Future<NaverLoginResult> logOut();
}

/// 실제 네이버 네이티브 SDK 구현
class NativeNaverLoginSdk implements NaverLoginSdk {
  @override
  Future<NaverLoginResult> logIn() {
    return FlutterNaverLogin.logIn();
  }

  @override
  Future<NaverToken> getCurrentAccessToken() {
    return FlutterNaverLogin.getCurrentAccessToken();
  }

  @override
  Future<NaverLoginResult> logOut() {
    return FlutterNaverLogin.logOut();
  }
}

/// 네이버 네이티브 로그인 서비스
///
/// iOS는 네이버 앱을 우선 사용하고, 앱이 설치되지 않은 경우에만
/// SDK의 인앱 브라우저로 대체합니다. Android의 인증 화면 선택 역시
/// 네이버 공식 SDK가 처리합니다.
class NaverLoginService {
  final NaverLoginSdk _naver_login_sdk;

  NaverLoginService({NaverLoginSdk? naver_login_sdk})
    : _naver_login_sdk = naver_login_sdk ?? NativeNaverLoginSdk();

  /// 네이버 SDK에서 발급한 Access Token을 반환합니다.
  Future<String> loginWithNaver() async {
    try {
      final login_result = await _naver_login_sdk.logIn();

      switch (login_result.status) {
        case NaverLoginStatus.loggedIn:
          var access_token = login_result.accessToken?.accessToken.trim();
          if (access_token == null || access_token.isEmpty) {
            final current_token = await _naver_login_sdk
                .getCurrentAccessToken();
            access_token = current_token.accessToken.trim();
          }
          if (access_token.isEmpty) {
            throw Exception('네이버 Access Token을 받지 못했습니다.');
          }
          return access_token;
        case NaverLoginStatus.loggedOut:
          throw Exception('네이버 로그인이 취소되었습니다.');
        case NaverLoginStatus.error:
          final error_message = login_result.errorMessage?.trim();
          throw Exception(
            error_message == null || error_message.isEmpty
                ? '네이버 로그인에 실패했습니다.'
                : error_message,
          );
      }
    } on PlatformException catch (error) {
      final error_message = error.message?.trim();
      if (error_message != null &&
          error_message.toLowerCase().contains('cancel')) {
        throw Exception('네이버 로그인이 취소되었습니다.');
      }

      throw Exception(
        error_message == null || error_message.isEmpty
            ? '네이버 로그인에 실패했습니다.'
            : '네이버 로그인에 실패했습니다: $error_message',
      );
    }
  }

  /// 네이버 SDK에 저장된 로컬 로그인 상태를 해제합니다.
  Future<void> logout() async {
    await _naver_login_sdk.logOut();
  }
}
