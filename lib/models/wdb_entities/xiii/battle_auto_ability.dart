import 'package:ff13_mod_resource/models/wdb_entities/converters.dart';
import 'package:ff13_mod_resource/models/wdb_entities/wdb_entity.dart';
import 'package:ff13_mod_resource/models/wdb_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'battle_auto_ability.g.dart';

@JsonSerializable()
class BattleAutoAbility extends WdbEntity {
  @JsonKey(name: 'sStringResId', defaultValue: '')
  final String stringResId;

  @JsonKey(name: 'sInfoStResId', defaultValue: '')
  final String infoStResId;

  @JsonKey(name: 'sScriptId', defaultValue: '')
  final String scriptId;

  @JsonKey(name: 'sAutoAblArgStr0', defaultValue: '')
  final String autoAblArgStr0;

  @JsonKey(name: 'sAutoAblArgStr1', defaultValue: '')
  final String autoAblArgStr1;

  @JsonKey(name: 'u1RsvFlag0')
  @BoolIntConverter()
  final bool rsvFlag0;

  @JsonKey(name: 'u1RsvFlag1')
  @BoolIntConverter()
  final bool rsvFlag1;

  @JsonKey(name: 'u1RsvFlag2')
  @BoolIntConverter()
  final bool rsvFlag2;

  @JsonKey(name: 'u1RsvFlag3')
  @BoolIntConverter()
  final bool rsvFlag3;

  @JsonKey(name: 'u4UseRole', defaultValue: 0)
  final int useRole;

  @JsonKey(name: 'u4MenuCategory', defaultValue: 0)
  final int menuCategory;

  @JsonKey(name: 'i16MenuSortNo', defaultValue: 0)
  final int menuSortNo;

  @JsonKey(name: 'i16ScriptArg0', defaultValue: 0)
  final int scriptArg0;

  @JsonKey(name: 'i16ScriptArg1', defaultValue: 0)
  final int scriptArg1;

  @JsonKey(name: 'u8AutoAblKind', defaultValue: 0)
  final int autoAblKind;

  @JsonKey(name: 'i16AutoAblArgInt0', defaultValue: 0)
  final int autoAblArgInt0;

  @JsonKey(name: 'i16AutoAblArgInt1', defaultValue: 0)
  final int autoAblArgInt1;

  @JsonKey(name: 'i16WepLvArg0', defaultValue: 0)
  final int wepLvArg0;

  @JsonKey(name: 'i16WepLvArg1', defaultValue: 0)
  final int wepLvArg1;

  BattleAutoAbility({
    required this.stringResId,
    required this.infoStResId,
    required this.scriptId,
    required this.autoAblArgStr0,
    required this.autoAblArgStr1,
    required this.rsvFlag0,
    required this.rsvFlag1,
    required this.rsvFlag2,
    required this.rsvFlag3,
    required this.useRole,
    required this.menuCategory,
    required this.menuSortNo,
    required this.scriptArg0,
    required this.scriptArg1,
    required this.autoAblKind,
    required this.autoAblArgInt0,
    required this.autoAblArgInt1,
    required this.wepLvArg0,
    required this.wepLvArg1,
  });

  factory BattleAutoAbility.fromMap(Map<String, dynamic> json) =>
      _$BattleAutoAbilityFromJson(json);

  static List<BattleAutoAbility> fromWdbData(WdbData data) {
    return data.rows.map((e) => BattleAutoAbility.fromMap(e)).toList();
  }

  @override
  Map<String, dynamic> toMap() => _$BattleAutoAbilityToJson(this);

  @override
  Map<LookupType, List<String>>? getLookupKeys() {
    return {
      LookupType.direct: ['sStringResId', 'sInfoStResId'],
    };
  }
}
