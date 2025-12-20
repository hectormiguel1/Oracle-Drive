import 'package:oracle_drive/models/wdb_entities/wdb_entity.dart';
import 'package:oracle_drive/models/wdb_entities/xiii-2/growth_pc_08.dart';

class WdbSchemaRegistry {
  static final Map<String, WdbEntity Function(Map<String, dynamic>)>
  _factories = {'r_grow_pc008': GrothPC08.fromMap};

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
    if (sheetName.startsWith('r_grow_pc')) {
      return GrothPC08.enumFields[fieldName];
    }
    return null;
  }

  static bool hasSchema(String sheetName) {
    return _factories.containsKey(sheetName);
  }
}
