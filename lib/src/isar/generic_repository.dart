import 'package:ff13_mod_resource/models/wdb_entities/wdb_entity.dart';

abstract class GameRepository {
  // --- Read (Sync - Fast Isolate access) ---
  String? getAbilityName(String abilityId);
  Map<String, String?> getBatchAbilityNames(List<String> abilityIds);
  String? getAbilityDescription(String abilityId);
  Map<String, String?> getBatchAbilityDescriptions(List<String> abilityIds);
  String? getItemDescription(String itemId);
  Map<String, String?> getBatchItemDescriptions(List<String> itemIds);
  String? getItemName(String itemId);
  Map<String, String?> getBatchItemNames(List<String> itemIds);
  String? resolveStringId(String stringId);
  Map<String, String?> resolveBatchStringIds(List<String> stringIds);
  bool stringsLoaded();

  // --- Write / Async Operations (Moved from AppDatabase) ---
  int insertStringData(Map<String, String> strings);
  void addString(String id, String value);
  void updateString(String id, String newValue);
  void deleteString(String id);
  int getStringCount();

  void clearDatabase();
  void close();
  //Will leverate a microtask instead of Isolate
  Future<void> upsertWdbEntities(
    String sheetName,
    Map<String, WdbEntity> entities,
  );
  Stream<Map<String, String>> getStrings();
}
