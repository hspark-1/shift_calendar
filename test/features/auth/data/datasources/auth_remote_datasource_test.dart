// ignore_for_file: non_constant_identifier_names

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/core/constants/api_constants.dart';
import 'package:shift_mate/features/auth/data/datasources/auth_remote_datasource.dart';

void main() {
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
  });
}
