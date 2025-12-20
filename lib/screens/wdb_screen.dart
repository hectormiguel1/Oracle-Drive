import 'package:oracle_drive/components/wdb/wdb_record_editor.dart';
import 'package:oracle_drive/components/wdb/wdb_table.dart';
import 'package:oracle_drive/components/wdb/wdb_toolbar.dart';
import 'package:oracle_drive/components/widgets/crystal_panel.dart';
import 'package:oracle_drive/components/widgets/crystal_progress_bar.dart';
import 'package:oracle_drive/components/widgets/crystal_ribbon.dart';
import 'package:oracle_drive/models/app_game_code.dart';
import 'package:oracle_drive/models/wdb_entities/wdb_entity.dart';
import 'package:oracle_drive/models/wdb_entities/xiii/schema_registry.dart';
import 'package:oracle_drive/models/wdb_model.dart';
import 'package:oracle_drive/providers/app_state_provider.dart';
import 'package:oracle_drive/providers/wdb_provider.dart';
import 'package:oracle_drive/src/services/native_service.dart';
import 'package:oracle_drive/src/third_party/wdb/wdb.dart';
import 'package:oracle_drive/src/third_party/wdb/wdb.g.dart' as native;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

class WdbScreen extends ConsumerWidget {
  const WdbScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameCode = ref.watch(selectedGameProvider);
    final filteredData = ref.watch(filteredWdbDataProvider(gameCode));
    final wdbPath = ref.watch(wdbPathProvider(gameCode));
    final isProcessing = ref.watch(wdbIsProcessingProvider(gameCode));
    final isLoaded = ref.watch(wdbDataProvider(gameCode)) != null;

    return Column(
      children: [
        WdbToolbar(
          onLoad: () => _loadWdb(context, ref, gameCode),
          onNew: isLoaded
              ? () => _handleNewRecord(context, ref, gameCode)
              : null,
          onSaveWdb: isLoaded ? () => _saveWdb(context, ref, gameCode) : null,
          onSaveJson: isLoaded ? () => _saveJson(context, ref, gameCode) : null,
          currentPath: wdbPath,
          onFilter: (val) {
            ref.read(wdbFilterProvider(gameCode).notifier).state = val;
          },
        ),
        Expanded(
          child: isProcessing
              ? const Center(child: CircularProgressIndicator())
              : filteredData == null
              ? const Center(
                  child: Text(
                    "No WDB loaded.",
                    style: TextStyle(color: Colors.white24),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CrystalPanel(
                    child: WdbTable(
                      data: filteredData,
                      gameCode: gameCode,
                      onEdit: (row, col) =>
                          _handleEdit(context, ref, gameCode, row, col),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _loadWdb(
    BuildContext context,
    WidgetRef ref,
    AppGameCode gameCode,
  ) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wdb'],
      dialogTitle: 'Select .wdb file',
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;

      ref.read(wdbPathProvider(gameCode).notifier).state = path;
      ref.read(wdbIsProcessingProvider(gameCode).notifier).state = true;
      ref.read(wdbDataProvider(gameCode).notifier).state = null;
      ref.read(wdbFilterProvider(gameCode).notifier).state = '';

      try {
        final wbtGameCode = gameCode.toWbtGameCode();
        if (wbtGameCode == null) {
          throw Exception(
            "Unsupported game code for WDB operations: ${gameCode.displayName}",
          );
        }

        Logger(
          'WdbScreen',
        ).info("Parsing WDB: $path with game code ${gameCode.displayName}");

        final data = await WdbTool.parseData(path, wbtGameCode);

        ref.read(wdbDataProvider(gameCode).notifier).state = data;
        Logger('WdbScreen').info("Parsed ${data.rows.length} records.");
      } catch (e) {
        Logger('WdbScreen').severe("Error loading WDB: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error loading WDB: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        ref.read(wdbIsProcessingProvider(gameCode).notifier).state = false;
      }
    }
  }

  Future<void> _handleNewRecord(
    BuildContext context,
    WidgetRef ref,
    AppGameCode gameCode,
  ) async {
    final wdbData = ref.read(wdbDataProvider(gameCode));
    if (wdbData == null) return;

    final newRow = <String, dynamic>{};
    for (var col in wdbData.columns) {
      if (col.type == native.WDBValueType.WDB_VALUE_TYPE_STRING) {
        newRow[col.originalName] = "";
      } else if (col.type == native.WDBValueType.WDB_VALUE_TYPE_FLOAT) {
        newRow[col.originalName] = 0.0;
      } else {
        newRow[col.originalName] = 0;
      }
    }

    final newRows = List<Map<String, dynamic>>.from(wdbData.rows);
    newRows.add(newRow);

    List<WdbEntity>? newEntities;
    if (wdbData.entities != null) {
      newEntities = List<WdbEntity>.from(wdbData.entities!);
      try {
        final sheetName = wdbData.sheetName;
        String? matchedSchemaName;
        if (WdbSchemaRegistry.hasSchema(sheetName)) {
          matchedSchemaName = sheetName;
        } else if (sheetName.contains('.')) {
          final nameNoExt = sheetName.split('.').first;
          if (WdbSchemaRegistry.hasSchema(nameNoExt)) {
            matchedSchemaName = nameNoExt;
          }
        }

        if (matchedSchemaName != null) {
          final entity = WdbSchemaRegistry.createEntity(
            matchedSchemaName,
            newRow,
          );
          if (entity != null) {
            newEntities.add(entity);
          }
        }
      } catch (e) {
        // Ignore entity creation errors
      }
    }

    ref.read(wdbDataProvider(gameCode).notifier).state = WdbData(
      sheetName: wdbData.sheetName,
      columns: wdbData.columns,
      rows: newRows,
      entities: newEntities ?? wdbData.entities,
      header: wdbData.header,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("New record added to the end.")),
      );
    }
  }

  Future<void> _saveWdb(
    BuildContext context,
    WidgetRef ref,
    AppGameCode gameCode,
  ) async {
    Logger('WdbScreen').info("_saveWdb called");
    final wdbData = ref.read(wdbDataProvider(gameCode));
    final wdbPath = ref.read(wdbPathProvider(gameCode));

    if (wdbData == null) {
      Logger('WdbScreen').warning("_saveWdb: wdbData is null");
      return;
    }

    String? fileName;
    if (wdbPath != null) {
      fileName = wdbPath.split(RegExp(r'[/\\]')).last;
    }

    Logger('WdbScreen').info("Opening FilePicker...");
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save WDB file',
      fileName: fileName,
      allowedExtensions: ['wdb'],
      type: FileType.custom,
    );
    Logger('WdbScreen').info("FilePicker result: $outputFile");

    if (outputFile == null) {
      return;
    }

    if (!outputFile.toLowerCase().endsWith('.wdb')) {
      outputFile = '$outputFile.wdb';
    }

    ref.read(wdbIsProcessingProvider(gameCode).notifier).state = true;
    try {
      final wbtGameCode = gameCode.toWbtGameCode();
      if (wbtGameCode == null) {
        throw Exception(
          "Unsupported game code for WDB operations: ${gameCode.displayName}",
        );
      }

      await NativeService.instance.saveWdb(outputFile, wbtGameCode, wdbData);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Saved to $outputFile"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Logger('WdbScreen').severe("Error saving WDB: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      ref.read(wdbIsProcessingProvider(gameCode).notifier).state = false;
    }
  }

  Future<void> _saveJson(
    BuildContext context,
    WidgetRef ref,
    AppGameCode gameCode,
  ) async {
    final wdbData = ref.read(wdbDataProvider(gameCode));
    if (wdbData == null) return;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Save to JSON not implemented yet."),
          backgroundColor: Colors.orange,
        ),
      );
    }
    await NativeService.instance.saveWdbJson("dummy.json", wdbData);
  }

  void _handleEdit(
    BuildContext context,
    WidgetRef ref,
    AppGameCode gameCode,
    Map<String, dynamic> row,
    WdbColumn col,
  ) {
    final filteredData = ref.read(filteredWdbDataProvider(gameCode));
    final wdbData = ref.read(wdbDataProvider(gameCode));

    if (filteredData == null || wdbData == null) return;

    final index = filteredData.rows.indexOf(row);

    if (index == -1) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WdbRecordEditor(
          rows: filteredData.rows,
          columns: filteredData.columns,
          entities: filteredData.entities,
          initialIndex: index,
          sheetName: filteredData.sheetName,
          gameCode: gameCode,
          onSave: (idx, updatedRow) {
            final oldData = ref.read(wdbDataProvider(gameCode));
            if (oldData != null) {
              ref.read(wdbDataProvider(gameCode).notifier).state = WdbData(
                sheetName: oldData.sheetName,
                columns: oldData.columns,
                rows: oldData.rows,
                entities: oldData.entities,
                header: oldData.header,
              );
            }

            if (wdbData.entities != null && wdbData.entities!.isNotEmpty) {
              try {
                final sheetName = wdbData.sheetName;
                String? matchedSchemaName;
                if (WdbSchemaRegistry.hasSchema(sheetName)) {
                  matchedSchemaName = sheetName;
                } else if (sheetName.contains('.')) {
                  final nameNoExt = sheetName.split('.').first;
                  if (WdbSchemaRegistry.hasSchema(nameNoExt)) {
                    matchedSchemaName = nameNoExt;
                  }
                }

                if (matchedSchemaName != null) {
                  WdbSchemaRegistry.createEntity(matchedSchemaName, updatedRow);
                }
              } catch (validationError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Validation Warning: $validationError"),
                    backgroundColor: Colors.orangeAccent,
                  ),
                );
              }
            }
          },
          onClone: () {
            final originalData = ref.read(wdbDataProvider(gameCode));
            if (originalData == null) return;

            // We use row reference to find index in original data
            // filteredData.rows[index] is the same object as in originalData.rows
            // UNLESS the row was just edited and replaced?
            // In WdbRecordEditor, _editedRow is a copy? No, it's `widget.rows[_currentIndex]`.
            // Wait, `WdbRecordEditor` sets `_editedRow = widget.rows[_currentIndex]`.
            // Dart Lists of Maps: `_editedRow` is a reference to the map if not copied.
            // But `WdbRecordEditor` modifies `_editedRow` in place: `_editedRow[originalName] = newValue;`.
            // So `filteredData.rows` IS modified.
            // And since `filteredData.rows` contains references to maps in `originalData.rows` (filteredWdbDataProvider builds a new List but points to SAME Map objects),
            // The references are valid.

            // However, `filteredWdbDataProvider` logic:
            // `final List<Map<String, dynamic>> filteredRows = [];`
            // `filteredRows.add(row);`
            // So yes, Map references are shared.

            final currentRow = filteredData.rows.length > index
                ? filteredData.rows[index]
                : null;
            if (currentRow == null) return;

            final originalIndex = originalData.rows.indexOf(currentRow);
            if (originalIndex == -1) return;

            final newRow = Map<String, dynamic>.from(currentRow);

            final newRows = List<Map<String, dynamic>>.from(originalData.rows);
            newRows.insert(originalIndex + 1, newRow);

            List<WdbEntity>? newEntities;
            if (originalData.entities != null) {
              newEntities = List<WdbEntity>.from(originalData.entities!);
              try {
                final sheetName = originalData.sheetName;
                String? matchedSchemaName;
                if (WdbSchemaRegistry.hasSchema(sheetName)) {
                  matchedSchemaName = sheetName;
                } else if (sheetName.contains('.')) {
                  final nameNoExt = sheetName.split('.').first;
                  if (WdbSchemaRegistry.hasSchema(nameNoExt)) {
                    matchedSchemaName = nameNoExt;
                  }
                }

                if (matchedSchemaName != null) {
                  final entity = WdbSchemaRegistry.createEntity(
                    matchedSchemaName,
                    newRow,
                  );
                  if (entity != null) {
                    newEntities.insert(originalIndex + 1, entity);
                  }
                }
              } catch (e) {
                // Ignore
              }
            }

            ref.read(wdbDataProvider(gameCode).notifier).state = WdbData(
              sheetName: originalData.sheetName,
              columns: originalData.columns,
              rows: newRows,
              entities: newEntities ?? originalData.entities,
              header: originalData.header,
            );

            Navigator.pop(context);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Record cloned.")));
          },
        ),
      ),
    );
  }
}
