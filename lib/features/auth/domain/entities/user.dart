// ignore_for_file: invalid_annotation_target, non_constant_identifier_names

import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// int 또는 String을 String?으로 변환하는 JsonConverter
class StringOrIntConverter implements JsonConverter<String?, dynamic> {
  const StringOrIntConverter();

  @override
  String? fromJson(dynamic json) {
    if (json == null) return null;
    return json.toString();
  }

  @override
  dynamic toJson(String? object) => object;
}

/// int 또는 String을 non-null String으로 변환하는 JsonConverter
class RequiredStringOrIntConverter implements JsonConverter<String, dynamic> {
  const RequiredStringOrIntConverter();

  @override
  String fromJson(dynamic json) {
    if (json == null) {
      throw ArgumentError('Required field cannot be null');
    }
    return json.toString();
  }

  @override
  dynamic toJson(String object) => object;
}

/// int(Unix timestamp) 또는 String(ISO 8601)을 DateTime?으로 변환하는 JsonConverter
class FlexibleDateTimeConverter implements JsonConverter<DateTime?, dynamic> {
  const FlexibleDateTimeConverter();

  @override
  DateTime? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is int) {
      // Unix timestamp (초 단위)를 DateTime으로 변환
      return DateTime.fromMillisecondsSinceEpoch(json * 1000, isUtc: true);
    }
    if (json is String) {
      return DateTime.parse(json);
    }
    return null;
  }

  @override
  dynamic toJson(DateTime? object) => object?.toIso8601String();
}

/// int(Unix timestamp milliseconds) 또는 String(ISO 8601)을 non-null DateTime으로 변환
class RequiredFlexibleDateTimeConverter
    implements JsonConverter<DateTime, dynamic> {
  const RequiredFlexibleDateTimeConverter();

  @override
  DateTime fromJson(dynamic json) {
    if (json == null) {
      throw ArgumentError('Required DateTime field cannot be null');
    }
    if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json, isUtc: true);
    }
    if (json is String) {
      return DateTime.parse(json);
    }
    throw ArgumentError('Invalid DateTime format: $json');
  }

  @override
  dynamic toJson(DateTime object) => object.toIso8601String();
}

/// 사용자 엔티티
@freezed
class User with _$User {
  const factory User({
    @JsonKey(name: 'user_id')
    @RequiredStringOrIntConverter()
    required String id,
    required String email,
    required String name,
    String? profile_image_url,
    String? timezone,
    @StringOrIntConverter() String? kakao_id,
    String? apple_id,
    String? google_id,
    @FlexibleDateTimeConverter() DateTime? created_at,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

/// 인증 토큰
@freezed
class AuthToken with _$AuthToken {
  const factory AuthToken({
    required String access_token,
    required String refresh_token,
    @RequiredFlexibleDateTimeConverter() required DateTime expires_at,
  }) = _AuthToken;

  factory AuthToken.fromJson(Map<String, dynamic> json) =>
      _$AuthTokenFromJson(json);
}

/// 인증 응답 (로그인/회원가입)
@freezed
class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    required User user,
    required String access_token,
    required String refresh_token,
    required DateTime expires_at,
    required bool is_new_user,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    // 신규 계약의 명시적 boolean을 우선하고 기존 서버 메시지는 호환용으로만 사용한다.
    final message = json['message'] as String? ?? '';
    final isNewUser =
        data['is_new_user'] as bool? ??
        json['is_new_user'] as bool? ??
        message.contains('회원가입');

    // expires_at이 int(Unix timestamp) 또는 String(ISO 8601)일 수 있음
    final expiresAtRaw = data['expires_at'];
    final DateTime expiresAt;
    if (expiresAtRaw is int) {
      expiresAt = DateTime.fromMillisecondsSinceEpoch(
        expiresAtRaw,
        isUtc: true,
      );
    } else {
      expiresAt = DateTime.parse(expiresAtRaw as String);
    }

    return AuthResponse(
      user: User.fromJson(data['user'] as Map<String, dynamic>),
      access_token: data['access_token'] as String,
      refresh_token: data['refresh_token'] as String,
      expires_at: expiresAt,
      is_new_user: isNewUser,
    );
  }
}
