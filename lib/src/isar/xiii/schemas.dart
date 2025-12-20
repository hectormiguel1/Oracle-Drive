import 'package:ff13_mod_resource/src/isar/xiii/mission.dart';
import 'package:ff13_mod_resource/src/isar/xiii/shop.dart';
import 'package:ff13_mod_resource/src/isar/xiii/special_ability.dart';
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
