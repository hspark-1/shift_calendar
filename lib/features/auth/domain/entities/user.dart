import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// 사용자 엔티티
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    required String name,
    String? profile_image_url,
    String? department,
    DateTime? created_at,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

/// 인증 토큰
@freezed
class AuthToken with _$AuthToken {
  const factory AuthToken({
    required String access_token,
    required String refresh_token,
    required DateTime expires_at,
  }) = _AuthToken;

  factory AuthToken.fromJson(Map<String, dynamic> json) =>
      _$AuthTokenFromJson(json);
}

