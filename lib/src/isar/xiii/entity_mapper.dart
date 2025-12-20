import 'package:oracle_drive/models/wdb_entities/xiii/mission.dart'
    as wdb_mission;
import 'package:oracle_drive/models/wdb_entities/xiii/shop.dart' as wdb_shop;
import 'package:oracle_drive/models/wdb_entities/xiii/special_ability.dart'
    as wdb_special_ability;
import 'package:oracle_drive/src/isar/update_sepc.dart';
import 'package:oracle_drive/src/isar/xiii/mission.dart' as isar_mission;
import 'package:oracle_drive/src/isar/xiii/shop.dart' as isar_shop;
import 'package:oracle_drive/src/isar/xiii/special_ability.dart'
    as isar_special_ability;

IsarUpsertSpec<T>? xiiiIsarEntityMappers<T>(String sheetName) {
  return switch (sheetName) {
        'mission' => IsarUpsertSpec<isar_mission.Mission>(
          getCollection: (isar) =>
              isar_mission.GetMissionCollection(isar).missions,
          map: (record, wdbEntity) => isar_mission.Mission.fromWdbEntity(
            record,
            wdbEntity as wdb_mission.Mission,
          ),
        ),
        'shop' => IsarUpsertSpec<isar_shop.ShopTable>(
          getCollection: (isar) =>
              isar_shop.GetShopTableCollection(isar).shopTables,
          map: (record, wdbEntity) => isar_shop.ShopTable.fromWdbEntity(
            record,
            wdbEntity as wdb_shop.Shop,
          ),
        ),
        'special_ability' =>
          IsarUpsertSpec<isar_special_ability.SpecialAbility>(
            getCollection: (isar) =>
                isar_special_ability.GetSpecialAbilityCollection(
                  isar,
                ).specialAbilitys,
            map: (record, wdbEntity) =>
                isar_special_ability.SpecialAbility.fromWdbEntity(
                  record,
                  wdbEntity as wdb_special_ability.SpecialAbility,
                ),
          ),
        _ => null,
      }
      as IsarUpsertSpec<T>?;
}

final Map<String, String> xiiiWdbSheetNameToIsarClassName = {
  'mission': 'Mission',
  'shop': 'Shop',
  'special_ability': 'SpecialAbility',
};
