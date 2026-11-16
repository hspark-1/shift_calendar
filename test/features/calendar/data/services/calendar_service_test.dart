// ignore_for_file: non_constant_identifier_names

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/core/constants/api_constants.dart';
import 'package:shift_mate/core/network/api_exception.dart';
import 'package:shift_mate/features/calendar/data/services/calendar_service.dart';
import 'package:shift_mate/features/calendar/data/models/event_api_model.dart';

void main() {
  for (final is_private in [false, true]) {
    for (final level in [0, -1, 6]) {
      test(
        '개인 일정 생성/수정은 레벨$level·private=$is_private를 HTTP 전송 전에 차단한다',
        () async {
          final dio = Dio();
          var requests = 0;
          dio.interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                requests++;
                handler.reject(DioException(requestOptions: options));
              },
            ),
          );
          final service = CalendarService(dio);
          final start_at = DateTime(2026, 11, 12, 9);
          final end_at = DateTime(2026, 11, 12, 10);
          final expected = throwsA(
            isA<ApiException>().having(
              (error) => error.code,
              'code',
              'INVALID_VISIBILITY_LEVEL',
            ),
          );
          await expectLater(
            service.createEvent(
              CreateEventRequest(
                title: '약속',
                allDay: false,
                startAt: start_at,
                endAt: end_at,
                visibilityLevel: level,
                isPrivate: is_private,
              ),
            ),
            expected,
          );
          await expectLater(
            service.updateEvent(
              'event',
              UpdateEventRequest(
                title: '약속',
                memo: null,
                place: null,
                allDay: false,
                startAt: start_at,
                endAt: end_at,
                visibilityLevel: level,
                isPrivate: is_private,
              ),
            ),
            expected,
          );
          expect(requests, 0);
        },
      );
    }
    for (final level in [1, 5]) {
      test('개인 일정 생성/수정 경계 레벨$level·private=$is_private를 그대로 전송한다', () async {
        final dio = Dio();
        final requests = <RequestOptions>[];
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests.add(options);
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'event_id': 'event',
                      ...options.data as Map<String, dynamic>,
                    },
                  },
                ),
              );
            },
          ),
        );
        final service = CalendarService(dio);
        final start_at = DateTime(2026, 11, 12, 9);
        final end_at = DateTime(2026, 11, 12, 10);
        final created = await service.createEvent(
          CreateEventRequest(
            title: '약속',
            allDay: false,
            startAt: start_at,
            endAt: end_at,
            visibilityLevel: level,
            isPrivate: is_private,
          ),
        );
        final updated = await service.updateEvent(
          'event',
          UpdateEventRequest(
            title: '약속',
            memo: null,
            place: null,
            allDay: false,
            startAt: start_at,
            endAt: end_at,
            visibilityLevel: level,
            isPrivate: is_private,
          ),
        );
        expect(created.visibilityLevel, level);
        expect(updated.visibilityLevel, level);
        expect(
          requests.map((request) => (request.data as Map)['visibility_level']),
          [level, level],
        );
      });
    }
  }

  group('CalendarService.updateEvent', () {
    for (final invalid in ['none', 'id', 'privacy']) {
      test('PUT 전체 편집/null/UTC와 응답 검증 ($invalid)', () async {
        final dio = Dio();
        RequestOptions? captured;
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              captured = options;
              final data = <String, dynamic>{
                'event_id': invalid == 'id' ? 'other' : 'edit',
                ...options.data as Map<String, dynamic>,
              };
              if (invalid == 'privacy') data.remove('is_private');
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'success': true, 'data': data},
                ),
              );
            },
          ),
        );
        final request = UpdateEventRequest(
          title: '수정',
          memo: null,
          place: null,
          allDay: false,
          startAt: DateTime(2026, 11, 12, 9),
          endAt: DateTime(2026, 11, 12, 10),
          visibilityLevel: 3,
          isPrivate: true,
        );
        final result = CalendarService(dio).updateEvent('edit', request);
        if (invalid == 'none') {
          expect((await result).eventId, 'edit');
        } else {
          await expectLater(
            result,
            throwsA(
              isA<ApiException>().having(
                (error) => error.code,
                'code',
                invalid == 'id'
                    ? 'EVENT_UPDATE_NOT_CONFIRMED'
                    : 'EVENT_PRIVACY_NOT_CONFIRMED',
              ),
            ),
          );
        }
        expect(captured?.method, 'PUT');
        expect(captured?.path, '${ApiConstants.events}/edit');
        expect(captured?.data, request.toJson());
        expect((captured?.data as Map).containsKey('memo'), true);
        expect(
          (captured?.data as Map)['start_at'],
          request.startAt.toUtc().toIso8601String(),
        );
      });
    }
  });

  group('CalendarService.createEvent privacy', () {
    for (final is_private in [false, true]) {
      test('is_private=$is_private 요청과 생성 응답을 보존한다', () async {
        final dio = Dio();
        Map<String, dynamic>? sent;
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              sent = options.data as Map<String, dynamic>;
              handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 201,
                  data: {
                    'success': true,
                    'data': {'event_id': 'event-privacy', ...sent!},
                  },
                ),
              );
            },
          ),
        );
        final result = await CalendarService(dio).createEvent(
          CreateEventRequest(
            title: '약속',
            allDay: false,
            startAt: DateTime(2026, 11, 11, 9),
            endAt: DateTime(2026, 11, 11, 10),
            visibilityLevel: 3,
            isPrivate: is_private,
          ),
        );
        expect(sent?['is_private'], is_private);
        expect(sent?['visibility_level'], 3);
        expect(result.isPrivate, is_private);
      });
    }
    for (final response_privacy in [null, false]) {
      test('private 요청 응답이 $response_privacy면 성공 처리하지 않는다', () async {
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              final data = Map<String, dynamic>.from(options.data as Map);
              data.remove('is_private');
              if (response_privacy != null) {
                data['is_private'] = response_privacy;
              }
              handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 201,
                  data: {
                    'success': true,
                    'data': {'event_id': 'event-privacy', ...data},
                  },
                ),
              );
            },
          ),
        );
        await expectLater(
          CalendarService(dio).createEvent(
            CreateEventRequest(
              title: '개인 약속',
              allDay: false,
              startAt: DateTime(2026, 11, 11, 9),
              endAt: DateTime(2026, 11, 11, 10),
              visibilityLevel: 1,
              isPrivate: true,
            ),
          ),
          throwsA(
            isA<ApiException>().having(
              (error) => error.code,
              'code',
              'EVENT_PRIVACY_NOT_CONFIRMED',
            ),
          ),
        );
      });
    }
  });

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
