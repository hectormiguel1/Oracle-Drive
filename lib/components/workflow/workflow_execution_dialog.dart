import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/crystal_button.dart';
import '../widgets/crystal_dialog.dart';
import '../../models/app_game_code.dart';
import '../../models/workflow/workflow_models.dart';
import '../../providers/workflow_provider.dart'
    show
        workflowExecutorProvider,
        ExecutionStatus,
        WorkflowExecutionStep;

/// Dialog showing workflow execution progress and results.
///
/// Performance optimizations:
/// - Uses [itemExtent] for fixed-height list items
/// - Uses [select] to minimize rebuilds
class WorkflowExecutionDialog extends ConsumerStatefulWidget {
  final Workflow workflow;
  final AppGameCode gameCode;
  final String? workspaceDir;
  final bool previewMode;

  const WorkflowExecutionDialog({
    super.key,
    required this.workflow,
    required this.gameCode,
    this.workspaceDir,
    required this.previewMode,
  });

  @override
  ConsumerState<WorkflowExecutionDialog> createState() =>
      _WorkflowExecutionDialogState();
}

class _WorkflowExecutionDialogState
    extends ConsumerState<WorkflowExecutionDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startExecution();
      }
    });
  }

  Future<void> _startExecution() async {
    final executor = ref.read(workflowExecutorProvider.notifier);
    await executor.execute(
      widget.workflow,
      widget.gameCode,
      previewMode: widget.previewMode,
      workspaceDir: widget.workspaceDir,
    );
  }

  @override
  Widget build(BuildContext context) {
    final execState = ref.watch(workflowExecutorProvider);

    return CrystalDialog(
      title: widget.previewMode ? 'Preview Workflow' : 'Execute Workflow',
      content: SizedBox(
        width: 500,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Workspace info
            if (widget.workspaceDir != null) ...[
              _WorkspaceInfo(workspaceDir: widget.workspaceDir!),
              const SizedBox(height: 12),
            ],
            // Status and progress
            _StatusHeader(
              status: execState.status,
              executedCount: execState.executedNodeCount,
              totalCount: execState.totalNodeCount,
            ),
            const SizedBox(height: 8),
            // Progress bar
            _ProgressBar(
              status: execState.status,
              executedCount: execState.executedNodeCount,
              totalCount: execState.totalNodeCount,
            ),
            const SizedBox(height: 16),
            // Execution log
            Expanded(
              child: _ExecutionLog(logs: execState.executionLog),
            ),
            // Error message
            if (execState.errorMessage != null) ...[
              const SizedBox(height: 8),
              _ErrorMessage(message: execState.errorMessage!),
            ],
            // Preview changes
            if (widget.previewMode && execState.pendingChanges.isNotEmpty) ...[
              const SizedBox(height: 12),
              _PendingChanges(changes: execState.pendingChanges),
            ],
          ],
        ),
      ),
      actions: _buildActions(context, ref, execState.status),
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    WidgetRef ref,
    ExecutionStatus status,
  ) {
    switch (status) {
      case ExecutionStatus.running:
        return [
          CrystalButton(
            label: 'Cancel',
            onPressed: () =>
                ref.read(workflowExecutorProvider.notifier).cancel(),
          ),
        ];
      case ExecutionStatus.paused:
        return [
          CrystalButton(
            label: 'Resume',
            isPrimary: true,
            onPressed: () =>
                ref.read(workflowExecutorProvider.notifier).resume(),
          ),
          CrystalButton(
            label: 'Cancel',
            onPressed: () =>
                ref.read(workflowExecutorProvider.notifier).cancel(),
          ),
        ];
      case ExecutionStatus.completed:
      case ExecutionStatus.error:
      case ExecutionStatus.cancelled:
        return [
          CrystalButton(
            label: 'Close',
            onPressed: () => Navigator.pop(context),
          ),
        ];
      case ExecutionStatus.idle:
        return [];
    }
  }
}

/// Workspace info row.
class _WorkspaceInfo extends StatelessWidget {
  final String workspaceDir;

  const _WorkspaceInfo({required this.workspaceDir});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.folder, color: Colors.cyan, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Workspace: $workspaceDir',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Status header with icon and node count.
class _StatusHeader extends StatelessWidget {
  final ExecutionStatus status;
  final int executedCount;
  final int totalCount;

  const _StatusHeader({
    required this.status,
    required this.executedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatusIcon(status: status),
        const SizedBox(width: 8),
        Text(
          _getStatusText(status),
          style: TextStyle(
            color: _getStatusColor(status),
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Text(
          '$executedCount/$totalCount nodes',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  String _getStatusText(ExecutionStatus status) {
    return switch (status) {
      ExecutionStatus.idle => 'Ready',
      ExecutionStatus.running => 'Running...',
      ExecutionStatus.paused => 'Paused',
      ExecutionStatus.completed => 'Completed',
      ExecutionStatus.error => 'Error',
      ExecutionStatus.cancelled => 'Cancelled',
    };
  }

  Color _getStatusColor(ExecutionStatus status) {
    return switch (status) {
      ExecutionStatus.idle => Colors.white38,
      ExecutionStatus.running => Colors.cyan,
      ExecutionStatus.paused => Colors.orange,
      ExecutionStatus.completed => Colors.green,
      ExecutionStatus.error => Colors.red,
      ExecutionStatus.cancelled => Colors.orange,
    };
  }
}

/// Status icon widget.
class _StatusIcon extends StatelessWidget {
  final ExecutionStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      ExecutionStatus.idle =>
        const Icon(Icons.pending, color: Colors.white38, size: 18),
      ExecutionStatus.running => const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ExecutionStatus.paused =>
        const Icon(Icons.pause_circle, color: Colors.orange, size: 18),
      ExecutionStatus.completed =>
        const Icon(Icons.check_circle, color: Colors.green, size: 18),
      ExecutionStatus.error =>
        const Icon(Icons.error, color: Colors.red, size: 18),
      ExecutionStatus.cancelled =>
        const Icon(Icons.cancel, color: Colors.orange, size: 18),
    };
  }
}

/// Progress bar widget.
class _ProgressBar extends StatelessWidget {
  final ExecutionStatus status;
  final int executedCount;
  final int totalCount;

  const _ProgressBar({
    required this.status,
    required this.executedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalCount > 0 ? executedCount / totalCount : 0.0;
    final color = switch (status) {
      ExecutionStatus.idle => Colors.white38,
      ExecutionStatus.running => Colors.cyan,
      ExecutionStatus.paused => Colors.orange,
      ExecutionStatus.completed => Colors.green,
      ExecutionStatus.error => Colors.red,
      ExecutionStatus.cancelled => Colors.orange,
    };

    return LinearProgressIndicator(
      value: progress,
      backgroundColor: Colors.white12,
      valueColor: AlwaysStoppedAnimation(color),
    );
  }
}

/// Execution log list with fixed item extent for performance.
class _ExecutionLog extends StatelessWidget {
  final List<WorkflowExecutionStep> logs;

  const _ExecutionLog({required this.logs});

  // Fixed height for each log item for ListView performance
  static const double _itemExtent = 48.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white12),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: logs.length,
        itemExtent: _itemExtent,
        itemBuilder: (context, index) {
          final step = logs[index];
          return _ExecutionLogItem(step: step);
        },
      ),
    );
  }
}

/// Individual execution log item.
class _ExecutionLogItem extends StatelessWidget {
  final WorkflowExecutionStep step;

  const _ExecutionLogItem({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          step.success ? Icons.check_circle : Icons.error,
          color: step.success ? Colors.green : Colors.red,
          size: 14,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                step.nodeName,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (step.message != null)
                Text(
                  step.message!,
                  style: TextStyle(
                    color: step.success ? Colors.white54 : Colors.red[300],
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Error message container.
class _ErrorMessage extends StatelessWidget {
  final String message;

  const _ErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red[300], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pending changes preview container.
class _PendingChanges extends StatelessWidget {
  final List<dynamic> changes;

  const _PendingChanges({required this.changes});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pending Changes:',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: changes.length,
            itemBuilder: (context, index) {
              final change = changes[index];
              return Text(
                change.toString(),
                style: const TextStyle(color: Colors.orange, fontSize: 11),
              );
            },
          ),
        ),
      ],
    );
  }
}
