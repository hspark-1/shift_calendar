// ignore_for_file: non_constant_identifier_names

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/core/network/api_client.dart';
import 'package:shift_mate/core/network/api_exception.dart';
import 'package:shift_mate/features/auth/data/models/phone_verification_models.dart';
import 'package:shift_mate/features/auth/data/repositories/phone_verification_repository.dart';

Map<String, Object> _challenge() => {
  'challenge_id': 'challenge',
  'phone': '01012345678',
  'phone_e164': '+821012345678',
  'purpose': 'SIGNUP',
  'server_now': '2026-11-21T03:00:00Z',
  'expires_at': '2026-11-21T03:10:00Z',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('보호된 challenge/verify에 앱 JWT와 작업 key를 전달한다', () async {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'shiftmate-token',
      'refresh_token': 'refresh',
      'expires_at': DateTime.now()
          .add(const Duration(hours: 1))
          .toIso8601String(),
    });
    final requests = <RequestOptions>[];
    final dio = ApiClient.createDio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'success': true,
                'data': options.path.endsWith('challenges')
                    ? _challenge()
                    : {
                        'phone_verification_token': 'app-proof',
                        'phone': '01012345678',
                        'purpose': 'SIGNUP',
                        'server_now': '2026-11-21T03:01:00Z',
                        'expires_at': '2026-11-21T03:06:00Z',
                      },
              },
            ),
          );
        },
      ),
    );
    final repository = RemotePhoneVerificationRepository(dio);
    final challenge = await repository.createChallenge(
      phone: '01012345678',
      purpose: PhoneVerificationPurpose.signup,
      idempotency_key: 'send-key',
    );
    final proof = await repository.verifyFirebasePhone(
      challenge_id: challenge.challenge_id,
      firebase_id_token: 'firebase-token',
      idempotency_key: 'verify-key',
    );
    expect(requests[0].path, '/auth/phone/challenges');
    expect(requests[0].data, {'phone': '01012345678', 'purpose': 'SIGNUP'});
    expect(requests[0].headers['Authorization'], 'Bearer shiftmate-token');
    expect(requests[0].headers['Idempotency-Key'], 'send-key');
    expect(requests[1].headers['Authorization'], 'Bearer shiftmate-token');
    expect(requests[1].headers['Idempotency-Key'], 'verify-key');
    expect(requests[1].data, {
      'challenge_id': 'challenge',
      'firebase_id_token': 'firebase-token',
    });
    expect(proof.token, 'app-proof');
  });

  for (final status in [404, 501]) {
    test('서버 준비 전 $status는 인증 우회 없이 안전한 안내를 반환한다', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: status,
                  data: 'internal route details',
                ),
              ),
            );
          },
        ),
      );
      await expectLater(
        RemotePhoneVerificationRepository(dio).createChallenge(
          phone: '01012345678',
          purpose: PhoneVerificationPurpose.signup,
          idempotency_key: 'key',
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'PHONE_VERIFICATION_UNAVAILABLE')
              .having(
                (e) => e.message,
                'safe message',
                isNot(contains('internal')),
              ),
        ),
      );
    });
  }

  test('서버 구조화429와 retry-after/request id를 보존한다', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 429,
                headers: Headers.fromMap({
                  'retry-after': ['42'],
                }),
                data: {
                  'success': false,
                  'error': {
                    'code': 'PHONE_VERIFICATION_RATE_LIMITED',
                    'message': '대기',
                  },
                  'request_id': 'request-id',
                },
              ),
            ),
          );
        },
      ),
    );
    await expectLater(
      RemotePhoneVerificationRepository(dio).createChallenge(
        phone: '01012345678',
        purpose: PhoneVerificationPurpose.signup,
        idempotency_key: 'key',
      ),
      throwsA(
        isA<ApiException>()
            .having((e) => e.retry_after_seconds, 'retry', 42)
            .having((e) => e.request_id, 'request id', 'request-id'),
      ),
    );
  });

  test('정규화가 잘못되거나 만료/시간대 없는 challenge 응답은 거부한다', () async {
    for (final entry in [
      {'phone_e164': '+8201012345678'},
      {'expires_at': '2026-11-21T02:00:00Z'},
      {'server_now': '2026-11-21T03:00:00'},
      {'purpose': 'UNKNOWN'},
    ]) {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'success': true,
                  'data': {..._challenge(), ...entry},
                },
              ),
            );
          },
        ),
      );
      await expectLater(
        RemotePhoneVerificationRepository(dio).createChallenge(
          phone: '01012345678',
          purpose: PhoneVerificationPurpose.signup,
          idempotency_key: 'key',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'PHONE_VERIFICATION_INVALID_RESPONSE',
          ),
        ),
      );
    }
  });

  test('국내 번호 변환은 앞자리0을 제거하고 임의의 +82/유선 입력을 거부한다', () {
    expect(koreanPhoneE164('01012345678'), '+821012345678');
    expect(
      () => koreanPhoneE164('+821012345678'),
      throwsA(isA<ApiException>()),
    );
    expect(() => koreanPhoneE164('0212345678'), throwsA(isA<ApiException>()));
  });
}
