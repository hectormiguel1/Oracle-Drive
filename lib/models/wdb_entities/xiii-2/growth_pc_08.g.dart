// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'growth_pc_08.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GrothPC08 _$GrothPC08FromJson(Map<String, dynamic> json) => GrothPC08(
  abilityID: json['sAbilityID'] as String? ?? '',
  role: $enumDecode(
    _$CrystalRoleEnumMap,
    json['u4Role'],
    unknownValue: CrystalRole.none,
  ),
  nodeType: $enumDecode(
    _$CrystalNodeTypeEnumMap,
    json['u3Kind'],
    unknownValue: CrystalNodeType.none,
  ),
  nodeVal: (json['u16Value'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$GrothPC08ToJson(GrothPC08 instance) => <String, dynamic>{
  'sAbilityID': instance.abilityID,
  'u4Role': _$CrystalRoleEnumMap[instance.role]!,
  'u3Kind': _$CrystalNodeTypeEnumMap[instance.nodeType]!,
  'u16Value': instance.nodeVal,
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
