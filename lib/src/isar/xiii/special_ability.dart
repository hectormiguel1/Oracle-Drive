import 'package:oracle_drive/src/isar/common/models.dart' show fastHash;
import 'package:isar_plus/isar_plus.dart';
import 'package:oracle_drive/models/wdb_entities/xiii/special_ability.dart'
    as wdb_entity;

part 'special_ability.g.dart';

@Collection()
class SpecialAbility {
  @Index()
  String record; // Primary key from WDB
  String ability;

  SpecialAbility({required this.record, required this.ability});

  factory SpecialAbility.fromWdbEntity(
    String record,
    wdb_entity.SpecialAbility wdbSpecialAbility,
  ) {
    return SpecialAbility(record: record, ability: wdbSpecialAbility.ability);
  }

  int get id => fastHash(record);
}
