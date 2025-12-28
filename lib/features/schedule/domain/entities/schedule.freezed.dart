// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schedule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Schedule _$ScheduleFromJson(Map<String, dynamic> json) {
  return _Schedule.fromJson(json);
}

/// @nodoc
mixin _$Schedule {
  String get id => throw _privateConstructorUsedError;
  String get user_id => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  String get shift_type => throw _privateConstructorUsedError; // D, E, N, OFF
  String? get note => throw _privateConstructorUsedError;
  bool get is_shared => throw _privateConstructorUsedError;
  DateTime? get created_at => throw _privateConstructorUsedError;
  DateTime? get updated_at => throw _privateConstructorUsedError;

  /// Serializes this Schedule to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Schedule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScheduleCopyWith<Schedule> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScheduleCopyWith<$Res> {
  factory $ScheduleCopyWith(Schedule value, $Res Function(Schedule) then) =
      _$ScheduleCopyWithImpl<$Res, Schedule>;
  @useResult
  $Res call({
    String id,
    String user_id,
    DateTime date,
    String shift_type,
    String? note,
    bool is_shared,
    DateTime? created_at,
    DateTime? updated_at,
  });
}

/// @nodoc
class _$ScheduleCopyWithImpl<$Res, $Val extends Schedule>
    implements $ScheduleCopyWith<$Res> {
  _$ScheduleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Schedule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? user_id = null,
    Object? date = null,
    Object? shift_type = null,
    Object? note = freezed,
    Object? is_shared = null,
    Object? created_at = freezed,
    Object? updated_at = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            user_id: null == user_id
                ? _value.user_id
                : user_id // ignore: cast_nullable_to_non_nullable
                      as String,
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            shift_type: null == shift_type
                ? _value.shift_type
                : shift_type // ignore: cast_nullable_to_non_nullable
                      as String,
            note: freezed == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                      as String?,
            is_shared: null == is_shared
                ? _value.is_shared
                : is_shared // ignore: cast_nullable_to_non_nullable
                      as bool,
            created_at: freezed == created_at
                ? _value.created_at
                : created_at // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updated_at: freezed == updated_at
                ? _value.updated_at
                : updated_at // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ScheduleImplCopyWith<$Res>
    implements $ScheduleCopyWith<$Res> {
  factory _$$ScheduleImplCopyWith(
    _$ScheduleImpl value,
    $Res Function(_$ScheduleImpl) then,
  ) = __$$ScheduleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String user_id,
    DateTime date,
    String shift_type,
    String? note,
    bool is_shared,
    DateTime? created_at,
    DateTime? updated_at,
  });
}

/// @nodoc
class __$$ScheduleImplCopyWithImpl<$Res>
    extends _$ScheduleCopyWithImpl<$Res, _$ScheduleImpl>
    implements _$$ScheduleImplCopyWith<$Res> {
  __$$ScheduleImplCopyWithImpl(
    _$ScheduleImpl _value,
    $Res Function(_$ScheduleImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Schedule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? user_id = null,
    Object? date = null,
    Object? shift_type = null,
    Object? note = freezed,
    Object? is_shared = null,
    Object? created_at = freezed,
    Object? updated_at = freezed,
  }) {
    return _then(
      _$ScheduleImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        user_id: null == user_id
            ? _value.user_id
            : user_id // ignore: cast_nullable_to_non_nullable
                  as String,
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        shift_type: null == shift_type
            ? _value.shift_type
            : shift_type // ignore: cast_nullable_to_non_nullable
                  as String,
        note: freezed == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
        is_shared: null == is_shared
            ? _value.is_shared
            : is_shared // ignore: cast_nullable_to_non_nullable
                  as bool,
        created_at: freezed == created_at
            ? _value.created_at
            : created_at // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updated_at: freezed == updated_at
            ? _value.updated_at
            : updated_at // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ScheduleImpl implements _Schedule {
  const _$ScheduleImpl({
    required this.id,
    required this.user_id,
    required this.date,
    required this.shift_type,
    this.note,
    this.is_shared = false,
    this.created_at,
    this.updated_at,
  });

  factory _$ScheduleImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScheduleImplFromJson(json);

  @override
  final String id;
  @override
  final String user_id;
  @override
  final DateTime date;
  @override
  final String shift_type;
  // D, E, N, OFF
  @override
  final String? note;
  @override
  @JsonKey()
  final bool is_shared;
  @override
  final DateTime? created_at;
  @override
  final DateTime? updated_at;

  @override
  String toString() {
    return 'Schedule(id: $id, user_id: $user_id, date: $date, shift_type: $shift_type, note: $note, is_shared: $is_shared, created_at: $created_at, updated_at: $updated_at)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScheduleImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.user_id, user_id) || other.user_id == user_id) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.shift_type, shift_type) ||
                other.shift_type == shift_type) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.is_shared, is_shared) ||
                other.is_shared == is_shared) &&
            (identical(other.created_at, created_at) ||
                other.created_at == created_at) &&
            (identical(other.updated_at, updated_at) ||
                other.updated_at == updated_at));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    user_id,
    date,
    shift_type,
    note,
    is_shared,
    created_at,
    updated_at,
  );

  /// Create a copy of Schedule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScheduleImplCopyWith<_$ScheduleImpl> get copyWith =>
      __$$ScheduleImplCopyWithImpl<_$ScheduleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScheduleImplToJson(this);
  }
}

abstract class _Schedule implements Schedule {
  const factory _Schedule({
    required final String id,
    required final String user_id,
    required final DateTime date,
    required final String shift_type,
    final String? note,
    final bool is_shared,
    final DateTime? created_at,
    final DateTime? updated_at,
  }) = _$ScheduleImpl;

  factory _Schedule.fromJson(Map<String, dynamic> json) =
      _$ScheduleImpl.fromJson;

  @override
  String get id;
  @override
  String get user_id;
  @override
  DateTime get date;
  @override
  String get shift_type; // D, E, N, OFF
  @override
  String? get note;
  @override
  bool get is_shared;
  @override
  DateTime? get created_at;
  @override
  DateTime? get updated_at;

  /// Create a copy of Schedule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScheduleImplCopyWith<_$ScheduleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ShiftPattern _$ShiftPatternFromJson(Map<String, dynamic> json) {
  return _ShiftPattern.fromJson(json);
}

/// @nodoc
mixin _$ShiftPattern {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  List<String> get pattern =>
      throw _privateConstructorUsedError; // ['D', 'D', 'E', 'E', 'N', 'N', 'OFF', 'OFF']
  bool get is_default => throw _privateConstructorUsedError;

  /// Serializes this ShiftPattern to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ShiftPattern
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ShiftPatternCopyWith<ShiftPattern> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShiftPatternCopyWith<$Res> {
  factory $ShiftPatternCopyWith(
    ShiftPattern value,
    $Res Function(ShiftPattern) then,
  ) = _$ShiftPatternCopyWithImpl<$Res, ShiftPattern>;
  @useResult
  $Res call({String id, String name, List<String> pattern, bool is_default});
}

/// @nodoc
class _$ShiftPatternCopyWithImpl<$Res, $Val extends ShiftPattern>
    implements $ShiftPatternCopyWith<$Res> {
  _$ShiftPatternCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ShiftPattern
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? pattern = null,
    Object? is_default = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            pattern: null == pattern
                ? _value.pattern
                : pattern // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            is_default: null == is_default
                ? _value.is_default
                : is_default // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ShiftPatternImplCopyWith<$Res>
    implements $ShiftPatternCopyWith<$Res> {
  factory _$$ShiftPatternImplCopyWith(
    _$ShiftPatternImpl value,
    $Res Function(_$ShiftPatternImpl) then,
  ) = __$$ShiftPatternImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, List<String> pattern, bool is_default});
}

/// @nodoc
class __$$ShiftPatternImplCopyWithImpl<$Res>
    extends _$ShiftPatternCopyWithImpl<$Res, _$ShiftPatternImpl>
    implements _$$ShiftPatternImplCopyWith<$Res> {
  __$$ShiftPatternImplCopyWithImpl(
    _$ShiftPatternImpl _value,
    $Res Function(_$ShiftPatternImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ShiftPattern
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? pattern = null,
    Object? is_default = null,
  }) {
    return _then(
      _$ShiftPatternImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        pattern: null == pattern
            ? _value._pattern
            : pattern // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        is_default: null == is_default
            ? _value.is_default
            : is_default // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ShiftPatternImpl implements _ShiftPattern {
  const _$ShiftPatternImpl({
    required this.id,
    required this.name,
    required final List<String> pattern,
    this.is_default = false,
  }) : _pattern = pattern;

  factory _$ShiftPatternImpl.fromJson(Map<String, dynamic> json) =>
      _$$ShiftPatternImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  final List<String> _pattern;
  @override
  List<String> get pattern {
    if (_pattern is EqualUnmodifiableListView) return _pattern;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_pattern);
  }

  // ['D', 'D', 'E', 'E', 'N', 'N', 'OFF', 'OFF']
  @override
  @JsonKey()
  final bool is_default;

  @override
  String toString() {
    return 'ShiftPattern(id: $id, name: $name, pattern: $pattern, is_default: $is_default)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShiftPatternImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._pattern, _pattern) &&
            (identical(other.is_default, is_default) ||
                other.is_default == is_default));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    const DeepCollectionEquality().hash(_pattern),
    is_default,
  );

  /// Create a copy of ShiftPattern
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ShiftPatternImplCopyWith<_$ShiftPatternImpl> get copyWith =>
      __$$ShiftPatternImplCopyWithImpl<_$ShiftPatternImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ShiftPatternImplToJson(this);
  }
}

abstract class _ShiftPattern implements ShiftPattern {
  const factory _ShiftPattern({
    required final String id,
    required final String name,
    required final List<String> pattern,
    final bool is_default,
  }) = _$ShiftPatternImpl;

  factory _ShiftPattern.fromJson(Map<String, dynamic> json) =
      _$ShiftPatternImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  List<String> get pattern; // ['D', 'D', 'E', 'E', 'N', 'N', 'OFF', 'OFF']
  @override
  bool get is_default;

  /// Create a copy of ShiftPattern
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ShiftPatternImplCopyWith<_$ShiftPatternImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
