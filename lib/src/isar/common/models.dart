import 'package:isar_plus/isar_plus.dart';

part 'models.g.dart';

/// FNV-1a 64bit hash algorithm optimized for Dart Strings
int fastHash(String string) {
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

@Collection()
class Strings {
  @Index()
  String strResourceId;

  String value;

  /// Source file path (relative to the scanned directory).
  /// Null for single-file loads, populated for batch/directory loads.
  @Index()
  String? sourceFile;

  Strings({required this.strResourceId, required this.value, this.sourceFile});

  int get id => fastHash(strResourceId);
}

/// A flexible lookup entry that maps any WDB record to its string resource IDs.
/// Replaces separate Item, BattleAbility, BattleAutoAbility collections with a
/// unified approach that can handle any entity type.
@Collection()
class EntityLookup {
  /// Entity category: 'item', 'ability', 'shop', 'mission', etc.
  @Index()
  String category;

  /// WDB record ID (unique within category)
  @Index()
  String record;

  /// String resource ID for the primary name
  String? nameStringId;

  /// String resource ID for description/help text
  String? descriptionStringId;

  /// Additional string references as key-value pairs.
  /// For extensibility without schema changes.
  List<String>? extraKeys;
  List<String>? extraValues;

  EntityLookup({
    required this.category,
    required this.record,
    this.nameStringId,
    this.descriptionStringId,
    this.extraKeys,
    this.extraValues,
  });

  int get id => fastHash('$category:$record');

  /// Get an extra string ID by key name.
  String? getExtraStringId(String key) {
    if (extraKeys == null) return null;
    final idx = extraKeys!.indexOf(key);
    return idx >= 0 && extraValues != null && idx < extraValues!.length
        ? extraValues![idx]
        : null;
  }
}
