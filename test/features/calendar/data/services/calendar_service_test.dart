// ignore_for_file: non_constant_identifier_names

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/core/constants/api_constants.dart';
import 'package:shift_mate/core/network/api_exception.dart';
import 'package:shift_mate/features/calendar/data/services/calendar_service.dart';

void main() {
  group('CalendarService.deleteEvent', () {
    test('body 없이 DELETE 요청하고 응답 event_id를 반환한다', () async {
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
                  'data': {'event_id': 'event-id'},
                  'message': '일정이 삭제되었습니다.',
                },
              ),
            );
          },
        ),
      );

      final deleted_event_id = await CalendarService(
        dio,
      ).deleteEvent('event-id');

      expect(captured_request?.method, 'DELETE');
      expect(captured_request?.path, '${ApiConstants.events}/event-id');
      expect(captured_request?.data, isNull);
      expect(deleted_event_id, 'event-id');
    });

    test('EVENT_NOT_FOUND와 상태 코드를 ApiException으로 보존한다', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 404,
                  data: {
                    'success': false,
                    'error': {
                      'code': 'EVENT_NOT_FOUND',
                      'message': '일정을 찾을 수 없습니다.',
                    },
                  },
                ),
              ),
            );
          },
        ),
      );

      await expectLater(
        CalendarService(dio).deleteEvent('event-id'),
        throwsA(
          isA<ApiException>()
              .having((error) => error.code, 'code', 'EVENT_NOT_FOUND')
              .having((error) => error.statusCode, 'statusCode', 404),
        ),
      );
    });
  });
}
