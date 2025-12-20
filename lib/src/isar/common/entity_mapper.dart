import 'package:ff13_mod_resource/models/wdb_entities/xiii/battle_ability.dart'
    as wdb_battle_ability;
import 'package:ff13_mod_resource/models/wdb_entities/xiii/battle_auto_ability.dart'
    as wdb_battle_auto_ability;
import 'package:ff13_mod_resource/models/wdb_entities/xiii/item.dart'
    as wdb_item;
import 'package:ff13_mod_resource/src/isar/common/models.dart' as common_models;
import 'package:ff13_mod_resource/src/isar/update_sepc.dart';

IsarUpsertSpec? commonIsarEntityMappers<T>(String sheetName) {
  return switch (sheetName) {
        'bt_ability' => IsarUpsertSpec<common_models.BattleAbility>(
          getCollection: (isar) =>
              common_models.GetBattleAbilityCollection(isar).battleAbilitys,
          map: (record, wdbEntity) {
            final entity = wdbEntity as wdb_battle_ability.BattleAbility;
            return common_models.BattleAbility(
              record: record,
              stringResId: entity.stringResId,
              infoStResId: entity.infoStResId,
            );
          },
        ),
        'bt_auto_ability' => IsarUpsertSpec<common_models.BattleAutoAbility>(
          getCollection: (isar) => common_models.GetBattleAutoAbilityCollection(
            isar,
          ).battleAutoAbilitys,
          map: (record, wdbEntity) {
            final entity =
                wdbEntity as wdb_battle_auto_ability.BattleAutoAbility;
            return common_models.BattleAutoAbility(
              record: record,
              stringResId: entity.stringResId,
              infoStResId: entity.infoStResId,
            );
          },
        ),
        'item' => IsarUpsertSpec<common_models.Item>(
          getCollection: (isar) => common_models.GetItemCollection(isar).items,
          map: (record, wdbEntity) {
            final entity = wdbEntity as wdb_item.Item;
            return common_models.Item(
              record: record,
              itemNameStringId: entity.itemNameStringId,
              helpStringId: entity.helpStringId,
            );
          },
        ),
        _ => null,
      }
      as IsarUpsertSpec<T>?;
}

final Map<String, String> commonWdbSheetNameToIsarClassName = {
  'bt_ability': 'BattleAbility',
  'bt_auto_ability': 'BattleAutoAbility',
  'item': 'Item',
};
