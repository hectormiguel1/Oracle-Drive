import 'package:ff13_mod_resource/components/widgets/crystal_table.dart';
import 'package:ff13_mod_resource/models/app_game_code.dart';
import 'package:ff13_mod_resource/models/shared_lookups.dart';
import 'package:ff13_mod_resource/models/wdb_entities/wdb_entity.dart';
import 'package:ff13_mod_resource/models/wdb_model.dart';
import 'package:ff13_mod_resource/models/wdb_entities/xiii/schema_registry.dart';
import 'package:ff13_mod_resource/src/services/app_database.dart';
import 'package:ff13_mod_resource/src/utils/ztr_text_renderer.dart';
import 'package:ff13_mod_resource/src/third_party/wdb/wdb.g.dart' as native;
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:logging/logging.dart';

final _logger = Logger('WdbTable');

class WdbTable extends StatefulWidget {
  final WdbData data;
  final AppGameCode gameCode;
  final Function(Map<String, dynamic> row, WdbColumn col) onEdit;

  const WdbTable({
    super.key,
    required this.data,
    required this.gameCode,
    required this.onEdit,
  });

  @override
  State<WdbTable> createState() => _WdbTableState();
}

class _WdbTableState extends State<WdbTable> {
  final Map<String, double> _columnWidths = {};
  final Map<String, List<String>?> _columnEnumCache = {};
  final Map<String, LookupType?> _columnLookupCache = {};

  @override
  void initState() {
    super.initState();
    _initColumnWidths();
    _analyzeColumns();
  }

  @override
  void didUpdateWidget(WdbTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {
      _initColumnWidths();
      _analyzeColumns();
    }
  }

  void _analyzeColumns() {
    _columnEnumCache.clear();
    _columnLookupCache.clear();

    // Cache Enums
    for (var col in widget.data.columns) {
      _columnEnumCache[col.originalName] = WdbSchemaRegistry.getEnumOptions(
        widget.data.sheetName,
        col.originalName,
      );
    }
    _logger.info(
      'Cached ${_columnEnumCache.length} enum columns for ${widget.data.sheetName}',
    );
    // Cache Lookups (based on the first entity if available)
    if (widget.data.entities != null && widget.data.entities!.isNotEmpty ||
        sharedLookups.containsKey(widget.data.sheetName)) {
      final firstEntity = widget.data.entities?.first;
      final lookupKeys =
          firstEntity?.getLookupKeys() ?? sharedLookups[widget.data.sheetName];
      if (lookupKeys != null) {
        for (var entry in lookupKeys.entries) {
          for (var colName in entry.value) {
            _columnLookupCache[colName] = entry.key;
          }
        }
      }
    }
  }

  void _initColumnWidths() {
    // We only set defaults for columns that don't have a width yet
    // This preserves manual resizing if data refreshes but columns stay same-ish
    for (var col in widget.data.columns) {
      if (!_columnWidths.containsKey(col.originalName)) {
        double width;
        if (col.type == native.WDBValueType.WDB_VALUE_TYPE_BOOL) {
          width = 60.0;
        } else if (col.type == native.WDBValueType.WDB_VALUE_TYPE_INT ||
            col.type == native.WDBValueType.WDB_VALUE_TYPE_UINT ||
            col.type == native.WDBValueType.WDB_VALUE_TYPE_FLOAT) {
          width = 80.0;
        } else {
          width = 200.0;
        }

        // Ensure title fits
        final titleWidth = col.displayName.length * 12.0 + 24.0;
        _columnWidths[col.originalName] = math.max(width, titleWidth);
      }
    }
  }

  Widget _buildCellContent(dynamic val, WdbColumn col) {
    final bool isBoolType = col.type == native.WDBValueType.WDB_VALUE_TYPE_BOOL;
    final double fontSize = 16;
    // Check for Enum
    final enumOptions = _columnEnumCache[col.originalName];
    if (enumOptions != null &&
        val is int &&
        val >= 0 &&
        val < enumOptions.length) {
      return Text(
        enumOptions[val],
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: fontSize, color: Colors.white70),
      );
    }

    if (isBoolType || (val is bool)) {
      final isTrue = val == true || val == 1;
      return Icon(
        isTrue ? Icons.check_box : Icons.check_box_outline_blank,
        size: fontSize,
        color: isTrue ? Colors.greenAccent : Colors.grey,
      );
    } else if (val is String) {
      if (val != '') {
        final lookupType = _columnLookupCache[col.originalName];
        if (lookupType != null) {
          final lookupFunction = switch (lookupType) {
            LookupType.direct =>
              AppDatabase.instance
                  .getRepositoryForGame(widget.gameCode)
                  .resolveStringId,
            LookupType.ability =>
              AppDatabase.instance
                  .getRepositoryForGame(widget.gameCode)
                  .getAbilityName,
            LookupType.item =>
              AppDatabase.instance
                  .getRepositoryForGame(widget.gameCode)
                  .getItemName,
          };
          final resolved = lookupFunction.call(val);
          val = resolved ?? val;
        }
      }
      return ZtrTextRenderer.render(
        val,
        widget.gameCode,
        style: TextStyle(fontSize: fontSize, color: Colors.white),
        overflow: TextOverflow.ellipsis,
      );
    } else {
      return Text(
        val.toString(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: fontSize, color: Colors.white70),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final columns = widget.data.columns;
    if (columns.isEmpty) return const Center(child: Text("No columns"));

    // Prepare fixed widths
    final widthList = columns
        .map((col) => _columnWidths[col.originalName] ?? 100.0)
        .toList();
    final headers = columns.map((col) => col.displayName).toList();

    return CrystalTable(
      headers: headers,
      itemCount: widget.data.rows.length,
      columnWidths: widthList,
      onCellTap: (row, col) {
        final rowData = widget.data.rows[row];
        final columnData = columns[col];
        widget.onEdit(rowData, columnData);
      },
      cellBuilder: (context, row, col) {
        final rowData = widget.data.rows[row];
        final columnData = columns[col];
        return Align(
          alignment: Alignment.centerLeft,
          child: _buildCellContent(
            rowData[columnData.originalName],
            columnData,
          ),
        );
      },
    );
  }
}
