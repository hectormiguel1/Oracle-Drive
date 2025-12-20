import 'package:oracle_drive/src/isar/xiii/mission.dart';
import 'package:oracle_drive/src/isar/xiii/shop.dart';
import 'package:oracle_drive/src/isar/xiii/special_ability.dart';
import 'package:isar_plus/isar_plus.dart';

final List<IsarGeneratedSchema> schemas = [
  MissionSchema,
  ShopTableSchema,
  SpecialAbilitySchema,
];

final Map<String, IsarGeneratedSchema> schemaByName = {
  'Mission': MissionSchema,
  'Shop': ShopTableSchema,
  'SpecialAbility': SpecialAbilitySchema,
};
