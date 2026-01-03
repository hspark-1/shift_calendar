// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

User _$UserFromJson(Map<String, dynamic> json) {
  return _User.fromJson(json);
}

/// @nodoc
mixin _$User {
  // ignore: invalid_annotation_target
  @JsonKey(name: 'user_id')
  @RequiredStringOrIntConverter()
  String get id => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get profile_image_url => throw _privateConstructorUsedError;
  String? get timezone => throw _privateConstructorUsedError;
  @StringOrIntConverter()
  String? get kakao_id => throw _privateConstructorUsedError;
  String? get apple_id => throw _privateConstructorUsedError;
  @FlexibleDateTimeConverter()
  DateTime? get created_at => throw _privateConstructorUsedError;

  /// Serializes this User to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserCopyWith<User> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserCopyWith<$Res> {
  factory $UserCopyWith(User value, $Res Function(User) then) =
      _$UserCopyWithImpl<$Res, User>;
  @useResult
  $Res call({
    @JsonKey(name: 'user_id') @RequiredStringOrIntConverter() String id,
    String email,
    String name,
    String? profile_image_url,
    String? timezone,
    @StringOrIntConverter() String? kakao_id,
    String? apple_id,
    @FlexibleDateTimeConverter() DateTime? created_at,
  });
}

/// @nodoc
class _$UserCopyWithImpl<$Res, $Val extends User>
    implements $UserCopyWith<$Res> {
  _$UserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? name = null,
    Object? profile_image_url = freezed,
    Object? timezone = freezed,
    Object? kakao_id = freezed,
    Object? apple_id = freezed,
    Object? created_at = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            profile_image_url: freezed == profile_image_url
                ? _value.profile_image_url
                : profile_image_url // ignore: cast_nullable_to_non_nullable
                      as String?,
            timezone: freezed == timezone
                ? _value.timezone
                : timezone // ignore: cast_nullable_to_non_nullable
                      as String?,
            kakao_id: freezed == kakao_id
                ? _value.kakao_id
                : kakao_id // ignore: cast_nullable_to_non_nullable
                      as String?,
            apple_id: freezed == apple_id
                ? _value.apple_id
                : apple_id // ignore: cast_nullable_to_non_nullable
                      as String?,
            created_at: freezed == created_at
                ? _value.created_at
                : created_at // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserImplCopyWith<$Res> implements $UserCopyWith<$Res> {
  factory _$$UserImplCopyWith(
    _$UserImpl value,
    $Res Function(_$UserImpl) then,
  ) = __$$UserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'user_id') @RequiredStringOrIntConverter() String id,
    String email,
    String name,
    String? profile_image_url,
    String? timezone,
    @StringOrIntConverter() String? kakao_id,
    String? apple_id,
    @FlexibleDateTimeConverter() DateTime? created_at,
  });
}

/// @nodoc
class __$$UserImplCopyWithImpl<$Res>
    extends _$UserCopyWithImpl<$Res, _$UserImpl>
    implements _$$UserImplCopyWith<$Res> {
  __$$UserImplCopyWithImpl(_$UserImpl _value, $Res Function(_$UserImpl) _then)
    : super(_value, _then);

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? name = null,
    Object? profile_image_url = freezed,
    Object? timezone = freezed,
    Object? kakao_id = freezed,
    Object? apple_id = freezed,
    Object? created_at = freezed,
  }) {
    return _then(
      _$UserImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        profile_image_url: freezed == profile_image_url
            ? _value.profile_image_url
            : profile_image_url // ignore: cast_nullable_to_non_nullable
                  as String?,
        timezone: freezed == timezone
            ? _value.timezone
            : timezone // ignore: cast_nullable_to_non_nullable
                  as String?,
        kakao_id: freezed == kakao_id
            ? _value.kakao_id
            : kakao_id // ignore: cast_nullable_to_non_nullable
                  as String?,
        apple_id: freezed == apple_id
            ? _value.apple_id
            : apple_id // ignore: cast_nullable_to_non_nullable
                  as String?,
        created_at: freezed == created_at
            ? _value.created_at
            : created_at // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserImpl implements _User {
  const _$UserImpl({
    @JsonKey(name: 'user_id') @RequiredStringOrIntConverter() required this.id,
    required this.email,
    required this.name,
    this.profile_image_url,
    this.timezone,
    @StringOrIntConverter() this.kakao_id,
    this.apple_id,
    @FlexibleDateTimeConverter() this.created_at,
  });

  factory _$UserImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserImplFromJson(json);

  // ignore: invalid_annotation_target
  @override
  @JsonKey(name: 'user_id')
  @RequiredStringOrIntConverter()
  final String id;
  @override
  final String email;
  @override
  final String name;
  @override
  final String? profile_image_url;
  @override
  final String? timezone;
  @override
  @StringOrIntConverter()
  final String? kakao_id;
  @override
  final String? apple_id;
  @override
  @FlexibleDateTimeConverter()
  final DateTime? created_at;

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, profile_image_url: $profile_image_url, timezone: $timezone, kakao_id: $kakao_id, apple_id: $apple_id, created_at: $created_at)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.profile_image_url, profile_image_url) ||
                other.profile_image_url == profile_image_url) &&
            (identical(other.timezone, timezone) ||
                other.timezone == timezone) &&
            (identical(other.kakao_id, kakao_id) ||
                other.kakao_id == kakao_id) &&
            (identical(other.apple_id, apple_id) ||
                other.apple_id == apple_id) &&
            (identical(other.created_at, created_at) ||
                other.created_at == created_at));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    email,
    name,
    profile_image_url,
    timezone,
    kakao_id,
    apple_id,
    created_at,
  );

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      __$$UserImplCopyWithImpl<_$UserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserImplToJson(this);
  }
}

abstract class _User implements User {
  const factory _User({
    @JsonKey(name: 'user_id')
    @RequiredStringOrIntConverter()
    required final String id,
    required final String email,
    required final String name,
    final String? profile_image_url,
    final String? timezone,
    @StringOrIntConverter() final String? kakao_id,
    final String? apple_id,
    @FlexibleDateTimeConverter() final DateTime? created_at,
  }) = _$UserImpl;

  factory _User.fromJson(Map<String, dynamic> json) = _$UserImpl.fromJson;

  // ignore: invalid_annotation_target
  @override
  @JsonKey(name: 'user_id')
  @RequiredStringOrIntConverter()
  String get id;
  @override
  String get email;
  @override
  String get name;
  @override
  String? get profile_image_url;
  @override
  String? get timezone;
  @override
  @StringOrIntConverter()
  String? get kakao_id;
  @override
  String? get apple_id;
  @override
  @FlexibleDateTimeConverter()
  DateTime? get created_at;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AuthToken _$AuthTokenFromJson(Map<String, dynamic> json) {
  return _AuthToken.fromJson(json);
}

/// @nodoc
mixin _$AuthToken {
  String get access_token => throw _privateConstructorUsedError;
  String get refresh_token => throw _privateConstructorUsedError;
  @RequiredFlexibleDateTimeConverter()
  DateTime get expires_at => throw _privateConstructorUsedError;

  /// Serializes this AuthToken to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AuthToken
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuthTokenCopyWith<AuthToken> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthTokenCopyWith<$Res> {
  factory $AuthTokenCopyWith(AuthToken value, $Res Function(AuthToken) then) =
      _$AuthTokenCopyWithImpl<$Res, AuthToken>;
  @useResult
  $Res call({
    String access_token,
    String refresh_token,
    @RequiredFlexibleDateTimeConverter() DateTime expires_at,
  });
}

/// @nodoc
class _$AuthTokenCopyWithImpl<$Res, $Val extends AuthToken>
    implements $AuthTokenCopyWith<$Res> {
  _$AuthTokenCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthToken
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? access_token = null,
    Object? refresh_token = null,
    Object? expires_at = null,
  }) {
    return _then(
      _value.copyWith(
            access_token: null == access_token
                ? _value.access_token
                : access_token // ignore: cast_nullable_to_non_nullable
                      as String,
            refresh_token: null == refresh_token
                ? _value.refresh_token
                : refresh_token // ignore: cast_nullable_to_non_nullable
                      as String,
            expires_at: null == expires_at
                ? _value.expires_at
                : expires_at // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AuthTokenImplCopyWith<$Res>
    implements $AuthTokenCopyWith<$Res> {
  factory _$$AuthTokenImplCopyWith(
    _$AuthTokenImpl value,
    $Res Function(_$AuthTokenImpl) then,
  ) = __$$AuthTokenImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String access_token,
    String refresh_token,
    @RequiredFlexibleDateTimeConverter() DateTime expires_at,
  });
}

/// @nodoc
class __$$AuthTokenImplCopyWithImpl<$Res>
    extends _$AuthTokenCopyWithImpl<$Res, _$AuthTokenImpl>
    implements _$$AuthTokenImplCopyWith<$Res> {
  __$$AuthTokenImplCopyWithImpl(
    _$AuthTokenImpl _value,
    $Res Function(_$AuthTokenImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthToken
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? access_token = null,
    Object? refresh_token = null,
    Object? expires_at = null,
  }) {
    return _then(
      _$AuthTokenImpl(
        access_token: null == access_token
            ? _value.access_token
            : access_token // ignore: cast_nullable_to_non_nullable
                  as String,
        refresh_token: null == refresh_token
            ? _value.refresh_token
            : refresh_token // ignore: cast_nullable_to_non_nullable
                  as String,
        expires_at: null == expires_at
            ? _value.expires_at
            : expires_at // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AuthTokenImpl implements _AuthToken {
  const _$AuthTokenImpl({
    required this.access_token,
    required this.refresh_token,
    @RequiredFlexibleDateTimeConverter() required this.expires_at,
  });

  factory _$AuthTokenImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuthTokenImplFromJson(json);

  @override
  final String access_token;
  @override
  final String refresh_token;
  @override
  @RequiredFlexibleDateTimeConverter()
  final DateTime expires_at;

  @override
  String toString() {
    return 'AuthToken(access_token: $access_token, refresh_token: $refresh_token, expires_at: $expires_at)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthTokenImpl &&
            (identical(other.access_token, access_token) ||
                other.access_token == access_token) &&
            (identical(other.refresh_token, refresh_token) ||
                other.refresh_token == refresh_token) &&
            (identical(other.expires_at, expires_at) ||
                other.expires_at == expires_at));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, access_token, refresh_token, expires_at);

  /// Create a copy of AuthToken
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthTokenImplCopyWith<_$AuthTokenImpl> get copyWith =>
      __$$AuthTokenImplCopyWithImpl<_$AuthTokenImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AuthTokenImplToJson(this);
  }
}

abstract class _AuthToken implements AuthToken {
  const factory _AuthToken({
    required final String access_token,
    required final String refresh_token,
    @RequiredFlexibleDateTimeConverter() required final DateTime expires_at,
  }) = _$AuthTokenImpl;

  factory _AuthToken.fromJson(Map<String, dynamic> json) =
      _$AuthTokenImpl.fromJson;

  @override
  String get access_token;
  @override
  String get refresh_token;
  @override
  @RequiredFlexibleDateTimeConverter()
  DateTime get expires_at;

  /// Create a copy of AuthToken
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthTokenImplCopyWith<_$AuthTokenImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$AuthResponse {
  User get user => throw _privateConstructorUsedError;
  String get access_token => throw _privateConstructorUsedError;
  String get refresh_token => throw _privateConstructorUsedError;
  DateTime get expires_at => throw _privateConstructorUsedError;
  bool get is_new_user => throw _privateConstructorUsedError;

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuthResponseCopyWith<AuthResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthResponseCopyWith<$Res> {
  factory $AuthResponseCopyWith(
    AuthResponse value,
    $Res Function(AuthResponse) then,
  ) = _$AuthResponseCopyWithImpl<$Res, AuthResponse>;
  @useResult
  $Res call({
    User user,
    String access_token,
    String refresh_token,
    DateTime expires_at,
    bool is_new_user,
  });

  $UserCopyWith<$Res> get user;
}

/// @nodoc
class _$AuthResponseCopyWithImpl<$Res, $Val extends AuthResponse>
    implements $AuthResponseCopyWith<$Res> {
  _$AuthResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? user = null,
    Object? access_token = null,
    Object? refresh_token = null,
    Object? expires_at = null,
    Object? is_new_user = null,
  }) {
    return _then(
      _value.copyWith(
            user: null == user
                ? _value.user
                : user // ignore: cast_nullable_to_non_nullable
                      as User,
            access_token: null == access_token
                ? _value.access_token
                : access_token // ignore: cast_nullable_to_non_nullable
                      as String,
            refresh_token: null == refresh_token
                ? _value.refresh_token
                : refresh_token // ignore: cast_nullable_to_non_nullable
                      as String,
            expires_at: null == expires_at
                ? _value.expires_at
                : expires_at // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            is_new_user: null == is_new_user
                ? _value.is_new_user
                : is_new_user // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserCopyWith<$Res> get user {
    return $UserCopyWith<$Res>(_value.user, (value) {
      return _then(_value.copyWith(user: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AuthResponseImplCopyWith<$Res>
    implements $AuthResponseCopyWith<$Res> {
  factory _$$AuthResponseImplCopyWith(
    _$AuthResponseImpl value,
    $Res Function(_$AuthResponseImpl) then,
  ) = __$$AuthResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    User user,
    String access_token,
    String refresh_token,
    DateTime expires_at,
    bool is_new_user,
  });

  @override
  $UserCopyWith<$Res> get user;
}

/// @nodoc
class __$$AuthResponseImplCopyWithImpl<$Res>
    extends _$AuthResponseCopyWithImpl<$Res, _$AuthResponseImpl>
    implements _$$AuthResponseImplCopyWith<$Res> {
  __$$AuthResponseImplCopyWithImpl(
    _$AuthResponseImpl _value,
    $Res Function(_$AuthResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? user = null,
    Object? access_token = null,
    Object? refresh_token = null,
    Object? expires_at = null,
    Object? is_new_user = null,
  }) {
    return _then(
      _$AuthResponseImpl(
        user: null == user
            ? _value.user
            : user // ignore: cast_nullable_to_non_nullable
                  as User,
        access_token: null == access_token
            ? _value.access_token
            : access_token // ignore: cast_nullable_to_non_nullable
                  as String,
        refresh_token: null == refresh_token
            ? _value.refresh_token
            : refresh_token // ignore: cast_nullable_to_non_nullable
                  as String,
        expires_at: null == expires_at
            ? _value.expires_at
            : expires_at // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        is_new_user: null == is_new_user
            ? _value.is_new_user
            : is_new_user // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$AuthResponseImpl implements _AuthResponse {
  const _$AuthResponseImpl({
    required this.user,
    required this.access_token,
    required this.refresh_token,
    required this.expires_at,
    required this.is_new_user,
  });

  @override
  final User user;
  @override
  final String access_token;
  @override
  final String refresh_token;
  @override
  final DateTime expires_at;
  @override
  final bool is_new_user;

  @override
  String toString() {
    return 'AuthResponse(user: $user, access_token: $access_token, refresh_token: $refresh_token, expires_at: $expires_at, is_new_user: $is_new_user)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthResponseImpl &&
            (identical(other.user, user) || other.user == user) &&
            (identical(other.access_token, access_token) ||
                other.access_token == access_token) &&
            (identical(other.refresh_token, refresh_token) ||
                other.refresh_token == refresh_token) &&
            (identical(other.expires_at, expires_at) ||
                other.expires_at == expires_at) &&
            (identical(other.is_new_user, is_new_user) ||
                other.is_new_user == is_new_user));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    user,
    access_token,
    refresh_token,
    expires_at,
    is_new_user,
  );

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthResponseImplCopyWith<_$AuthResponseImpl> get copyWith =>
      __$$AuthResponseImplCopyWithImpl<_$AuthResponseImpl>(this, _$identity);
}

abstract class _AuthResponse implements AuthResponse {
  const factory _AuthResponse({
    required final User user,
    required final String access_token,
    required final String refresh_token,
    required final DateTime expires_at,
    required final bool is_new_user,
  }) = _$AuthResponseImpl;

  @override
  User get user;
  @override
  String get access_token;
  @override
  String get refresh_token;
  @override
  DateTime get expires_at;
  @override
  bool get is_new_user;

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthResponseImplCopyWith<_$AuthResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
