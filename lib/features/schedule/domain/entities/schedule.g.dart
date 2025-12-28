// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ScheduleImpl _$$ScheduleImplFromJson(Map<String, dynamic> json) =>
    _$ScheduleImpl(
      id: json['id'] as String,
      user_id: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      shift_type: json['shift_type'] as String,
      note: json['note'] as String?,
      is_shared: json['is_shared'] as bool? ?? false,
      created_at: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updated_at: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$ScheduleImplToJson(_$ScheduleImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.user_id,
      'date': instance.date.toIso8601String(),
      'shift_type': instance.shift_type,
      'note': instance.note,
      'is_shared': instance.is_shared,
      'created_at': instance.created_at?.toIso8601String(),
      'updated_at': instance.updated_at?.toIso8601String(),
    };

_$ShiftPatternImpl _$$ShiftPatternImplFromJson(Map<String, dynamic> json) =>
    _$ShiftPatternImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      pattern: (json['pattern'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      is_default: json['is_default'] as bool? ?? false,
    );

Map<String, dynamic> _$$ShiftPatternImplToJson(_$ShiftPatternImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'pattern': instance.pattern,
      'is_default': instance.is_default,
    };
