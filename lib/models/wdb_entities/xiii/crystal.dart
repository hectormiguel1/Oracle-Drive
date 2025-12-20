import 'package:oracle_drive/models/wdb_entities/wdb_entity.dart';
import 'package:oracle_drive/models/wdb_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'crystal.g.dart';

enum CrystalRole {
  @JsonValue(0)
  none,
  @JsonValue(1)
  defender,
  @JsonValue(2)
  attacker,
  @JsonValue(3)
  blaster,
  @JsonValue(4)
  enhancer,
  @JsonValue(5)
  jammer,
  @JsonValue(6)
  healer,
}

enum CrystalNodeType {
  @JsonValue(0)
  none,
  @JsonValue(1)
  hp,
  @JsonValue(2)
  strength,
  @JsonValue(3)
  magic,
  @JsonValue(4)
  accessory,
  @JsonValue(5)
  atbSegment,
  @JsonValue(6)
  ability,
  @JsonValue(7)
  role,
}

@JsonSerializable()
class Crystal extends WdbEntity {
  @JsonKey(name: 'uCPCost', defaultValue: 0)
  final int cpCost;

  @JsonKey(name: 'sAbilityID', defaultValue: '')
  final String abilityID;

  @JsonKey(name: 'u4Role', unknownEnumValue: CrystalRole.none)
  final CrystalRole role;

  @JsonKey(name: 'u4CrystalStage', defaultValue: 0)
  final int crystalStage;

  @JsonKey(name: 'u8NodeType', unknownEnumValue: CrystalNodeType.none)
  final CrystalNodeType nodeType;

  @JsonKey(name: 'u16NodeVal', defaultValue: 0)
  final int nodeVal;

  Crystal({
    required this.cpCost,
    required this.abilityID,
    required this.role,
    required this.crystalStage,
    required this.nodeType,
    required this.nodeVal,
  });

  factory Crystal.fromMap(Map<String, dynamic> json) => _$CrystalFromJson(json);

  static List<Crystal> fromWdbData(WdbData data) {
    return data.rows.map((e) => Crystal.fromMap(e)).toList();
  }

  @override
  Map<String, dynamic> toMap() => _$CrystalToJson(this);

  static const Map<String, List<String>> enumFields = {
    'u4Role': [
      'None',
      'Defender',
      'Attacker',
      'Blaster',
      'Enhancer',
      'Jammer',
      'Healer',
    ],
    'u8NodeType': [
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
  Map<LookupType, List<String>>? getLookupKeys() {
    return {
      .ability: ['sAbilityID'],
    };
  }
}
