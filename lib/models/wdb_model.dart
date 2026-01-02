import 'dart:typed_data';
import 'package:fabula_nova_sdk/bridge_generated/modules/wdb/structs.dart' as sdk;
import 'package:fabula_nova_sdk/bridge_generated/modules/wdb/enums.dart' as wdb_enums;

enum WdbColumnType { int, float, string, bool, array, crystalRole, crystalNodeType, unknown }

class WdbColumn {
  final String originalName;
  final String displayName;
  final WdbColumnType type;

  WdbColumn({
    required this.originalName,
    required this.displayName,
    this.type = WdbColumnType.unknown,
  });

  static String formatColumnName(String name) {
    if (name.toLowerCase() == 'record') return 'Record';

    String stripped = name;
    final prefixRegex = RegExp(r'^([ui][0-9]+|[uisfb])(?=[A-Z])');
    final match = prefixRegex.firstMatch(name);

    if (match != null) {
      stripped = name.substring(match.end);
    } else if (name.length > 1 &&
        ['u', 'i', 's', 'f', 'b'].contains(name[0]) &&
        name[1] == name[1].toUpperCase()) {
      stripped = name.substring(1);
    }

    final buffer = StringBuffer();
    for (int i = 0; i < stripped.length; i++) {
      final char = stripped[i];
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

class WdbData {
  String sheetName;
  List<WdbColumn> columns;
  List<Map<String, dynamic>> rows;
  Map<String, dynamic> header;

  WdbData({
    required this.sheetName,
    required this.columns,
    required this.rows,
    this.header = const {},
  });

  factory WdbData.fromSdk(sdk.WdbData sdkData) {
    final header = sdkData.header.map((k, v) => MapEntry(k, v.toDartValue()));
    final sheetName = header['sheetName'] as String? ?? "Unknown";
    
    final List<String> fieldNames = (header['!structitem'] as List<String>?) ?? [];
    
    final rows = sdkData.records.map((record) {
      return record.map((k, v) => MapEntry(k, v.toDartValue()));
    }).toList();

    final List<WdbColumn> columns = [];
    final firstRow = rows.isNotEmpty ? rows.first : null;

    // Add the "record" column first if it exists in the rows
    if (firstRow != null && firstRow.containsKey('record')) {
      columns.add(WdbColumn(
        originalName: 'record',
        displayName: 'Record',
        type: WdbColumnType.string,
      ));
    }

    for (int i = 0; i < fieldNames.length; i++) {
      final name = fieldNames[i];
      WdbColumnType type = WdbColumnType.unknown;
      
      if (firstRow != null && firstRow.containsKey(name)) {
        final val = firstRow[name];
        if (val is wdb_enums.CrystalRole) {
          type = WdbColumnType.crystalRole;
        } else if (val is wdb_enums.CrystalNodeType) {
          type = WdbColumnType.crystalNodeType;
        } else if (val is int) {
          type = WdbColumnType.int;
        } else if (val is double) {
          type = WdbColumnType.float;
        } else if (val is String) {
          type = WdbColumnType.string;
        } else if (val is bool) {
          type = WdbColumnType.bool;
        } else if (val is List) {
          type = WdbColumnType.array;
        }
      } else if (name.startsWith('s')) {
        type = WdbColumnType.string;
      } else if (name.startsWith('f')) {
        type = WdbColumnType.float;
      } else if (name.startsWith('b')) {
        type = WdbColumnType.bool;
      } else if (name.startsWith('u') || name.startsWith('i')) {
        type = WdbColumnType.int;
      }

      columns.add(WdbColumn(
        originalName: name,
        displayName: WdbColumn.formatColumnName(name),
        type: type,
      ));
    }

    return WdbData(
      sheetName: sheetName,
      columns: columns,
      rows: rows,
      header: header,
    );
  }

  sdk.WdbData toSdk() {
    final Map<String, sdk.WdbValue> sdkHeader = {};
    header.forEach((k, v) {
      sdkHeader[k] = _inferWdbValue(v);
    });

    final List<Map<String, sdk.WdbValue>> sdkRecords = rows.map((row) {
      final Map<String, sdk.WdbValue> record = {};
      row.forEach((k, v) {
        // Find column to get type hint
        final col = columns.firstWhere(
          (c) => c.originalName == k,
          orElse: () => WdbColumn(originalName: k, displayName: k),
        );
        record[k] = _toWdbValue(v, col.type);
      });
      return record;
    }).toList();

    return sdk.WdbData(header: sdkHeader, records: sdkRecords);
  }

  static sdk.WdbValue _inferWdbValue(dynamic v) {
    if (v is wdb_enums.CrystalRole) return sdk.WdbValue.crystalRole(v);
    if (v is wdb_enums.CrystalNodeType) return sdk.WdbValue.crystalNodeType(v);
    if (v is int) return sdk.WdbValue.int(v);
    if (v is double) return sdk.WdbValue.float(v);
    if (v is String) return sdk.WdbValue.string(v);
    if (v is bool) return sdk.WdbValue.bool(v);
    if (v is Int32List) return sdk.WdbValue.intArray(v);
    if (v is Uint32List) return sdk.WdbValue.uIntArray(v);
    if (v is List<String>) return sdk.WdbValue.stringArray(v);
    if (v is BigInt) return sdk.WdbValue.uInt64(v);
    return const sdk.WdbValue.unknown();
  }

  static sdk.WdbValue _toWdbValue(dynamic v, WdbColumnType type) {
    if (v == null) return const sdk.WdbValue.unknown();

    switch (type) {
      case WdbColumnType.int:
        return sdk.WdbValue.int(v is int ? v : int.tryParse(v.toString()) ?? 0);
      case WdbColumnType.float:
        return sdk.WdbValue.float(
          v is double ? v : double.tryParse(v.toString()) ?? 0.0,
        );
      case WdbColumnType.string:
        return sdk.WdbValue.string(v.toString());
      case WdbColumnType.bool:
        if (v is bool) return sdk.WdbValue.bool(v);
        if (v is int) return sdk.WdbValue.bool(v != 0);
        return sdk.WdbValue.bool(v.toString().toLowerCase() == 'true');
      case WdbColumnType.array:
        if (v is Int32List) return sdk.WdbValue.intArray(v);
        if (v is Uint32List) return sdk.WdbValue.uIntArray(v);
        if (v is List<String>) return sdk.WdbValue.stringArray(v);
        return const sdk.WdbValue.unknown();
      case WdbColumnType.crystalRole:
        if (v is wdb_enums.CrystalRole) return sdk.WdbValue.crystalRole(v);
        // Handle conversion from int or string
        if (v is int) return sdk.WdbValue.crystalRole(wdb_enums.CrystalRole.values[v.clamp(0, wdb_enums.CrystalRole.values.length - 1)]);
        return sdk.WdbValue.crystalRole(wdb_enums.CrystalRole.none);
      case WdbColumnType.crystalNodeType:
        if (v is wdb_enums.CrystalNodeType) return sdk.WdbValue.crystalNodeType(v);
        // Handle conversion from int or string
        if (v is int) return sdk.WdbValue.crystalNodeType(wdb_enums.CrystalNodeType.values[v.clamp(0, wdb_enums.CrystalNodeType.values.length - 1)]);
        return sdk.WdbValue.crystalNodeType(wdb_enums.CrystalNodeType.none);
      case WdbColumnType.unknown:
        return _inferWdbValue(v);
    }
  }
}

extension WdbValueExt on sdk.WdbValue {
  dynamic toDartValue() {
    return when(
      int: (v) => v,
      uInt: (v) => v,
      float: (v) => v,
      string: (v) => v,
      bool: (v) => v,
      intArray: (v) => v,
      uIntArray: (v) => v,
      stringArray: (v) => v,
      uInt64: (v) => v,
      crystalRole: (v) => v, // Returns wdb_enums.CrystalRole
      crystalNodeType: (v) => v, // Returns wdb_enums.CrystalNodeType
      unknown: () => null,
    );
  }
}

/// Extension to convert SDK WdbValue to display string for UI
extension WdbValueDisplay on sdk.WdbValue {
  String toDisplayString() {
    return when(
      int: (v) => v.toString(),
      uInt: (v) => v.toString(),
      float: (v) => v.toString(),
      string: (v) => v,
      bool: (v) => v ? 'true' : 'false',
      intArray: (v) => v.toString(),
      uIntArray: (v) => v.toString(),
      stringArray: (v) => v.toString(),
      uInt64: (v) => v.toString(),
      crystalRole: (v) => v.name,
      crystalNodeType: (v) => v.name,
      unknown: () => '',
    );
  }
}

/// Re-export the enums for convenience
typedef CrystalRole = wdb_enums.CrystalRole;
typedef CrystalNodeType = wdb_enums.CrystalNodeType;
