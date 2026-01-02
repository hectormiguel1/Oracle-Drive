import 'dart:convert';

import 'package:isar_plus/isar_plus.dart';
import 'package:logging/logging.dart';
import 'package:oracle_drive/src/isar/settings/settings_models.dart';

/// Repository for managing application settings in the central database.
class SettingsRepository {
  final Isar _database;
  final Logger _logger = Logger('SettingsRepository');

  SettingsRepository(this._database);

  // --- Generic Operations ---

  /// Get a setting value by key.
  /// Returns null if the key doesn't exist.
  T? getValue<T>(String key, {T? defaultValue}) {
    final setting = _database.read((db) {
      return GetAppSettingsCollection(db)
          .appSettings
          .where()
          .keyEqualTo(key)
          .findFirst();
    });

    if (setting == null) return defaultValue;

    final decoded = _decodeValue<T>(setting.value);
    return decoded ?? defaultValue;
  }

  /// Set a setting value.
  void setValue<T>(String key, T value) {
    final encoded = _encodeValue(value);
    final setting = AppSettings(
      key: key,
      value: encoded,
      modifiedAt: DateTime.now(),
    );

    _database.write((db) {
      GetAppSettingsCollection(db).appSettings.put(setting);
    });

    _logger.fine('Set setting $key');
  }

  /// Check if a setting key exists.
  bool hasKey(String key) {
    return _database.read((db) {
      return GetAppSettingsCollection(db)
          .appSettings
          .where()
          .keyEqualTo(key)
          .findFirst() != null;
    });
  }

  /// Delete a setting by key.
  void deleteSetting(String key) {
    _database.write((db) {
      GetAppSettingsCollection(db)
          .appSettings
          .where()
          .keyEqualTo(key)
          .deleteAll();
    });
    _logger.fine('Deleted setting $key');
  }

  /// Get all settings as a map.
  Map<String, dynamic> getAllSettings() {
    return _database.read((db) {
      final settings = GetAppSettingsCollection(db)
          .appSettings
          .where()
          .findAll();

      return {
        for (final s in settings) s.key: _decodeValue<dynamic>(s.value),
      };
    });
  }

  // --- Journal Settings Convenience Methods ---

  /// Check if journaling is enabled.
  bool isJournalEnabled() {
    return getValue<bool>(SettingKeys.journalEnabled, defaultValue: true) ?? true;
  }

  /// Set whether journaling is enabled.
  void setJournalEnabled(bool enabled) {
    setValue(SettingKeys.journalEnabled, enabled);
  }

  /// Get the journal retention mode.
  JournalRetentionMode getJournalRetentionMode() {
    final value = getValue<String>(
      SettingKeys.journalRetentionMode,
      defaultValue: 'unlimited',
    );
    return JournalRetentionMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => JournalRetentionMode.unlimited,
    );
  }

  /// Set the journal retention mode.
  void setJournalRetentionMode(JournalRetentionMode mode) {
    setValue(SettingKeys.journalRetentionMode, mode.name);
  }

  /// Get the journal retention days (for time-based retention).
  int getJournalRetentionDays() {
    return getValue<int>(SettingKeys.journalRetentionDays, defaultValue: 30) ?? 30;
  }

  /// Set the journal retention days.
  void setJournalRetentionDays(int days) {
    setValue(SettingKeys.journalRetentionDays, days);
  }

  /// Get the journal retention count (for count-based retention).
  int getJournalRetentionCount() {
    return getValue<int>(SettingKeys.journalRetentionCount, defaultValue: 1000) ?? 1000;
  }

  /// Set the journal retention count.
  void setJournalRetentionCount(int count) {
    setValue(SettingKeys.journalRetentionCount, count);
  }

  // --- Workspace Settings Convenience Methods ---

  /// Get the default workspace path for a game.
  String? getDefaultWorkspace(int gameCode) {
    final key = _workspaceKeyForGame(gameCode);
    return getValue<String>(key);
  }

  /// Set the default workspace path for a game.
  void setDefaultWorkspace(int gameCode, String? path) {
    final key = _workspaceKeyForGame(gameCode);
    if (path == null) {
      deleteSetting(key);
    } else {
      setValue(key, path);
    }
  }

  String _workspaceKeyForGame(int gameCode) {
    switch (gameCode) {
      case 0:
        return SettingKeys.defaultWorkspaceFf13;
      case 1:
        return SettingKeys.defaultWorkspaceFf132;
      case 2:
        return SettingKeys.defaultWorkspaceFf13Lr;
      default:
        return SettingKeys.defaultWorkspaceFf13;
    }
  }

  // --- UI Settings Convenience Methods ---

  /// Get the last selected game code.
  int? getLastSelectedGame() {
    return getValue<int>(SettingKeys.lastSelectedGame);
  }

  /// Set the last selected game code.
  void setLastSelectedGame(int gameCode) {
    setValue(SettingKeys.lastSelectedGame, gameCode);
  }

  // --- Private Helpers ---

  String _encodeValue<T>(T value) {
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is double) return value.toString();
    if (value is bool) return value.toString();
    if (value is List || value is Map) return jsonEncode(value);
    return value.toString();
  }

  T? _decodeValue<T>(String encoded) {
    // Handle null/empty
    if (encoded.isEmpty) return null;

    // Try to infer type
    if (T == String || T == dynamic) {
      // Check if it looks like JSON
      if (encoded.startsWith('[') || encoded.startsWith('{')) {
        try {
          return jsonDecode(encoded) as T?;
        } catch (_) {
          return encoded as T?;
        }
      }
      return encoded as T?;
    }

    if (T == int) return int.tryParse(encoded) as T?;
    if (T == double) return double.tryParse(encoded) as T?;
    if (T == bool) return (encoded == 'true') as T?;

    // For dynamic, try to parse intelligently
    if (encoded == 'true') return true as T?;
    if (encoded == 'false') return false as T?;
    if (int.tryParse(encoded) != null) return int.parse(encoded) as T?;
    if (double.tryParse(encoded) != null) return double.parse(encoded) as T?;

    // Try JSON
    if (encoded.startsWith('[') || encoded.startsWith('{')) {
      try {
        return jsonDecode(encoded) as T?;
      } catch (_) {
        return encoded as T?;
      }
    }

    return encoded as T?;
  }

  /// Initialize default settings if not present.
  void initializeDefaults() {
    if (!hasKey(SettingKeys.journalEnabled)) {
      setValue(SettingKeys.journalEnabled, true);
    }
    if (!hasKey(SettingKeys.journalRetentionMode)) {
      setValue(SettingKeys.journalRetentionMode, 'unlimited');
    }
    if (!hasKey(SettingKeys.journalRetentionDays)) {
      setValue(SettingKeys.journalRetentionDays, 30);
    }
    if (!hasKey(SettingKeys.journalRetentionCount)) {
      setValue(SettingKeys.journalRetentionCount, 1000);
    }
    _logger.info('Initialized default settings');
  }
}
