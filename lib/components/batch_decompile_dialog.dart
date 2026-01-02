import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:oracle_drive/components/widgets/crystal_button.dart';
import 'package:oracle_drive/components/widgets/crystal_checkbox.dart';
import 'package:oracle_drive/components/widgets/crystal_dialog.dart';
import 'package:oracle_drive/components/widgets/crystal_snackbar.dart';
import 'package:oracle_drive/components/widgets/crystal_text_field.dart';
import 'package:oracle_drive/components/widgets/style.dart';
import 'package:oracle_drive/src/services/batch_decompilation_service.dart';

/// Dialog for configuring batch CLB decompilation
class BatchDecompileDialog extends StatefulWidget {
  final String sourceDirectory;

  const BatchDecompileDialog({
    super.key,
    required this.sourceDirectory,
  });

  /// Show the dialog and return configuration, or null if cancelled
  static Future<BatchDecompileConfig?> show(
    BuildContext context,
    String sourceDirectory,
  ) async {
    return showDialog<BatchDecompileConfig>(
      context: context,
      builder: (context) => BatchDecompileDialog(sourceDirectory: sourceDirectory),
    );
  }

  @override
  State<BatchDecompileDialog> createState() => _BatchDecompileDialogState();
}

class _BatchDecompileDialogState extends State<BatchDecompileDialog> {
  final _outputController = TextEditingController();
  bool _processBinContainers = true;
  bool _cleanUpIntermediate = true;
  bool _generateGradle = false;

  @override
  void initState() {
    super.initState();
    // Default output path: sibling directory with _decompiled suffix
    final sourceName = widget.sourceDirectory.split('/').last.split('\\').last;
    final parentDir = widget.sourceDirectory.substring(
      0,
      widget.sourceDirectory.length - sourceName.length - 1,
    );
    _outputController.text = '$parentDir/${sourceName}_decompiled';
  }

  @override
  void dispose() {
    _outputController.dispose();
    super.dispose();
  }

  Future<void> _pickOutputDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Output Directory',
    );
    if (result != null) {
      _outputController.text = result;
    }
  }

  void _onConfirm() {
    if (_outputController.text.trim().isEmpty) {
      context.showWarningSnackBar('Please specify an output directory');
      return;
    }

    Navigator.of(context).pop(BatchDecompileConfig(
      outputPath: _outputController.text.trim(),
      processBinContainers: _processBinContainers,
      cleanUpIntermediateFiles: _cleanUpIntermediate,
      generateGradleProject: _generateGradle,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return CrystalDialog(
      title: 'Batch Decompile CLB Files',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Decompile all CLB files in the selected directory to Java source code.',
            style: CrystalStyles.label.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 24),

          // Output directory
          Text('Output Directory', style: CrystalStyles.sectionHeader),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CrystalTextField(
                  controller: _outputController,
                  hintText: 'Select output directory...',
                ),
              ),
              const SizedBox(width: 8),
              CrystalButton(
                onPressed: _pickOutputDirectory,
                icon: Icons.folder_open,
                label: 'Browse',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Options
          Text('Options', style: CrystalStyles.sectionHeader),
          const SizedBox(height: 12),

          CrystalCheckbox(
            value: _processBinContainers,
            onChanged: (value) => setState(() => _processBinContainers = value),
            label: 'Process .bin containers',
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              'Unpack .bin files (WPD format) to find nested CLB files',
              style: CrystalStyles.label.copyWith(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),

          CrystalCheckbox(
            value: _cleanUpIntermediate,
            onChanged: (value) => setState(() => _cleanUpIntermediate = value),
            label: 'Clean up intermediate files',
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              'Delete .class files after decompilation',
              style: CrystalStyles.label.copyWith(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),

          CrystalCheckbox(
            value: _generateGradle,
            onChanged: (value) => setState(() => _generateGradle = value),
            label: 'Generate Gradle project files',
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              'Create build.gradle and settings.gradle for IDE import',
              style: CrystalStyles.label.copyWith(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      actions: [
        CrystalButton(
          onPressed: () => Navigator.of(context).pop(),
          label: 'Cancel',
        ),
        CrystalButton(
          onPressed: _onConfirm,
          label: 'Start Decompilation',
          isPrimary: true,
          icon: Icons.play_arrow,
        ),
      ],
    );
  }
}

/// Dialog showing decompilation results
class BatchDecompileResultDialog extends StatelessWidget {
  final BatchDecompilationResult result;

  const BatchDecompileResultDialog({
    super.key,
    required this.result,
  });

  static Future<void> show(BuildContext context, BatchDecompilationResult result) {
    return showDialog(
      context: context,
      builder: (context) => BatchDecompileResultDialog(result: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasErrors = result.errors.isNotEmpty;

    return CrystalDialog(
      title: 'Decompilation Complete',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary
          _buildSummaryRow(
            Icons.check_circle,
            Colors.green,
            'Successful',
            '${result.successCount}',
          ),
          const SizedBox(height: 8),
          if (result.skippedCount > 0) ...[
            _buildSummaryRow(
              Icons.skip_next,
              Colors.orange,
              'Skipped',
              '${result.skippedCount}',
            ),
            const SizedBox(height: 8),
          ],
          if (hasErrors)
            _buildSummaryRow(
              Icons.error,
              Colors.red,
              'Failed',
              '${result.errorCount}',
            ),
          const SizedBox(height: 16),

          // Output path
          Text('Output Location', style: CrystalStyles.sectionHeader),
          const SizedBox(height: 8),
          SelectableText(
            result.projectPath,
            style: const TextStyle(
              color: Colors.cyan,
              fontSize: 13,
            ),
          ),

          // Errors list (if any)
          if (hasErrors) ...[
            const SizedBox(height: 16),
            Text('Errors', style: CrystalStyles.sectionHeader),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: result.errors.length,
                itemBuilder: (context, index) {
                  final error = result.errors[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          error.filePath.split('/').last.split('\\').last,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '[${error.stage}] ${error.message}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
      actions: [
        CrystalButton(
          onPressed: () => Navigator.of(context).pop(),
          label: 'Close',
          isPrimary: true,
        ),
      ],
    );
  }

  Widget _buildSummaryRow(IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
