import 'dart:ffi';

import 'package:ff13_mod_resource/models/wdb_entities/wdb_entity.dart';
import 'package:ff13_mod_resource/models/wdb_entities/xiii/schema_registry.dart'
    as ff13_schema_registry;
import 'package:ff13_mod_resource/models/wdb_entities/xiii-2/schema_registry.dart'
    as ff132_schema_registry;

import 'package:ff13_mod_resource/models/wdb_model.dart';
import 'package:ff13_mod_resource/src/services/native_service.dart';
import 'package:ff13_mod_resource/src/third_party/wbtlib/wbt.g.dart'
    as wbt_native;
import 'package:ff13_mod_resource/src/utils/native_result_utils.dart';
import 'package:ffi/ffi.dart';
import 'package:logging/logging.dart';

import 'wdb.g.dart' as native;

typedef LogLevel = native.LogLevel;

class WdbTool {
  static final Logger logger = Logger('WdbTool');

  static WdbData parseFile(String path, wbt_native.GameCode game) {
    return using((Arena arena) {
      final pathPtr = path.toNativeUtf8(allocator: arena).cast<Char>();
      final gameCodeValue = game.value;

      final result = native.WDB_ParseFile(pathPtr, gameCodeValue);

      return NativeResult.unwrap(
        result,
        native.free_result,
        onSuccess: (res) {
          final wdbFileCPtr = res.payload.data.cast<native.WDBFileC>();
          return convertFromWDBFileC(wdbFileCPtr, game);
        },
        failureMessage: "Failed to parse WDB file: $path",
      );
    });
  }

  static void writeFile(String path, wbt_native.GameCode game, WdbData data) {
    return using((Arena arena) {
      final pathPtr = path.toNativeUtf8(allocator: arena).cast<Char>();
      final gameCodeValue = game.value;

      final wdbFilePtr = arena<native.WDBFileC>();
      final ref = wdbFilePtr.ref;

      // 1. Set Name
      ref.wdbName = data.sheetName.toNativeUtf8(allocator: arena).cast();

      // 2. Set Header
      final headerList = data.header;
      ref.header.entryCount = headerList.length;
      if (headerList.isNotEmpty) {
        final headerEntriesPtr = arena<native.WDBEntry>(headerList.length);
        ref.header.entries = headerEntriesPtr;
        for (int i = 0; i < headerList.length; i++) {
          final entry = headerList[i];
          final entryRef = headerEntriesPtr[i];
          entryRef.key = entry.name.toNativeUtf8(allocator: arena).cast();
          setEntryValue(entryRef, entry.value, entry.type, arena);
        }
      } else {
        ref.header.entries = nullptr;
      }

      // 3. Set Records
      ref.recordCount = data.rows.length;
      if (data.rows.isNotEmpty) {
        final recordsPtr = arena<native.WDBRecordC>(data.rows.length);
        ref.records = recordsPtr;

        for (int i = 0; i < data.rows.length; i++) {
          final rowMap = data.rows[i];
          final recordRef = recordsPtr[i];

          // We use data.columns to determine order and type
          final colCount = data.columns.length;
          recordRef.entryCount = colCount;
          final entriesPtr = arena<native.WDBEntry>(colCount);
          recordRef.entries = entriesPtr;

          for (int j = 0; j < colCount; j++) {
            final col = data.columns[j];
            final entryRef = entriesPtr[j];

            // Key
            entryRef.key = col.originalName
                .toNativeUtf8(allocator: arena)
                .cast();
            setEntryValue(entryRef, rowMap[col.originalName], col.type, arena);
          }
        }
      } else {
        ref.records = nullptr;
      }

      // Call Native Write
      final result = native.WDB_WriteFile(pathPtr, gameCodeValue, wdbFilePtr);

      NativeResult.check(
        result,
        native.free_result,
        failureMessage: "Failed to write WDB file: $path",
      );
    });
  }

  // ========================================================================
  // Parsing (Delegated to NativeService)
  // ========================================================================

  static Future<WdbData> parseData(
    String path,
    wbt_native.GameCode game,
  ) async {
    return await NativeService.instance.parseWdb(path, game);
  }

  static Future<void> saveData(
    String path,
    wbt_native.GameCode game,
    WdbData data,
  ) async {
    await NativeService.instance.saveWdb(path, game, data);
  }

  /// Helper used by NativeService worker to convert C struct to Dart object.
  static WdbData convertFromWDBFileC(
    Pointer<native.WDBFileC> ptr,
    wbt_native.GameCode gameCode,
  ) {
    final ref = ptr.ref;
    final wdbName = ref.wdbName.cast<Utf8>().toDartString();

    final List<WdbColumn> columns = [];
    final List<Map<String, dynamic>> rows = [];
    final List<WdbHeaderEntry> header = [];

    // 0. Build Header
    if (ref.header.entryCount > 0) {
      for (int i = 0; i < ref.header.entryCount; i++) {
        final nativeEntry = ref.header.entries[i];
        final fieldName = nativeEntry.key.cast<Utf8>().toDartString();
        header.add(
          WdbHeaderEntry(
            name: fieldName,
            type: nativeEntry.value.type,
            value: _convertWDBValue(nativeEntry),
          ),
        );
      }
    }

    if (ref.recordCount > 0) {
      // 1. Build Schema from the first record
      final firstRecord = ref.records[0];
      for (int j = 0; j < firstRecord.entryCount; j++) {
        final nativeEntry = firstRecord.entries[j];
        final fieldName = nativeEntry.key.cast<Utf8>().toDartString();
        final valType = nativeEntry.value.type;

        columns.add(
          WdbColumn(
            originalName: fieldName,
            displayName: WdbColumn.formatColumnName(fieldName),
            type: valType,
          ),
        );
      }

      // 2. Populate Rows
      for (int i = 0; i < ref.recordCount; i++) {
        final nativeRecord = ref.records[i];
        final Map<String, dynamic> row = {};

        for (int j = 0; j < nativeRecord.entryCount; j++) {
          final nativeEntry = nativeRecord.entries[j];
          final fieldName = nativeEntry.key.cast<Utf8>().toDartString();
          final value = _convertWDBValue(nativeEntry);

          if (value == null &&
              nativeEntry.value.type !=
                  native.WDBValueType.WDB_VALUE_TYPE_UNKNOWN) {
            // It might be unknown type or handled, but let's keep it null if _convertWDBValue returned null
          }
          row[fieldName] = value;
        }
        rows.add(row);
      }
    }

    // 3. Create Typed Entities (Optional)
    List<WdbEntity>? entities;

    // Check if we have a schema for this sheet
    // We try exact match first, then stripped extension
    String? matchedSchemaName;
    final schemaCheckFunction = _schemaRegistryForGame(gameCode);
    final schemaCreationFunction = _schemaCreationForGame(gameCode);

    if (schemaCheckFunction(wdbName)) {
      matchedSchemaName = wdbName;
    } else if (wdbName.contains('.')) {
      final nameNoExt = wdbName.split('.').first;
      if (schemaCheckFunction(nameNoExt)) {
        matchedSchemaName = nameNoExt;
      }
    }

    if (matchedSchemaName != null) {
      entities = [];
      for (final row in rows) {
        final entity = schemaCreationFunction(matchedSchemaName, row);
        if (entity != null) {
          entities.add(entity);
        }
      }
    }

    return WdbData(
      sheetName: wdbName,
      columns: columns,
      rows: rows,
      entities: entities,
      header: header,
    );
  }

  static bool Function(String) _schemaRegistryForGame(
    wbt_native.GameCode gameCode,
  ) {
    return switch (gameCode) {
      .FF131 => ff13_schema_registry.WdbSchemaRegistry.hasSchema,
      .FF132 => ff132_schema_registry.WdbSchemaRegistry.hasSchema,
    };
  }

  static WdbEntity? Function(String, Map<String, dynamic>)
  _schemaCreationForGame(wbt_native.GameCode gameCode) {
    return switch (gameCode) {
      .FF131 => ff13_schema_registry.WdbSchemaRegistry.createEntity,
      .FF132 => ff132_schema_registry.WdbSchemaRegistry.createEntity,
    };
  }

  static void setEntryValue(
    native.WDBEntry entry,
    dynamic value,
    native.WDBValueType type,
    Arena arena,
  ) {
    entry.value.typeAsInt = type.value;

    switch (type) {
      case native.WDBValueType.WDB_VALUE_TYPE_INT:
        entry.value.data.int_val = (value is int) ? value : 0;
        break;
      case native.WDBValueType.WDB_VALUE_TYPE_UINT:
        entry.value.data.uint_val = (value is int) ? value : 0;
        break;
      case native.WDBValueType.WDB_VALUE_TYPE_FLOAT:
        entry.value.data.float_val = (value is double)
            ? value
            : (value is int ? value.toDouble() : 0.0);
        break;
      case native.WDBValueType.WDB_VALUE_TYPE_STRING:
        final s = value?.toString() ?? "";
        entry.value.data.string_val = s.toNativeUtf8(allocator: arena).cast();
        break;
      case native.WDBValueType.WDB_VALUE_TYPE_BOOL:
        // Dart bool to C int (0/1)
        entry.value.data.bool_val = (value == true || value == 1) ? 1 : 0;
        break;
      case native.WDBValueType.WDB_VALUE_TYPE_INT_ARRAY:
        final list = (value is List) ? value.cast<int>() : <int>[];
        entry.value.data.int_array_val.count = list.length;
        if (list.isNotEmpty) {
          final arrPtr = arena<Int>(list.length);
          for (int k = 0; k < list.length; k++) {
            arrPtr[k] = list[k];
          }
          entry.value.data.int_array_val.items = arrPtr;
        } else {
          entry.value.data.int_array_val.items = nullptr;
        }
        break;
      case native.WDBValueType.WDB_VALUE_TYPE_UINT_ARRAY:
        final list = (value is List) ? value.cast<int>() : <int>[];
        entry.value.data.uint_array_val.count = list.length;
        if (list.isNotEmpty) {
          final arrPtr = arena<UnsignedInt>(list.length);
          for (int k = 0; k < list.length; k++) {
            arrPtr[k] = list[k];
          }
          entry.value.data.uint_array_val.items = arrPtr;
        } else {
          entry.value.data.uint_array_val.items = nullptr;
        }
        break;
      case native.WDBValueType.WDB_VALUE_TYPE_STRING_ARRAY:
        final list = (value is List) ? value.cast<String>() : <String>[];
        entry.value.data.string_array_val.count = list.length;
        if (list.isNotEmpty) {
          final arrPtr = arena<Pointer<Char>>(list.length);
          for (int k = 0; k < list.length; k++) {
            arrPtr[k] = list[k].toNativeUtf8(allocator: arena).cast<Char>();
          }
          entry.value.data.string_array_val.items = arrPtr;
        } else {
          entry.value.data.string_array_val.items = nullptr;
        }
        break;
      case native.WDBValueType.WDB_VALUE_TYPE_UNKNOWN:
        // Do nothing or log
        break;
    }
  }

  static dynamic _convertWDBValue(native.WDBEntry entry) {
    switch (entry.value.type) {
      case native.WDBValueType.WDB_VALUE_TYPE_INT:
        return entry.value.data.int_val;
      case native.WDBValueType.WDB_VALUE_TYPE_UINT:
        return entry.value.data.uint_val;
      case native.WDBValueType.WDB_VALUE_TYPE_FLOAT:
        return entry.value.data.float_val;
      case native.WDBValueType.WDB_VALUE_TYPE_STRING:
        final sPtr = entry.value.data.string_val;
        return (sPtr != nullptr) ? sPtr.cast<Utf8>().toDartString() : "";
      case native.WDBValueType.WDB_VALUE_TYPE_BOOL:
        return entry.value.data.bool_val == 1; // Convert C int to Dart bool
      case native.WDBValueType.WDB_VALUE_TYPE_INT_ARRAY:
        List<int> intList = [];
        for (int k = 0; k < entry.value.data.int_array_val.count; k++) {
          intList.add(entry.value.data.int_array_val.items[k]);
        }
        return intList;
      case native.WDBValueType.WDB_VALUE_TYPE_UINT_ARRAY:
        List<int> uintList = [];
        for (int k = 0; k < entry.value.data.uint_array_val.count; k++) {
          uintList.add(entry.value.data.uint_array_val.items[k]);
        }
        return uintList;
      case native.WDBValueType.WDB_VALUE_TYPE_STRING_ARRAY:
        List<String> stringList = [];
        for (int k = 0; k < entry.value.data.string_array_val.count; k++) {
          final sAPtr = entry.value.data.string_array_val.items[k];
          stringList.add(
            (sAPtr != nullptr) ? sAPtr.cast<Utf8>().toDartString() : "",
          );
        }
        return stringList;
      case native.WDBValueType.WDB_VALUE_TYPE_UNKNOWN:
        logger.warning(
          'Unknown WDBValueType encountered: ${entry.value.type} for field',
        );
        return null;
    }
  }
}
