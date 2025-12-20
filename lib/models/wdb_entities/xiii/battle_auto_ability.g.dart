// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'battle_auto_ability.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BattleAutoAbility _$BattleAutoAbilityFromJson(Map<String, dynamic> json) =>
    BattleAutoAbility(
      stringResId: json['sStringResId'] as String? ?? '',
      infoStResId: json['sInfoStResId'] as String? ?? '',
      scriptId: json['sScriptId'] as String? ?? '',
      autoAblArgStr0: json['sAutoAblArgStr0'] as String? ?? '',
      autoAblArgStr1: json['sAutoAblArgStr1'] as String? ?? '',
      rsvFlag0: const BoolIntConverter().fromJson(json['u1RsvFlag0']),
      rsvFlag1: const BoolIntConverter().fromJson(json['u1RsvFlag1']),
      rsvFlag2: const BoolIntConverter().fromJson(json['u1RsvFlag2']),
      rsvFlag3: const BoolIntConverter().fromJson(json['u1RsvFlag3']),
      useRole: (json['u4UseRole'] as num?)?.toInt() ?? 0,
      menuCategory: (json['u4MenuCategory'] as num?)?.toInt() ?? 0,
      menuSortNo: (json['i16MenuSortNo'] as num?)?.toInt() ?? 0,
      scriptArg0: (json['i16ScriptArg0'] as num?)?.toInt() ?? 0,
      scriptArg1: (json['i16ScriptArg1'] as num?)?.toInt() ?? 0,
      autoAblKind: (json['u8AutoAblKind'] as num?)?.toInt() ?? 0,
      autoAblArgInt0: (json['i16AutoAblArgInt0'] as num?)?.toInt() ?? 0,
      autoAblArgInt1: (json['i16AutoAblArgInt1'] as num?)?.toInt() ?? 0,
      wepLvArg0: (json['i16WepLvArg0'] as num?)?.toInt() ?? 0,
      wepLvArg1: (json['i16WepLvArg1'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$BattleAutoAbilityToJson(BattleAutoAbility instance) =>
    <String, dynamic>{
      'sStringResId': instance.stringResId,
      'sInfoStResId': instance.infoStResId,
      'sScriptId': instance.scriptId,
      'sAutoAblArgStr0': instance.autoAblArgStr0,
      'sAutoAblArgStr1': instance.autoAblArgStr1,
      'u1RsvFlag0': const BoolIntConverter().toJson(instance.rsvFlag0),
      'u1RsvFlag1': const BoolIntConverter().toJson(instance.rsvFlag1),
      'u1RsvFlag2': const BoolIntConverter().toJson(instance.rsvFlag2),
      'u1RsvFlag3': const BoolIntConverter().toJson(instance.rsvFlag3),
      'u4UseRole': instance.useRole,
      'u4MenuCategory': instance.menuCategory,
      'i16MenuSortNo': instance.menuSortNo,
      'i16ScriptArg0': instance.scriptArg0,
      'i16ScriptArg1': instance.scriptArg1,
      'u8AutoAblKind': instance.autoAblKind,
      'i16AutoAblArgInt0': instance.autoAblArgInt0,
      'i16AutoAblArgInt1': instance.autoAblArgInt1,
      'i16WepLvArg0': instance.wepLvArg0,
      'i16WepLvArg1': instance.wepLvArg1,
    };
