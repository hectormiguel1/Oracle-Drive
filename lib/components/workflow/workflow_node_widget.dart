import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/workflow/node_status.dart';
import '../../models/workflow/workflow_models.dart';
import '../../providers/workflow_provider.dart';
import '../widgets/crystal_panel.dart';
import '../widgets/crystal_popup_menu.dart';

/// Visual representation of a workflow node.
class WorkflowNodeWidget extends ConsumerStatefulWidget {
  final WorkflowNode node;
  final bool isSelected;
  final bool isConnecting;

  const WorkflowNodeWidget({
    super.key,
    required this.node,
    this.isSelected = false,
    this.isConnecting = false,
  });

  @override
  ConsumerState<WorkflowNodeWidget> createState() => _WorkflowNodeWidgetState();
}

class _WorkflowNodeWidgetState extends ConsumerState<WorkflowNodeWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final nodeColor = widget.node.type.nodeColor;
    final executionMode = widget.node.type.executionMode;

    // Get node status from either execution state or immediate node state
    final execState = ref.watch(workflowExecutorProvider);
    final editorState = ref.watch(workflowEditorProvider);

    // Determine the node's execution status
    NodeExecutionStatus nodeStatus;
    String? errorMessage;

    if (executionMode == NodeExecutionMode.immediate) {
      // Immediate nodes get their status from editor state
      nodeStatus = editorState.immediateNodeStatuses[widget.node.id] ??
          NodeExecutionStatus.pending;
      errorMessage = editorState.immediateNodeErrors[widget.node.id];
    } else {
      // Lazy nodes get their status from execution state (during workflow runs)
      nodeStatus = execState.nodeStatuses[widget.node.id] ??
          NodeExecutionStatus.pending;
      errorMessage = execState.nodeErrors[widget.node.id];
    }

    // Override with "executing" if this is the current node during execution
    if (execState.isRunning && execState.currentNodeId == widget.node.id) {
      nodeStatus = NodeExecutionStatus.executing;
    }

    return MouseRegion(
      onEnter: (_) {
        if (mounted) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (mounted) setState(() => _isHovered = false);
      },
      child: GestureDetector(
        onTap: () {
          ref.read(workflowEditorProvider.notifier).selectNode(widget.node.id);
        },
        onDoubleTap: () {
          // Open node editor on double-tap
          ref.read(workflowEditorProvider.notifier).selectNode(widget.node.id);
        },
        onPanStart: (details) {
          ref.read(workflowEditorProvider.notifier).selectNode(widget.node.id);
        },
        onPanUpdate: (details) {
          ref.read(workflowEditorProvider.notifier).updateNodePosition(
                widget.node.id,
                widget.node.position + details.delta,
              );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected
                    ? nodeColor.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.3),
                blurRadius: widget.isSelected ? 16 : 8,
                spreadRadius: widget.isSelected ? 2 : 0,
              ),
            ],
          ),
          child: CrystalPanel(
            padding: EdgeInsets.zero,
            blurSigma: CrystalBlur.subtle,
            borderRadius: 8,
            showAccentBorder: widget.isSelected,
            child: SizedBox(
              width: 220,
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header with badges
                      _buildHeader(nodeColor, nodeStatus, errorMessage, executionMode),
                      // Ports
                      _buildPorts(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    Color nodeColor,
    NodeExecutionStatus nodeStatus,
    String? errorMessage,
    NodeExecutionMode executionMode,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: nodeColor.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        border: Border(
          bottom: BorderSide(
            color: nodeColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          // Execution mode badge (left side)
          _ExecutionModeBadge(mode: executionMode),
          const SizedBox(width: 8),
          Icon(
            widget.node.type.icon,
            color: nodeColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.node.displayName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Status badge (right side, before menu)
          _NodeStatusBadge(
            status: nodeStatus,
            errorMessage: errorMessage,
          ),
          // Context menu
          if (_isHovered || widget.isSelected) ...[
            const SizedBox(width: 4),
            CrystalPopupMenuButton<String>(
              icon: Icons.more_vert,
              items: const [
                CrystalMenuItem(
                  value: 'duplicate',
                  label: 'Duplicate',
                  icon: Icons.copy,
                ),
                CrystalMenuItem(
                  value: 'delete',
                  label: 'Delete',
                  icon: Icons.delete,
                  isDanger: true,
                ),
              ],
              onSelected: (value) => _handleMenuAction(value),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPorts() {
    final inputPorts = widget.node.type.inputPorts;
    final outputPorts = widget.node.type.outputPorts;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input ports (left side)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: inputPorts
                .map((port) => _PortWidget(
                      port: port,
                      isInput: true,
                      nodeId: widget.node.id,
                      isConnecting: widget.isConnecting,
                    ))
                .toList(),
          ),
          // Output ports (right side)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: outputPorts
                .map((port) => _PortWidget(
                      port: port,
                      isInput: false,
                      nodeId: widget.node.id,
                      isConnecting: widget.isConnecting,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    final notifier = ref.read(workflowEditorProvider.notifier);
    switch (action) {
      case 'duplicate':
        notifier.duplicateNode(widget.node.id);
        break;
      case 'delete':
        notifier.removeNode(widget.node.id);
        break;
    }
  }
}

/// A port widget that can be connected to other ports.
class _PortWidget extends ConsumerStatefulWidget {
  final PortDefinition port;
  final bool isInput;
  final String nodeId;
  final bool isConnecting;

  const _PortWidget({
    required this.port,
    required this.isInput,
    required this.nodeId,
    required this.isConnecting,
  });

  @override
  ConsumerState<_PortWidget> createState() => _PortWidgetState();
}

class _PortWidgetState extends ConsumerState<_PortWidget> {
  bool _isHovered = false;
  final GlobalKey _circleKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _reportPositionAfterLayout();
  }

  @override
  void didUpdateWidget(covariant _PortWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-report position when node might have moved
    _reportPositionAfterLayout();
  }

  void _reportPositionAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final circleBox = _circleKey.currentContext?.findRenderObject() as RenderBox?;
      if (circleBox == null || !circleBox.hasSize) return;

      // Find the WorkflowNodeWidget ancestor to get relative position within node
      RenderBox? nodeBox;
      context.visitAncestorElements((element) {
        if (element.widget is WorkflowNodeWidget) {
          nodeBox = element.findRenderObject() as RenderBox?;
          return false;
        }
        return true;
      });

      if (nodeBox == null) return;

      // Get circle center position relative to the node widget
      final circleGlobal = circleBox.localToGlobal(
        Offset(circleBox.size.width / 2, circleBox.size.height / 2),
      );
      final nodeGlobal = nodeBox!.localToGlobal(Offset.zero);
      final offsetInNode = circleGlobal - nodeGlobal;

      // Get the node's position from the workflow state
      final workflow = ref.read(workflowEditorProvider).workflow;
      if (workflow == null) return;

      final node = workflow.nodes.cast<WorkflowNode?>().firstWhere(
            (n) => n?.id == widget.nodeId,
            orElse: () => null,
          );
      if (node == null) return;

      // Final position = node position + offset within node
      final canvasPos = node.position + offsetInNode;

      ref.read(workflowEditorProvider.notifier).updatePortPosition(
            widget.nodeId,
            widget.port.id,
            widget.isInput,
            canvasPos,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final portColor = widget.port.color ?? Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: GestureDetector(
        onTap: () => _handleTap(),
        child: MouseRegion(
          onEnter: (_) {
            if (mounted) setState(() => _isHovered = true);
          },
          onExit: (_) {
            if (mounted) setState(() => _isHovered = false);
          },
          cursor: SystemMouseCursors.click,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.isInput) ...[
                Text(
                  widget.port.displayName,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              AnimatedContainer(
                key: _circleKey,
                duration: const Duration(milliseconds: 100),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isHovered
                      ? portColor.withValues(alpha: 0.6)
                      : portColor.withValues(alpha: 0.3),
                  border: Border.all(
                    color: portColor,
                    width: 1.5,
                  ),
                  boxShadow: _isHovered
                      ? [
                          BoxShadow(
                            color: portColor.withValues(alpha: 0.6),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
              ),
              if (widget.isInput) ...[
                const SizedBox(width: 6),
                Text(
                  widget.port.displayName,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap() {
    final notifier = ref.read(workflowEditorProvider.notifier);
    final editorState = ref.read(workflowEditorProvider);

    if (widget.isInput) {
      // Input port - complete connection if we're connecting
      if (editorState.isConnecting) {
        notifier.completeConnection(widget.nodeId, widget.port.id);
      }
    } else {
      // Output port - start connection
      notifier.startConnection(widget.nodeId, widget.port.id);
    }
  }
}

/// Badge showing the node's execution status.
class _NodeStatusBadge extends StatefulWidget {
  final NodeExecutionStatus status;
  final String? errorMessage;

  const _NodeStatusBadge({
    required this.status,
    this.errorMessage,
  });

  @override
  State<_NodeStatusBadge> createState() => _NodeStatusBadgeState();
}

class _NodeStatusBadgeState extends State<_NodeStatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    if (widget.status == NodeExecutionStatus.executing) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(_NodeStatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == NodeExecutionStatus.executing) {
      if (!_animationController.isAnimating) {
        _animationController.repeat();
      }
    } else {
      _animationController.stop();
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Don't show badge for pending status
    if (widget.status == NodeExecutionStatus.pending) {
      return const SizedBox(width: 20);
    }

    Widget badge = Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.status.color,
        border: Border.all(
          color: widget.status.color.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.status.color.withValues(alpha: 0.4),
            blurRadius: 4,
          ),
        ],
      ),
      child: widget.status == NodeExecutionStatus.executing
          ? RotationTransition(
              turns: _animationController,
              child: Icon(
                Icons.sync,
                size: 12,
                color: Colors.white,
              ),
            )
          : Icon(
              widget.status.icon,
              size: 12,
              color: Colors.white,
            ),
    );

    // Add tooltip for error messages
    if (widget.errorMessage != null) {
      badge = Tooltip(
        message: widget.errorMessage!,
        child: badge,
      );
    }

    return badge;
  }
}

/// Badge showing the node's execution mode (immediate vs lazy).
class _ExecutionModeBadge extends StatelessWidget {
  final NodeExecutionMode mode;

  const _ExecutionModeBadge({required this.mode});

  @override
  Widget build(BuildContext context) {
    final isImmediate = mode == NodeExecutionMode.immediate;

    return Tooltip(
      message: '${mode.displayName}: ${mode.description}',
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isImmediate
              ? const Color(0xFFFFAB00) // Vivid amber
              : const Color(0xFF546E7A), // Blue-grey
          border: Border.all(
            color: isImmediate
                ? const Color(0xFFFFD740) // Light amber border
                : const Color(0xFF78909C), // Light grey border
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isImmediate
                      ? const Color(0xFFFFAB00)
                      : const Color(0xFF546E7A))
                  .withValues(alpha: 0.4),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(
          mode.icon,
          size: 12,
          color: Colors.white,
        ),
      ),
    );
  }
}
