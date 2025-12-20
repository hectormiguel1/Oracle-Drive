import 'package:ff13_mod_resource/components/widgets/crystal_background.dart';
import 'package:ff13_mod_resource/components/widgets/crystal_badge.dart';
import 'package:ff13_mod_resource/components/widgets/crystal_checkbox.dart';
import 'package:ff13_mod_resource/components/widgets/crystal_dropdowns.dart';
import 'package:ff13_mod_resource/components/widgets/crystal_panel.dart';
import 'package:ff13_mod_resource/components/widgets/crystal_text_field.dart';
import 'package:ff13_mod_resource/models/app_game_code.dart';
import 'package:ff13_mod_resource/models/shared_lookups.dart';
import 'package:ff13_mod_resource/models/wdb_entities/wdb_entity.dart';
import 'package:ff13_mod_resource/models/wdb_model.dart';
import 'package:ff13_mod_resource/models/wdb_entities/xiii/schema_registry.dart';
import 'package:ff13_mod_resource/src/services/app_database.dart';
import 'package:ff13_mod_resource/src/third_party/wdb/wdb.g.dart' as native;
import 'package:ff13_mod_resource/src/utils/ztr_text_renderer.dart';
import 'package:ff13_mod_resource/theme/crystal_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WdbRecordEditor extends StatefulWidget {
  final List<Map<String, dynamic>> rows;
  final List<WdbEntity>? entities;
  final List<WdbColumn> columns;
  final int initialIndex;
  final String sheetName;
  final AppGameCode gameCode;
  final Function(int index, Map<String, dynamic> updatedRow) onSave;
  final VoidCallback? onClone;

  const WdbRecordEditor({
    super.key,
    required this.rows,
    required this.columns,
    this.entities,
    required this.initialIndex,
    required this.sheetName,
    required this.gameCode,
    required this.onSave,
    this.onClone,
  });

  @override
  State<WdbRecordEditor> createState() => _WdbRecordEditorState();
}

class _WdbRecordEditorState extends State<WdbRecordEditor> {
  late int _currentIndex;
  late Map<String, dynamic> _editedRow; // Working copy (or reference)

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, List<String>?> _enumOptionsCache = {};
  final Map<String, LookupType?> _lookupCache = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadRowData();
  }

  void _loadRowData() {
    _editedRow = widget.rows[_currentIndex];

    // Clear old controllers text to avoid stale data
    _controllers.forEach((key, controller) {
      controller.text = _editedRow[key]?.toString() ?? '';
    });

    _initializeFields();
  }

  void _initializeFields() {
    _lookupCache.clear();

    WdbEntity? entity;
    if (widget.entities != null && _currentIndex < widget.entities!.length) {
      entity = widget.entities![_currentIndex];
    }

    if (entity != null || sharedLookups.containsKey(widget.sheetName)) {
      final lookupKeys =
          entity?.getLookupKeys() ?? sharedLookups[widget.sheetName];
      if (lookupKeys != null) {
        for (var entry in lookupKeys.entries) {
          for (var colName in entry.value) {
            _lookupCache[colName] = entry.key;
          }
        }
      }
    }

    for (var col in widget.columns) {
      // Cache Enums
      if (!_enumOptionsCache.containsKey(col.originalName)) {
        _enumOptionsCache[col.originalName] = WdbSchemaRegistry.getEnumOptions(
          widget.sheetName,
          col.originalName,
        );
      }

      // Initialize Controllers
      if (!_isEnum(col) && !_isBool(col)) {
        if (!_controllers.containsKey(col.originalName)) {
          _controllers[col.originalName] = TextEditingController();
        }
        // Update text
        final text = _editedRow[col.originalName]?.toString() ?? '';
        if (_controllers[col.originalName]!.text != text) {
          _controllers[col.originalName]!.text = text;
        }
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveCurrent() {
    widget.onSave(_currentIndex, _editedRow);
  }

  void _nextRecord() {
    if (_currentIndex < widget.rows.length - 1) {
      _saveCurrent();
      setState(() {
        _currentIndex++;
        _loadRowData();
      });
    }
  }

  void _prevRecord() {
    if (_currentIndex > 0) {
      _saveCurrent();
      setState(() {
        _currentIndex--;
        _loadRowData();
      });
    }
  }

  String _getRecordName(int index) {
    if (index < 0 || index >= widget.rows.length) return "";
    final row = widget.rows[index];
    if (widget.columns.isNotEmpty) {
      final val = row[widget.columns.first.originalName];
      return "$val";
    }
    return "Row $index";
  }

  bool _isEnum(WdbColumn col) {
    return _enumOptionsCache[col.originalName] != null;
  }

  bool _isBool(WdbColumn col) {
    if (col.type == native.WDBValueType.WDB_VALUE_TYPE_BOOL) return true;
    if (col.type == native.WDBValueType.WDB_VALUE_TYPE_INT ||
        col.type == native.WDBValueType.WDB_VALUE_TYPE_UINT) {
      final name = col.originalName;
      if (name.startsWith('b')) return true;
      if (name.startsWith('u1')) {
        if (name.length == 2) return true;
        final nextChar = name[2];
        final isNextDigit = int.tryParse(nextChar) != null;
        if (!isNextDigit) return true;
      }
    }
    return false;
  }

  bool _isNumber(WdbColumn col) {
    return col.type == native.WDBValueType.WDB_VALUE_TYPE_INT ||
        col.type == native.WDBValueType.WDB_VALUE_TYPE_UINT ||
        col.type == native.WDBValueType.WDB_VALUE_TYPE_FLOAT;
  }

  Widget _buildTypeBadge(native.WDBValueType type) {
    Color color;
    String label;
    switch (type) {
      case native.WDBValueType.WDB_VALUE_TYPE_INT:
        color = Colors.blueAccent;
        label = 'INT';
        break;
      case native.WDBValueType.WDB_VALUE_TYPE_UINT:
        color = Colors.lightBlueAccent;
        label = 'UINT';
        break;
      case native.WDBValueType.WDB_VALUE_TYPE_FLOAT:
        color = Colors.orangeAccent;
        label = 'DEC';
        break;
      case native.WDBValueType.WDB_VALUE_TYPE_STRING:
        color = Colors.greenAccent;
        label = 'STR';
        break;
      case native.WDBValueType.WDB_VALUE_TYPE_BOOL:
        color = Colors.purpleAccent;
        label = 'BOOL';
        break;
      default:
        color = Colors.grey;
        label = 'UNK';
    }

    return CrystalBadge(label: label, color: color);
  }

  Widget _buildFieldRow(WdbColumn col) {
    final originalName = col.originalName;
    final displayName = col.displayName;
    final val = _editedRow[originalName];
    final isEnum = _isEnum(col);
    final isBool = _isBool(col);
    final isNum = _isNumber(col);
    final accentColor = Theme.of(context).extension<CrystalTheme>()!.accent;

    Widget inputWidget;
    Widget? resolvedPreview;

    if (isEnum) {
      final options = _enumOptionsCache[originalName]!;
      int currentValue = (val is int && val >= 0 && val < options.length)
          ? val
          : 0;
      inputWidget = CrystalDropdown<int>(
        value: currentValue,
        items: List.generate(options.length, (index) => index),
        itemLabelBuilder: (index) => options[index],
        onChanged: (newValue) {
          setState(() {
            _editedRow[originalName] = newValue;
          });
          _saveCurrent();
        },
      );
    } else if (isBool) {
      final bool isTrue = val == true || val == 1;
      inputWidget = Align(
        alignment: Alignment.centerLeft,
        child: CrystalCheckbox(
          value: isTrue,
          onChanged: (newValue) {
            setState(() {
              if (col.type == native.WDBValueType.WDB_VALUE_TYPE_BOOL) {
                _editedRow[originalName] = newValue;
              } else {
                _editedRow[originalName] = newValue ? 1 : 0;
              }
            });
            _saveCurrent();
          },
        ),
      );
    } else {
      // Text / Number Input
      final controller = _controllers[originalName];

      // Resolve String if applicable
      if (!isNum && val is String && val.isNotEmpty) {
        String? resolved;
        final lookupType = _lookupCache[originalName];
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
          resolved = lookupFunction.call(val);
        }

        if (resolved != null || lookupType != null) {
          final textToRender =
              resolved ??
              val; // Show val if resolution fails but it was a lookup field
          resolvedPreview = Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white12),
            ),
            alignment: Alignment.centerLeft,
            child: ZtrTextRenderer.render(
              textToRender,
              widget.gameCode,
              style: TextStyle(
                color: accentColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }
      }

      inputWidget = CrystalTextField(
        controller: controller,
        hintText: "Enter $displayName",
        inputFormatters: isNum
            ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9\.\-]'))]
            : null,
        onChanged: (text) {
          dynamic newValue = text;
          if (isNum) {
            if (col.type == native.WDBValueType.WDB_VALUE_TYPE_FLOAT) {
              newValue = double.tryParse(text) ?? 0.0;
            } else {
              newValue = int.tryParse(text) ?? 0;
            }
          }
          _editedRow[originalName] = newValue;
          _saveCurrent();
          if (!isNum) {
            setState(() {}); // Re-render for resolution updates
          }
        },
      );
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildTypeBadge(col.type),
              const SizedBox(width: 8),
              Text(
                displayName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.blue[200],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  originalName,
                  style: const TextStyle(
                    color: Colors.white30,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: inputWidget),
              if (resolvedPreview != null) ...[
                const SizedBox(width: 8),
                Expanded(flex: 2, child: resolvedPreview),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nextName = _currentIndex < widget.rows.length - 1
        ? _getRecordName(_currentIndex + 1)
        : null;
    final prevName = _currentIndex > 0
        ? _getRecordName(_currentIndex - 1)
        : null;
    final accentColor = Theme.of(context).extension<CrystalTheme>()!.accent;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: CrystalBackgroundGrid()),
          Column(
            mainAxisSize: .min,
            children: [
              // Custom Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Colors.black.withValues(alpha: 0.4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Edit Record #${_currentIndex + 1}",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.sheetName,
                            style: TextStyle(
                              fontSize: 12,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.onClone != null)
                      Tooltip(
                        message: "Clone Record",
                        child: IconButton(
                          icon: Icon(Icons.copy, color: accentColor),
                          onPressed: widget.onClone,
                        ),
                      ),
                    Tooltip(
                      message: prevName != null
                          ? "Previous: $prevName"
                          : "No Previous Record",
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_upward,
                          color: accentColor,
                        ),
                        onPressed: _currentIndex > 0 ? _prevRecord : null,
                      ),
                    ),
                    Tooltip(
                      message: nextName != null
                          ? "Next: $nextName"
                          : "No Next Record",
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_downward,
                          color: accentColor,
                        ),
                        onPressed: _currentIndex < widget.rows.length - 1
                            ? _nextRecord
                            : null,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    int columns = 1;
                    if (constraints.maxWidth > 900) columns = 2;
                    if (constraints.maxWidth > 1400) columns = 3;
                    if (constraints.maxWidth > 1900) columns = 4;

                    final fieldsPerColumn = (widget.columns.length / columns)
                        .ceil();

                    final columnWidgets = <Widget>[];
                    for (int i = 0; i < columns; i++) {
                      final start = i * fieldsPerColumn;
                      final end =
                          (start + fieldsPerColumn < widget.columns.length)
                          ? start + fieldsPerColumn
                          : widget.columns.length;

                      if (start >= widget.columns.length) break;

                      final subList = widget.columns.sublist(start, end);
                      columnWidgets.add(
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.only(
                              left: i == 0 ? 16 : 8,
                              right: i == columns - 1 ? 16 : 8,
                              bottom: 50, // space for scrolling
                              top: 16,
                            ),
                            itemCount: subList.length,
                            itemBuilder: (context, index) {
                              return _buildFieldRow(subList[index]);
                            },
                          ),
                        ),
                      );

                      if (i < columns - 1) {
                        columnWidgets.add(
                          const VerticalDivider(
                            width: 1,
                            color: Colors.white10,
                          ),
                        );
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: CrystalPanel(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: columnWidgets,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
