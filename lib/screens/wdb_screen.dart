import 'package:oracle_drive/components/wdb/wdb_bulk_update_dialog.dart';
import 'package:oracle_drive/components/wdb/wdb_record_editor.dart';
import 'package:oracle_drive/components/wdb/wdb_table.dart';
import 'package:oracle_drive/components/wdb/wdb_toolbar.dart';
import 'package:oracle_drive/components/widgets/crystal_loading_spinner.dart';
import 'package:oracle_drive/components/widgets/crystal_panel.dart';
import 'package:oracle_drive/components/widgets/crystal_snackbar.dart';
import 'package:oracle_drive/models/app_game_code.dart';
import 'package:oracle_drive/models/wdb_model.dart';
import 'package:oracle_drive/providers/app_state_provider.dart';
import 'package:oracle_drive/providers/wdb_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          onNew: isLoaded ? () => _handleNewRecord(context, ref, gameCode) : null,
          onBulkUpdate: isLoaded ? () => _handleBulkUpdate(context, ref, gameCode) : null,
          onSaveWdb: isLoaded ? () => _saveWdb(context, ref, gameCode) : null,
          onSaveJson: isLoaded ? () => _saveJson(context, ref, gameCode) : null,
          currentPath: wdbPath,
          onFilter: (val) => ref.read(wdbNotifierProvider(gameCode)).setFilter(val),
        ),
        Expanded(
          child: isProcessing
              ? const Center(child: CrystalLoadingSpinner(label: 'Processing...'))
              : filteredData == null
                  ? const Center(
                      child: Text("No WDB loaded.", style: TextStyle(color: Colors.white24)),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CrystalPanel(
                        child: WdbTable(
                          data: filteredData,
                          gameCode: gameCode,
                          onEdit: (row, col) => _handleEdit(context, ref, gameCode, row, col),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Future<void> _loadWdb(BuildContext context, WidgetRef ref, AppGameCode gameCode) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wdb'],
      dialogTitle: 'Select .wdb file',
    );

    if (result != null && result.files.single.path != null) {
      try {
        await ref.read(wdbNotifierProvider(gameCode)).loadWdb(result.files.single.path!);
      } catch (e) {
        if (context.mounted) {
          context.showErrorSnackBar("Error loading WDB: $e");
        }
      }
    }
  }

  void _handleNewRecord(BuildContext context, WidgetRef ref, AppGameCode gameCode) {
    ref.read(wdbNotifierProvider(gameCode)).addNewRecord();
    if (context.mounted) {
      context.showSuccessSnackBar("New record added to the end.");
    }
  }

  Future<void> _saveWdb(BuildContext context, WidgetRef ref, AppGameCode gameCode) async {
    final notifier = ref.read(wdbNotifierProvider(gameCode));
    final currentPath = notifier.path;

    String? fileName;
    if (currentPath != null) {
      fileName = currentPath.split(RegExp(r'[/\\]')).last;
    }

    final outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save WDB file',
      fileName: fileName,
      allowedExtensions: ['wdb'],
      type: FileType.custom,
    );

    if (outputFile == null) return;

    final path = outputFile.toLowerCase().endsWith('.wdb') ? outputFile : '$outputFile.wdb';

    try {
      await notifier.saveWdb(path);
      if (context.mounted) {
        context.showSuccessSnackBar("Saved to $path");
      }
    } catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar("Error saving: $e");
      }
    }
  }

  Future<void> _saveJson(BuildContext context, WidgetRef ref, AppGameCode gameCode) async {
    final notifier = ref.read(wdbNotifierProvider(gameCode));
    final data = notifier.data;
    if (data == null) return;

    final outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save JSON file',
      fileName: '${data.sheetName}.json',
      allowedExtensions: ['json'],
      type: FileType.custom,
    );

    if (outputFile == null) return;

    final path = outputFile.toLowerCase().endsWith('.json') ? outputFile : '$outputFile.json';

    try {
      await notifier.saveJson(path);
      if (context.mounted) {
        context.showSuccessSnackBar("Saved JSON to $path");
      }
    } catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar("Error saving JSON: $e");
      }
    }
  }

  Future<void> _handleBulkUpdate(BuildContext context, WidgetRef ref, AppGameCode gameCode) async {
    final notifier = ref.read(wdbNotifierProvider(gameCode));
    final wdbData = notifier.data;
    final filteredData = ref.read(filteredWdbDataProvider(gameCode));
    final filterText = ref.read(wdbFilterProvider(gameCode));

    if (wdbData == null || filteredData == null) return;

    final result = await showDialog<BulkUpdateResult>(
      context: context,
      builder: (context) => WdbBulkUpdateDialog(
        columns: wdbData.columns,
        totalRows: wdbData.rows.length,
        filteredRows: filteredData.rows.length,
        hasFilter: filterText.isNotEmpty,
      ),
    );

    if (result == null || !context.mounted) return;

    final updatedCount = notifier.applyBulkUpdate(
      column: result.column,
      operation: result.operation,
      value: result.value,
      applyToFiltered: result.applyToFiltered,
      treatZeroAsOne: result.treatZeroAsOne,
      onlyIfGreater: result.onlyIfGreater,
    );

    if (context.mounted) {
      context.showSuccessSnackBar(
        'Updated $updatedCount row${updatedCount != 1 ? 's' : ''} in "${result.column.displayName}"',
      );
    }
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
    final notifier = ref.read(wdbNotifierProvider(gameCode));

    if (filteredData == null || wdbData == null) return;

    final index = filteredData.rows.indexOf(row);
    if (index == -1) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WdbRecordEditor(
          rows: filteredData.rows,
          columns: filteredData.columns,
          initialIndex: index,
          sheetName: filteredData.sheetName,
          gameCode: gameCode,
          onSave: (idx, updatedRow) => notifier.notifyDataChanged(),
          onClone: () {
            final currentRow = filteredData.rows.length > index ? filteredData.rows[index] : null;
            if (currentRow == null) return;

            final originalIndex = wdbData.rows.indexOf(currentRow);
            if (originalIndex == -1) return;

            notifier.cloneRecord(originalIndex, currentRow);

            if (context.mounted) {
              Navigator.pop(context);
              context.showSuccessSnackBar("Record cloned.");
            }
          },
        ),
      ),
    );
  }
}
