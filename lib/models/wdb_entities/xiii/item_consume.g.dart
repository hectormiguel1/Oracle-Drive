// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_consume.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemConsume _$ItemConsumeFromJson(Map<String, dynamic> json) => ItemConsume(
  abilityId: json['sAbilityId'] as String? ?? '',
  learnAbilityId: json['sLearnAbilityId'] as String? ?? '',
  isUseRemodel: const BoolIntConverter().fromJson(json['u1IsUseRemodel']),
  isUseGrow: const BoolIntConverter().fromJson(json['u1IsUseGrow']),
  consumeAP: (json['u16ConsumeAP'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ItemConsumeToJson(ItemConsume instance) =>
    <String, dynamic>{
      'sAbilityId': instance.abilityId,
      'sLearnAbilityId': instance.learnAbilityId,
      'u1IsUseRemodel': const BoolIntConverter().toJson(instance.isUseRemodel),
      'u1IsUseGrow': const BoolIntConverter().toJson(instance.isUseGrow),
      'u16ConsumeAP': instance.consumeAP,
    };
