import 'package:oracle_drive/models/wdb_entities/wdb_entity.dart';
import 'package:oracle_drive/models/wdb_entities/xiii/battle_ability.dart';
import 'package:oracle_drive/models/wdb_entities/xiii/battle_auto_ability.dart';
import 'package:oracle_drive/models/wdb_entities/xiii/crystal.dart';
import 'package:oracle_drive/models/wdb_entities/xiii/item.dart';
import 'package:oracle_drive/models/wdb_entities/xiii/item_consume.dart';
import 'package:oracle_drive/models/wdb_entities/xiii/item_weapon.dart';
import 'package:oracle_drive/models/wdb_entities/xiii/mission.dart';
import 'package:oracle_drive/models/wdb_entities/xiii/shop.dart';
import 'package:oracle_drive/models/wdb_entities/xiii/special_ability.dart';

class WdbSchemaRegistry {
  static final Map<String, WdbEntity Function(Map<String, dynamic>)>
  _factories = {
    'item': Item.fromMap,
    'item_consume': ItemConsume.fromMap,
    'special_ability': SpecialAbility.fromMap,
    'item_weapon': ItemWeapon.fromMap,
    'bt_ability': BattleAbility.fromMap,
    'shop': Shop.fromMap,
    'bt_auto_ability': BattleAutoAbility.fromMap,
    'mission': Mission.fromMap,

    // Crystal
    'crystal_fang': Crystal.fromMap,
    'crystal_hope': Crystal.fromMap,
    'crystal_lightning': Crystal.fromMap,
    'crystal_sazh': Crystal.fromMap,
    'crystal_snow': Crystal.fromMap,
    'crystal_vanille': Crystal.fromMap,
  };

  static WdbEntity? createEntity(String sheetName, Map<String, dynamic> row) {
    // Normalize sheetName (e.g., remove extension if needed, but the dictionary includes extensions for some)
    // The dictionary keys are exact.
    // Try exact match first.
    if (_factories.containsKey(sheetName)) {
      return _factories[sheetName]!(row);
    }

    // Fallback: Check if it's a zone or script pattern if strict match failed?
    // The map is comprehensive for now based on the C# file.

    return null;
  }

  static List<String>? getEnumOptions(String sheetName, String fieldName) {
    if (sheetName.startsWith('crystal_')) {
      return Crystal.enumFields[fieldName];
    }
    return null;
  }

  static bool hasSchema(String sheetName) {
    return _factories.containsKey(sheetName);
  }
}
