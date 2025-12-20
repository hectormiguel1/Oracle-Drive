import 'package:ff13_mod_resource/src/isar/common/models.dart';
import 'package:isar_plus/isar_plus.dart';

final List<IsarGeneratedSchema> schemas = [
  StringsSchema,
  BattleAbilitySchema,
  BattleAutoAbilitySchema,
  ItemSchema,
];

final Map<String, IsarGeneratedSchema> schemaByName = {
  'Strings': StringsSchema,
  'BattleAbility': BattleAbilitySchema,
  'BattleAutoAbility': BattleAutoAbilitySchema,
  'Item': ItemSchema,
};
