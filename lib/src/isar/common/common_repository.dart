import 'package:oracle_drive/models/wdb_entities/wdb_entity.dart';
import 'package:oracle_drive/src/isar/common/entity_mapper.dart';
import 'package:oracle_drive/src/isar/common/models.dart';
import 'package:oracle_drive/src/isar/generic_repository.dart';
import 'package:oracle_drive/src/isar/update_sepc.dart';
import 'package:isar_plus/isar_plus.dart';
import 'package:logging/logging.dart';

/// A base repository implementation containing logic shared across all three games.
/// specific game repositories should extend this class.
class CommonGameRepository implements GameRepository {
  final Logger _logger;
  final Isar database;

  CommonGameRepository(this.database, String debugName)
    : _logger = Logger('${debugName}Repository');

  IsarUpsertSpec<dynamic>? getEntityMapper(String sheetName) {
    return commonIsarEntityMappers(sheetName);
  }

  // --- Read Methods (Sync) ---

  String? _resolveStringById(String stringId, [Isar? db]) {
    final stringsCollection = GetStringsCollection(db ?? database).strings;
    final stringEntry = stringsCollection
        .where()
        .strResourceIdEqualTo(stringId)
        .findFirst();
    return stringEntry?.value;
  }

  String? _getItemString(
    String itemId,
    String Function(Item) stringIdSelector,
  ) {
    return database.read<String?>((db) {
      final itemCollection = GetItemCollection(db).items;
      final item = itemCollection.where().recordEqualTo(itemId).findFirst();
      if (item == null) {
        return null;
      }
      return _resolveStringById(stringIdSelector(item), db);
    });
  }

  String? _getAbilityString(
    String abilityId,
    String Function(dynamic) stringIdSelector,
  ) {
    return database.read<String?>((db) {
      final abilityCollection = GetBattleAbilityCollection(db).battleAbilitys;
      final autoAbilityCollection = GetBattleAutoAbilityCollection(
        db,
      ).battleAutoAbilitys;

      final ability = abilityCollection
          .where()
          .recordEqualTo(abilityId)
          .findFirst();
      final autoAbility = autoAbilityCollection
          .where()
          .recordEqualTo(abilityId)
          .findFirst();
      if (ability == null && autoAbility == null) {
        return null;
      }
      String stringResId = stringIdSelector(ability ?? autoAbility!);
      return _resolveStringById(stringResId, db);
    });
  }

  Map<String, String?> _getBatchItemStrings(
    List<String> itemIds,
    String Function(Item) stringIdSelector,
  ) {
    if (itemIds.isEmpty) return {};

    return database.read((db) {
      final itemCollection = GetItemCollection(db).items;
      final stringsCollection = GetStringsCollection(db).strings;

      // 1. Fetch all items
      final items = itemCollection
          .where()
          .anyOf(itemIds, (q, String id) => q.recordEqualTo(id))
          .findAll();

      // 2. Extract string IDs
      final stringIds = items.map(stringIdSelector).toSet().toList();

      // 3. Fetch all strings
      final strings = stringsCollection
          .where()
          .anyOf(stringIds, (q, String id) => q.strResourceIdEqualTo(id))
          .findAll();

      // 4. Create lookup map
      final stringMap = {for (var s in strings) s.strResourceId: s.value};
      final itemMap = {for (var i in items) i.record: i};

      final Map<String, String?> result = {};

      for (final id in itemIds) {
        final item = itemMap[id];
        if (item == null) {
          result[id] = null;
        } else {
          result[id] = stringMap[stringIdSelector(item)];
        }
      }

      return result;
    });
  }

  Map<String, String?> _getBatchAbilityStrings(
    List<String> abilityIds,
    String Function(dynamic) stringIdSelector,
  ) {
    if (abilityIds.isEmpty) return {};

    return database.read((db) {
      final abilityCollection = GetBattleAbilityCollection(db).battleAbilitys;
      final autoAbilityCollection = GetBattleAutoAbilityCollection(
        db,
      ).battleAutoAbilitys;
      final stringsCollection = GetStringsCollection(db).strings;

      // 1. Fetch abilities
      final abilities = abilityCollection
          .where()
          .anyOf(abilityIds, (q, String id) => q.recordEqualTo(id))
          .findAll();

      final foundAbilityIds = abilities.map((e) => e.record).toSet();
      final missingIds = abilityIds
          .where((id) => !foundAbilityIds.contains(id))
          .toList();

      // 2. Fetch auto-abilities for missing IDs
      final autoAbilities = missingIds.isEmpty
          ? <BattleAutoAbility>[] // Type hint for safety
          : autoAbilityCollection
                .where()
                .anyOf(missingIds, (q, String id) => q.recordEqualTo(id))
                .findAll();

      final stringIds = <String>{};
      final Map<String, String> abilityToStringIdMap = {};

      void processEntities(List<dynamic> entities) {
        for (var e in entities) {
          final sid = stringIdSelector(e);
          stringIds.add(sid);
          abilityToStringIdMap[e.record] = sid;
        }
      }

      processEntities(abilities);
      processEntities(autoAbilities);

      // 3. Fetch Strings
      final strings = stringsCollection
          .where()
          .anyOf(
            stringIds.toList(),
            (q, String id) => q.strResourceIdEqualTo(id),
          )
          .findAll();

      final stringMap = {for (var s in strings) s.strResourceId: s.value};

      // 4. Build Result
      final Map<String, String?> result = {};
      for (final id in abilityIds) {
        final resId = abilityToStringIdMap[id];
        if (resId == null) {
          result[id] = null;
        } else {
          result[id] = stringMap[resId];
        }
      }

      return result;
    });
  }

  @override
  String? getItemName(String itemId) {
    return _getItemString(itemId, (item) => item.itemNameStringId);
  }

  @override
  String? getItemDescription(String itemId) {
    return _getItemString(itemId, (item) => item.helpStringId);
  }

  @override
  String? getAbilityName(String abilityId) {
    return _getAbilityString(abilityId, (ability) => ability.stringResId);
  }

  @override
  String? getAbilityDescription(String abilityId) {
    return _getAbilityString(abilityId, (ability) => ability.infoStResId);
  }

  @override
  Map<String, String?> getBatchItemNames(List<String> itemIds) {
    return _getBatchItemStrings(itemIds, (item) => item.itemNameStringId);
  }

  @override
  Map<String, String?> getBatchItemDescriptions(List<String> itemIds) {
    return _getBatchItemStrings(itemIds, (item) => item.helpStringId);
  }

  @override
  Map<String, String?> getBatchAbilityNames(List<String> abilityIds) {
    return _getBatchAbilityStrings(
      abilityIds,
      (ability) => ability.stringResId,
    );
  }

  @override
  Map<String, String?> getBatchAbilityDescriptions(List<String> abilityIds) {
    return _getBatchAbilityStrings(
      abilityIds,
      (ability) => ability.infoStResId,
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
  Future<void> upsertWdbEntities(
    String sheetName,
    Map<String, WdbEntity> entities,
  ) async {
    final mapper = getEntityMapper(sheetName);
    if (mapper != null) {
      mapper.upsertEntities(database, entities);
    } else {
      _logger.warning('No mapper found for sheet: $sheetName');
    }
  }

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
    final collection = GetStringsCollection(database).strings;
    return collection.where().count();
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
  void clearDatabase() =>
      database.write((db) => GetStringsCollection(db).strings.clear());

  @override
  void close() {
    // We typically close the database here if the repo owns it.
    database.close();
  }
}
