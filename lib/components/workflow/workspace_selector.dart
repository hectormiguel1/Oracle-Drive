import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/crystal_ribbon.dart';
import '../widgets/crystal_snackbar.dart';
import '../../providers/workflow_provider.dart';

/// Workspace directory selector widget.
///
/// Uses [select] to only rebuild when workspace path changes.
class WorkspaceSelector extends ConsumerWidget {
  const WorkspaceSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceDir = ref.watch(
      workflowEditorProvider.select((s) => s.workflow?.workspacePath),
    );
    final hasWorkspace = workspaceDir != null && workspaceDir.isNotEmpty;
    final displayPath = hasWorkspace ? _getShortPath(workspaceDir) : 'No workspace';

    return Tooltip(
      message: hasWorkspace
          ? workspaceDir
          : 'Set workspace directory for relative paths',
      child: InkWell(
        onTap: () => _selectWorkspaceDir(context, ref, workspaceDir),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: hasWorkspace
                ? Colors.cyan.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: hasWorkspace
                  ? Colors.cyan.withValues(alpha: 0.3)
                  : Colors.white12,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_outlined,
                color: hasWorkspace ? Colors.cyan : Colors.white38,
                size: 16,
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  displayPath,
                  style: TextStyle(
                    color: hasWorkspace ? Colors.white70 : Colors.white38,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasWorkspace) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    ref.read(workflowEditorProvider.notifier).setWorkspacePath(null);
                    ref.read(workflowExecutorProvider.notifier).setWorkspaceDir(null);
                  },
                  child: const Icon(
                    Icons.close,
                    color: Colors.white38,
                    size: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getShortPath(String path) {
    final parts = path.split(Platform.pathSeparator);
    if (parts.length <= 2) return path;
    return '...${Platform.pathSeparator}${parts.last}';
  }

  Future<void> _selectWorkspaceDir(
    BuildContext context,
    WidgetRef ref,
    String? currentWorkspace,
  ) async {
    final initialDir = currentWorkspace ?? Platform.environment['HOME'] ?? '/';

    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Workspace Directory',
      initialDirectory: initialDir,
    );

    if (result != null) {
      ref.read(workflowEditorProvider.notifier).setWorkspacePath(result);
      ref.read(workflowExecutorProvider.notifier).setWorkspaceDir(result);
      if (context.mounted) {
        showCrystalSnackBar(
          context,
          'Workspace set to: $result',
          type: CrystalSnackBarType.success,
        );
      }
    }
  }
}
