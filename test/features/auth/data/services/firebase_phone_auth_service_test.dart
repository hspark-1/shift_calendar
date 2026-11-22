// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/core/network/api_exception.dart';
import 'package:shift_mate/features/auth/data/services/firebase_phone_auth_service.dart';

class _User extends Fake implements User {
  bool? force_refresh;
  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    force_refresh = forceRefresh;
    return 'firebase-id-token';
  }
}

class _Credential extends Fake implements UserCredential {
  final _User verified_user = _User();
  @override
  User get user => verified_user;
}

class _Auth extends Fake implements FirebaseAuth {
  int sign_out_count = 0;
  int sign_in_count = 0;
  String? language;
  String? phone;
  int? resend;
  Completer<UserCredential>? pending_sign_in;
  final result = _Credential();
  PhoneCodeSent? codeSent;
  @override
  Future<void> signOut() async => sign_out_count += 1;
  @override
  Future<void> setLanguageCode(String? languageCode) async {
    language = languageCode;
  }

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    sign_in_count += 1;
    return pending_sign_in?.future ?? Future.value(result);
  }

  @override
  Future<void> verifyPhoneNumber({
    String? phoneNumber,
    PhoneMultiFactorInfo? multiFactorInfo,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    String? autoRetrievedSmsCodeForTesting,
    Duration timeout = const Duration(seconds: 30),
    int? forceResendingToken,
    MultiFactorSession? multiFactorSession,
  }) async {
    phone = phoneNumber;
    resend = forceResendingToken;
    this.codeSent = codeSent;
  }
}

void main() {
  test('세션은 기존 Firebase 로그인만 정리하고 ko·E164·재발송 token을 전달한다', () async {
    final auth = _Auth();
    final service = NativeFirebasePhoneAuthService(
      auth_loader: () async => auth,
    );
    final session = await service.startSession();
    var sent_count = 0;
    await service.requestCode(
      session: session,
      phone_e164: '+821012345678',
      resend_token: 4,
      onCodeSent: (_, token) {
        sent_count += 1;
        expect(token, 4);
      },
      onAutomatic: (_) {},
      onAutoRetrievalTimeout: () {},
      onError: (_) {},
    );
    auth.codeSent!('verification', 4);
    expect(sent_count, 1);
    expect(auth.phone, '+821012345678');
    expect(auth.resend, 4);
    expect(auth.language, 'ko');
    expect(
      await service.signIn(
        session: session,
        verification_id: 'verification',
        code: '012345',
      ),
      'firebase-id-token',
    );
    expect(auth.result.verified_user.force_refresh, isTrue);
    await service.closeSession(session);
    auth.codeSent!('stale', 4);
    expect(sent_count, 1);
    expect(auth.sign_out_count, 2);
  });

  test('이전 signIn이 늦게 끝나도 새 세션 전 정리하며 이전 close는 새 세션을 지우지 않는다', () async {
    final auth = _Auth()..pending_sign_in = Completer<UserCredential>();
    final service = NativeFirebasePhoneAuthService(
      auth_loader: () async => auth,
    );
    final old_session = await service.startSession();
    final old_sign_in = service.signIn(
      session: old_session,
      verification_id: 'old',
      code: '012345',
    );
    final rejected = expectLater(
      old_sign_in,
      throwsA(
        isA<ApiException>().having(
          (e) => e.code,
          'code',
          'PHONE_AUTH_CANCELLED',
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(auth.sign_in_count, 1);
    final new_session_future = service.startSession();
    await service.closeSession(old_session);
    auth.pending_sign_in!.complete(auth.result);
    await rejected;
    final new_session = await new_session_future;
    expect(auth.sign_out_count, 2);
    await service.closeSession(old_session);
    expect(auth.sign_out_count, 2);
    auth.pending_sign_in = null;
    expect(
      await service.signIn(
        session: new_session,
        verification_id: 'new',
        code: '123456',
      ),
      'firebase-id-token',
    );
    await service.clearSessions();
    expect(auth.sign_out_count, 3);
    await expectLater(
      service.signIn(
        session: new_session,
        verification_id: 'new',
        code: '123456',
      ),
      throwsA(isA<ApiException>()),
    );
  });

  test('Firebase 원문 오류나 전화번호는 사용자 메시지에 노출하지 않는다', () {
    final error = phoneAuthError(
      FirebaseAuthException(
        code: 'invalid-verification-code',
        message: 'sensitive 01012345678',
      ),
    );
    expect(error.code, 'PHONE_AUTH_invalid-verification-code');
    expect(error.message, '인증번호가 맞지 않아요. 다시 입력해주세요.');
    expect(
      phoneAuthError(StateError('sensitive')).message,
      isNot(contains('sensitive')),
    );
  });
}
