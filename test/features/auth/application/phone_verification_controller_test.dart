// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/core/network/api_exception.dart';
import 'package:shift_mate/features/auth/application/phone_verification_controller.dart';
import 'package:shift_mate/features/auth/application/phone_verification_state.dart';
import 'package:shift_mate/features/auth/data/models/phone_verification_models.dart';
import 'package:shift_mate/features/auth/data/repositories/phone_verification_repository.dart';

import '../../../helpers/phone_auth_fakes.dart';

void main() {
  late FakePhoneRepository repository;
  late FakeFirebasePhoneService firebase;
  late PhoneVerificationController controller;
  late Duration elapsed;

  setUp(() {
    repository = FakePhoneRepository();
    firebase = FakeFirebasePhoneService();
    elapsed = Duration.zero;
    controller = PhoneVerificationController(
      repository,
      firebase,
      PhoneVerificationPurpose.signup,
      elapsed: () => elapsed,
      use_timer: false,
    );
    controller.setPhone('01012345678');
  });
  tearDown(() => controller.dispose());

  test('중복 확인 응답 전에는 checking, SDK 준비와 codeSent 대기는 sending이다', () async {
    final challenge = Completer<PhoneChallenge>();
    repository.pending_challenge = challenge;
    firebase.pending_start = Completer<void>();
    firebase.auto_send = false;
    final request = controller.sendCode();
    expect(controller.state.stage, PhoneVerificationStage.checking);
    expect(firebase.start_count, 0);
    repository.challenge = PhoneChallenge(
      challenge_id: 'pending',
      phone: '01012345678',
      phone_e164: '+821012345678',
      purpose: PhoneVerificationPurpose.signup,
      server_now: DateTime.utc(2000),
      expires_at: DateTime.utc(2000, 1, 1, 0, 10),
    );
    challenge.complete(repository.challenge!);
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.stage, PhoneVerificationStage.sending);
    expect(firebase.start_count, 1);
    expect(firebase.request_count, 0);
    await controller.verifyCode('000123');
    expect(firebase.sign_in_count, 0);
    expect(controller.tokenFor('01012345678'), isNull);
    firebase.pending_start!.complete();
    await request;
    expect(controller.state.stage, PhoneVerificationStage.sending);
    expect(firebase.request_count, 1);
    await controller.verifyCode('000123');
    expect(firebase.sign_in_count, 0);
    firebase.codeSent!('sent', 7);
    await controller.verifyCode('000123');
    expect(controller.state.is_verified, isTrue);
  });

  test('중복 번호 거절은 SDK 준비와 문자 발송을 시작하지 않는다', () async {
    repository.create_error = ApiException(
      code: 'PHONE_ALREADY_EXISTS',
      message: '이미 사용 중인 전화번호입니다.',
      statusCode: 409,
    );
    await controller.sendCode();
    expect(controller.state.stage, PhoneVerificationStage.idle);
    expect(controller.state.error?.code, 'PHONE_ALREADY_EXISTS');
    expect(firebase.start_count, 0);
    expect(firebase.request_count, 0);
  });

  test('선표시 후 SDK 준비 실패는 인증을 완료하지 않고 idle로 복귀한다', () async {
    firebase.start_error = ApiException(
      code: 'PHONE_AUTH_FAILED',
      message: '준비 실패',
    );
    await controller.sendCode();
    expect(controller.state.stage, PhoneVerificationStage.idle);
    expect(controller.state.error?.message, '준비 실패');
    expect(firebase.request_count, 0);
    expect(controller.tokenFor('01012345678'), isNull);
  });

  testWidgets('선표시 후 SDK 준비90초 timeout과 늦은 세션 완료를 정리한다', (tester) async {
    firebase.pending_start = Completer<void>();
    final request = controller.sendCode();
    await tester.pump();
    expect(controller.state.stage, PhoneVerificationStage.sending);
    await tester.pump(const Duration(seconds: 91));
    expect(controller.state.stage, PhoneVerificationStage.idle);
    expect(controller.state.error?.code, 'PHONE_AUTH_TIMEOUT');
    firebase.pending_start!.complete();
    await request;
    expect(firebase.close_count, 1);
    expect(firebase.request_count, 0);
    expect(controller.state.stage, PhoneVerificationStage.idle);
  });

  testWidgets('선표시 후 발송 콜백 timeout은 늦은 codeSent를 무시한다', (tester) async {
    firebase.auto_send = false;
    await controller.sendCode();
    final late_code_sent = firebase.codeSent!;
    await tester.pump(const Duration(seconds: 91));
    expect(controller.state.stage, PhoneVerificationStage.idle);
    expect(controller.state.error?.code, 'PHONE_AUTH_TIMEOUT');
    late_code_sent('late', 7);
    expect(controller.state.stage, PhoneVerificationStage.idle);
    expect(controller.tokenFor('01012345678'), isNull);
  });

  test('문자 발송 대기 중 번호 변경은 오래된 성공·실패 콜백을 무시한다', () async {
    firebase.auto_send = false;
    await controller.sendCode();
    final old_code_sent = firebase.codeSent!;
    final old_failure = firebase.failure!;
    controller.setPhone('01099998888');
    old_code_sent('late', 7);
    old_failure(ApiException(code: 'PHONE_AUTH_FAILED', message: '이전 실패'));
    expect(controller.state.stage, PhoneVerificationStage.idle);
    expect(controller.state.phone, '01099998888');
    expect(controller.state.error, isNull);
  });

  test('서버 challenge 후 E.164로 발송하고 코드만 받은 상태는 저장 증명이 아니다', () async {
    await controller.sendCode();
    expect(firebase.last_e164, '+821012345678');
    expect(controller.state.stage, PhoneVerificationStage.code_sent);
    expect(controller.tokenFor('01012345678'), isNull);
    await controller.verifyCode('000123');
    expect(firebase.last_code, '000123');
    expect(repository.last_id_token, 'firebase-id-token');
    expect(controller.tokenFor('01012345678'), startsWith('proof-'));
    expect(controller.tokenFor('01099998888'), isNull);
    expect(firebase.close_count, 1);
  });

  test('번호 변경 후 원래 번호로 돌아와도 이전 증명을 복원하지 않는다', () async {
    await controller.sendCode();
    await controller.verifyCode('000123');
    controller.setPhone('01099998888');
    controller.setPhone('01012345678');
    expect(controller.tokenFor('01012345678'), isNull);
  });

  test('자동 읽기 종료 뒤에도 수동 코드 확인을 허용한다', () async {
    await controller.sendCode();
    firebase.retrievalTimeout!();
    expect(controller.state.auto_retrieval_finished, isTrue);
    expect(controller.state.stage, PhoneVerificationStage.code_sent);
    await controller.verifyCode('000123');
    expect(controller.state.is_verified, isTrue);
  });

  test('자동/수동 경합에서 SDK와 서버 검증은 한 번만 수행한다', () async {
    await controller.sendCode();
    final pending = Completer<String>();
    firebase.pending_sign_in = pending;
    firebase.automatic!(
      PhoneAuthProvider.credential(verificationId: 'id', smsCode: '000123'),
    );
    await controller.verifyCode('000123');
    expect(firebase.sign_in_count, 1);
    pending.complete('token');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(repository.verify_count, 1);
    expect(controller.state.is_verified, isTrue);
    firebase.codeSent!('late-id', 0);
    expect(controller.state.is_verified, isTrue);
  });

  test('번호 수정 이전의 늦은 codeSent/자동 완료는 버린다', () async {
    await controller.sendCode();
    final code_sent = firebase.codeSent!;
    final automatic = firebase.automatic!;
    controller.setPhone('01099998888');
    code_sent('late', 0);
    automatic(
      PhoneAuthProvider.credential(verificationId: 'late', smsCode: '000123'),
    );
    expect(controller.state.phone, '01099998888');
    expect(controller.state.stage, PhoneVerificationStage.idle);
    expect(firebase.sign_in_count, 0);
  });

  test('서버 응답 유실 뒤 SDK 재로그인 없이 같은 ID token/key로 복구한다', () async {
    await controller.sendCode();
    repository.verify_error = ApiException(
      code: 'TIMEOUT_ERROR',
      message: '연결 오류',
    );
    await controller.verifyCode('000123');
    final key = repository.last_verify_key;
    expect(controller.state.awaiting_server, isTrue);
    repository.verify_error = null;
    await controller.verifyCode('');
    expect(firebase.sign_in_count, 1);
    expect(repository.last_verify_key, key);
    expect(controller.state.is_verified, isTrue);
  });

  test('서버가 증명/토큰을 거부하면 코드 확인을 계속 재사용하지 않는다', () async {
    await controller.sendCode();
    repository.verify_error = ApiException(
      code: 'PHONE_FIREBASE_TOKEN_INVALID',
      message: '다시 인증',
      statusCode: 400,
    );
    await controller.verifyCode('000123');
    expect(controller.state.stage, PhoneVerificationStage.idle);
    expect(controller.tokenFor('01012345678'), isNull);
    expect(firebase.close_count, 1);
  });

  test('오답 수정과 재입력은 허용하되 임의로 인증 완료하지 않는다', () async {
    await controller.sendCode();
    firebase.sign_in_error = ApiException(
      code: 'PHONE_AUTH_invalid-verification-code',
      message: '오답',
    );
    await controller.verifyCode('000000');
    expect(controller.state.stage, PhoneVerificationStage.code_sent);
    expect(repository.verify_count, 0);
    firebase.sign_in_error = null;
    await controller.verifyCode('000123');
    expect(controller.state.is_verified, isTrue);
  });

  test('단조 시계 기준 재발송 대기와 proof 만료를 서버 시각에서 계산한다', () async {
    await controller.sendCode();
    await controller.sendCode();
    expect(repository.create_count, 1);
    await controller.verifyCode('000123');
    elapsed = const Duration(seconds: 301);
    expect(controller.tokenFor('01012345678'), isNull);
    expect(controller.state.error?.code, 'PHONE_VERIFICATION_EXPIRED');
    await controller.sendCode();
    expect(repository.create_count, 2);
  });

  test('재발송은 새 challenge/key와 Android resend token을 사용한다', () async {
    await controller.sendCode();
    final key = repository.last_challenge_key;
    elapsed = const Duration(seconds: 61);
    await controller.sendCode();
    expect(repository.last_challenge_key, isNot(key));
    expect(firebase.last_resend_token, 7);
    expect(repository.create_count, 2);
  });

  test('challenge 요청 timeout 재시도는 같은 key를 유지하고 실패 시 SMS를 보내지 않는다', () async {
    repository.create_error = ApiException(
      code: 'TIMEOUT_ERROR',
      message: '시간 초과',
    );
    await controller.sendCode();
    final key = repository.last_challenge_key;
    expect(firebase.request_count, 0);
    repository.create_error = null;
    await controller.sendCode();
    expect(repository.last_challenge_key, key);
    expect(firebase.request_count, 1);
  });

  test('응답 유실 후 만료200을 받으면 같은 번호도 새 key로 인증을 다시 시작한다', () async {
    final dio = Dio();
    addTearDown(dio.close);
    final keys = <String>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          keys.add(options.headers['Idempotency-Key'] as String);
          if (keys.length == 1) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.receiveTimeout,
              ),
            );
            return;
          }
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'success': true,
                'data': {
                  'challenge_id': keys.last == keys.first
                      ? 'expired-challenge'
                      : 'fresh-challenge',
                  'phone': '01012345678',
                  'phone_e164': '+821012345678',
                  'purpose': 'SIGNUP',
                  'server_now': '2026-11-21T03:11:00Z',
                  'expires_at': keys.last == keys.first
                      ? '2026-11-21T03:10:00Z'
                      : '2026-11-21T03:21:00Z',
                },
              },
            ),
          );
        },
      ),
    );
    final actual = PhoneVerificationController(
      RemotePhoneVerificationRepository(dio),
      firebase,
      PhoneVerificationPurpose.signup,
      use_timer: false,
      initial_phone: '01012345678',
    );
    addTearDown(actual.dispose);
    await actual.sendCode();
    expect(actual.state.error?.code, 'TIMEOUT_ERROR');
    await actual.sendCode();
    expect(actual.state.error?.code, 'PHONE_VERIFICATION_INVALID_RESPONSE');
    expect(keys[1], keys[0]);
    expect(firebase.request_count, 0);
    await actual.sendCode();
    expect(keys[2], isNot(keys[1]));
    expect(firebase.request_count, 1);
    expect(actual.state.stage, PhoneVerificationStage.code_sent);
    expect(actual.tokenFor('01012345678'), isNull);
  });

  for (final failure in [
    ApiException(
      code: 'PHONE_CHALLENGE_EXPIRED',
      message: '만료',
      statusCode: 410,
    ),
    ApiException(
      code: 'PHONE_VERIFICATION_INVALID',
      message: '취소',
      statusCode: 400,
    ),
    ApiException(
      code: 'IDEMPOTENCY_KEY_REUSED',
      message: '키 충돌',
      statusCode: 409,
    ),
    ApiException(code: 'PHONE_CHALLENGE_EXPIRED', message: '로컬 만료'),
  ]) {
    test(
      'challenge 확정 실패 ${failure.code}/${failure.statusCode} 후 새 key로 복구한다',
      () async {
        repository.create_error = failure;
        await controller.sendCode();
        final failed_key = repository.last_challenge_key;
        expect(controller.state.error, same(failure));
        expect(firebase.request_count, 0);
        expect(controller.tokenFor('01012345678'), isNull);
        repository.create_error = null;
        await controller.sendCode();
        expect(repository.last_challenge_key, isNot(failed_key));
        expect(controller.state.stage, PhoneVerificationStage.code_sent);
        expect(controller.tokenFor('01012345678'), isNull);
        await controller.verifyCode('012345');
        expect(controller.state.is_verified, isTrue);
      },
    );
  }

  for (final failure in [
    ApiException(code: 'NETWORK_ERROR', message: '연결 실패'),
    ApiException(
      code: 'PHONE_VERIFICATION_UNAVAILABLE',
      message: '서버 장애',
      statusCode: 503,
    ),
    ApiException(code: 'HTTP_ERROR', message: '요청 시간 초과', statusCode: 408),
    ApiException(
      code: 'PHONE_VERIFICATION_RATE_LIMITED',
      message: '대기',
      statusCode: 429,
      retry_after_seconds: 42,
    ),
  ]) {
    test(
      'challenge 일시 실패 ${failure.code}/${failure.statusCode}는 같은 key와 대기를 유지한다',
      () async {
        repository.create_error = failure;
        await controller.sendCode();
        final retry_key = repository.last_challenge_key;
        expect(firebase.request_count, 0);
        repository.create_error = null;
        if (failure.retry_after_seconds != null) {
          await controller.sendCode();
          expect(repository.create_count, 1);
          elapsed = Duration(seconds: failure.retry_after_seconds!);
        }
        await controller.sendCode();
        expect(repository.last_challenge_key, retry_key);
        expect(controller.state.stage, PhoneVerificationStage.code_sent);
      },
    );
  }

  test('서버 retry-after 동안 새 요청을 막는다', () async {
    repository.create_error = ApiException(
      code: 'PHONE_VERIFICATION_RATE_LIMITED',
      message: '대기',
      statusCode: 429,
      retry_after_seconds: 42,
    );
    await controller.sendCode();
    expect(controller.state.resend_seconds, 42);
    await controller.sendCode();
    expect(repository.create_count, 1);
  });

  test('SDK 준비 중 번호 변경 뒤 도착한 서버 challenge를 버린다', () async {
    final pending = Completer<PhoneChallenge>();
    repository.pending_challenge = pending;
    final request = controller.sendCode();
    controller.setPhone('01099998888');
    pending.complete(
      PhoneChallenge(
        challenge_id: 'old',
        phone: '01012345678',
        phone_e164: '+821012345678',
        purpose: PhoneVerificationPurpose.signup,
        server_now: DateTime.utc(2000),
        expires_at: DateTime.utc(2000, 1, 1, 0, 10),
      ),
    );
    await request;
    expect(firebase.start_count, 0);
    expect(controller.state.phone, '01099998888');
  });

  test('잘못된 번호와 다른 목적의 서버 응답을 인증하지 않는다', () async {
    controller.setPhone('0212345678');
    await controller.sendCode();
    expect(repository.create_count, 0);
    controller.setPhone('01012345678');
    final pending = Completer<PhoneChallenge>();
    repository.pending_challenge = pending;
    final request = controller.sendCode();
    pending.complete(
      PhoneChallenge(
        challenge_id: 'bad',
        phone: '01012345678',
        phone_e164: '+821012345678',
        purpose: PhoneVerificationPurpose.phone_change,
        server_now: DateTime.utc(2000),
        expires_at: DateTime.utc(2000, 1, 1, 0, 10),
      ),
    );
    await request;
    expect(controller.state.error?.code, 'PHONE_VERIFICATION_INVALID_RESPONSE');
    expect(firebase.request_count, 0);
  });
}
