// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'structs.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ActorType {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is ActorType);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'ActorType()';
  }
}

/// @nodoc
class $ActorTypeCopyWith<$Res> {
  $ActorTypeCopyWith(ActorType _, $Res Function(ActorType) __);
}

/// Adds pattern-matching-related methods to [ActorType].
extension ActorTypePatterns on ActorType {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ActorType_Camera value)? camera,
    TResult Function(ActorType_Sound value)? sound,
    TResult Function(ActorType_Effect value)? effect,
    TResult Function(ActorType_Bgm value)? bgm,
    TResult Function(ActorType_Proxy value)? proxy,
    TResult Function(ActorType_System value)? system,
    TResult Function(ActorType_Character value)? character,
    TResult Function(ActorType_Unknown value)? unknown,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case ActorType_Camera() when camera != null:
        return camera(_that);
      case ActorType_Sound() when sound != null:
        return sound(_that);
      case ActorType_Effect() when effect != null:
        return effect(_that);
      case ActorType_Bgm() when bgm != null:
        return bgm(_that);
      case ActorType_Proxy() when proxy != null:
        return proxy(_that);
      case ActorType_System() when system != null:
        return system(_that);
      case ActorType_Character() when character != null:
        return character(_that);
      case ActorType_Unknown() when unknown != null:
        return unknown(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ActorType_Camera value) camera,
    required TResult Function(ActorType_Sound value) sound,
    required TResult Function(ActorType_Effect value) effect,
    required TResult Function(ActorType_Bgm value) bgm,
    required TResult Function(ActorType_Proxy value) proxy,
    required TResult Function(ActorType_System value) system,
    required TResult Function(ActorType_Character value) character,
    required TResult Function(ActorType_Unknown value) unknown,
  }) {
    final _that = this;
    switch (_that) {
      case ActorType_Camera():
        return camera(_that);
      case ActorType_Sound():
        return sound(_that);
      case ActorType_Effect():
        return effect(_that);
      case ActorType_Bgm():
        return bgm(_that);
      case ActorType_Proxy():
        return proxy(_that);
      case ActorType_System():
        return system(_that);
      case ActorType_Character():
        return character(_that);
      case ActorType_Unknown():
        return unknown(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ActorType_Camera value)? camera,
    TResult? Function(ActorType_Sound value)? sound,
    TResult? Function(ActorType_Effect value)? effect,
    TResult? Function(ActorType_Bgm value)? bgm,
    TResult? Function(ActorType_Proxy value)? proxy,
    TResult? Function(ActorType_System value)? system,
    TResult? Function(ActorType_Character value)? character,
    TResult? Function(ActorType_Unknown value)? unknown,
  }) {
    final _that = this;
    switch (_that) {
      case ActorType_Camera() when camera != null:
        return camera(_that);
      case ActorType_Sound() when sound != null:
        return sound(_that);
      case ActorType_Effect() when effect != null:
        return effect(_that);
      case ActorType_Bgm() when bgm != null:
        return bgm(_that);
      case ActorType_Proxy() when proxy != null:
        return proxy(_that);
      case ActorType_System() when system != null:
        return system(_that);
      case ActorType_Character() when character != null:
        return character(_that);
      case ActorType_Unknown() when unknown != null:
        return unknown(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? camera,
    TResult Function()? sound,
    TResult Function()? effect,
    TResult Function()? bgm,
    TResult Function()? proxy,
    TResult Function()? system,
    TResult Function(String field0)? character,
    TResult Function(String field0)? unknown,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case ActorType_Camera() when camera != null:
        return camera();
      case ActorType_Sound() when sound != null:
        return sound();
      case ActorType_Effect() when effect != null:
        return effect();
      case ActorType_Bgm() when bgm != null:
        return bgm();
      case ActorType_Proxy() when proxy != null:
        return proxy();
      case ActorType_System() when system != null:
        return system();
      case ActorType_Character() when character != null:
        return character(_that.field0);
      case ActorType_Unknown() when unknown != null:
        return unknown(_that.field0);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() camera,
    required TResult Function() sound,
    required TResult Function() effect,
    required TResult Function() bgm,
    required TResult Function() proxy,
    required TResult Function() system,
    required TResult Function(String field0) character,
    required TResult Function(String field0) unknown,
  }) {
    final _that = this;
    switch (_that) {
      case ActorType_Camera():
        return camera();
      case ActorType_Sound():
        return sound();
      case ActorType_Effect():
        return effect();
      case ActorType_Bgm():
        return bgm();
      case ActorType_Proxy():
        return proxy();
      case ActorType_System():
        return system();
      case ActorType_Character():
        return character(_that.field0);
      case ActorType_Unknown():
        return unknown(_that.field0);
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? camera,
    TResult? Function()? sound,
    TResult? Function()? effect,
    TResult? Function()? bgm,
    TResult? Function()? proxy,
    TResult? Function()? system,
    TResult? Function(String field0)? character,
    TResult? Function(String field0)? unknown,
  }) {
    final _that = this;
    switch (_that) {
      case ActorType_Camera() when camera != null:
        return camera();
      case ActorType_Sound() when sound != null:
        return sound();
      case ActorType_Effect() when effect != null:
        return effect();
      case ActorType_Bgm() when bgm != null:
        return bgm();
      case ActorType_Proxy() when proxy != null:
        return proxy();
      case ActorType_System() when system != null:
        return system();
      case ActorType_Character() when character != null:
        return character(_that.field0);
      case ActorType_Unknown() when unknown != null:
        return unknown(_that.field0);
      case _:
        return null;
    }
  }
}

/// @nodoc

class ActorType_Camera extends ActorType {
  const ActorType_Camera() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is ActorType_Camera);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'ActorType.camera()';
  }
}

/// @nodoc

class ActorType_Sound extends ActorType {
  const ActorType_Sound() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is ActorType_Sound);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'ActorType.sound()';
  }
}

/// @nodoc

class ActorType_Effect extends ActorType {
  const ActorType_Effect() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is ActorType_Effect);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'ActorType.effect()';
  }
}

/// @nodoc

class ActorType_Bgm extends ActorType {
  const ActorType_Bgm() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is ActorType_Bgm);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'ActorType.bgm()';
  }
}

/// @nodoc

class ActorType_Proxy extends ActorType {
  const ActorType_Proxy() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is ActorType_Proxy);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'ActorType.proxy()';
  }
}

/// @nodoc

class ActorType_System extends ActorType {
  const ActorType_System() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is ActorType_System);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'ActorType.system()';
  }
}

/// @nodoc

class ActorType_Character extends ActorType {
  const ActorType_Character(this.field0) : super._();

  final String field0;

  /// Create a copy of ActorType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ActorType_CharacterCopyWith<ActorType_Character> get copyWith =>
      _$ActorType_CharacterCopyWithImpl<ActorType_Character>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ActorType_Character &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'ActorType.character(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $ActorType_CharacterCopyWith<$Res>
    implements $ActorTypeCopyWith<$Res> {
  factory $ActorType_CharacterCopyWith(
          ActorType_Character value, $Res Function(ActorType_Character) _then) =
      _$ActorType_CharacterCopyWithImpl;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class _$ActorType_CharacterCopyWithImpl<$Res>
    implements $ActorType_CharacterCopyWith<$Res> {
  _$ActorType_CharacterCopyWithImpl(this._self, this._then);

  final ActorType_Character _self;
  final $Res Function(ActorType_Character) _then;

  /// Create a copy of ActorType
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(ActorType_Character(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class ActorType_Unknown extends ActorType {
  const ActorType_Unknown(this.field0) : super._();

  final String field0;

  /// Create a copy of ActorType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ActorType_UnknownCopyWith<ActorType_Unknown> get copyWith =>
      _$ActorType_UnknownCopyWithImpl<ActorType_Unknown>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ActorType_Unknown &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'ActorType.unknown(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $ActorType_UnknownCopyWith<$Res>
    implements $ActorTypeCopyWith<$Res> {
  factory $ActorType_UnknownCopyWith(
          ActorType_Unknown value, $Res Function(ActorType_Unknown) _then) =
      _$ActorType_UnknownCopyWithImpl;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class _$ActorType_UnknownCopyWithImpl<$Res>
    implements $ActorType_UnknownCopyWith<$Res> {
  _$ActorType_UnknownCopyWithImpl(this._self, this._then);

  final ActorType_Unknown _self;
  final $Res Function(ActorType_Unknown) _then;

  /// Create a copy of ActorType
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(ActorType_Unknown(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
mixin _$TrackType {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is TrackType);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'TrackType()';
  }
}

/// @nodoc
class $TrackTypeCopyWith<$Res> {
  $TrackTypeCopyWith(TrackType _, $Res Function(TrackType) __);
}

/// Adds pattern-matching-related methods to [TrackType].
extension TrackTypePatterns on TrackType {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TrackType_MotionSet value)? motionSet,
    TResult Function(TrackType_CharacterSet value)? characterSet,
    TResult Function(TrackType_Camera value)? camera,
    TResult Function(TrackType_Sound value)? sound,
    TResult Function(TrackType_MusicBus value)? musicBus,
    TResult Function(TrackType_Dialogue value)? dialogue,
    TResult Function(TrackType_Effect value)? effect,
    TResult Function(TrackType_EventDef value)? eventDef,
    TResult Function(TrackType_ActorControl value)? actorControl,
    TResult Function(TrackType_Unknown value)? unknown,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case TrackType_MotionSet() when motionSet != null:
        return motionSet(_that);
      case TrackType_CharacterSet() when characterSet != null:
        return characterSet(_that);
      case TrackType_Camera() when camera != null:
        return camera(_that);
      case TrackType_Sound() when sound != null:
        return sound(_that);
      case TrackType_MusicBus() when musicBus != null:
        return musicBus(_that);
      case TrackType_Dialogue() when dialogue != null:
        return dialogue(_that);
      case TrackType_Effect() when effect != null:
        return effect(_that);
      case TrackType_EventDef() when eventDef != null:
        return eventDef(_that);
      case TrackType_ActorControl() when actorControl != null:
        return actorControl(_that);
      case TrackType_Unknown() when unknown != null:
        return unknown(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TrackType_MotionSet value) motionSet,
    required TResult Function(TrackType_CharacterSet value) characterSet,
    required TResult Function(TrackType_Camera value) camera,
    required TResult Function(TrackType_Sound value) sound,
    required TResult Function(TrackType_MusicBus value) musicBus,
    required TResult Function(TrackType_Dialogue value) dialogue,
    required TResult Function(TrackType_Effect value) effect,
    required TResult Function(TrackType_EventDef value) eventDef,
    required TResult Function(TrackType_ActorControl value) actorControl,
    required TResult Function(TrackType_Unknown value) unknown,
  }) {
    final _that = this;
    switch (_that) {
      case TrackType_MotionSet():
        return motionSet(_that);
      case TrackType_CharacterSet():
        return characterSet(_that);
      case TrackType_Camera():
        return camera(_that);
      case TrackType_Sound():
        return sound(_that);
      case TrackType_MusicBus():
        return musicBus(_that);
      case TrackType_Dialogue():
        return dialogue(_that);
      case TrackType_Effect():
        return effect(_that);
      case TrackType_EventDef():
        return eventDef(_that);
      case TrackType_ActorControl():
        return actorControl(_that);
      case TrackType_Unknown():
        return unknown(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TrackType_MotionSet value)? motionSet,
    TResult? Function(TrackType_CharacterSet value)? characterSet,
    TResult? Function(TrackType_Camera value)? camera,
    TResult? Function(TrackType_Sound value)? sound,
    TResult? Function(TrackType_MusicBus value)? musicBus,
    TResult? Function(TrackType_Dialogue value)? dialogue,
    TResult? Function(TrackType_Effect value)? effect,
    TResult? Function(TrackType_EventDef value)? eventDef,
    TResult? Function(TrackType_ActorControl value)? actorControl,
    TResult? Function(TrackType_Unknown value)? unknown,
  }) {
    final _that = this;
    switch (_that) {
      case TrackType_MotionSet() when motionSet != null:
        return motionSet(_that);
      case TrackType_CharacterSet() when characterSet != null:
        return characterSet(_that);
      case TrackType_Camera() when camera != null:
        return camera(_that);
      case TrackType_Sound() when sound != null:
        return sound(_that);
      case TrackType_MusicBus() when musicBus != null:
        return musicBus(_that);
      case TrackType_Dialogue() when dialogue != null:
        return dialogue(_that);
      case TrackType_Effect() when effect != null:
        return effect(_that);
      case TrackType_EventDef() when eventDef != null:
        return eventDef(_that);
      case TrackType_ActorControl() when actorControl != null:
        return actorControl(_that);
      case TrackType_Unknown() when unknown != null:
        return unknown(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? motionSet,
    TResult Function()? characterSet,
    TResult Function()? camera,
    TResult Function()? sound,
    TResult Function()? musicBus,
    TResult Function()? dialogue,
    TResult Function()? effect,
    TResult Function()? eventDef,
    TResult Function()? actorControl,
    TResult Function(int field0)? unknown,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case TrackType_MotionSet() when motionSet != null:
        return motionSet();
      case TrackType_CharacterSet() when characterSet != null:
        return characterSet();
      case TrackType_Camera() when camera != null:
        return camera();
      case TrackType_Sound() when sound != null:
        return sound();
      case TrackType_MusicBus() when musicBus != null:
        return musicBus();
      case TrackType_Dialogue() when dialogue != null:
        return dialogue();
      case TrackType_Effect() when effect != null:
        return effect();
      case TrackType_EventDef() when eventDef != null:
        return eventDef();
      case TrackType_ActorControl() when actorControl != null:
        return actorControl();
      case TrackType_Unknown() when unknown != null:
        return unknown(_that.field0);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() motionSet,
    required TResult Function() characterSet,
    required TResult Function() camera,
    required TResult Function() sound,
    required TResult Function() musicBus,
    required TResult Function() dialogue,
    required TResult Function() effect,
    required TResult Function() eventDef,
    required TResult Function() actorControl,
    required TResult Function(int field0) unknown,
  }) {
    final _that = this;
    switch (_that) {
      case TrackType_MotionSet():
        return motionSet();
      case TrackType_CharacterSet():
        return characterSet();
      case TrackType_Camera():
        return camera();
      case TrackType_Sound():
        return sound();
      case TrackType_MusicBus():
        return musicBus();
      case TrackType_Dialogue():
        return dialogue();
      case TrackType_Effect():
        return effect();
      case TrackType_EventDef():
        return eventDef();
      case TrackType_ActorControl():
        return actorControl();
      case TrackType_Unknown():
        return unknown(_that.field0);
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? motionSet,
    TResult? Function()? characterSet,
    TResult? Function()? camera,
    TResult? Function()? sound,
    TResult? Function()? musicBus,
    TResult? Function()? dialogue,
    TResult? Function()? effect,
    TResult? Function()? eventDef,
    TResult? Function()? actorControl,
    TResult? Function(int field0)? unknown,
  }) {
    final _that = this;
    switch (_that) {
      case TrackType_MotionSet() when motionSet != null:
        return motionSet();
      case TrackType_CharacterSet() when characterSet != null:
        return characterSet();
      case TrackType_Camera() when camera != null:
        return camera();
      case TrackType_Sound() when sound != null:
        return sound();
      case TrackType_MusicBus() when musicBus != null:
        return musicBus();
      case TrackType_Dialogue() when dialogue != null:
        return dialogue();
      case TrackType_Effect() when effect != null:
        return effect();
      case TrackType_EventDef() when eventDef != null:
        return eventDef();
      case TrackType_ActorControl() when actorControl != null:
        return actorControl();
      case TrackType_Unknown() when unknown != null:
        return unknown(_that.field0);
      case _:
        return null;
    }
  }
}

/// @nodoc

class TrackType_MotionSet extends TrackType {
  const TrackType_MotionSet() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is TrackType_MotionSet);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'TrackType.motionSet()';
  }
}

/// @nodoc

class TrackType_CharacterSet extends TrackType {
  const TrackType_CharacterSet() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is TrackType_CharacterSet);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'TrackType.characterSet()';
  }
}

/// @nodoc

class TrackType_Camera extends TrackType {
  const TrackType_Camera() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is TrackType_Camera);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'TrackType.camera()';
  }
}

/// @nodoc

class TrackType_Sound extends TrackType {
  const TrackType_Sound() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is TrackType_Sound);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'TrackType.sound()';
  }
}

/// @nodoc

class TrackType_MusicBus extends TrackType {
  const TrackType_MusicBus() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is TrackType_MusicBus);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'TrackType.musicBus()';
  }
}

/// @nodoc

class TrackType_Dialogue extends TrackType {
  const TrackType_Dialogue() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is TrackType_Dialogue);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'TrackType.dialogue()';
  }
}

/// @nodoc

class TrackType_Effect extends TrackType {
  const TrackType_Effect() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is TrackType_Effect);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'TrackType.effect()';
  }
}

/// @nodoc

class TrackType_EventDef extends TrackType {
  const TrackType_EventDef() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is TrackType_EventDef);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'TrackType.eventDef()';
  }
}

/// @nodoc

class TrackType_ActorControl extends TrackType {
  const TrackType_ActorControl() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is TrackType_ActorControl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'TrackType.actorControl()';
  }
}

/// @nodoc

class TrackType_Unknown extends TrackType {
  const TrackType_Unknown(this.field0) : super._();

  final int field0;

  /// Create a copy of TrackType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TrackType_UnknownCopyWith<TrackType_Unknown> get copyWith =>
      _$TrackType_UnknownCopyWithImpl<TrackType_Unknown>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TrackType_Unknown &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'TrackType.unknown(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $TrackType_UnknownCopyWith<$Res>
    implements $TrackTypeCopyWith<$Res> {
  factory $TrackType_UnknownCopyWith(
          TrackType_Unknown value, $Res Function(TrackType_Unknown) _then) =
      _$TrackType_UnknownCopyWithImpl;
  @useResult
  $Res call({int field0});
}

/// @nodoc
class _$TrackType_UnknownCopyWithImpl<$Res>
    implements $TrackType_UnknownCopyWith<$Res> {
  _$TrackType_UnknownCopyWithImpl(this._self, this._then);

  final TrackType_Unknown _self;
  final $Res Function(TrackType_Unknown) _then;

  /// Create a copy of TrackType
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(TrackType_Unknown(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
