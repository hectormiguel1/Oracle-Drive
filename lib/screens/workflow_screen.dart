import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/widgets/crystal_ribbon.dart';
import '../components/widgets/crystal_snackbar.dart';
import '../components/workflow/node_palette.dart';
import '../components/workflow/property_panel.dart';
import '../components/workflow/workflow_canvas.dart';
import '../components/workflow/workflow_dialogs.dart';
import '../components/workflow/workflow_execution_dialog.dart';
import '../components/workflow/workflow_list_view.dart';
import '../components/workflow/workflow_toolbar.dart';
import '../providers/app_state_provider.dart';
import '../providers/workflow_provider.dart';
import 'fullscreen_workflow_page.dart';

/// Main screen for the workflow editor.
///
/// This screen has been refactored to use extracted components:
/// - [WorkflowToolbar] - Top toolbar with actions
/// - [WorkflowListView] - List of saved workflows
/// - [WorkflowExecutionDialog] - Execution progress dialog
/// - [NodePalette], [WorkflowCanvas], [PropertyPanel] - Editor panels
class WorkflowScreen extends ConsumerStatefulWidget {
  const WorkflowScreen({super.key});

  @override
  ConsumerState<WorkflowScreen> createState() => _WorkflowScreenState();
}

class _WorkflowScreenState extends ConsumerState<WorkflowScreen> {
  bool _showWorkflowList = true;

  @override
  Widget build(BuildContext context) {
    // Use select to only watch workflow existence, not entire state
    final hasWorkflow = ref.watch(
      workflowEditorProvider.select((s) => s.workflow != null),
    );
    final gameCode = ref.watch(selectedGameProvider);

    return CallbackShortcuts(
      bindings: _buildKeyboardShortcuts(),
      child: Focus(
        autofocus: true,
        child: Column(
          children: [
            // Toolbar
            WorkflowToolbar(
              showWorkflowList: _showWorkflowList,
              onBackToList: _handleBackToList,
              onNew: () => _handleCreateNew(gameCode),
              onOpen: _handleOpen,
              onSave: _handleSave,
              onValidate: _handleValidate,
              onPreview: _handlePreview,
              onRun: _handleRun,
              onImport: _handleImport,
              onExportJson: _handleExportJson,
              onExportClipboard: _handleExportClipboard,
              onEnterFullscreen: _handleEnterFullscreen,
            ),
            // Main content
            Expanded(
              child: _showWorkflowList && !hasWorkflow
                  ? WorkflowListView(
                      gameCode: gameCode,
                      onOpen: (workflow) {
                        ref.read(workflowEditorProvider.notifier).load(workflow.id);
                        setState(() => _showWorkflowList = false);
                      },
                      onCreate: () => _handleCreateNew(gameCode),
                    )
                  : const _EditorPanels(),
            ),
          ],
        ),
      ),
    );
  }

  Map<ShortcutActivator, VoidCallback> _buildKeyboardShortcuts() {
    return {
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ): () =>
          ref.read(workflowEditorProvider.notifier).undo(),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY): () =>
          ref.read(workflowEditorProvider.notifier).redo(),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): () =>
          _handleSave(),
      LogicalKeySet(LogicalKeyboardKey.escape): () =>
          ref.read(workflowEditorProvider.notifier).cancelConnection(),
    };
  }

  Future<void> _handleBackToList() async {
    final isDirty = ref.read(workflowEditorProvider).isDirty;

    if (isDirty) {
      final result = await showUnsavedChangesDialog(context);
      if (result == null) return; // Cancelled

      if (result) {
        // Save first
        await _handleSave();
      }
    }

    ref.read(workflowEditorProvider.notifier).close();
    setState(() => _showWorkflowList = true);
  }

  Future<void> _handleCreateNew(dynamic gameCode) async {
    final name = await showCreateWorkflowDialog(context, ref, gameCode);
    if (name != null) {
      setState(() => _showWorkflowList = false);
    }
  }

  void _handleOpen() {
    setState(() => _showWorkflowList = true);
    ref.read(workflowEditorProvider.notifier).close();
  }

  void _handleEnterFullscreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FullscreenWorkflowPage(),
      ),
    );
  }

  Future<void> _handleSave() async {
    await ref.read(workflowEditorProvider.notifier).save();
    if (mounted) {
      showCrystalSnackBar(
        context,
        'Workflow saved',
        type: CrystalSnackBarType.success,
      );
    }
  }

  void _handleValidate() {
    final errors = ref.read(workflowEditorProvider.notifier).validate();
    if (errors.isEmpty) {
      showCrystalSnackBar(
        context,
        'Workflow is valid!',
        type: CrystalSnackBarType.success,
      );
    } else {
      showValidationErrorsDialog(context, errors);
    }
  }

  void _handlePreview() {
    final workflow = ref.read(workflowEditorProvider).workflow;
    if (workflow == null) return;

    final gameCode = ref.read(selectedGameProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WorkflowExecutionDialog(
        workflow: workflow,
        gameCode: gameCode,
        workspaceDir: workflow.workspacePath,
        previewMode: true,
      ),
    );
  }

  void _handleRun() {
    final workflow = ref.read(workflowEditorProvider).workflow;
    if (workflow == null) return;

    final gameCode = ref.read(selectedGameProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WorkflowExecutionDialog(
        workflow: workflow,
        gameCode: gameCode,
        workspaceDir: workflow.workspacePath,
        previewMode: false,
      ),
    );
  }

  Future<void> _handleImport() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Import Workflow',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.isNotEmpty) {
      try {
        final file = File(result.files.single.path!);
        final json = await file.readAsString();
        final repo = ref.read(workflowRepositoryProvider);
        final workflow = await repo.importFromJson(json);
        ref.invalidate(workflowListProvider);
        ref.read(workflowEditorProvider.notifier).load(workflow.id);
        setState(() => _showWorkflowList = false);
        if (mounted) {
          showCrystalSnackBar(
            context,
            'Imported workflow: ${workflow.name}',
            type: CrystalSnackBarType.success,
          );
        }
      } catch (e) {
        if (mounted) {
          showCrystalSnackBar(
            context,
            'Failed to import: $e',
            type: CrystalSnackBarType.error,
          );
        }
      }
    }
  }

  Future<void> _handleExportJson() async {
    final workflow = ref.read(workflowEditorProvider).workflow;
    if (workflow == null) return;

    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Workflow',
      fileName: '${workflow.name}.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null) {
      final file = File(result);
      await file.writeAsString(workflow.toJsonString());
      if (mounted) {
        showCrystalSnackBar(
          context,
          'Exported to $result',
          type: CrystalSnackBarType.success,
        );
      }
    }
  }

  Future<void> _handleExportClipboard() async {
    final workflow = ref.read(workflowEditorProvider).workflow;
    if (workflow == null) return;

    await Clipboard.setData(ClipboardData(text: workflow.toJsonString()));
    if (mounted) {
      showCrystalSnackBar(
        context,
        'Copied to clipboard',
        type: CrystalSnackBarType.success,
      );
    }
  }
}

/// Editor panels layout - extracted to const widget for performance.
class _EditorPanels extends StatelessWidget {
  const _EditorPanels();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        // Node palette
        SizedBox(
          width: 220,
          child: NodePalette(),
        ),
        // Canvas
        Expanded(
          child: WorkflowCanvas(),
        ),
        // Property panel
        SizedBox(
          width: 280,
          child: PropertyPanel(),
        ),
      ],
    );
  }
}
