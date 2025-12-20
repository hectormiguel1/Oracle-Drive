import 'package:oracle_drive/models/wdb_entities/wdb_entity.dart';
import 'package:oracle_drive/src/third_party/wdb/wdb.g.dart' as native;

class WdbData {
  String sheetName;
  List<WdbColumn> columns;
  List<Map<String, dynamic>> rows;
  List<WdbEntity>? entities;
  List<WdbHeaderEntry> header;

  WdbData({
    required this.sheetName,
    required this.columns,
    required this.rows,
    this.entities,
    this.header = const [],
  });
}

class WdbHeaderEntry {
  final String name;
  final native.WDBValueType type;
  final dynamic value;

  WdbHeaderEntry({required this.name, required this.type, required this.value});
}

class WdbColumn {
  final String originalName;
  final String displayName;
  final native.WDBValueType type;

  WdbColumn({
    required this.originalName,
    required this.displayName,
    required this.type,
  });

  static String formatColumnName(String name) {
    if (name.toLowerCase() == 'record') return 'Record';

    // 1. Identify and strip Hungarian prefix
    // Regex: Starts with (u, i followed by digits) OR (u, i, s, f, b single char)
    // Matches "u16NodeVal" -> "NodeVal"
    // Matches "sName" -> "Name"
    // Matches "uCPCost" -> "CPCost" (u without digits is often uint)

    String stripped = name;
    final prefixRegex = RegExp(r'^([ui][0-9]+|[uisfb])(?=[A-Z])');
    final match = prefixRegex.firstMatch(name);

    if (match != null) {
      stripped = name.substring(match.end);
    } else if (name.length > 1 &&
        ['u', 'i', 's', 'f', 'b'].contains(name[0]) &&
        name[1] == name[1].toUpperCase()) {
      // Fallback for simple single char prefix followed by Upper
      stripped = name.substring(1);
    }

    // 2. Split CamelCase (e.g., "CPCost" -> "CP Cost")
    final buffer = StringBuffer();
    for (int i = 0; i < stripped.length; i++) {
      final char = stripped[i];
      // Insert space if current is Upper, and previous was Lower
      if (i > 0 &&
          char.toUpperCase() == char &&
          stripped[i - 1].toUpperCase() != stripped[i - 1]) {
        buffer.write(' ');
      }
      buffer.write(char);
    }

    return buffer.toString();
  }
}
