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
mixin _$WdbValue {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is WdbValue);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'WdbValue()';
  }
}

/// @nodoc
class $WdbValueCopyWith<$Res> {
  $WdbValueCopyWith(WdbValue _, $Res Function(WdbValue) __);
}

/// Adds pattern-matching-related methods to [WdbValue].
extension WdbValuePatterns on WdbValue {
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
    TResult Function(WdbValue_Int value)? int,
    TResult Function(WdbValue_UInt value)? uInt,
    TResult Function(WdbValue_Float value)? float,
    TResult Function(WdbValue_String value)? string,
    TResult Function(WdbValue_Bool value)? bool,
    TResult Function(WdbValue_IntArray value)? intArray,
    TResult Function(WdbValue_UIntArray value)? uIntArray,
    TResult Function(WdbValue_StringArray value)? stringArray,
    TResult Function(WdbValue_UInt64 value)? uInt64,
    TResult Function(WdbValue_CrystalRole value)? crystalRole,
    TResult Function(WdbValue_CrystalNodeType value)? crystalNodeType,
    TResult Function(WdbValue_Unknown value)? unknown,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case WdbValue_Int() when int != null:
        return int(_that);
      case WdbValue_UInt() when uInt != null:
        return uInt(_that);
      case WdbValue_Float() when float != null:
        return float(_that);
      case WdbValue_String() when string != null:
        return string(_that);
      case WdbValue_Bool() when bool != null:
        return bool(_that);
      case WdbValue_IntArray() when intArray != null:
        return intArray(_that);
      case WdbValue_UIntArray() when uIntArray != null:
        return uIntArray(_that);
      case WdbValue_StringArray() when stringArray != null:
        return stringArray(_that);
      case WdbValue_UInt64() when uInt64 != null:
        return uInt64(_that);
      case WdbValue_CrystalRole() when crystalRole != null:
        return crystalRole(_that);
      case WdbValue_CrystalNodeType() when crystalNodeType != null:
        return crystalNodeType(_that);
      case WdbValue_Unknown() when unknown != null:
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
    required TResult Function(WdbValue_Int value) int,
    required TResult Function(WdbValue_UInt value) uInt,
    required TResult Function(WdbValue_Float value) float,
    required TResult Function(WdbValue_String value) string,
    required TResult Function(WdbValue_Bool value) bool,
    required TResult Function(WdbValue_IntArray value) intArray,
    required TResult Function(WdbValue_UIntArray value) uIntArray,
    required TResult Function(WdbValue_StringArray value) stringArray,
    required TResult Function(WdbValue_UInt64 value) uInt64,
    required TResult Function(WdbValue_CrystalRole value) crystalRole,
    required TResult Function(WdbValue_CrystalNodeType value) crystalNodeType,
    required TResult Function(WdbValue_Unknown value) unknown,
  }) {
    final _that = this;
    switch (_that) {
      case WdbValue_Int():
        return int(_that);
      case WdbValue_UInt():
        return uInt(_that);
      case WdbValue_Float():
        return float(_that);
      case WdbValue_String():
        return string(_that);
      case WdbValue_Bool():
        return bool(_that);
      case WdbValue_IntArray():
        return intArray(_that);
      case WdbValue_UIntArray():
        return uIntArray(_that);
      case WdbValue_StringArray():
        return stringArray(_that);
      case WdbValue_UInt64():
        return uInt64(_that);
      case WdbValue_CrystalRole():
        return crystalRole(_that);
      case WdbValue_CrystalNodeType():
        return crystalNodeType(_that);
      case WdbValue_Unknown():
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
    TResult? Function(WdbValue_Int value)? int,
    TResult? Function(WdbValue_UInt value)? uInt,
    TResult? Function(WdbValue_Float value)? float,
    TResult? Function(WdbValue_String value)? string,
    TResult? Function(WdbValue_Bool value)? bool,
    TResult? Function(WdbValue_IntArray value)? intArray,
    TResult? Function(WdbValue_UIntArray value)? uIntArray,
    TResult? Function(WdbValue_StringArray value)? stringArray,
    TResult? Function(WdbValue_UInt64 value)? uInt64,
    TResult? Function(WdbValue_CrystalRole value)? crystalRole,
    TResult? Function(WdbValue_CrystalNodeType value)? crystalNodeType,
    TResult? Function(WdbValue_Unknown value)? unknown,
  }) {
    final _that = this;
    switch (_that) {
      case WdbValue_Int() when int != null:
        return int(_that);
      case WdbValue_UInt() when uInt != null:
        return uInt(_that);
      case WdbValue_Float() when float != null:
        return float(_that);
      case WdbValue_String() when string != null:
        return string(_that);
      case WdbValue_Bool() when bool != null:
        return bool(_that);
      case WdbValue_IntArray() when intArray != null:
        return intArray(_that);
      case WdbValue_UIntArray() when uIntArray != null:
        return uIntArray(_that);
      case WdbValue_StringArray() when stringArray != null:
        return stringArray(_that);
      case WdbValue_UInt64() when uInt64 != null:
        return uInt64(_that);
      case WdbValue_CrystalRole() when crystalRole != null:
        return crystalRole(_that);
      case WdbValue_CrystalNodeType() when crystalNodeType != null:
        return crystalNodeType(_that);
      case WdbValue_Unknown() when unknown != null:
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
    TResult Function(int field0)? int,
    TResult Function(int field0)? uInt,
    TResult Function(double field0)? float,
    TResult Function(String field0)? string,
    TResult Function(bool field0)? bool,
    TResult Function(Int32List field0)? intArray,
    TResult Function(Uint32List field0)? uIntArray,
    TResult Function(List<String> field0)? stringArray,
    TResult Function(BigInt field0)? uInt64,
    TResult Function(CrystalRole field0)? crystalRole,
    TResult Function(CrystalNodeType field0)? crystalNodeType,
    TResult Function()? unknown,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case WdbValue_Int() when int != null:
        return int(_that.field0);
      case WdbValue_UInt() when uInt != null:
        return uInt(_that.field0);
      case WdbValue_Float() when float != null:
        return float(_that.field0);
      case WdbValue_String() when string != null:
        return string(_that.field0);
      case WdbValue_Bool() when bool != null:
        return bool(_that.field0);
      case WdbValue_IntArray() when intArray != null:
        return intArray(_that.field0);
      case WdbValue_UIntArray() when uIntArray != null:
        return uIntArray(_that.field0);
      case WdbValue_StringArray() when stringArray != null:
        return stringArray(_that.field0);
      case WdbValue_UInt64() when uInt64 != null:
        return uInt64(_that.field0);
      case WdbValue_CrystalRole() when crystalRole != null:
        return crystalRole(_that.field0);
      case WdbValue_CrystalNodeType() when crystalNodeType != null:
        return crystalNodeType(_that.field0);
      case WdbValue_Unknown() when unknown != null:
        return unknown();
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
    required TResult Function(int field0) int,
    required TResult Function(int field0) uInt,
    required TResult Function(double field0) float,
    required TResult Function(String field0) string,
    required TResult Function(bool field0) bool,
    required TResult Function(Int32List field0) intArray,
    required TResult Function(Uint32List field0) uIntArray,
    required TResult Function(List<String> field0) stringArray,
    required TResult Function(BigInt field0) uInt64,
    required TResult Function(CrystalRole field0) crystalRole,
    required TResult Function(CrystalNodeType field0) crystalNodeType,
    required TResult Function() unknown,
  }) {
    final _that = this;
    switch (_that) {
      case WdbValue_Int():
        return int(_that.field0);
      case WdbValue_UInt():
        return uInt(_that.field0);
      case WdbValue_Float():
        return float(_that.field0);
      case WdbValue_String():
        return string(_that.field0);
      case WdbValue_Bool():
        return bool(_that.field0);
      case WdbValue_IntArray():
        return intArray(_that.field0);
      case WdbValue_UIntArray():
        return uIntArray(_that.field0);
      case WdbValue_StringArray():
        return stringArray(_that.field0);
      case WdbValue_UInt64():
        return uInt64(_that.field0);
      case WdbValue_CrystalRole():
        return crystalRole(_that.field0);
      case WdbValue_CrystalNodeType():
        return crystalNodeType(_that.field0);
      case WdbValue_Unknown():
        return unknown();
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
    TResult? Function(int field0)? int,
    TResult? Function(int field0)? uInt,
    TResult? Function(double field0)? float,
    TResult? Function(String field0)? string,
    TResult? Function(bool field0)? bool,
    TResult? Function(Int32List field0)? intArray,
    TResult? Function(Uint32List field0)? uIntArray,
    TResult? Function(List<String> field0)? stringArray,
    TResult? Function(BigInt field0)? uInt64,
    TResult? Function(CrystalRole field0)? crystalRole,
    TResult? Function(CrystalNodeType field0)? crystalNodeType,
    TResult? Function()? unknown,
  }) {
    final _that = this;
    switch (_that) {
      case WdbValue_Int() when int != null:
        return int(_that.field0);
      case WdbValue_UInt() when uInt != null:
        return uInt(_that.field0);
      case WdbValue_Float() when float != null:
        return float(_that.field0);
      case WdbValue_String() when string != null:
        return string(_that.field0);
      case WdbValue_Bool() when bool != null:
        return bool(_that.field0);
      case WdbValue_IntArray() when intArray != null:
        return intArray(_that.field0);
      case WdbValue_UIntArray() when uIntArray != null:
        return uIntArray(_that.field0);
      case WdbValue_StringArray() when stringArray != null:
        return stringArray(_that.field0);
      case WdbValue_UInt64() when uInt64 != null:
        return uInt64(_that.field0);
      case WdbValue_CrystalRole() when crystalRole != null:
        return crystalRole(_that.field0);
      case WdbValue_CrystalNodeType() when crystalNodeType != null:
        return crystalNodeType(_that.field0);
      case WdbValue_Unknown() when unknown != null:
        return unknown();
      case _:
        return null;
    }
  }
}

/// @nodoc

class WdbValue_Int extends WdbValue {
  const WdbValue_Int(this.field0) : super._();

  final int field0;

  /// Create a copy of WdbValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WdbValue_IntCopyWith<WdbValue_Int> get copyWith =>
      _$WdbValue_IntCopyWithImpl<WdbValue_Int>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WdbValue_Int &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'WdbValue.int(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $WdbValue_IntCopyWith<$Res>
    implements $WdbValueCopyWith<$Res> {
  factory $WdbValue_IntCopyWith(
          WdbValue_Int value, $Res Function(WdbValue_Int) _then) =
      _$WdbValue_IntCopyWithImpl;
  @useResult
  $Res call({int field0});
}

/// @nodoc
class _$WdbValue_IntCopyWithImpl<$Res> implements $WdbValue_IntCopyWith<$Res> {
  _$WdbValue_IntCopyWithImpl(this._self, this._then);

  final WdbValue_Int _self;
  final $Res Function(WdbValue_Int) _then;

  /// Create a copy of WdbValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(WdbValue_Int(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class WdbValue_UInt extends WdbValue {
  const WdbValue_UInt(this.field0) : super._();

  final int field0;

  /// Create a copy of WdbValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WdbValue_UIntCopyWith<WdbValue_UInt> get copyWith =>
      _$WdbValue_UIntCopyWithImpl<WdbValue_UInt>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WdbValue_UInt &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'WdbValue.uInt(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $WdbValue_UIntCopyWith<$Res>
    implements $WdbValueCopyWith<$Res> {
  factory $WdbValue_UIntCopyWith(
          WdbValue_UInt value, $Res Function(WdbValue_UInt) _then) =
      _$WdbValue_UIntCopyWithImpl;
  @useResult
  $Res call({int field0});
}

/// @nodoc
class _$WdbValue_UIntCopyWithImpl<$Res>
    implements $WdbValue_UIntCopyWith<$Res> {
  _$WdbValue_UIntCopyWithImpl(this._self, this._then);

  final WdbValue_UInt _self;
  final $Res Function(WdbValue_UInt) _then;

  /// Create a copy of WdbValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(WdbValue_UInt(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class WdbValue_Float extends WdbValue {
  const WdbValue_Float(this.field0) : super._();

  final double field0;

  /// Create a copy of WdbValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WdbValue_FloatCopyWith<WdbValue_Float> get copyWith =>
      _$WdbValue_FloatCopyWithImpl<WdbValue_Float>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WdbValue_Float &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'WdbValue.float(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $WdbValue_FloatCopyWith<$Res>
    implements $WdbValueCopyWith<$Res> {
  factory $WdbValue_FloatCopyWith(
          WdbValue_Float value, $Res Function(WdbValue_Float) _then) =
      _$WdbValue_FloatCopyWithImpl;
  @useResult
  $Res call({double field0});
}

/// @nodoc
class _$WdbValue_FloatCopyWithImpl<$Res>
    implements $WdbValue_FloatCopyWith<$Res> {
  _$WdbValue_FloatCopyWithImpl(this._self, this._then);

  final WdbValue_Float _self;
  final $Res Function(WdbValue_Float) _then;

  /// Create a copy of WdbValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(WdbValue_Float(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class WdbValue_String extends WdbValue {
  const WdbValue_String(this.field0) : super._();

  final String field0;

  /// Create a copy of WdbValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WdbValue_StringCopyWith<WdbValue_String> get copyWith =>
      _$WdbValue_StringCopyWithImpl<WdbValue_String>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WdbValue_String &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'WdbValue.string(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $WdbValue_StringCopyWith<$Res>
    implements $WdbValueCopyWith<$Res> {
  factory $WdbValue_StringCopyWith(
          WdbValue_String value, $Res Function(WdbValue_String) _then) =
      _$WdbValue_StringCopyWithImpl;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class _$WdbValue_StringCopyWithImpl<$Res>
    implements $WdbValue_StringCopyWith<$Res> {
  _$WdbValue_StringCopyWithImpl(this._self, this._then);

  final WdbValue_String _self;
  final $Res Function(WdbValue_String) _then;

  /// Create a copy of WdbValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(WdbValue_String(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class WdbValue_Bool extends WdbValue {
  const WdbValue_Bool(this.field0) : super._();

  final bool field0;

  /// Create a copy of WdbValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WdbValue_BoolCopyWith<WdbValue_Bool> get copyWith =>
      _$WdbValue_BoolCopyWithImpl<WdbValue_Bool>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WdbValue_Bool &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'WdbValue.bool(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $WdbValue_BoolCopyWith<$Res>
    implements $WdbValueCopyWith<$Res> {
  factory $WdbValue_BoolCopyWith(
          WdbValue_Bool value, $Res Function(WdbValue_Bool) _then) =
      _$WdbValue_BoolCopyWithImpl;
  @useResult
  $Res call({bool field0});
}

/// @nodoc
class _$WdbValue_BoolCopyWithImpl<$Res>
    implements $WdbValue_BoolCopyWith<$Res> {
  _$WdbValue_BoolCopyWithImpl(this._self, this._then);

  final WdbValue_Bool _self;
  final $Res Function(WdbValue_Bool) _then;

  /// Create a copy of WdbValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(WdbValue_Bool(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class WdbValue_IntArray extends WdbValue {
  const WdbValue_IntArray(this.field0) : super._();

  final Int32List field0;

  /// Create a copy of WdbValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WdbValue_IntArrayCopyWith<WdbValue_IntArray> get copyWith =>
      _$WdbValue_IntArrayCopyWithImpl<WdbValue_IntArray>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WdbValue_IntArray &&
            const DeepCollectionEquality().equals(other.field0, field0));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(field0));

  @override
  String toString() {
    return 'WdbValue.intArray(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $WdbValue_IntArrayCopyWith<$Res>
    implements $WdbValueCopyWith<$Res> {
  factory $WdbValue_IntArrayCopyWith(
          WdbValue_IntArray value, $Res Function(WdbValue_IntArray) _then) =
      _$WdbValue_IntArrayCopyWithImpl;
  @useResult
  $Res call({Int32List field0});
}

/// @nodoc
class _$WdbValue_IntArrayCopyWithImpl<$Res>
    implements $WdbValue_IntArrayCopyWith<$Res> {
  _$WdbValue_IntArrayCopyWithImpl(this._self, this._then);

  final WdbValue_IntArray _self;
  final $Res Function(WdbValue_IntArray) _then;

  /// Create a copy of WdbValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(WdbValue_IntArray(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as Int32List,
    ));
  }
}

/// @nodoc

class WdbValue_UIntArray extends WdbValue {
  const WdbValue_UIntArray(this.field0) : super._();

  final Uint32List field0;

  /// Create a copy of WdbValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WdbValue_UIntArrayCopyWith<WdbValue_UIntArray> get copyWith =>
      _$WdbValue_UIntArrayCopyWithImpl<WdbValue_UIntArray>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WdbValue_UIntArray &&
            const DeepCollectionEquality().equals(other.field0, field0));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(field0));

  @override
  String toString() {
    return 'WdbValue.uIntArray(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $WdbValue_UIntArrayCopyWith<$Res>
    implements $WdbValueCopyWith<$Res> {
  factory $WdbValue_UIntArrayCopyWith(
          WdbValue_UIntArray value, $Res Function(WdbValue_UIntArray) _then) =
      _$WdbValue_UIntArrayCopyWithImpl;
  @useResult
  $Res call({Uint32List field0});
}

/// @nodoc
class _$WdbValue_UIntArrayCopyWithImpl<$Res>
    implements $WdbValue_UIntArrayCopyWith<$Res> {
  _$WdbValue_UIntArrayCopyWithImpl(this._self, this._then);

  final WdbValue_UIntArray _self;
  final $Res Function(WdbValue_UIntArray) _then;

  /// Create a copy of WdbValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(WdbValue_UIntArray(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as Uint32List,
    ));
  }
}

/// @nodoc

class WdbValue_StringArray extends WdbValue {
  const WdbValue_StringArray(final List<String> field0)
      : _field0 = field0,
        super._();

  final List<String> _field0;
  List<String> get field0 {
    if (_field0 is EqualUnmodifiableListView) return _field0;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_field0);
  }

  /// Create a copy of WdbValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WdbValue_StringArrayCopyWith<WdbValue_StringArray> get copyWith =>
      _$WdbValue_StringArrayCopyWithImpl<WdbValue_StringArray>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WdbValue_StringArray &&
            const DeepCollectionEquality().equals(other._field0, _field0));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_field0));

  @override
  String toString() {
    return 'WdbValue.stringArray(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $WdbValue_StringArrayCopyWith<$Res>
    implements $WdbValueCopyWith<$Res> {
  factory $WdbValue_StringArrayCopyWith(WdbValue_StringArray value,
          $Res Function(WdbValue_StringArray) _then) =
      _$WdbValue_StringArrayCopyWithImpl;
  @useResult
  $Res call({List<String> field0});
}

/// @nodoc
class _$WdbValue_StringArrayCopyWithImpl<$Res>
    implements $WdbValue_StringArrayCopyWith<$Res> {
  _$WdbValue_StringArrayCopyWithImpl(this._self, this._then);

  final WdbValue_StringArray _self;
  final $Res Function(WdbValue_StringArray) _then;

  /// Create a copy of WdbValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(WdbValue_StringArray(
      null == field0
          ? _self._field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

class WdbValue_UInt64 extends WdbValue {
  const WdbValue_UInt64(this.field0) : super._();

  final BigInt field0;

  /// Create a copy of WdbValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WdbValue_UInt64CopyWith<WdbValue_UInt64> get copyWith =>
      _$WdbValue_UInt64CopyWithImpl<WdbValue_UInt64>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WdbValue_UInt64 &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'WdbValue.uInt64(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $WdbValue_UInt64CopyWith<$Res>
    implements $WdbValueCopyWith<$Res> {
  factory $WdbValue_UInt64CopyWith(
          WdbValue_UInt64 value, $Res Function(WdbValue_UInt64) _then) =
      _$WdbValue_UInt64CopyWithImpl;
  @useResult
  $Res call({BigInt field0});
}

/// @nodoc
class _$WdbValue_UInt64CopyWithImpl<$Res>
    implements $WdbValue_UInt64CopyWith<$Res> {
  _$WdbValue_UInt64CopyWithImpl(this._self, this._then);

  final WdbValue_UInt64 _self;
  final $Res Function(WdbValue_UInt64) _then;

  /// Create a copy of WdbValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(WdbValue_UInt64(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as BigInt,
    ));
  }
}

/// @nodoc

class WdbValue_CrystalRole extends WdbValue {
  const WdbValue_CrystalRole(this.field0) : super._();

  final CrystalRole field0;

  /// Create a copy of WdbValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WdbValue_CrystalRoleCopyWith<WdbValue_CrystalRole> get copyWith =>
      _$WdbValue_CrystalRoleCopyWithImpl<WdbValue_CrystalRole>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WdbValue_CrystalRole &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'WdbValue.crystalRole(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $WdbValue_CrystalRoleCopyWith<$Res>
    implements $WdbValueCopyWith<$Res> {
  factory $WdbValue_CrystalRoleCopyWith(WdbValue_CrystalRole value,
          $Res Function(WdbValue_CrystalRole) _then) =
      _$WdbValue_CrystalRoleCopyWithImpl;
  @useResult
  $Res call({CrystalRole field0});
}

/// @nodoc
class _$WdbValue_CrystalRoleCopyWithImpl<$Res>
    implements $WdbValue_CrystalRoleCopyWith<$Res> {
  _$WdbValue_CrystalRoleCopyWithImpl(this._self, this._then);

  final WdbValue_CrystalRole _self;
  final $Res Function(WdbValue_CrystalRole) _then;

  /// Create a copy of WdbValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(WdbValue_CrystalRole(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as CrystalRole,
    ));
  }
}

/// @nodoc

class WdbValue_CrystalNodeType extends WdbValue {
  const WdbValue_CrystalNodeType(this.field0) : super._();

  final CrystalNodeType field0;

  /// Create a copy of WdbValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WdbValue_CrystalNodeTypeCopyWith<WdbValue_CrystalNodeType> get copyWith =>
      _$WdbValue_CrystalNodeTypeCopyWithImpl<WdbValue_CrystalNodeType>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WdbValue_CrystalNodeType &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'WdbValue.crystalNodeType(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $WdbValue_CrystalNodeTypeCopyWith<$Res>
    implements $WdbValueCopyWith<$Res> {
  factory $WdbValue_CrystalNodeTypeCopyWith(WdbValue_CrystalNodeType value,
          $Res Function(WdbValue_CrystalNodeType) _then) =
      _$WdbValue_CrystalNodeTypeCopyWithImpl;
  @useResult
  $Res call({CrystalNodeType field0});
}

/// @nodoc
class _$WdbValue_CrystalNodeTypeCopyWithImpl<$Res>
    implements $WdbValue_CrystalNodeTypeCopyWith<$Res> {
  _$WdbValue_CrystalNodeTypeCopyWithImpl(this._self, this._then);

  final WdbValue_CrystalNodeType _self;
  final $Res Function(WdbValue_CrystalNodeType) _then;

  /// Create a copy of WdbValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(WdbValue_CrystalNodeType(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as CrystalNodeType,
    ));
  }
}

/// @nodoc

class WdbValue_Unknown extends WdbValue {
  const WdbValue_Unknown() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is WdbValue_Unknown);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'WdbValue.unknown()';
  }
}

// dart format on
