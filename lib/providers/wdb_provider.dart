import 'package:oracle_drive/models/app_game_code.dart';
import 'package:oracle_drive/models/wdb_entities/wdb_entity.dart';
import 'package:oracle_drive/models/wdb_entities/xiii/schema_registry.dart'
    as xiii_registry;
import 'package:oracle_drive/models/wdb_entities/xiii-2/schema_registry.dart'
    as xiii2_registry;
import 'package:oracle_drive/models/wdb_model.dart';
import 'package:oracle_drive/src/services/app_database.dart';
import 'package:oracle_drive/src/utils/ztr_text_renderer.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final wdbPathProvider = StateProvider.family<String?, AppGameCode>(
  (ref, game) => null,
);

final wdbDataProvider = StateProvider.family<WdbData?, AppGameCode>(
  (ref, game) => null,
);

final wdbFilterProvider = StateProvider.family<String, AppGameCode>(
  (ref, game) => '',
);

final wdbIsProcessingProvider = StateProvider.family<bool, AppGameCode>(
  (ref, game) => false,
);

final filteredWdbDataProvider = Provider.family<WdbData?, AppGameCode>((
  ref,
  gameCode,
) {
  final data = ref.watch(wdbDataProvider(gameCode));
  final filterText = ref.watch(wdbFilterProvider(gameCode));

  if (data == null) {
    return null;
  }

  if (filterText.isEmpty) {
    return data;
  }

  final filter = filterText.toLowerCase();
  final originalRows = data.rows;
  final originalEntities = data.entities;

  final List<Map<String, dynamic>> filteredRows = [];
  final List<WdbEntity> filteredEntities = [];

  // Helper to get enum options dynamically based on game
  List<String>? getEnumOptions(String sheet, String col) {
    if (gameCode == AppGameCode.ff13_1) {
      return xiii_registry.WdbSchemaRegistry.getEnumOptions(sheet, col);
    } else if (gameCode == AppGameCode.ff13_2) {
      return xiii2_registry.WdbSchemaRegistry.getEnumOptions(sheet, col);
    }
    // Default or fallback
    return xiii_registry.WdbSchemaRegistry.getEnumOptions(sheet, col);
  }

  // Pre-fetch enum options for columns to avoid repeated lookups
  final Map<String, List<String>?> colEnumOptions = {};
  for (var col in data.columns) {
    colEnumOptions[col.originalName] = getEnumOptions(
      data.sheetName,
      col.originalName,
    );
  }

  // Pre-fetch Lookup Types
  final Map<String, LookupType> colLookupTypes = {};
  if (originalEntities != null && originalEntities.isNotEmpty) {
    final firstEntity = originalEntities.first;
    final lookupKeys = firstEntity.getLookupKeys();
    if (lookupKeys != null) {
      for (var entry in lookupKeys.entries) {
        for (var colName in entry.value) {
          colLookupTypes[colName] = entry.key;
        }
      }
    }
  }

  final repo = AppDatabase.instance.getRepositoryForGame(gameCode);

  for (int i = 0; i < originalRows.length; i++) {
    final row = originalRows[i];
    final entity = (originalEntities != null && i < originalEntities.length)
        ? originalEntities[i]
        : null;

    bool match = false;
    for (var col in data.columns) {
      final val = row[col.originalName];
      final enumOptions = colEnumOptions[col.originalName];

      if (enumOptions != null &&
          val is int &&
          val >= 0 &&
          val < enumOptions.length) {
        if (enumOptions[val].toLowerCase().contains(filter)) {
          match = true;
          break;
        }
      }

      // Check raw value string
      if (val.toString().toLowerCase().contains(filter)) {
        match = true;
        break;
      }

      // Check resolved string match (ZTR, Lookups)
      if (val is String) {
        String? resolved;
        if (val.isNotEmpty) {
          final lookupType = colLookupTypes[col.originalName];
          if (lookupType != null) {
            resolved = switch (lookupType) {
              LookupType.direct => repo.resolveStringId(val),
              LookupType.ability => repo.getAbilityName(val),
              LookupType.item => repo.getItemName(val),
            };
          }
        }

        final textToCheck = resolved ?? val;
        // Check ZTR stripped
        final stripped = ZtrTextRenderer.stripTags(textToCheck);
        if (stripped.toLowerCase().contains(filter)) {
          match = true;
          break;
        }
      }
    }

    if (match) {
      filteredRows.add(row);
      if (entity != null) filteredEntities.add(entity);
    }
  }

  return WdbData(
    sheetName: data.sheetName,
    columns: data.columns,
    rows: filteredRows,
    entities: (filteredEntities.isEmpty && originalEntities == null)
        ? null
        : filteredEntities,
  );
});
