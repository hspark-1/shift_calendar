// ignore_for_file: non_constant_identifier_names

import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/features/calendar/data/models/event_api_model.dart';

void main() {
  test('개인 일정의 공개 여부를 파싱하고 구형 응답은 false로 복원한다', () {
    final json = <String, dynamic>{
      'event_id': 'event-privacy',
      'title': '개인 약속',
      'all_day': false,
      'start_at': '2026-11-11T00:00:00Z',
      'end_at': '2026-11-11T01:00:00Z',
      'visibility_level': 3,
    };
    expect(EventApiModel.fromJson(json).isPrivate, false);
    expect(
      EventApiModel.fromJson({...json, 'is_private': false}).isPrivate,
      false,
    );
    expect(
      EventApiModel.fromJson({...json, 'is_private': true}).isPrivate,
      true,
    );
    expect(
      () => EventApiModel.fromJson({...json, 'is_private': 'true'}),
      throwsA(isA<TypeError>()),
    );
  });

  test('공개와 나만 보기 요청은 boolean을 전송하고 레벨과 UTC를 보존한다', () {
    for (final is_private in [false, true]) {
      final request = CreateEventRequest(
        title: '약속',
        allDay: false,
        startAt: DateTime(2026, 11, 11, 9),
        endAt: DateTime(2026, 11, 11, 10),
        visibilityLevel: 3,
        isPrivate: is_private,
      );
      expect(request.toJson()['is_private'], is_private);
      expect(request.toJson()['visibility_level'], 3);
      expect(
        request.toJson()['start_at'],
        request.startAt.toUtc().toIso8601String(),
      );
    }
  });

  test('자정인 exclusive 종료일에는 종일 일정을 추가하지 않는다', () {
    final events_by_date = <DateTime, List<EventApiModel>>{};
    final event = EventApiModel(
      eventId: 'all-day-event',
      title: '하루 일정',
      allDay: true,
      startAt: DateTime(2026, 7, 16),
      endAt: DateTime(2026, 7, 17),
      visibilityLevel: 0,
    );

    addEventToCalendarDateMap(events_by_date, event);

    expect(events_by_date.keys, [DateTime(2026, 7, 16)]);
  });

  test('같은 일정을 중복 없이 시작 시각 순으로 정렬한다', () {
    final events_by_date = <DateTime, List<EventApiModel>>{};
    final later_event = EventApiModel(
      eventId: 'later-event',
      title: '늦은 일정',
      allDay: false,
      startAt: DateTime(2026, 7, 16, 18),
      endAt: DateTime(2026, 7, 16, 19),
      visibilityLevel: 0,
    );
    final earlier_event = EventApiModel(
      eventId: 'earlier-event',
      title: '이른 일정',
      allDay: false,
      startAt: DateTime(2026, 7, 16, 9),
      endAt: DateTime(2026, 7, 16, 10),
      visibilityLevel: 0,
    );

    addEventToCalendarDateMap(events_by_date, later_event);
    addEventToCalendarDateMap(events_by_date, earlier_event);
    addEventToCalendarDateMap(events_by_date, later_event);

    expect(
      events_by_date[DateTime(2026, 7, 16)]?.map((event) => event.eventId),
      ['earlier-event', 'later-event'],
    );
  });
}
