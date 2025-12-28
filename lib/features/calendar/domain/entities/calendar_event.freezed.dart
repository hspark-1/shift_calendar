// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'calendar_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CalendarEvent _$CalendarEventFromJson(Map<String, dynamic> json) {
  return _CalendarEvent.fromJson(json);
}

/// @nodoc
mixin _$CalendarEvent {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  DateTime get start_date => throw _privateConstructorUsedError;
  DateTime get end_date => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get color => throw _privateConstructorUsedError;
  bool get is_all_day => throw _privateConstructorUsedError;
  bool get is_shared => throw _privateConstructorUsedError;
  String? get created_by => throw _privateConstructorUsedError;
  List<String>? get shared_with => throw _privateConstructorUsedError;
  DateTime? get created_at => throw _privateConstructorUsedError;
  DateTime? get updated_at => throw _privateConstructorUsedError;

  /// Serializes this CalendarEvent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CalendarEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CalendarEventCopyWith<CalendarEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CalendarEventCopyWith<$Res> {
  factory $CalendarEventCopyWith(
    CalendarEvent value,
    $Res Function(CalendarEvent) then,
  ) = _$CalendarEventCopyWithImpl<$Res, CalendarEvent>;
  @useResult
  $Res call({
    String id,
    String title,
    DateTime start_date,
    DateTime end_date,
    String? description,
    String? color,
    bool is_all_day,
    bool is_shared,
    String? created_by,
    List<String>? shared_with,
    DateTime? created_at,
    DateTime? updated_at,
  });
}

/// @nodoc
class _$CalendarEventCopyWithImpl<$Res, $Val extends CalendarEvent>
    implements $CalendarEventCopyWith<$Res> {
  _$CalendarEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CalendarEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? start_date = null,
    Object? end_date = null,
    Object? description = freezed,
    Object? color = freezed,
    Object? is_all_day = null,
    Object? is_shared = null,
    Object? created_by = freezed,
    Object? shared_with = freezed,
    Object? created_at = freezed,
    Object? updated_at = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            start_date: null == start_date
                ? _value.start_date
                : start_date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            end_date: null == end_date
                ? _value.end_date
                : end_date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            color: freezed == color
                ? _value.color
                : color // ignore: cast_nullable_to_non_nullable
                      as String?,
            is_all_day: null == is_all_day
                ? _value.is_all_day
                : is_all_day // ignore: cast_nullable_to_non_nullable
                      as bool,
            is_shared: null == is_shared
                ? _value.is_shared
                : is_shared // ignore: cast_nullable_to_non_nullable
                      as bool,
            created_by: freezed == created_by
                ? _value.created_by
                : created_by // ignore: cast_nullable_to_non_nullable
                      as String?,
            shared_with: freezed == shared_with
                ? _value.shared_with
                : shared_with // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
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
abstract class _$$CalendarEventImplCopyWith<$Res>
    implements $CalendarEventCopyWith<$Res> {
  factory _$$CalendarEventImplCopyWith(
    _$CalendarEventImpl value,
    $Res Function(_$CalendarEventImpl) then,
  ) = __$$CalendarEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    DateTime start_date,
    DateTime end_date,
    String? description,
    String? color,
    bool is_all_day,
    bool is_shared,
    String? created_by,
    List<String>? shared_with,
    DateTime? created_at,
    DateTime? updated_at,
  });
}

/// @nodoc
class __$$CalendarEventImplCopyWithImpl<$Res>
    extends _$CalendarEventCopyWithImpl<$Res, _$CalendarEventImpl>
    implements _$$CalendarEventImplCopyWith<$Res> {
  __$$CalendarEventImplCopyWithImpl(
    _$CalendarEventImpl _value,
    $Res Function(_$CalendarEventImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CalendarEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? start_date = null,
    Object? end_date = null,
    Object? description = freezed,
    Object? color = freezed,
    Object? is_all_day = null,
    Object? is_shared = null,
    Object? created_by = freezed,
    Object? shared_with = freezed,
    Object? created_at = freezed,
    Object? updated_at = freezed,
  }) {
    return _then(
      _$CalendarEventImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        start_date: null == start_date
            ? _value.start_date
            : start_date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        end_date: null == end_date
            ? _value.end_date
            : end_date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        color: freezed == color
            ? _value.color
            : color // ignore: cast_nullable_to_non_nullable
                  as String?,
        is_all_day: null == is_all_day
            ? _value.is_all_day
            : is_all_day // ignore: cast_nullable_to_non_nullable
                  as bool,
        is_shared: null == is_shared
            ? _value.is_shared
            : is_shared // ignore: cast_nullable_to_non_nullable
                  as bool,
        created_by: freezed == created_by
            ? _value.created_by
            : created_by // ignore: cast_nullable_to_non_nullable
                  as String?,
        shared_with: freezed == shared_with
            ? _value._shared_with
            : shared_with // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
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
class _$CalendarEventImpl implements _CalendarEvent {
  const _$CalendarEventImpl({
    required this.id,
    required this.title,
    required this.start_date,
    required this.end_date,
    this.description,
    this.color,
    this.is_all_day = false,
    this.is_shared = false,
    this.created_by,
    final List<String>? shared_with,
    this.created_at,
    this.updated_at,
  }) : _shared_with = shared_with;

  factory _$CalendarEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$CalendarEventImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final DateTime start_date;
  @override
  final DateTime end_date;
  @override
  final String? description;
  @override
  final String? color;
  @override
  @JsonKey()
  final bool is_all_day;
  @override
  @JsonKey()
  final bool is_shared;
  @override
  final String? created_by;
  final List<String>? _shared_with;
  @override
  List<String>? get shared_with {
    final value = _shared_with;
    if (value == null) return null;
    if (_shared_with is EqualUnmodifiableListView) return _shared_with;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final DateTime? created_at;
  @override
  final DateTime? updated_at;

  @override
  String toString() {
    return 'CalendarEvent(id: $id, title: $title, start_date: $start_date, end_date: $end_date, description: $description, color: $color, is_all_day: $is_all_day, is_shared: $is_shared, created_by: $created_by, shared_with: $shared_with, created_at: $created_at, updated_at: $updated_at)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CalendarEventImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.start_date, start_date) ||
                other.start_date == start_date) &&
            (identical(other.end_date, end_date) ||
                other.end_date == end_date) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.is_all_day, is_all_day) ||
                other.is_all_day == is_all_day) &&
            (identical(other.is_shared, is_shared) ||
                other.is_shared == is_shared) &&
            (identical(other.created_by, created_by) ||
                other.created_by == created_by) &&
            const DeepCollectionEquality().equals(
              other._shared_with,
              _shared_with,
            ) &&
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
    title,
    start_date,
    end_date,
    description,
    color,
    is_all_day,
    is_shared,
    created_by,
    const DeepCollectionEquality().hash(_shared_with),
    created_at,
    updated_at,
  );

  /// Create a copy of CalendarEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CalendarEventImplCopyWith<_$CalendarEventImpl> get copyWith =>
      __$$CalendarEventImplCopyWithImpl<_$CalendarEventImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CalendarEventImplToJson(this);
  }
}

abstract class _CalendarEvent implements CalendarEvent {
  const factory _CalendarEvent({
    required final String id,
    required final String title,
    required final DateTime start_date,
    required final DateTime end_date,
    final String? description,
    final String? color,
    final bool is_all_day,
    final bool is_shared,
    final String? created_by,
    final List<String>? shared_with,
    final DateTime? created_at,
    final DateTime? updated_at,
  }) = _$CalendarEventImpl;

  factory _CalendarEvent.fromJson(Map<String, dynamic> json) =
      _$CalendarEventImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  DateTime get start_date;
  @override
  DateTime get end_date;
  @override
  String? get description;
  @override
  String? get color;
  @override
  bool get is_all_day;
  @override
  bool get is_shared;
  @override
  String? get created_by;
  @override
  List<String>? get shared_with;
  @override
  DateTime? get created_at;
  @override
  DateTime? get updated_at;

  /// Create a copy of CalendarEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CalendarEventImplCopyWith<_$CalendarEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SharedSchedule _$SharedScheduleFromJson(Map<String, dynamic> json) {
  return _SharedSchedule.fromJson(json);
}

/// @nodoc
mixin _$SharedSchedule {
  String get id => throw _privateConstructorUsedError;
  String get owner_id => throw _privateConstructorUsedError;
  String get owner_name => throw _privateConstructorUsedError;
  List<String> get shared_user_ids => throw _privateConstructorUsedError;
  DateTime get start_date => throw _privateConstructorUsedError;
  DateTime get end_date => throw _privateConstructorUsedError;
  String get permission => throw _privateConstructorUsedError; // 'view', 'edit'
  DateTime? get created_at => throw _privateConstructorUsedError;

  /// Serializes this SharedSchedule to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SharedSchedule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SharedScheduleCopyWith<SharedSchedule> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SharedScheduleCopyWith<$Res> {
  factory $SharedScheduleCopyWith(
    SharedSchedule value,
    $Res Function(SharedSchedule) then,
  ) = _$SharedScheduleCopyWithImpl<$Res, SharedSchedule>;
  @useResult
  $Res call({
    String id,
    String owner_id,
    String owner_name,
    List<String> shared_user_ids,
    DateTime start_date,
    DateTime end_date,
    String permission,
    DateTime? created_at,
  });
}

/// @nodoc
class _$SharedScheduleCopyWithImpl<$Res, $Val extends SharedSchedule>
    implements $SharedScheduleCopyWith<$Res> {
  _$SharedScheduleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SharedSchedule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? owner_id = null,
    Object? owner_name = null,
    Object? shared_user_ids = null,
    Object? start_date = null,
    Object? end_date = null,
    Object? permission = null,
    Object? created_at = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            owner_id: null == owner_id
                ? _value.owner_id
                : owner_id // ignore: cast_nullable_to_non_nullable
                      as String,
            owner_name: null == owner_name
                ? _value.owner_name
                : owner_name // ignore: cast_nullable_to_non_nullable
                      as String,
            shared_user_ids: null == shared_user_ids
                ? _value.shared_user_ids
                : shared_user_ids // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            start_date: null == start_date
                ? _value.start_date
                : start_date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            end_date: null == end_date
                ? _value.end_date
                : end_date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            permission: null == permission
                ? _value.permission
                : permission // ignore: cast_nullable_to_non_nullable
                      as String,
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
abstract class _$$SharedScheduleImplCopyWith<$Res>
    implements $SharedScheduleCopyWith<$Res> {
  factory _$$SharedScheduleImplCopyWith(
    _$SharedScheduleImpl value,
    $Res Function(_$SharedScheduleImpl) then,
  ) = __$$SharedScheduleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String owner_id,
    String owner_name,
    List<String> shared_user_ids,
    DateTime start_date,
    DateTime end_date,
    String permission,
    DateTime? created_at,
  });
}

/// @nodoc
class __$$SharedScheduleImplCopyWithImpl<$Res>
    extends _$SharedScheduleCopyWithImpl<$Res, _$SharedScheduleImpl>
    implements _$$SharedScheduleImplCopyWith<$Res> {
  __$$SharedScheduleImplCopyWithImpl(
    _$SharedScheduleImpl _value,
    $Res Function(_$SharedScheduleImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SharedSchedule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? owner_id = null,
    Object? owner_name = null,
    Object? shared_user_ids = null,
    Object? start_date = null,
    Object? end_date = null,
    Object? permission = null,
    Object? created_at = freezed,
  }) {
    return _then(
      _$SharedScheduleImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        owner_id: null == owner_id
            ? _value.owner_id
            : owner_id // ignore: cast_nullable_to_non_nullable
                  as String,
        owner_name: null == owner_name
            ? _value.owner_name
            : owner_name // ignore: cast_nullable_to_non_nullable
                  as String,
        shared_user_ids: null == shared_user_ids
            ? _value._shared_user_ids
            : shared_user_ids // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        start_date: null == start_date
            ? _value.start_date
            : start_date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        end_date: null == end_date
            ? _value.end_date
            : end_date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        permission: null == permission
            ? _value.permission
            : permission // ignore: cast_nullable_to_non_nullable
                  as String,
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
class _$SharedScheduleImpl implements _SharedSchedule {
  const _$SharedScheduleImpl({
    required this.id,
    required this.owner_id,
    required this.owner_name,
    required final List<String> shared_user_ids,
    required this.start_date,
    required this.end_date,
    this.permission = 'view',
    this.created_at,
  }) : _shared_user_ids = shared_user_ids;

  factory _$SharedScheduleImpl.fromJson(Map<String, dynamic> json) =>
      _$$SharedScheduleImplFromJson(json);

  @override
  final String id;
  @override
  final String owner_id;
  @override
  final String owner_name;
  final List<String> _shared_user_ids;
  @override
  List<String> get shared_user_ids {
    if (_shared_user_ids is EqualUnmodifiableListView) return _shared_user_ids;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_shared_user_ids);
  }

  @override
  final DateTime start_date;
  @override
  final DateTime end_date;
  @override
  @JsonKey()
  final String permission;
  // 'view', 'edit'
  @override
  final DateTime? created_at;

  @override
  String toString() {
    return 'SharedSchedule(id: $id, owner_id: $owner_id, owner_name: $owner_name, shared_user_ids: $shared_user_ids, start_date: $start_date, end_date: $end_date, permission: $permission, created_at: $created_at)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SharedScheduleImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.owner_id, owner_id) ||
                other.owner_id == owner_id) &&
            (identical(other.owner_name, owner_name) ||
                other.owner_name == owner_name) &&
            const DeepCollectionEquality().equals(
              other._shared_user_ids,
              _shared_user_ids,
            ) &&
            (identical(other.start_date, start_date) ||
                other.start_date == start_date) &&
            (identical(other.end_date, end_date) ||
                other.end_date == end_date) &&
            (identical(other.permission, permission) ||
                other.permission == permission) &&
            (identical(other.created_at, created_at) ||
                other.created_at == created_at));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    owner_id,
    owner_name,
    const DeepCollectionEquality().hash(_shared_user_ids),
    start_date,
    end_date,
    permission,
    created_at,
  );

  /// Create a copy of SharedSchedule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SharedScheduleImplCopyWith<_$SharedScheduleImpl> get copyWith =>
      __$$SharedScheduleImplCopyWithImpl<_$SharedScheduleImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SharedScheduleImplToJson(this);
  }
}

abstract class _SharedSchedule implements SharedSchedule {
  const factory _SharedSchedule({
    required final String id,
    required final String owner_id,
    required final String owner_name,
    required final List<String> shared_user_ids,
    required final DateTime start_date,
    required final DateTime end_date,
    final String permission,
    final DateTime? created_at,
  }) = _$SharedScheduleImpl;

  factory _SharedSchedule.fromJson(Map<String, dynamic> json) =
      _$SharedScheduleImpl.fromJson;

  @override
  String get id;
  @override
  String get owner_id;
  @override
  String get owner_name;
  @override
  List<String> get shared_user_ids;
  @override
  DateTime get start_date;
  @override
  DateTime get end_date;
  @override
  String get permission; // 'view', 'edit'
  @override
  DateTime? get created_at;

  /// Create a copy of SharedSchedule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SharedScheduleImplCopyWith<_$SharedScheduleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
