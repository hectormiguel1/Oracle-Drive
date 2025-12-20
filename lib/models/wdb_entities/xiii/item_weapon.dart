import 'package:oracle_drive/models/wdb_entities/converters.dart';
import 'package:oracle_drive/models/wdb_entities/wdb_entity.dart';
import 'package:oracle_drive/models/wdb_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'item_weapon.g.dart';

@JsonSerializable()
class ItemWeapon extends WdbEntity {
  @JsonKey(name: 'sWeaponCharaSpecId', defaultValue: '')
  final String weaponCharaSpecId;

  @JsonKey(name: 'sWeaponCharaSpecId2', defaultValue: '')
  final String weaponCharaSpecId2;

  @JsonKey(name: 'sAbility', defaultValue: '')
  final String ability;

  @JsonKey(name: 'sAbility2', defaultValue: '')
  final String ability2;

  @JsonKey(name: 'sAbility3', defaultValue: '')
  final String ability3;

  @JsonKey(name: 'sUpgradeAbility', defaultValue: '')
  final String upgradeAbility;

  @JsonKey(name: 'sAbilityHelpStringId', defaultValue: '')
  final String abilityHelpStringId;

  @JsonKey(name: 'uBuyPriceIncrement', defaultValue: 0)
  final int buyPriceIncrement;

  @JsonKey(name: 'uSellPriceIncrement', defaultValue: 0)
  final int sellPriceIncrement;

  @JsonKey(name: 'sDisasItem1', defaultValue: '')
  final String disasItem1;

  @JsonKey(name: 'sDisasItem2', defaultValue: '')
  final String disasItem2;

  @JsonKey(name: 'sDisasItem3', defaultValue: '')
  final String disasItem3;

  @JsonKey(name: 'sDisasItem4', defaultValue: '')
  final String disasItem4;

  @JsonKey(name: 'sDisasItem5', defaultValue: '')
  final String disasItem5;

  @JsonKey(name: 'u8UnkVal1', defaultValue: 0)
  final int unkVal1;

  @JsonKey(name: 'u8UnkVal2', defaultValue: 0)
  final int unkVal2;

  @JsonKey(name: 'u2UnkVal3', defaultValue: 0)
  final int unkVal3;

  @JsonKey(name: 'u7MaxLvl', defaultValue: 0)
  final int maxLvl;

  @JsonKey(name: 'u4UnkVal4', defaultValue: 0)
  final int unkVal4;

  @JsonKey(name: 'u1LightCanWear')
  @BoolIntConverter()
  final bool lightningCanWear;

  @JsonKey(name: 'u1SazCanWear')
  @BoolIntConverter()
  final bool sazCanWear;

  @JsonKey(name: 'u1SnowCanWear')
  @BoolIntConverter()
  final bool snowCanWear;

  @JsonKey(name: 'i10ExpRate1', defaultValue: 0)
  final int expRate1;

  @JsonKey(name: 'i10ExpRate2', defaultValue: 0)
  final int expRate2;

  @JsonKey(name: 'i10ExpRate3', defaultValue: 0)
  final int expRate3;

  @JsonKey(name: 'u1UnkBool4')
  @BoolIntConverter()
  final bool unkownBool4;

  @JsonKey(name: 'u1HopeCanWear')
  @BoolIntConverter()
  final bool hopeCanWear;

  @JsonKey(name: 'u8StatusModKind0', defaultValue: 0)
  final int statusModKind0;

  @JsonKey(name: 'u8StatusModKind1', defaultValue: 0)
  final int statusModKind1;

  @JsonKey(name: 'u4StatusModType', defaultValue: 0)
  final int statusModType;

  @JsonKey(name: 'u1FangCanWear')
  @BoolIntConverter()
  final bool fangCanWear;

  @JsonKey(name: 'u1VanilleCanWear')
  @BoolIntConverter()
  final bool vanilleCanWear;

  @JsonKey(name: 'u16UnkVal5', defaultValue: 0)
  final int unkVal5;

  @JsonKey(name: 'i16StatusModVal', defaultValue: 0)
  final int statusModVal;

  @JsonKey(name: 'u16UnkVal6', defaultValue: 0)
  final int unkVal6;

  @JsonKey(name: 'i16AttackModVal', defaultValue: 0)
  final int attackModVal;

  @JsonKey(name: 'u16UnkVal7', defaultValue: 0)
  final int unkVal7;

  @JsonKey(name: 'i16MagicModVal', defaultValue: 0)
  final int magicModVal;

  @JsonKey(name: 'i16AtbModVal', defaultValue: 0)
  final int atbModVal;

  @JsonKey(name: 'u16UnkVal8', defaultValue: 0)
  final int unkVal8;

  @JsonKey(name: 'u16UnkVal9', defaultValue: 0)
  final int unkVal9;

  @JsonKey(name: 'u16UnkVal10', defaultValue: 0)
  final int unkVal10;

  @JsonKey(name: 'u14DisasRate1', defaultValue: 0)
  final int disasRate1;

  @JsonKey(name: 'u7UnkVal11', defaultValue: 0)
  final int unkVal11;

  @JsonKey(name: 'u7UnkVal12', defaultValue: 0)
  final int unkVal12;

  @JsonKey(name: 'u14DisasRate2', defaultValue: 0)
  final int disasRate2;

  @JsonKey(name: 'u14DisasRate3', defaultValue: 0)
  final int disasRate3;

  @JsonKey(name: 'u7UnkVal13', defaultValue: 0)
  final int unkVal13;

  @JsonKey(name: 'u14DisasRate4', defaultValue: 0)
  final int disasRate4;

  @JsonKey(name: 'u7UnkVal14', defaultValue: 0)
  final int unkVal14;

  @JsonKey(name: 'u14DisasRate5', defaultValue: 0)
  final int disasRate5;

  ItemWeapon({
    required this.weaponCharaSpecId,
    required this.weaponCharaSpecId2,
    required this.ability,
    required this.ability2,
    required this.ability3,
    required this.upgradeAbility,
    required this.abilityHelpStringId,
    required this.buyPriceIncrement,
    required this.sellPriceIncrement,
    required this.disasItem1,
    required this.disasItem2,
    required this.disasItem3,
    required this.disasItem4,
    required this.disasItem5,
    required this.unkVal1,
    required this.unkVal2,
    required this.unkVal3,
    required this.maxLvl,
    required this.unkVal4,
    required this.lightningCanWear,
    required this.sazCanWear,
    required this.snowCanWear,
    required this.expRate1,
    required this.expRate2,
    required this.expRate3,
    required this.unkownBool4,
    required this.hopeCanWear,
    required this.statusModKind0,
    required this.statusModKind1,
    required this.statusModType,
    required this.fangCanWear,
    required this.vanilleCanWear,
    required this.unkVal5,
    required this.statusModVal,
    required this.unkVal6,
    required this.attackModVal,
    required this.unkVal7,
    required this.magicModVal,
    required this.atbModVal,
    required this.unkVal8,
    required this.unkVal9,
    required this.unkVal10,
    required this.disasRate1,
    required this.unkVal11,
    required this.unkVal12,
    required this.disasRate2,
    required this.disasRate3,
    required this.unkVal13,
    required this.disasRate4,
    required this.unkVal14,
    required this.disasRate5,
  });

  factory ItemWeapon.fromMap(Map<String, dynamic> json) =>
      _$ItemWeaponFromJson(json);

  static List<ItemWeapon> fromWdbData(WdbData data) {
    return data.rows.map((e) => ItemWeapon.fromMap(e)).toList();
  }

  @override
  Map<String, dynamic> toMap() => _$ItemWeaponToJson(this);

  @override
  Map<LookupType, List<String>>? getLookupKeys() {
    return {
      LookupType.ability: ['sAbility'],
      LookupType.direct: ['sAbility2', 'sAbility3', 'sAbilityHelpStringId'],
      LookupType.item: [
        'sUpgradeAbility',
        'sDisasItem1',
        'sDisasItem2',
        'sDisasItem3',
        'sDisasItem4',
        'sDisasItem5',
      ],
    };
  }
}
