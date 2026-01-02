import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/widgets/crystal_background.dart';
import '../components/widgets/crystal_button.dart';
import '../components/widgets/crystal_panel.dart';
import '../components/widgets/crystal_ribbon.dart';
import '../components/widgets/crystal_snackbar.dart';
import '../components/workflow/compact_game_selector.dart';
import '../components/workflow/node_palette.dart';
import '../components/workflow/workspace_selector.dart';
import '../components/workflow/property_panel.dart';
import '../components/workflow/workflow_canvas.dart';
import '../components/workflow/workflow_dialogs.dart';
import '../components/workflow/workflow_execution_dialog.dart';
import '../components/workflow/workflow_list_view.dart';
import '../providers/app_state_provider.dart';
import '../providers/workflow_provider.dart';
import 'overlay/wbt_overlay_screen.dart';
import 'overlay/wdb_overlay_screen.dart';
import 'overlay/ztr_overlay_screen.dart';

/// Fullscreen workflow page that hides the navigation rail.
///
/// This page provides:
/// - A compact toolbar with game selector and quick navigation
/// - Full workflow editor without the sidebar
/// - Navigation to other screens via overlay pages
class FullscreenWorkflowPage extends ConsumerStatefulWidget {
  const FullscreenWorkflowPage({super.key});

  @override
  ConsumerState<FullscreenWorkflowPage> createState() =>
      _FullscreenWorkflowPageState();
}

class _FullscreenWorkflowPageState
    extends ConsumerState<FullscreenWorkflowPage> {
  bool _showWorkflowList = false;

  @override
  void initState() {
    super.initState();
    // Check if we have a workflow loaded, otherwise show list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hasWorkflow = ref.read(workflowEditorProvider).workflow != null;
      if (!hasWorkflow) {
        setState(() => _showWorkflowList = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasWorkflow = ref.watch(
      workflowEditorProvider.select((s) => s.workflow != null),
    );
    final gameCode = ref.watch(selectedGameProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: CrystalBackgroundGrid()),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CallbackShortcuts(
              bindings: _buildKeyboardShortcuts(),
              child: Focus(
                autofocus: true,
                child: Column(
                  children: [
                    // Fullscreen toolbar
                    _FullscreenToolbar(
                      showWorkflowList: _showWorkflowList,
                      onExitFullscreen: _handleExitFullscreen,
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
                      onNavigateToWdb: _navigateToWdb,
                      onNavigateToZtr: _navigateToZtr,
                      onNavigateToWbt: _navigateToWbt,
                    ),
                    // Main content
                    Expanded(
                      child: _showWorkflowList && !hasWorkflow
                          ? CrystalPanel(
                              child: WorkflowListView(
                                gameCode: gameCode,
                                onOpen: (workflow) {
                                  ref
                                      .read(workflowEditorProvider.notifier)
                                      .load(workflow.id, workflow.gameCode);
                                  setState(() => _showWorkflowList = false);
                                },
                                onCreate: () => _handleCreateNew(gameCode),
                              ),
                            )
                          : const _EditorPanels(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
      LogicalKeySet(LogicalKeyboardKey.escape): () {
        // First try to cancel connection, then exit fullscreen
        final notifier = ref.read(workflowEditorProvider.notifier);
        if (ref.read(workflowEditorProvider).isConnecting) {
          notifier.cancelConnection();
        } else {
          _handleExitFullscreen();
        }
      },
    };
  }

  void _handleExitFullscreen() {
    Navigator.of(context).pop();
  }

  Future<void> _handleBackToList() async {
    final isDirty = ref.read(workflowEditorProvider).isDirty;

    if (isDirty) {
      final result = await showUnsavedChangesDialog(context);
      if (result == null) return;

      if (result) {
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
        final gameCode = ref.read(selectedGameProvider);
        final repo = ref.read(gameRepositoryProvider(gameCode));
        final workflow = await repo.importWorkflowFromJson(json);
        ref.invalidate(workflowListProvider(gameCode));
        ref.read(workflowEditorProvider.notifier).load(workflow.id, workflow.gameCode);
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

  void _navigateToWdb() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const WdbOverlayScreen()),
    );
  }

  void _navigateToZtr() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ZtrOverlayScreen()),
    );
  }

  void _navigateToWbt() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const WbtOverlayScreen()),
    );
  }
}

/// Fullscreen toolbar with game selector and quick navigation.
class _FullscreenToolbar extends ConsumerWidget {
  final bool showWorkflowList;
  final VoidCallback onExitFullscreen;
  final VoidCallback onBackToList;
  final VoidCallback onNew;
  final VoidCallback onOpen;
  final VoidCallback onSave;
  final VoidCallback onValidate;
  final VoidCallback onPreview;
  final VoidCallback onRun;
  final VoidCallback onImport;
  final Future<void> Function() onExportJson;
  final Future<void> Function() onExportClipboard;
  final VoidCallback onNavigateToWdb;
  final VoidCallback onNavigateToZtr;
  final VoidCallback onNavigateToWbt;

  const _FullscreenToolbar({
    required this.showWorkflowList,
    required this.onExitFullscreen,
    required this.onBackToList,
    required this.onNew,
    required this.onOpen,
    required this.onSave,
    required this.onValidate,
    required this.onPreview,
    required this.onRun,
    required this.onImport,
    required this.onExportJson,
    required this.onExportClipboard,
    required this.onNavigateToWdb,
    required this.onNavigateToZtr,
    required this.onNavigateToWbt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasWorkflow = ref.watch(
      workflowEditorProvider.select((s) => s.workflow != null),
    );
    final isDirty = ref.watch(
      workflowEditorProvider.select((s) => s.isDirty),
    );
    final canUndo = ref.watch(
      workflowEditorProvider.select((s) => s.canUndo),
    );
    final canRedo = ref.watch(
      workflowEditorProvider.select((s) => s.canRedo),
    );
    final workflowName = ref.watch(
      workflowEditorProvider.select((s) => s.workflow?.name ?? ''),
    );

    return CrystalPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: 0,
      child: Row(
        children: [
          // Exit fullscreen button
          IconButton(
            icon: const Icon(Icons.fullscreen_exit, color: Colors.white70),
            onPressed: onExitFullscreen,
            tooltip: 'Exit Fullscreen (Esc)',
          ),
          const SizedBox(width: 8),
          // Compact game selector
          const CompactGameSelector(),
          const SizedBox(width: 16),
          // Quick navigation buttons
          _QuickNavButton(
            icon: Icons.archive,
            label: 'WBT',
            onPressed: onNavigateToWbt,
          ),
          const SizedBox(width: 4),
          _QuickNavButton(
            icon: Icons.table_chart,
            label: 'WDB',
            onPressed: onNavigateToWdb,
          ),
          const SizedBox(width: 4),
          _QuickNavButton(
            icon: Icons.description,
            label: 'ZTR',
            onPressed: onNavigateToZtr,
          ),
          Container(
            height: 24,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: Colors.white24,
          ),
          // Back button (when not in list view)
          if (!showWorkflowList && hasWorkflow) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
              onPressed: onBackToList,
              tooltip: 'Back to list',
            ),
            const SizedBox(width: 8),
          ],
          // Standard workflow actions
          CrystalButton(
            label: 'New',
            icon: Icons.add,
            onPressed: onNew,
          ),
          const SizedBox(width: 8),
          CrystalButton(
            label: 'Open',
            icon: Icons.folder_open,
            onPressed: onOpen,
          ),
          if (hasWorkflow) ...[
            const SizedBox(width: 8),
            CrystalButton(
              label: 'Save',
              icon: Icons.save,
              isPrimary: isDirty,
              onPressed: isDirty ? onSave : null,
            ),
            const SizedBox(width: 8),
            CrystalButton(
              label: 'Import',
              icon: Icons.file_upload,
              onPressed: onImport,
            ),
            const SizedBox(width: 16),
            // Workspace directory selector
            const WorkspaceSelector(),
            const Spacer(),
            // Workflow name
            Text(
              workflowName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isDirty)
              const Text(
                ' *',
                style: TextStyle(color: Colors.orange, fontSize: 14),
              ),
            const Spacer(),
            // Undo/Redo
            IconButton(
              icon: const Icon(Icons.undo),
              color: canUndo ? Colors.white70 : Colors.white24,
              onPressed: canUndo
                  ? () => ref.read(workflowEditorProvider.notifier).undo()
                  : null,
              tooltip: 'Undo (Ctrl+Z)',
            ),
            IconButton(
              icon: const Icon(Icons.redo),
              color: canRedo ? Colors.white70 : Colors.white24,
              onPressed: canRedo
                  ? () => ref.read(workflowEditorProvider.notifier).redo()
                  : null,
              tooltip: 'Redo (Ctrl+Y)',
            ),
            const SizedBox(width: 16),
            CrystalButton(
              label: 'Validate',
              icon: Icons.check_circle_outline,
              onPressed: onValidate,
            ),
            const SizedBox(width: 8),
            CrystalButton(
              label: 'Preview',
              icon: Icons.visibility,
              onPressed: onPreview,
            ),
            const SizedBox(width: 8),
            CrystalButton(
              label: 'Run',
              icon: Icons.play_arrow,
              isPrimary: true,
              onPressed: onRun,
            ),
          ] else ...[
            const Spacer(),
            const Text(
              'Workflow Editor',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
          ],
        ],
      ),
    );
  }
}

/// Quick navigation button for accessing other screens.
class _QuickNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _QuickNavButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Open $label',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white54, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Editor panels layout.
class _EditorPanels extends StatelessWidget {
  const _EditorPanels();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(width: 220, child: NodePalette()),
        Expanded(child: WorkflowCanvas()),
        SizedBox(width: 280, child: PropertyPanel()),
      ],
    );
  }
}
