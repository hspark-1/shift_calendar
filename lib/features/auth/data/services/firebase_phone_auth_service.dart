// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firebase/firebase_initializer.dart';
import '../../../../core/network/api_exception.dart';

export 'package:firebase_auth/firebase_auth.dart' show PhoneAuthCredential;

final firebase_phone_auth_service_provider = Provider<FirebasePhoneAuthService>(
  (ref) => NativeFirebasePhoneAuthService(),
);

abstract class FirebasePhoneAuthService {
  Future<Object> startSession();
  Future<void> requestCode({
    required Object session,
    required String phone_e164,
    int? resend_token,
    required void Function(String verification_id, int? resend_token)
    onCodeSent,
    required void Function(firebase.PhoneAuthCredential credential) onAutomatic,
    required void Function() onAutoRetrievalTimeout,
    required void Function(ApiException error) onError,
  });
  Future<String> signIn({
    required Object session,
    firebase.PhoneAuthCredential? credential,
    String? verification_id,
    String? code,
  });
  Future<void> closeSession(Object session);
  Future<void> clearSessions();
}

ApiException phoneAuthError(Object error) {
  if (error is ApiException) return error;
  final code = error is firebase.FirebaseAuthException ? error.code : '';
  final message = switch (code) {
    'invalid-phone-number' => '한국 휴대폰 번호 형식을 확인해주세요.',
    'invalid-verification-code' => '인증번호가 맞지 않아요. 다시 입력해주세요.',
    'session-expired' ||
    'invalid-verification-id' ||
    'code-expired' => '인증번호를 다시 받아주세요.',
    'too-many-requests' || 'quota-exceeded' => '인증 요청이 많아요. 잠시 후 다시 시도해주세요.',
    'network-request-failed' => '네트워크 연결을 확인한 후 다시 시도해주세요.',
    _ => '휴대폰 인증을 완료하지 못했어요. 다시 시도해주세요.',
  };
  return ApiException(
    code: code.isEmpty ? 'PHONE_AUTH_FAILED' : 'PHONE_AUTH_$code',
    message: message,
  );
}

/// Native Auth의 지속 세션은 보조 인증에만 사용한다. 작업 직렬화로 이전
/// 화면의 늦은 signIn/signOut이 새 화면의 Firebase 세션을 바꾸지 못하게 한다.
class NativeFirebasePhoneAuthService implements FirebasePhoneAuthService {
  final Future<firebase.FirebaseAuth> Function() _auth_loader;
  Future<void> _tail = Future<void>.value();
  Object? _active_session;
  firebase.FirebaseAuth? _auth;

  NativeFirebasePhoneAuthService({
    Future<firebase.FirebaseAuth> Function()? auth_loader,
  }) : _auth_loader = auth_loader ?? _loadAuth;

  static Future<firebase.FirebaseAuth> _loadAuth() async {
    final app = await FirebaseInitializer.ensureInitialized();
    return firebase.FirebaseAuth.instanceFor(app: app);
  }

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final future = _tail.then((_) => action());
    _tail = future.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack_trace) {},
    );
    return future;
  }

  void _checkSession(Object session) {
    if (!identical(session, _active_session)) {
      throw ApiException(code: 'PHONE_AUTH_CANCELLED', message: '인증이 취소되었어요.');
    }
  }

  @override
  Future<Object> startSession() {
    final session = Object();
    _active_session = session;
    return _enqueue(() async {
      try {
        _checkSession(session);
        final auth = await _auth_loader();
        _checkSession(session);
        _auth = auth;
        await auth.signOut();
        _checkSession(session);
        await auth.setLanguageCode('ko');
        _checkSession(session);
        return session;
      } catch (error) {
        if (identical(session, _active_session)) _active_session = null;
        throw phoneAuthError(error);
      }
    });
  }

  @override
  Future<void> requestCode({
    required Object session,
    required String phone_e164,
    int? resend_token,
    required void Function(String verification_id, int? resend_token)
    onCodeSent,
    required void Function(firebase.PhoneAuthCredential credential) onAutomatic,
    required void Function() onAutoRetrievalTimeout,
    required void Function(ApiException error) onError,
  }) => _enqueue(() async {
    try {
      _checkSession(session);
      await _auth!.verifyPhoneNumber(
        phoneNumber: phone_e164,
        timeout: const Duration(seconds: 60),
        forceResendingToken: resend_token,
        verificationCompleted: (credential) {
          if (identical(session, _active_session)) onAutomatic(credential);
        },
        verificationFailed: (error) {
          if (identical(session, _active_session)) {
            onError(phoneAuthError(error));
          }
        },
        codeSent: (verification_id, token) {
          if (identical(session, _active_session)) {
            onCodeSent(verification_id, token);
          }
        },
        codeAutoRetrievalTimeout: (_) {
          if (identical(session, _active_session)) onAutoRetrievalTimeout();
        },
      );
    } catch (error) {
      throw phoneAuthError(error);
    }
  });

  @override
  Future<String> signIn({
    required Object session,
    firebase.PhoneAuthCredential? credential,
    String? verification_id,
    String? code,
  }) => _enqueue(() async {
    try {
      _checkSession(session);
      final selected_credential =
          credential ??
          firebase.PhoneAuthProvider.credential(
            verificationId: verification_id!,
            smsCode: code!,
          );
      final result = await _auth!.signInWithCredential(selected_credential);
      _checkSession(session);
      final token = await result.user?.getIdToken(true);
      _checkSession(session);
      if (token == null || token.isEmpty) {
        throw ApiException(
          code: 'PHONE_AUTH_TOKEN_MISSING',
          message: '인증 결과를 확인하지 못했어요.',
        );
      }
      return token;
    } catch (error) {
      throw phoneAuthError(error);
    }
  });

  @override
  Future<void> closeSession(Object session) {
    if (!identical(session, _active_session)) return Future<void>.value();
    _active_session = null;
    return _enqueue(() async {
      if (_active_session == null) await _auth?.signOut();
    });
  }

  @override
  Future<void> clearSessions() {
    _active_session = null;
    return _enqueue(() async {
      if (_active_session != null) return;
      if (_auth == null && Firebase.apps.isNotEmpty) {
        _auth = firebase.FirebaseAuth.instance;
      }
      await _auth?.signOut();
    });
  }
}
