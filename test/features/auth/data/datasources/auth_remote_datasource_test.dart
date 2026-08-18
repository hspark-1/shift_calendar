// ignore_for_file: non_constant_identifier_names

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/core/constants/api_constants.dart';
import 'package:shift_mate/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:shift_mate/features/auth/data/models/apple_auth_models.dart';
import 'package:shift_mate/features/auth/domain/entities/user.dart';
import 'package:shift_mate/core/network/api_exception.dart';

void main() {
  group('AuthRemoteDataSource.deleteAccount', () {
    test('DELETE /auth/account에 boolean confirmation true를 전송한다', () async {
      final dio = Dio(
        BaseOptions(baseUrl: 'https://stage-api.shiftmate.co.kr/api/v1'),
      );
      RequestOptions? captured_request;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured_request = options;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 202,
                data: {
                  'success': true,
                  'data': {
                    'deletion_request_id': 'deletion-id',
                    'status': 'PENDING',
                    'requested_at': '2026-08-14T02:30:00.000Z',
                  },
                  'request_id': 'request-id',
                },
              ),
            );
          },
        ),
      );

      await AuthRemoteDataSource(dio).deleteAccount();

      expect(captured_request?.method, 'DELETE');
      expect(captured_request?.path, ApiConstants.auth_account);
      expect(captured_request?.data, {'confirmation': true});
      expect(captured_request?.extra['skip_auth_refresh'], isTrue);
    });

    test(
      'REAUTHENTICATION_REQUIRED와 request_id를 ApiException으로 보존한다',
      () async {
        final dio = Dio(
          BaseOptions(baseUrl: 'https://stage-api.shiftmate.co.kr/api/v1'),
        );
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 403,
                    data: {
                      'success': false,
                      'error': {
                        'code': 'REAUTHENTICATION_REQUIRED',
                        'message': '회원 탈퇴를 위해 다시 로그인해주세요.',
                      },
                      'request_id': 'server-request-id',
                    },
                  ),
                ),
              );
            },
          ),
        );

        await expectLater(
          AuthRemoteDataSource(dio).deleteAccount(),
          throwsA(
            isA<ApiException>()
                .having(
                  (error) => error.code,
                  'code',
                  'REAUTHENTICATION_REQUIRED',
                )
                .having(
                  (error) => error.request_id,
                  'request_id',
                  'server-request-id',
                ),
          ),
        );
      },
    );
  });

  group('AuthRemoteDataSource.loginWithNaverToken', () {
    test('POST /auth/naver/token으로 네이버 Access Token을 전송한다', () async {
      final dio = Dio(
        BaseOptions(baseUrl: 'https://stage-api.shiftmate.co.kr/api/v1'),
      );
      RequestOptions? captured_request;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured_request = options;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'message': '로그인 성공',
                  'data': {
                    'user': {
                      'user_id': 'naver-user-id',
                      'email': 'naver@example.com',
                      'name': '네이버 사용자',
                    },
                    'access_token': 'app-access-token',
                    'refresh_token': 'app-refresh-token',
                    'expires_at': '2026-07-27T00:00:00.000Z',
                  },
                },
              ),
            );
          },
        ),
      );

      final data_source = AuthRemoteDataSource(dio);
      final auth_response = await data_source.loginWithNaverToken(
        'naver-access-token',
      );

      expect(captured_request, isNotNull);
      expect(captured_request!.method, 'POST');
      expect(captured_request!.path, ApiConstants.auth_naver_token);
      expect(captured_request!.data, {'access_token': 'naver-access-token'});
      expect(auth_response.user.id, 'naver-user-id');
      expect(auth_response.access_token, 'app-access-token');
    });
  });

  group('AuthRemoteDataSource.loginWithKakaoToken', () {
    test('POST /auth/kakao/token으로 카카오 Access Token을 전송한다', () async {
      final dio = Dio(
        BaseOptions(baseUrl: 'https://stage-api.shiftmate.co.kr/api/v1'),
      );
      RequestOptions? captured_request;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured_request = options;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'message': '로그인 성공',
                  'data': {
                    'user': {
                      'user_id': 'kakao-user-id',
                      'email': 'kakao@example.com',
                      'name': '카카오 사용자',
                      'kakao_id': 'kakao-subject',
                    },
                    'access_token': 'app-access-token',
                    'refresh_token': 'app-refresh-token',
                    'expires_at': '2026-08-17T00:00:00.000Z',
                  },
                },
              ),
            );
          },
        ),
      );

      final data_source = AuthRemoteDataSource(dio);
      final auth_response = await data_source.loginWithKakaoToken(
        'kakao-access-token',
      );

      expect(captured_request, isNotNull);
      expect(captured_request!.method, 'POST');
      expect(captured_request!.path, ApiConstants.auth_kakao_token);
      expect(captured_request!.data, {'access_token': 'kakao-access-token'});
      expect(auth_response.user.id, 'kakao-user-id');
      expect(auth_response.user.kakao_id, 'kakao-subject');
      expect(auth_response.access_token, 'app-access-token');
    });

    test('서버의 Kakao App 불일치 오류 코드와 request_id를 보존한다', () async {
      final dio = Dio(
        BaseOptions(baseUrl: 'https://stage-api.shiftmate.co.kr/api/v1'),
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 401,
                  data: {
                    'success': false,
                    'error': {
                      'code': 'KAKAO_TOKEN_APP_MISMATCH',
                      'message': '유효하지 않은 카카오 로그인 정보입니다.',
                    },
                    'request_id': 'kakao-request-id',
                  },
                ),
              ),
            );
          },
        ),
      );

      await expectLater(
        AuthRemoteDataSource(dio).loginWithKakaoToken('foreign-app-token'),
        throwsA(
          isA<ApiException>()
              .having((error) => error.code, 'code', 'KAKAO_TOKEN_APP_MISMATCH')
              .having(
                (error) => error.message,
                'message',
                '유효하지 않은 카카오 로그인 정보입니다.',
              )
              .having(
                (error) => error.request_id,
                'request_id',
                'kakao-request-id',
              ),
        ),
      );
    });
  });

  group('AuthRemoteDataSource.loginWithGoogleIdToken', () {
    test('정확한 endpoint/body로 ID Token을 보내고 millisecond 만료 시각을 파싱한다', () async {
      final dio = Dio(
        BaseOptions(baseUrl: 'https://stage-api.shiftmate.co.kr/api/v1'),
      );
      RequestOptions? captured_request;
      final expires_at = DateTime.utc(2026, 8, 11, 12);

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured_request = options;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'message': 'Google 로그인 성공',
                  'data': {
                    'user': {
                      'user_id': 'google-user-id',
                      'email': 'google@example.com',
                      'name': 'Google 사용자',
                      'google_id': 'google-subject',
                    },
                    'access_token': 'app-access-token',
                    'refresh_token': 'app-refresh-token',
                    'expires_at': expires_at.millisecondsSinceEpoch,
                    'is_new_user': true,
                  },
                },
              ),
            );
          },
        ),
      );

      final data_source = AuthRemoteDataSource(dio);
      final auth_response = await data_source.loginWithGoogleIdToken(
        'google-id-token',
      );

      expect(captured_request?.method, 'POST');
      expect(captured_request?.path, ApiConstants.auth_google_token);
      expect(captured_request?.data, {'id_token': 'google-id-token'});
      expect(auth_response.user.id, 'google-user-id');
      expect(auth_response.user.google_id, 'google-subject');
      expect(auth_response.expires_at, expires_at);
      expect(auth_response.is_new_user, isTrue);
    });

    test('AuthToken JSON의 정수 expires_at도 Unix epoch milliseconds로 파싱한다', () {
      final expires_at = DateTime.utc(2026, 8, 11, 12);

      final auth_token = AuthToken.fromJson({
        'access_token': 'access-token',
        'refresh_token': 'refresh-token',
        'expires_at': expires_at.millisecondsSinceEpoch,
      });

      expect(auth_token.expires_at, expires_at);
    });
  });

  group('AuthRemoteDataSource.updateProfile', () {
    test('POST /auth/profile로 전달된 프로필 필드만 전송한다', () async {
      final dio = Dio(
        BaseOptions(baseUrl: 'https://stage-api.shiftmate.co.kr/api/v1'),
      );
      RequestOptions? captured_request;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured_request = options;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {
                    'user_id': 'user-id',
                    'email': 'user@example.com',
                    'name': '변경된 이름',
                    'timezone': 'Asia/Seoul',
                  },
                },
              ),
            );
          },
        ),
      );

      final data_source = AuthRemoteDataSource(dio);
      final user = await data_source.updateProfile(
        name: '변경된 이름',
        timezone: 'Asia/Seoul',
      );

      expect(captured_request, isNotNull);
      expect(captured_request!.method, 'POST');
      expect(captured_request!.path, ApiConstants.auth_profile);
      expect(captured_request!.data, {
        'name': '변경된 이름',
        'timezone': 'Asia/Seoul',
      });
      expect(user.id, 'user-id');
      expect(user.name, '변경된 이름');
      expect(user.timezone, 'Asia/Seoul');
    });

    test('프로필 수정의 구조화 오류 코드와 메시지를 보존한다', () async {
      final dio = Dio(
        BaseOptions(baseUrl: 'https://stage-api.shiftmate.co.kr/api/v1'),
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 409,
                  data: {
                    'success': false,
                    'error': {
                      'code': 'PHONE_ALREADY_EXISTS',
                      'message': '이미 사용 중인 휴대폰 번호입니다.',
                    },
                    'request_id': 'profile-request-id',
                  },
                ),
              ),
            );
          },
        ),
      );

      await expectLater(
        AuthRemoteDataSource(dio).updateProfile(phone: '01012345678'),
        throwsA(
          isA<ApiException>()
              .having((error) => error.code, 'code', 'PHONE_ALREADY_EXISTS')
              .having(
                (error) => error.message,
                'message',
                '이미 사용 중인 휴대폰 번호입니다.',
              )
              .having(
                (error) => error.request_id,
                'request_id',
                'profile-request-id',
              ),
        ),
      );
    });
  });

  group('AuthRemoteDataSource.completeProfile', () {
    test('필수 기본 정보와 입력한 선택 근무 정보만 완료 endpoint로 전송한다', () async {
      final dio = Dio(
        BaseOptions(baseUrl: 'https://stage-api.shiftmate.co.kr/api/v1'),
      );
      RequestOptions? captured_request;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured_request = options;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {
                    'user_id': 'user-id',
                    'email': 'user@example.com',
                    'name': '김간호',
                    'timezone': 'Asia/Seoul',
                    'phone': '010-1234-5678',
                    'job_type': 'NURSE',
                    'workplace': '제일병원 중환자실',
                    'requires_profile_setup': false,
                  },
                },
              ),
            );
          },
        ),
      );

      final user = await AuthRemoteDataSource(dio).completeProfile(
        name: '김간호',
        timezone: 'Asia/Seoul',
        phone: '01012345678',
        job_type: 'NURSE',
        workplace: '제일병원 중환자실',
      );

      expect(captured_request?.method, 'POST');
      expect(captured_request?.path, ApiConstants.auth_profile_complete);
      expect(captured_request?.data, {
        'name': '김간호',
        'timezone': 'Asia/Seoul',
        'phone': '01012345678',
        'job_type': 'NURSE',
        'workplace': '제일병원 중환자실',
      });
      expect(user.phone, '010-1234-5678');
      expect(user.job_type, 'NURSE');
      expect(user.workplace, '제일병원 중환자실');
      expect(user.requires_profile_setup, isFalse);
    });

    test('선택 근무 정보가 없으면 request body에서 제외한다', () async {
      final dio = Dio();
      RequestOptions? captured_request;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured_request = options;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                data: {
                  'success': true,
                  'data': {
                    'user_id': 'user-id',
                    'email': 'user@example.com',
                    'name': '사용자',
                    'timezone': 'Asia/Seoul',
                    'phone': '010-1234-5678',
                  },
                },
              ),
            );
          },
        ),
      );

      await AuthRemoteDataSource(dio).completeProfile(
        name: '사용자',
        timezone: 'Asia/Seoul',
        phone: '01012345678',
      );

      expect(captured_request?.data, {
        'name': '사용자',
        'timezone': 'Asia/Seoul',
        'phone': '01012345678',
      });
    });
  });

  group('AuthRemoteDataSource Apple 로그인', () {
    test('POST /auth/apple/challenge로 플랫폼을 보내고 challenge를 파싱한다', () async {
      final dio = Dio(
        BaseOptions(baseUrl: 'https://stage-api.shiftmate.co.kr/api/v1'),
      );
      RequestOptions? captured_request;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured_request = options;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {
                    'nonce': 'server-nonce',
                    'state': 'signed-state',
                    'client_id': 'com.hspark.shiftmate.android',
                    'redirect_uri':
                        'https://stage-api.shiftmate.co.kr/api/v1/auth/apple/callback',
                    'expires_at': '2026-08-06T00:05:00.000Z',
                  },
                },
              ),
            );
          },
        ),
      );

      final data_source = AuthRemoteDataSource(dio);
      final challenge = await data_source.createAppleChallenge(
        AppleLoginPlatform.android,
      );

      expect(captured_request?.method, 'POST');
      expect(captured_request?.path, ApiConstants.auth_apple_challenge);
      expect(captured_request?.data, {'platform': 'android'});
      expect(challenge.nonce, 'server-nonce');
      expect(challenge.state, 'signed-state');
      expect(challenge.client_id, 'com.hspark.shiftmate.android');
      expect(
        challenge.redirect_uri,
        Uri.parse(
          'https://stage-api.shiftmate.co.kr/api/v1/auth/apple/callback',
        ),
      );
    });

    test('POST /auth/apple로 검증용 credential을 보내고 신규 여부를 파싱한다', () async {
      final dio = Dio(
        BaseOptions(baseUrl: 'https://stage-api.shiftmate.co.kr/api/v1'),
      );
      RequestOptions? captured_request;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured_request = options;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'message': 'Apple 로그인 성공',
                  'data': {
                    'user': {
                      'user_id': 'apple-user-id',
                      'email': 'relay@privaterelay.appleid.com',
                      'name': 'Apple 사용자',
                      'apple_id': 'apple-subject',
                    },
                    'access_token': 'app-access-token',
                    'refresh_token': 'app-refresh-token',
                    'expires_at': '2026-08-06T01:00:00.000Z',
                    'is_new_user': true,
                  },
                },
              ),
            );
          },
        ),
      );
      const credential = AppleLoginCredential(
        platform: AppleLoginPlatform.ios,
        authorization_code: 'authorization-code',
        identity_token: 'identity-token',
        state: 'signed-state',
        nonce: 'server-nonce',
        given_name: '길동',
        family_name: '홍',
      );

      final data_source = AuthRemoteDataSource(dio);
      final auth_response = await data_source.loginWithApple(credential);

      expect(captured_request?.method, 'POST');
      expect(captured_request?.path, ApiConstants.auth_apple);
      expect(captured_request?.data, {
        'platform': 'ios',
        'authorization_code': 'authorization-code',
        'identity_token': 'identity-token',
        'state': 'signed-state',
        'nonce': 'server-nonce',
        'given_name': '길동',
        'family_name': '홍',
      });
      expect(auth_response.user.apple_id, 'apple-subject');
      expect(auth_response.is_new_user, isTrue);
    });

    test('명시적인 is_new_user boolean을 성공 메시지보다 우선한다', () {
      final response = AuthResponse.fromJson({
        'success': true,
        'message': '회원가입이 완료되었습니다.',
        'data': {
          'user': {
            'user_id': 'existing-user-id',
            'email': 'existing@example.com',
            'name': '기존 사용자',
          },
          'access_token': 'app-access-token',
          'refresh_token': 'app-refresh-token',
          'expires_at': '2026-08-06T01:00:00.000Z',
          'is_new_user': false,
        },
      });

      expect(response.is_new_user, isFalse);
    });
  });
}
