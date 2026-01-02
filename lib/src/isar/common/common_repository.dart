import 'package:oracle_drive/src/isar/common/lookup_config.dart';
import 'package:oracle_drive/src/isar/common/models.dart';
import 'package:oracle_drive/src/isar/generic_repository.dart';
import 'package:isar_plus/isar_plus.dart';
import 'package:logging/logging.dart';

/// A unified repository implementation for all games.
/// Lookups are handled by LookupConfig, not entity mappers.
class CommonGameRepository implements GameRepository {
  final Logger _logger;
  final Isar database;

  CommonGameRepository(this.database, String debugName)
    : _logger = Logger('${debugName}Repository');

  // --- Read Methods (Sync) ---

  String? _resolveStringById(String stringId, [Isar? db]) {
    final stringsCollection = GetStringsCollection(db ?? database).strings;
    final stringEntry = stringsCollection
        .where()
        .strResourceIdEqualTo(stringId)
        .findFirst();
    return stringEntry?.value;
  }

  /// Get an entity lookup by category and record ID.
  /// Uses the computed ID (hash of '$category:$record') for O(1) lookup.
  EntityLookup? _getEntityLookup(String category, String record, [Isar? db]) {
    final collection = GetEntityLookupCollection(db ?? database).entityLookups;
    final id = fastHash('$category:$record');
    return collection.get(id);
  }

  /// Get a string from an entity lookup by category and record ID.
  String? _getEntityString(
    String category,
    String recordId,
    String? Function(EntityLookup) stringIdSelector,
  ) {
    return database.read<String?>((db) {
      final entity = _getEntityLookup(category, recordId, db);
      if (entity == null) return null;
      final stringId = stringIdSelector(entity);
      if (stringId == null) return null;
      return _resolveStringById(stringId, db);
    });
  }

  /// Get batch strings from entity lookups by category and record IDs.
  /// Uses computed IDs for efficient batch lookup.
  Map<String, String?> _getBatchEntityStrings(
    String category,
    List<String> recordIds,
    String? Function(EntityLookup) stringIdSelector,
  ) {
    if (recordIds.isEmpty) return {};

    return database.read((db) {
      final entityCollection = GetEntityLookupCollection(db).entityLookups;
      final stringsCollection = GetStringsCollection(db).strings;

      // 1. Compute IDs and fetch all entities in one call
      final ids = recordIds.map((r) => fastHash('$category:$r')).toList();
      final entities = entityCollection.getAll(ids);

      // 2. Extract string IDs (filter out nulls from getAll)
      final stringIds = entities
          .whereType<EntityLookup>()
          .map(stringIdSelector)
          .whereType<String>()
          .toSet()
          .toList();

      // 3. Fetch all strings
      final strings = stringsCollection
          .where()
          .anyOf(stringIds, (q, String id) => q.strResourceIdEqualTo(id))
          .findAll();

      // 4. Create lookup maps
      final stringMap = {for (var s in strings) s.strResourceId: s.value};
      final entityMap = {
        for (var e in entities.whereType<EntityLookup>()) e.record: e,
      };

      final Map<String, String?> result = {};

      for (final id in recordIds) {
        final entity = entityMap[id];
        if (entity == null) {
          result[id] = null;
        } else {
          final stringId = stringIdSelector(entity);
          result[id] = stringId != null ? stringMap[stringId] : null;
        }
      }

      return result;
    });
  }

  @override
  String? getItemName(String itemId) {
    return _getEntityString(
      EntityCategory.item.value,
      itemId,
      (e) => e.nameStringId,
    );
  }

  @override
  String? getItemDescription(String itemId) {
    return _getEntityString(
      EntityCategory.item.value,
      itemId,
      (e) => e.descriptionStringId,
    );
  }

  @override
  String? getAbilityName(String abilityId) {
    return _getEntityString(
      EntityCategory.ability.value,
      abilityId,
      (e) => e.nameStringId,
    );
  }

  @override
  String? getAbilityDescription(String abilityId) {
    return _getEntityString(
      EntityCategory.ability.value,
      abilityId,
      (e) => e.descriptionStringId,
    );
  }

  @override
  Map<String, String?> getBatchItemNames(List<String> itemIds) {
    return _getBatchEntityStrings(
      EntityCategory.item.value,
      itemIds,
      (e) => e.nameStringId,
    );
  }

  @override
  Map<String, String?> getBatchItemDescriptions(List<String> itemIds) {
    return _getBatchEntityStrings(
      EntityCategory.item.value,
      itemIds,
      (e) => e.descriptionStringId,
    );
  }

  @override
  Map<String, String?> getBatchAbilityNames(List<String> abilityIds) {
    return _getBatchEntityStrings(
      EntityCategory.ability.value,
      abilityIds,
      (e) => e.nameStringId,
    );
  }

  @override
  Map<String, String?> getBatchAbilityDescriptions(List<String> abilityIds) {
    return _getBatchEntityStrings(
      EntityCategory.ability.value,
      abilityIds,
      (e) => e.descriptionStringId,
    );
  }

  @override
  String? resolveStringId(String stringId) {
    return database.read((db) {
      return _resolveStringById(stringId, db);
    });
  }

  @override
  Map<String, String?> resolveBatchStringIds(List<String> stringIds) {
    if (stringIds.isEmpty) return {};

    return database.read((db) {
      final stringsCollection = GetStringsCollection(db).strings;

      final strings = stringsCollection
          .where()
          .anyOf(stringIds, (q, String id) => q.strResourceIdEqualTo(id))
          .findAll();

      final stringMap = {for (var s in strings) s.strResourceId: s.value};

      final Map<String, String?> result = {};
      for (final id in stringIds) {
        result[id] = stringMap[id];
      }

      return result;
    });
  }

  @override
  bool stringsLoaded() {
    return database.read((db) {
      final stringsCollection = GetStringsCollection(db).strings;
      final count = stringsCollection.count();
      return count > 0;
    });
  }

  // --- Write / Async Operations ---

  @override
  int insertStringData(Map<String, String> strings) {
    return database.write((db) {
      final col = GetStringsCollection(db).strings;
      final objs = <Strings>[];
      for (final e in strings.entries) {
        objs.add(Strings(strResourceId: e.key, value: e.value));
      }
      col.putAll(objs);
      return objs.length;
    });
  }

  @override
  void addString(String id, String value) => database.write(
    (db) => GetStringsCollection(
      db,
    ).strings.put(Strings(strResourceId: id, value: value)),
  );

  @override
  void updateString(String id, String newValue) => database.write((db) {
    final existing = GetStringsCollection(
      db,
    ).strings.where().strResourceIdEqualTo(id).findFirst();
    if (existing != null) {
      existing.value = newValue;
      GetStringsCollection(db).strings.put(existing);
    } else {
      _logger.warning('String with id $id not found for update.');
    }
  });

  @override
  void deleteString(String id) => database.write(
    (db) => GetStringsCollection(
      db,
    ).strings.where().strResourceIdEqualTo(id).deleteAll(),
  );

  @override
  int getStringCount() {
    return database.read((db) {
      final collection = GetStringsCollection(db).strings;
      return collection.where().count();
    });
  }

  @override
  Stream<Map<String, String>> getStrings() async* {
    final List<Strings> allStrings = database.read((db) {
      return GetStringsCollection(db).strings.where().findAll();
    });

    int offset = 0;
    final int limit = 1000;

    while (offset < allStrings.length) {
      final chunk = allStrings.skip(offset).take(limit);
      yield {for (var str in chunk) str.strResourceId: str.value};
      offset += limit;
    }
  }

  @override
  Stream<List<Strings>> getStringsWithSource() async* {
    final List<Strings> allStrings = database.read((db) {
      return GetStringsCollection(db).strings.where().findAll();
    });

    int offset = 0;
    final int limit = 1000;

    while (offset < allStrings.length) {
      final chunk = allStrings.skip(offset).take(limit).toList();
      yield chunk;
      offset += limit;
    }
  }

  @override
  void upsertLookups(List<EntityLookup> lookups) {
    if (lookups.isEmpty) return;
    database.write((db) {
      final collection = GetEntityLookupCollection(db).entityLookups;
      collection.putAll(lookups);
    });
  }

  @override
  void clearDatabase() =>
      database.write((db) => GetStringsCollection(db).strings.clear());

  @override
  void close() {
    // We typically close the database here if the repo owns it.
    database.close();
  }

  @override
  void insertStringsWithSource(List<Strings> strings) {
    if (strings.isEmpty) return;
    database.write((db) {
      final col = GetStringsCollection(db).strings;
      col.putAll(strings);
    });
    _logger.info('Inserted ${strings.length} strings with source tracking');
  }

  @override
  Map<String, String> getStringsBySourceFile(String sourceFile) {
    return database.read((db) {
      final stringsCollection = GetStringsCollection(db).strings;
      final strings = stringsCollection
          .where()
          .sourceFileEqualTo(sourceFile)
          .findAll();
      return {for (var s in strings) s.strResourceId: s.value};
    });
  }

  @override
  List<String> getDistinctSourceFiles() {
    return database.read((db) {
      final stringsCollection = GetStringsCollection(db).strings;
      // Get all strings and extract unique source files
      final allStrings = stringsCollection.where().findAll();
      final sourceFiles = <String>{};
      for (final s in allStrings) {
        if (s.sourceFile != null && s.sourceFile!.isNotEmpty) {
          sourceFiles.add(s.sourceFile!);
        }
      }
      return sourceFiles.toList()..sort();
    });
  }
}
