// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserImpl _$$UserImplFromJson(Map<String, dynamic> json) => _$UserImpl(
  id: const RequiredStringOrIntConverter().fromJson(json['user_id']),
  email: json['email'] as String,
  name: json['name'] as String,
  profile_image_url: json['profile_image_url'] as String?,
  timezone: json['timezone'] as String?,
  kakao_id: const StringOrIntConverter().fromJson(json['kakao_id']),
  apple_id: json['apple_id'] as String?,
  created_at: const FlexibleDateTimeConverter().fromJson(json['created_at']),
);

Map<String, dynamic> _$$UserImplToJson(
  _$UserImpl instance,
) => <String, dynamic>{
  'user_id': const RequiredStringOrIntConverter().toJson(instance.id),
  'email': instance.email,
  'name': instance.name,
  'profile_image_url': instance.profile_image_url,
  'timezone': instance.timezone,
  'kakao_id': const StringOrIntConverter().toJson(instance.kakao_id),
  'apple_id': instance.apple_id,
  'created_at': const FlexibleDateTimeConverter().toJson(instance.created_at),
};

_$AuthTokenImpl _$$AuthTokenImplFromJson(Map<String, dynamic> json) =>
    _$AuthTokenImpl(
      access_token: json['access_token'] as String,
      refresh_token: json['refresh_token'] as String,
      expires_at: const RequiredFlexibleDateTimeConverter().fromJson(
        json['expires_at'],
      ),
    );

Map<String, dynamic> _$$AuthTokenImplToJson(_$AuthTokenImpl instance) =>
    <String, dynamic>{
      'access_token': instance.access_token,
      'refresh_token': instance.refresh_token,
      'expires_at': const RequiredFlexibleDateTimeConverter().toJson(
        instance.expires_at,
      ),
    };
