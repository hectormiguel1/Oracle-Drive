// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'special_ability.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpecialAbility _$SpecialAbilityFromJson(Map<String, dynamic> json) =>
    SpecialAbility(
      ability: json['sAbility'] as String? ?? '',
      genre: (json['u6Genre'] as num?)?.toInt() ?? 0,
      count: (json['u3Count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$SpecialAbilityToJson(SpecialAbility instance) =>
    <String, dynamic>{
      'sAbility': instance.ability,
      'u6Genre': instance.genre,
      'u3Count': instance.count,
    };
