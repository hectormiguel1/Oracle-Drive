import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/crystal_button.dart';
import '../widgets/crystal_popup_menu.dart';
import '../widgets/crystal_panel.dart';
import '../widgets/style.dart';
import '../../providers/workflow_provider.dart';
import 'workspace_selector.dart';

/// Toolbar for the workflow editor.
///
/// Uses [select] to minimize rebuilds - only rebuilds when specific
/// properties change rather than the entire editor state.
class WorkflowToolbar extends ConsumerWidget {
  final bool showWorkflowList;
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
  final VoidCallback? onEnterFullscreen;

  const WorkflowToolbar({
    super.key,
    required this.showWorkflowList,
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
    this.onEnterFullscreen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use select to only rebuild on specific property changes
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
          // Back button
          if (!showWorkflowList) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
              onPressed: onBackToList,
              tooltip: 'Back to list',
            ),
            const SizedBox(width: 8),
          ],
          // New button
          CrystalButton(
            label: 'New',
            icon: Icons.add,
            onPressed: onNew,
          ),
          const SizedBox(width: 8),
          // Open button
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
            _ExportMenu(
              onExportJson: onExportJson,
              onExportClipboard: onExportClipboard,
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
            _UndoRedoButtons(canUndo: canUndo, canRedo: canRedo),
            const SizedBox(width: 16),
            // Validate
            CrystalButton(
              label: 'Validate',
              icon: Icons.check_circle_outline,
              onPressed: onValidate,
            ),
            const SizedBox(width: 8),
            // Preview
            CrystalButton(
              label: 'Preview',
              icon: Icons.visibility,
              onPressed: onPreview,
            ),
            const SizedBox(width: 8),
            // Fullscreen
            if (onEnterFullscreen != null)
              IconButton(
                icon: const Icon(Icons.fullscreen, color: Colors.white70),
                onPressed: onEnterFullscreen,
                tooltip: 'Fullscreen Mode',
              ),
            const SizedBox(width: 8),
            // Run
            CrystalButton(
              label: 'Run',
              icon: Icons.play_arrow,
              isPrimary: true,
              onPressed: onRun,
            ),
          ] else ...[
            const Spacer(),
            Text(
              'Workflow Editor',
              style: CrystalStyles.sectionHeader,
            ),
            const Spacer(),
          ],
        ],
      ),
    );
  }
}

/// Export menu button with dropdown options.
class _ExportMenu extends StatelessWidget {
  final Future<void> Function() onExportJson;
  final Future<void> Function() onExportClipboard;

  const _ExportMenu({
    required this.onExportJson,
    required this.onExportClipboard,
  });

  @override
  Widget build(BuildContext context) {
    return CrystalPopupMenuButton<String>(
      items: const [
        CrystalMenuItem(
          value: 'json',
          label: 'Export to JSON file',
          icon: Icons.save_alt,
        ),
        CrystalMenuItem(
          value: 'clipboard',
          label: 'Copy to clipboard',
          icon: Icons.content_copy,
        ),
      ],
      onSelected: (value) {
        if (value == 'json') onExportJson();
        if (value == 'clipboard') onExportClipboard();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.file_download, color: Colors.white70, size: 18),
            SizedBox(width: 6),
            Text('Export', style: TextStyle(color: Colors.white70, fontSize: 12)),
            SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Undo/Redo buttons - separated to minimize rebuilds.
class _UndoRedoButtons extends ConsumerWidget {
  final bool canUndo;
  final bool canRedo;

  const _UndoRedoButtons({
    required this.canUndo,
    required this.canRedo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
      ],
    );
  }
}

