import 'package:isar_plus/isar_plus.dart';

part 'settings_models.g.dart';

/// FNV-1a 64bit hash algorithm optimized for Dart Strings
int _fastHash(String string) {
  var hash = 0xcbf29ce484222325;

  var i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }

  return hash;
}

/// A key-value setting stored in the central database.
@Collection()
class AppSettings {
  /// Setting key (unique identifier)
  @Index(unique: true)
  String key;

  /// Setting value (JSON-encoded for complex types)
  String value;

  /// Last modified timestamp
  DateTime modifiedAt;

  AppSettings({
    required this.key,
    required this.value,
    required this.modifiedAt,
  });

  int get id => _fastHash(key);

  @override
  String toString() => 'AppSettings($key=$value)';
}

/// Well-known setting keys for the application.
class SettingKeys {
  SettingKeys._();

  // Journal settings
  static const String journalEnabled = 'journal.enabled';
  static const String journalRetentionMode = 'journal.retention.mode';
  static const String journalRetentionDays = 'journal.retention.days';
  static const String journalRetentionCount = 'journal.retention.count';

  // Default workspace paths per game
  static const String defaultWorkspaceFf13 = 'workspace.default.ff13';
  static const String defaultWorkspaceFf132 = 'workspace.default.ff13_2';
  static const String defaultWorkspaceFf13Lr = 'workspace.default.ff13_lr';

  // UI preferences
  static const String themeMode = 'ui.theme.mode';
  static const String lastSelectedGame = 'ui.last_selected_game';
}

/// Journal retention mode options.
enum JournalRetentionMode {
  unlimited,
  days,
  count,
}
