import 'package:oracle_drive/src/isar/common/models.dart';

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

  /// Upsert lookup entities to the database.
  void upsertLookups(List<EntityLookup> lookups);

  Stream<Map<String, String>> getStrings();

  /// Get all strings with source file information.
  Stream<List<Strings>> getStringsWithSource();

  /// Insert strings with source file tracking.
  void insertStringsWithSource(List<Strings> strings);

  /// Get strings filtered by source file path.
  Map<String, String> getStringsBySourceFile(String sourceFile);

  /// Get all distinct source files in the database.
  List<String> getDistinctSourceFiles();
}
