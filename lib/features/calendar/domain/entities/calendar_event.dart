import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_event.freezed.dart';
part 'calendar_event.g.dart';

/// 캘린더 이벤트 엔티티
@freezed
class CalendarEvent with _$CalendarEvent {
  const factory CalendarEvent({
    required String id,
    required String title,
    required DateTime start_date,
    required DateTime end_date,
    String? description,
    String? color,
    @Default(false) bool is_all_day,
    @Default(false) bool is_shared,
    String? created_by,
    List<String>? shared_with,
    DateTime? created_at,
    DateTime? updated_at,
  }) = _CalendarEvent;

  factory CalendarEvent.fromJson(Map<String, dynamic> json) =>
      _$CalendarEventFromJson(json);
}

/// 공유 일정
@freezed
class SharedSchedule with _$SharedSchedule {
  const factory SharedSchedule({
    required String id,
    required String owner_id,
    required String owner_name,
    required List<String> shared_user_ids,
    required DateTime start_date,
    required DateTime end_date,
    @Default('view') String permission, // 'view', 'edit'
    DateTime? created_at,
  }) = _SharedSchedule;

  factory SharedSchedule.fromJson(Map<String, dynamic> json) =>
      _$SharedScheduleFromJson(json);
}

