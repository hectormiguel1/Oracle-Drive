import 'package:oracle_drive/models/wdb_entities/converters.dart';
import 'package:oracle_drive/models/wdb_entities/wdb_entity.dart';
import 'package:oracle_drive/models/wdb_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'item_consume.g.dart';

@JsonSerializable()
class ItemConsume extends WdbEntity {
  @JsonKey(name: 'sAbilityId', defaultValue: '')
  final String abilityId;

  @JsonKey(name: 'sLearnAbilityId', defaultValue: '')
  final String learnAbilityId;

  @JsonKey(name: 'u1IsUseRemodel')
  @BoolIntConverter()
  final bool isUseRemodel;

  @JsonKey(name: 'u1IsUseGrow')
  @BoolIntConverter()
  final bool isUseGrow;

  @JsonKey(name: 'u16ConsumeAP', defaultValue: 0)
  final int consumeAP;

  ItemConsume({
    required this.abilityId,
    required this.learnAbilityId,
    required this.isUseRemodel,
    required this.isUseGrow,
    required this.consumeAP,
  });

  factory ItemConsume.fromMap(Map<String, dynamic> json) =>
      _$ItemConsumeFromJson(json);

  static List<ItemConsume> fromWdbData(WdbData data) {
    return data.rows.map((e) => ItemConsume.fromMap(e)).toList();
  }

  @override
  Map<String, dynamic> toMap() => _$ItemConsumeToJson(this);

  @override
  Map<LookupType, List<String>>? getLookupKeys() {
    return {
      LookupType.ability: ['sAbilityId', 'sLearnAbilityId'],
    };
  }
}
