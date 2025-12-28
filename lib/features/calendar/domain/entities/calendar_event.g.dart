// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CalendarEventImpl _$$CalendarEventImplFromJson(Map<String, dynamic> json) =>
    _$CalendarEventImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      start_date: DateTime.parse(json['start_date'] as String),
      end_date: DateTime.parse(json['end_date'] as String),
      description: json['description'] as String?,
      color: json['color'] as String?,
      is_all_day: json['is_all_day'] as bool? ?? false,
      is_shared: json['is_shared'] as bool? ?? false,
      created_by: json['created_by'] as String?,
      shared_with: (json['shared_with'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      created_at: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updated_at: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$CalendarEventImplToJson(_$CalendarEventImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'start_date': instance.start_date.toIso8601String(),
      'end_date': instance.end_date.toIso8601String(),
      'description': instance.description,
      'color': instance.color,
      'is_all_day': instance.is_all_day,
      'is_shared': instance.is_shared,
      'created_by': instance.created_by,
      'shared_with': instance.shared_with,
      'created_at': instance.created_at?.toIso8601String(),
      'updated_at': instance.updated_at?.toIso8601String(),
    };

_$SharedScheduleImpl _$$SharedScheduleImplFromJson(Map<String, dynamic> json) =>
    _$SharedScheduleImpl(
      id: json['id'] as String,
      owner_id: json['owner_id'] as String,
      owner_name: json['owner_name'] as String,
      shared_user_ids: (json['shared_user_ids'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      start_date: DateTime.parse(json['start_date'] as String),
      end_date: DateTime.parse(json['end_date'] as String),
      permission: json['permission'] as String? ?? 'view',
      created_at: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$SharedScheduleImplToJson(
  _$SharedScheduleImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'owner_id': instance.owner_id,
  'owner_name': instance.owner_name,
  'shared_user_ids': instance.shared_user_ids,
  'start_date': instance.start_date.toIso8601String(),
  'end_date': instance.end_date.toIso8601String(),
  'permission': instance.permission,
  'created_at': instance.created_at?.toIso8601String(),
};
