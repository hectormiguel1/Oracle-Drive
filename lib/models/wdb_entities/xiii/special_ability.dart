import 'package:ff13_mod_resource/models/wdb_entities/wdb_entity.dart';
import 'package:ff13_mod_resource/models/wdb_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'special_ability.g.dart';

@JsonSerializable()
class SpecialAbility extends WdbEntity {
  @JsonKey(name: 'sAbility', defaultValue: '')
  final String ability;

  @JsonKey(name: 'u6Genre', defaultValue: 0)
  final int genre;

  @JsonKey(name: 'u3Count', defaultValue: 0)
  final int count;

  SpecialAbility({
    required this.ability,
    required this.genre,
    required this.count,
  });

  factory SpecialAbility.fromMap(Map<String, dynamic> json) =>
      _$SpecialAbilityFromJson(json);

  static List<SpecialAbility> fromWdbData(WdbData data) {
    return data.rows.map((e) => SpecialAbility.fromMap(e)).toList();
  }

  @override
  Map<String, dynamic> toMap() => _$SpecialAbilityToJson(this);

  @override
  Map<LookupType, List<String>>? getLookupKeys() {
    return {
      LookupType.ability: ['sAbility'],
    };
  }
}
