import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/crystal_button.dart';
import '../widgets/crystal_dialog.dart';
import '../widgets/crystal_panel.dart';
import '../widgets/style.dart';
import '../../models/app_game_code.dart';
import '../../models/workflow/workflow_models.dart';
import '../../providers/workflow_provider.dart';

/// Widget showing the list of saved workflows.
class WorkflowListView extends ConsumerWidget {
  final AppGameCode gameCode;
  final void Function(Workflow) onOpen;
  final VoidCallback onCreate;

  const WorkflowListView({
    super.key,
    required this.gameCode,
    required this.onOpen,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflowsAsync = ref.watch(workflowListProvider(gameCode));

    return CrystalPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Saved Workflows', style: CrystalStyles.sectionHeader),
              const SizedBox(width: 8),
              Text(
                '(${gameCode.displayName})',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const Spacer(),
              CrystalButton(
                label: 'New Workflow',
                icon: Icons.add,
                isPrimary: true,
                onPressed: onCreate,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: workflowsAsync.when(
              data: (workflows) {
                if (workflows.isEmpty) {
                  return _EmptyWorkflowState(onCreate: onCreate);
                }

                return ListView.builder(
                  itemCount: workflows.length,
                  itemBuilder: (context, index) {
                    final workflow = workflows[index];
                    return WorkflowTile(
                      workflow: workflow,
                      onTap: () => onOpen(workflow),
                      onDelete: () async {
                        final repo = ref.read(gameRepositoryProvider(workflow.gameCode));
                        await repo.deleteWorkflow(workflow.id);
                        ref.invalidate(workflowListProvider(gameCode));
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Error loading workflows: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state shown when no workflows exist.
class _EmptyWorkflowState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyWorkflowState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_tree_outlined, color: Colors.white24, size: 64),
          const SizedBox(height: 16),
          const Text(
            'No workflows yet',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first workflow to automate modding tasks',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 24),
          CrystalButton(
            label: 'Create Workflow',
            icon: Icons.add,
            isPrimary: true,
            onPressed: onCreate,
          ),
        ],
      ),
    );
  }
}

/// Individual workflow tile in the list.
///
/// Uses [StatelessWidget] with [MouseRegion] and [ValueNotifier]
/// to avoid rebuilding the entire widget on hover state changes.
class WorkflowTile extends StatelessWidget {
  final Workflow workflow;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const WorkflowTile({
    super.key,
    required this.workflow,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return _HoverableWorkflowTile(
      workflow: workflow,
      onTap: onTap,
      onDelete: onDelete,
    );
  }
}

/// Internal hoverable implementation using ValueNotifier for performance.
class _HoverableWorkflowTile extends StatefulWidget {
  final Workflow workflow;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HoverableWorkflowTile({
    required this.workflow,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_HoverableWorkflowTile> createState() => _HoverableWorkflowTileState();
}

class _HoverableWorkflowTileState extends State<_HoverableWorkflowTile> {
  final _isHovered = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _isHovered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _isHovered.value = true,
      onExit: (_) => _isHovered.value = false,
      child: InkWell(
        onTap: widget.onTap,
        child: ValueListenableBuilder<bool>(
          valueListenable: _isHovered,
          builder: (context, isHovered, child) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isHovered
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isHovered
                      ? Colors.cyan.withValues(alpha: 0.3)
                      : Colors.white12,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_tree,
                    color: Colors.cyan,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.workflow.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.workflow.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.workflow.description,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          '${widget.workflow.nodes.length} nodes • Modified ${_formatDate(widget.workflow.modifiedAt)}',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isHovered) ...[
                    IconButton(
                      icon: const Icon(Icons.play_arrow, color: Colors.green),
                      onPressed: widget.onTap,
                      tooltip: 'Run',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDelete(context),
                      tooltip: 'Delete',
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CrystalDialog(
        title: 'Delete Workflow',
        content: Text(
          'Are you sure you want to delete "${widget.workflow.name}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          CrystalButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context),
          ),
          CrystalButton(
            label: 'Delete',
            isPrimary: true,
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete();
            },
          ),
        ],
      ),
    );
  }
}
