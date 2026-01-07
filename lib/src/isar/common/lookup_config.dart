import 'dart:convert';
import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'package:oracle_drive/models/app_game_code.dart';
import 'package:oracle_drive/src/isar/common/models.dart';

part 'lookup_config.g.dart';

/// Entity category for the unified EntityLookup collection.
enum EntityCategory {
  item('item'),
  ability('ability'),
  itemAbility('item_ability'),
  mission('mission'),
  shop('shop'),
  specialAbility('special_ability');

  final String value;
  const EntityCategory(this.value);

  @override
  String toString() => value;
}

/// Configuration for extracting lookup data directly from WDB rows.
/// No need for full WdbEntity classes - just specify the field names.
@JsonSerializable()
class LookupConfig {
  /// EntityLookup.category (e.g., 'item', 'ability')
  final String category;

  /// WDB field name containing the name string ID
  final String nameField;

  /// WDB field name containing the description string ID (optional)
  final String? descriptionField;

  /// Additional WDB fields to extract as extra key-value pairs
  /// Maps extraKey name → WDB field name
  final Map<String, String>? extraFields;

  const LookupConfig({
    required this.category,
    required this.nameField,
    this.descriptionField,
    this.extraFields,
  });

  factory LookupConfig.fromJson(Map<String, dynamic> json) =>
      _$LookupConfigFromJson(json);

  Map<String, dynamic> toJson() => _$LookupConfigToJson(this);

  /// Extract an EntityLookup directly from a WDB row.
  EntityLookup? extractFromRow(String record, Map<String, dynamic> row) {
    final nameStringId = row[nameField] as String?;
    if (nameStringId == null || nameStringId.isEmpty) return null;

    final descriptionStringId = descriptionField != null
        ? row[descriptionField] as String?
        : null;

    List<String>? extraKeys;
    List<String>? extraValues;

    if (extraFields != null && extraFields!.isNotEmpty) {
      extraKeys = [];
      extraValues = [];
      for (final entry in extraFields!.entries) {
        final value = row[entry.value] as String?;
        if (value != null && value.isNotEmpty) {
          extraKeys.add(entry.key);
          extraValues.add(value);
        }
      }
      if (extraKeys.isEmpty) {
        extraKeys = null;
        extraValues = null;
      }
    }

    return EntityLookup(
      category: category,
      record: record,
      nameStringId: nameStringId,
      descriptionStringId: descriptionStringId,
      extraKeys: extraKeys,
      extraValues: extraValues,
    );
  }
}

/// Root configuration containing common lookups and game-specific overrides.
@JsonSerializable()
class LookupConfigRoot {
  /// Lookup configs shared across all games
  final Map<String, LookupConfig> common;

  /// Game-specific overrides (game code string → sheet name → config)
  final Map<String, Map<String, LookupConfig>>? overrides;

  const LookupConfigRoot({
    required this.common,
    this.overrides,
  });

  factory LookupConfigRoot.fromJson(Map<String, dynamic> json) =>
      _$LookupConfigRootFromJson(json);

  Map<String, dynamic> toJson() => _$LookupConfigRootToJson(this);

  /// Resolve the lookup config for a specific game and sheet name.
  /// Game-specific overrides take priority over common configs.
  LookupConfig? resolve(AppGameCode game, String sheetName) {
    // Check game-specific override first
    final gameKey = game.name; // e.g., 'ff13_1', 'ff13_2', 'ff13_lr'
    final override = overrides?[gameKey]?[sheetName];
    if (override != null) return override;

    // Fall back to common
    return common[sheetName];
  }

  /// Get all sheet names that have lookup configs (for a specific game).
  Set<String> getConfiguredSheets(AppGameCode game) {
    final sheets = common.keys.toSet();
    final gameKey = game.name;
    if (overrides?[gameKey] != null) {
      sheets.addAll(overrides![gameKey]!.keys);
    }
    return sheets;
  }
}

/// Registry that manages lookup configurations.
/// Supports loading from external JSON file or using embedded defaults.
class LookupConfigRegistry {
  static LookupConfigRegistry? _instance;
  static LookupConfigRegistry get instance => _instance ??= LookupConfigRegistry._();

  LookupConfigRoot _config;

  LookupConfigRegistry._() : _config = _defaultConfig;

  /// Load config from an external JSON file.
  /// Returns true if loaded successfully, false if file doesn't exist.
  Future<bool> loadFromFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return false;

    try {
      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      _config = LookupConfigRoot.fromJson(json);
      return true;
    } catch (e) {
      // Fall back to default on error
      _config = _defaultConfig;
      return false;
    }
  }

  /// Reset to embedded default config.
  void resetToDefault() {
    _config = _defaultConfig;
  }

  /// Get the current config.
  LookupConfigRoot get config => _config;

  /// Resolve lookup config for a game and sheet.
  LookupConfig? resolve(AppGameCode game, String sheetName) {
    return _config.resolve(game, sheetName);
  }

  /// Check if a sheet has lookup config for a game.
  bool hasConfig(AppGameCode game, String sheetName) {
    return resolve(game, sheetName) != null;
  }

  /// Export current config to JSON string (for saving/debugging).
  String exportToJson() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(_config.toJson());
  }
}

/// Embedded default configuration.
/// This can be overridden by loading from an external JSON file.
final LookupConfigRoot _defaultConfig = LookupConfigRoot(
  common: {
    // Items
    'Item': const LookupConfig(
      category: 'item',
      nameField: 'sItemNameStringId',
      descriptionField: 'sHelpStringId',
    ),
    'item_consume': const LookupConfig(
      category: 'item',
      nameField: 'sItemNameStringId',
      descriptionField: 'sHelpStringId',
    ),
    'ItemWeapon': const LookupConfig(
      category: 'item',
      nameField: 'sItemNameStringId',
      descriptionField: 'sHelpStringId',
    ),
    // Abilities
    'BattleAbility': const LookupConfig(
      category: 'ability',
      nameField: 'sStringResId',
      descriptionField: 'sInfoStResId',
    ),
    'BattleAutoAbility': const LookupConfig(
      category: 'ability',
      nameField: 'sStringResId',
      descriptionField: 'sInfoStResId',
    ),
    'PassiveAbility': const LookupConfig(
      category: 'ability',
      nameField: 'sStringResId',
      descriptionField: 'sInfoStResId',
    ),
    'SecretAbility': const LookupConfig(
      category: 'ability',
      nameField: 'sAbilityId',
    ),
    'BtRankedAbility': const LookupConfig(
      category: 'ability',
      nameField: 'sAbilityId',
    ),
    // Missions (FF13)
    'mission': const LookupConfig(
      category: 'mission',
      nameField: 'sMissionTitleStringId',
      descriptionField: 'sMissionExplanationStringId',
      extraFields: {
        'target': 'sMissionTargetStringId',
        'pos': 'sMissionPosStringId',
        'markPos': 'sMissionMarkPosStringId',
      },
    ),
    // Shops (FF13)
    'Shop': const LookupConfig(
      category: 'shop',
      nameField: 'sShopNameLabel',
    ),
    // Special Abilities (FF13) - stores ability reference for chained lookup
    'SpecialAbility': const LookupConfig(
      category: 'special_ability',
      nameField: 'sAbility', // This is an ability ID, not a string ID
    ),
    // Item Abilities - links items to their abilities
    'ItemAbility': const LookupConfig(
      category: 'item_ability',
      nameField: 'sAbilityId',
      extraFields: {
        'passiveAbility': 'sPasvAbility',
      },
    ),
  },
  overrides: {
    // Game-specific overrides go here if field names differ between games
  },
);
