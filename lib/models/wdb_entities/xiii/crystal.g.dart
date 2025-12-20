// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crystal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Crystal _$CrystalFromJson(Map<String, dynamic> json) => Crystal(
  cpCost: (json['uCPCost'] as num?)?.toInt() ?? 0,
  abilityID: json['sAbilityID'] as String? ?? '',
  role: $enumDecode(
    _$CrystalRoleEnumMap,
    json['u4Role'],
    unknownValue: CrystalRole.none,
  ),
  crystalStage: (json['u4CrystalStage'] as num?)?.toInt() ?? 0,
  nodeType: $enumDecode(
    _$CrystalNodeTypeEnumMap,
    json['u8NodeType'],
    unknownValue: CrystalNodeType.none,
  ),
  nodeVal: (json['u16NodeVal'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$CrystalToJson(Crystal instance) => <String, dynamic>{
  'uCPCost': instance.cpCost,
  'sAbilityID': instance.abilityID,
  'u4Role': _$CrystalRoleEnumMap[instance.role]!,
  'u4CrystalStage': instance.crystalStage,
  'u8NodeType': _$CrystalNodeTypeEnumMap[instance.nodeType]!,
  'u16NodeVal': instance.nodeVal,
};

const _$CrystalRoleEnumMap = {
  CrystalRole.none: 0,
  CrystalRole.defender: 1,
  CrystalRole.attacker: 2,
  CrystalRole.blaster: 3,
  CrystalRole.enhancer: 4,
  CrystalRole.jammer: 5,
  CrystalRole.healer: 6,
};

const _$CrystalNodeTypeEnumMap = {
  CrystalNodeType.none: 0,
  CrystalNodeType.hp: 1,
  CrystalNodeType.strength: 2,
  CrystalNodeType.magic: 3,
  CrystalNodeType.accessory: 4,
  CrystalNodeType.atbSegment: 5,
  CrystalNodeType.ability: 6,
  CrystalNodeType.role: 7,
};
