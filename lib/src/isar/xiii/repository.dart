import 'package:oracle_drive/src/isar/common/common_repository.dart';
import 'package:oracle_drive/src/isar/update_sepc.dart';
import 'package:oracle_drive/src/isar/xiii/entity_mapper.dart';
import 'package:oracle_drive/src/isar/xiii/mission.dart';
import 'package:oracle_drive/src/isar/xiii/shop.dart';
import 'package:oracle_drive/src/isar/xiii/special_ability.dart';
import 'package:isar_plus/isar_plus.dart';

class FF13Repository extends CommonGameRepository {
  FF13Repository(Isar database) : super(database, 'FF13');

  @override
  IsarUpsertSpec<dynamic>? getEntityMapper(String sheetName) {
    final specificMapper = xiiiIsarEntityMappers(sheetName);
    if (specificMapper != null) return specificMapper;
    return super.getEntityMapper(sheetName);
  }

  String? getSpecialAbilityName(String specialAbilityId) {
    return database.read<String?>((db) {
      final collection = GetSpecialAbilityCollection(db).specialAbilitys;
      final entity = collection
          .where()
          .recordEqualTo(specialAbilityId)
          .findFirst();
      if (entity == null) return null;
      return getAbilityName(entity.ability);
    });
  }

  String? getSpecialAbilityDescription(String specialAbilityId) {
    return database.read<String?>((db) {
      final collection = GetSpecialAbilityCollection(db).specialAbilitys;
      final entity = collection
          .where()
          .recordEqualTo(specialAbilityId)
          .findFirst();
      if (entity == null) return null;
      return getAbilityDescription(entity.ability);
    });
  }

  String? getShopName(String shopId) {
    return database.read<String?>((db) {
      final collection = GetShopTableCollection(db).shopTables;
      final entity = collection.where().recordEqualTo(shopId).findFirst();
      if (entity == null) return null;
      return resolveStringId(entity.shopNameLabel);
    });
  }

  Map<String, String?> getShopItems(String shopId) {
    return database.read<Map<String, String?>>((db) {
      final collection = GetShopTableCollection(db).shopTables;
      final entity = collection.where().recordEqualTo(shopId).findFirst();
      if (entity == null) return {};
      return getBatchItemNames(entity.itemLabels);
    });
  }

  Map<String, String?> getMissionInfo(String missionId) {
    return database.read<Map<String, String?>>((db) {
      final collection = GetMissionCollection(db).missions;
      final entity = collection.where().recordEqualTo(missionId).findFirst();
      if (entity == null) return {};

      final stringIds = [
        entity.missionTitleStringId,
        entity.missionExplanationStringId,
        entity.missionTargetStringId,
        entity.missionPosStringId,
        entity.missionMarkPosStringId,
      ];

      final resolved = resolveBatchStringIds(stringIds);

      return {
        'title': resolved[entity.missionTitleStringId],
        'explanation': resolved[entity.missionExplanationStringId],
        'target': resolved[entity.missionTargetStringId],
        'pos': resolved[entity.missionPosStringId],
        'markPos': resolved[entity.missionMarkPosStringId],
      };
    });
  }
}
