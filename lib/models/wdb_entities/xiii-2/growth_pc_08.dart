import 'package:ff13_mod_resource/models/wdb_entities/wdb_entity.dart';
import 'package:ff13_mod_resource/models/wdb_entities/xiii-2/crystal_enums.dart';
import 'package:ff13_mod_resource/models/wdb_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'growth_pc_08.g.dart';

@JsonSerializable()
class GrothPC08 extends WdbEntity {
  @JsonKey(name: 'sAbilityID', defaultValue: '')
  final String abilityID;
  @JsonKey(name: 'u4Role', unknownEnumValue: CrystalRole.none)
  final CrystalRole role;
  @JsonKey(name: 'u3Kind', unknownEnumValue: CrystalNodeType.none)
  final CrystalNodeType nodeType;
  @JsonKey(name: 'u16Value', defaultValue: 0)
  final int nodeVal;

  GrothPC08({
    required this.abilityID,
    required this.role,
    required this.nodeType,
    required this.nodeVal,
  });

  static List<GrothPC08> fromWdbData(WdbData wdbData) {
    return wdbData.rows
        .map((e) => GrothPC08.fromMap(e))
        .toList(growable: false);
  }

  factory GrothPC08.fromMap(Map<String, dynamic> map) =>
      _$GrothPC08FromJson(map);

  @override
  Map<LookupType, List<String>>? getLookupKeys() {
    return {
      .ability: ["sAbilityID"],
    };
  }

  static const Map<String, List<String>?> enumFields = {
    'u4Role': [
      'None',
      'Defender',
      'Attacker',
      'Blaster',
      'Enhancer',
      'Jammer',
      'Healer',
    ],
    'u3Kind': [
      'None',
      'HP',
      'Strength',
      'Magic',
      'Accessory',
      'AtbSegment',
      'Ability',
      'Role',
    ],
  };

  @override
  Map<String, dynamic> toMap() => _$GrothPC08ToJson(this);
}
