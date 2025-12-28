import 'package:freezed_annotation/freezed_annotation.dart';

part 'schedule.freezed.dart';
part 'schedule.g.dart';

/// 스케줄 엔티티
@freezed
class Schedule with _$Schedule {
  const factory Schedule({
    required String id,
    required String user_id,
    required DateTime date,
    required String shift_type, // D, E, N, OFF
    String? note,
    @Default(false) bool is_shared,
    DateTime? created_at,
    DateTime? updated_at,
  }) = _Schedule;

  factory Schedule.fromJson(Map<String, dynamic> json) =>
      _$ScheduleFromJson(json);
}

/// 근무 타입 열거형
enum ShiftType {
  @JsonValue('D')
  day('D', '주간'),
  @JsonValue('E')
  evening('E', '저녁'),
  @JsonValue('N')
  night('N', '야간'),
  @JsonValue('OFF')
  off('OFF', '휴무');

  const ShiftType(this.code, this.display_name);

  final String code;
  final String display_name;
}

/// 근무 패턴 엔티티
@freezed
class ShiftPattern with _$ShiftPattern {
  const factory ShiftPattern({
    required String id,
    required String name,
    required List<String> pattern, // ['D', 'D', 'E', 'E', 'N', 'N', 'OFF', 'OFF']
    @Default(false) bool is_default,
  }) = _ShiftPattern;

  factory ShiftPattern.fromJson(Map<String, dynamic> json) =>
      _$ShiftPatternFromJson(json);
}

