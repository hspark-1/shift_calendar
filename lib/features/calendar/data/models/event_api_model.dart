// ignore_for_file: non_constant_identifier_names

import 'work_shift_api_model.dart';

/// API 응답의 일정 정보 모델
class EventApiModel {
  final String eventId;
  final String title;
  final String? memo;
  final String? place;
  final bool allDay;
  final DateTime startAt;
  final DateTime endAt;
  final int visibilityLevel;

  EventApiModel({
    required this.eventId,
    required this.title,
    this.memo,
    this.place,
    required this.allDay,
    required this.startAt,
    required this.endAt,
    required this.visibilityLevel,
  });

  factory EventApiModel.fromJson(Map<String, dynamic> json) {
    return EventApiModel(
      eventId: json['event_id'] as String,
      title: json['title'] as String,
      memo: json['memo'] as String?,
      place: json['place'] as String?,
      allDay: json['all_day'] as bool,
      startAt: DateTime.parse(json['start_at'] as String).toLocal(),
      endAt: DateTime.parse(json['end_at'] as String).toLocal(),
      visibilityLevel: json['visibility_level'] as int,
    );
  }
}

DateTime normalizeCalendarDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

/// 일정 기간을 날짜별 맵에 반영한다. `end_at`은 API 계약상 exclusive다.
void addEventToCalendarDateMap(
  Map<DateTime, List<EventApiModel>> events_by_date,
  EventApiModel event,
) {
  final start_date = normalizeCalendarDate(event.startAt);
  var end_date = normalizeCalendarDate(event.endAt);
  final ends_at_midnight =
      event.endAt.hour == 0 &&
      event.endAt.minute == 0 &&
      event.endAt.second == 0 &&
      event.endAt.millisecond == 0 &&
      event.endAt.microsecond == 0;

  if (ends_at_midnight) {
    end_date = end_date.subtract(const Duration(days: 1));
  }
  if (end_date.isBefore(start_date)) {
    end_date = start_date;
  }

  var current_date = start_date;
  while (current_date.isBefore(end_date) ||
      current_date.isAtSameMomentAs(end_date)) {
    final event_list = events_by_date.putIfAbsent(current_date, () => []);
    event_list.removeWhere((item) => item.eventId == event.eventId);
    event_list.add(event);
    event_list.sort((a, b) => a.startAt.compareTo(b.startAt));
    current_date = current_date.add(const Duration(days: 1));
  }
}

/// 개인 일정 생성 요청
class CreateEventRequest {
  final String title;
  final String? memo;
  final String? place;
  final bool allDay;
  final DateTime startAt;
  final DateTime endAt;
  final int visibilityLevel;

  CreateEventRequest({
    required this.title,
    this.memo,
    this.place,
    required this.allDay,
    required this.startAt,
    required this.endAt,
    required this.visibilityLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      if (memo != null && memo!.isNotEmpty) 'memo': memo,
      if (place != null && place!.isNotEmpty) 'place': place,
      'all_day': allDay,
      'start_at': startAt.toUtc().toIso8601String(),
      'end_at': endAt.toUtc().toIso8601String(),
      'visibility_level': visibilityLevel,
    };
  }
}

/// 일별 일정 응답 데이터
class DayScheduleData {
  final DateTime date;
  final List<WorkShiftApiModel> workShifts;
  final List<EventApiModel> events;

  DayScheduleData({
    required this.date,
    required this.workShifts,
    required this.events,
  });

  factory DayScheduleData.fromJson(Map<String, dynamic> json) {
    return DayScheduleData(
      date: DateTime.parse(json['date'] as String),
      workShifts: (json['work_shifts'] as List)
          .map((e) => WorkShiftApiModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      events: (json['events'] as List)
          .map((e) => EventApiModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// 일별 일정 응답
class DayScheduleResponse {
  final bool success;
  final DayScheduleData data;

  DayScheduleResponse({required this.success, required this.data});

  factory DayScheduleResponse.fromJson(Map<String, dynamic> json) {
    return DayScheduleResponse(
      success: json['success'] as bool,
      data: DayScheduleData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

/// 기간별 일정 응답 데이터
class EventsData {
  final List<EventApiModel> events;

  EventsData({required this.events});

  factory EventsData.fromJson(Map<String, dynamic> json) {
    return EventsData(
      events: (json['events'] as List)
          .map((e) => EventApiModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// 기간별 일정 응답
class EventsResponse {
  final bool success;
  final EventsData data;

  EventsResponse({required this.success, required this.data});

  factory EventsResponse.fromJson(Map<String, dynamic> json) {
    return EventsResponse(
      success: json['success'] as bool,
      data: EventsData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

/// 통합 캘린더 데이터 (근무표 + 일정)
class CalendarRangeData {
  final List<WorkShiftApiModel> workShifts;
  final List<EventApiModel> events;

  CalendarRangeData({required this.workShifts, required this.events});

  factory CalendarRangeData.fromJson(Map<String, dynamic> json) {
    return CalendarRangeData(
      workShifts: (json['work_shifts'] as List)
          .map((e) => WorkShiftApiModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      events: (json['events'] as List)
          .map((e) => EventApiModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// 통합 캘린더 응답
class CalendarRangeResponse {
  final bool success;
  final CalendarRangeData data;

  CalendarRangeResponse({required this.success, required this.data});

  factory CalendarRangeResponse.fromJson(Map<String, dynamic> json) {
    return CalendarRangeResponse(
      success: json['success'] as bool,
      data: CalendarRangeData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}
