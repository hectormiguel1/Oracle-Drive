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

  Strings({required this.strResourceId, required this.value});

  int get id => fastHash(strResourceId);
}

@Collection()
class Item {
  @Index()
  String record;
  String itemNameStringId;
  String helpStringId;

  Item({
    required this.record,
    required this.itemNameStringId,
    required this.helpStringId,
  });

  int get id => fastHash(record);
}

@Collection()
class BattleAbility {
  @Index()
  String record; // Primary key from WDB
  String stringResId;
  String infoStResId;

  BattleAbility({
    required this.record,
    required this.stringResId,
    required this.infoStResId,
  });

  int get id => fastHash(record);
}

@Collection()
class BattleAutoAbility {
  @Index()
  String record; // Primary key from WDB
  String stringResId;
  String infoStResId;

  BattleAutoAbility({
    required this.record,
    required this.stringResId,
    required this.infoStResId,
  });

  int get id => fastHash(record);
}
