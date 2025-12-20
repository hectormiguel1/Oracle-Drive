import 'package:json_annotation/json_annotation.dart';

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
