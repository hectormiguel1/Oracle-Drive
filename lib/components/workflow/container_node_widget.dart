import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/workflow/node_status.dart';
import '../../models/workflow/workflow_models.dart';
import '../../providers/workflow_provider.dart';
import '../widgets/crystal_panel.dart';
import '../widgets/crystal_popup_menu.dart';
import 'workflow_node_widget.dart';

/// Constants for container node layout.
class ContainerDimensions {
  static const double containerWidth = 260.0;
  static const double headerHeight = 44.0;
  static const double footerHeight = 36.0;
  static const double childPaddingHorizontal = 24.0;
  static const double childPaddingVertical = 12.0;
  static const double childSpacing = 12.0;
  static const double minBodyHeight = 80.0;
  static const double bracketWidth = 4.0;
  static const double portCircleSize = 12.0;
}

/// Widget for rendering Loop and ForEach container nodes in Scratch-style.
/// Displays a wrapper around child nodes with a vertical flow.
class ContainerNodeWidget extends ConsumerStatefulWidget {
  final WorkflowNode node;
  final bool isSelected;
  final bool isConnecting;

  const ContainerNodeWidget({
    super.key,
    required this.node,
    this.isSelected = false,
    this.isConnecting = false,
  });

  @override
  ConsumerState<ContainerNodeWidget> createState() => _ContainerNodeWidgetState();
}

class _ContainerNodeWidgetState extends ConsumerState<ContainerNodeWidget> {
  bool _isHovered = false;
  final GlobalKey _inputPortKey = GlobalKey();
  final GlobalKey _donePortKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _reportPortPositionsAfterLayout();
  }

  @override
  void didUpdateWidget(covariant ContainerNodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reportPortPositionsAfterLayout();
  }

  void _reportPortPositionsAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reportPortPosition(_inputPortKey, 'input', true);
      _reportPortPosition(_donePortKey, 'done', false);
    });
  }

  void _reportPortPosition(GlobalKey portKey, String portId, bool isInput) {
    final circleBox = portKey.currentContext?.findRenderObject() as RenderBox?;
    if (circleBox == null || !circleBox.hasSize) return;

    final myBox = context.findRenderObject() as RenderBox?;
    if (myBox == null) return;

    final circleGlobal = circleBox.localToGlobal(
      Offset(circleBox.size.width / 2, circleBox.size.height / 2),
    );
    final myGlobal = myBox.localToGlobal(Offset.zero);
    final offsetInWidget = circleGlobal - myGlobal;

    final workflow = ref.read(workflowEditorProvider).workflow;
    if (workflow == null) return;

    final node = workflow.findNode(widget.node.id);
    if (node == null) return;

    final canvasPos = node.position + offsetInWidget;

    ref.read(workflowEditorProvider.notifier).updatePortPosition(
          widget.node.id,
          portId,
          isInput,
          canvasPos,
        );
  }

  @override
  Widget build(BuildContext context) {
    final nodeColor = widget.node.type.nodeColor;
    final executionMode = widget.node.type.executionMode;
    final children = widget.node.children ?? [];

    final execState = ref.watch(workflowExecutorProvider);
    final editorState = ref.watch(workflowEditorProvider);

    NodeExecutionStatus nodeStatus;
    String? errorMessage;

    if (executionMode == NodeExecutionMode.immediate) {
      nodeStatus = editorState.immediateNodeStatuses[widget.node.id] ??
          NodeExecutionStatus.pending;
      errorMessage = editorState.immediateNodeErrors[widget.node.id];
    } else {
      nodeStatus =
          execState.nodeStatuses[widget.node.id] ?? NodeExecutionStatus.pending;
      errorMessage = execState.nodeErrors[widget.node.id];
    }

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
              width: ContainerDimensions.containerWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header section
                  _buildHeader(nodeColor, nodeStatus, errorMessage, executionMode),
                  // Body with children (Scratch-style bracket)
                  _buildBody(nodeColor, children),
                  // Footer with done port
                  _buildFooter(nodeColor),
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
      height: ContainerDimensions.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: nodeColor.withValues(alpha: 0.25),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(6),
        ),
      ),
      child: Row(
        children: [
          // Input port
          _buildInputPort(nodeColor),
          const SizedBox(width: 8),
          // Scratch-style left bracket indicator
          Container(
            width: ContainerDimensions.bracketWidth,
            height: 24,
            decoration: BoxDecoration(
              color: nodeColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          // Node icon
          Icon(
            widget.node.type.icon,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          // Node name
          Expanded(
            child: Text(
              widget.node.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Context menu on hover
          if (_isHovered || widget.isSelected)
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
      ),
    );
  }

  Widget _buildInputPort(Color nodeColor) {
    return _ContainerPortWidget(
      portKey: _inputPortKey,
      portColor: Colors.cyan,
      isInput: true,
      onTap: () {
        final editorState = ref.read(workflowEditorProvider);
        if (editorState.isConnecting) {
          ref
              .read(workflowEditorProvider.notifier)
              .completeConnection(widget.node.id, 'input');
        }
      },
    );
  }

  Widget _buildBody(Color nodeColor, List<WorkflowNode> children) {
    return DragTarget<NodeType>(
      onWillAcceptWithDetails: (details) {
        // Don't accept container nodes (no nesting)
        return !details.data.isContainer;
      },
      onAcceptWithDetails: (details) {
        // Add node as child of this container
        ref.read(workflowEditorProvider.notifier).addChildToContainer(
              widget.node.id,
              details.data,
            );
      },
      builder: (context, candidateData, rejectedData) {
        final isDropTarget = candidateData.isNotEmpty;

        return Container(
          constraints: BoxConstraints(
            minHeight: ContainerDimensions.minBodyHeight,
          ),
          decoration: BoxDecoration(
            color: isDropTarget
                ? nodeColor.withValues(alpha: 0.15)
                : nodeColor.withValues(alpha: 0.05),
            border: Border(
              left: BorderSide(
                color: nodeColor,
                width: ContainerDimensions.bracketWidth,
              ),
            ),
          ),
          child: children.isEmpty
              ? _buildEmptyBody(nodeColor, isDropTarget)
              : _buildChildrenLayout(children),
        );
      },
    );
  }

  Widget _buildEmptyBody(Color nodeColor, bool isDropTarget) {
    return Container(
      height: ContainerDimensions.minBodyHeight,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isDropTarget ? Icons.add_circle : Icons.add_circle_outline,
            color: isDropTarget
                ? nodeColor.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.3),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            isDropTarget ? 'Drop here' : 'Drag nodes here',
            style: TextStyle(
              color: isDropTarget
                  ? nodeColor.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.3),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenLayout(List<WorkflowNode> children) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ContainerDimensions.childPaddingHorizontal,
        vertical: ContainerDimensions.childPaddingVertical,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) ...[
              // Connection line between children
              _buildChildConnectionLine(),
              const SizedBox(height: ContainerDimensions.childSpacing / 2),
            ],
            _buildChildNode(children[i], i),
            if (i < children.length - 1)
              const SizedBox(height: ContainerDimensions.childSpacing / 2),
          ],
        ],
      ),
    );
  }

  Widget _buildChildConnectionLine() {
    return Container(
      width: 2,
      height: ContainerDimensions.childSpacing,
      decoration: BoxDecoration(
        color: Colors.cyan.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildChildNode(WorkflowNode child, int index) {
    final editorState = ref.watch(workflowEditorProvider);
    final isSelected = editorState.selectedNodeId == child.id;

    return GestureDetector(
      onTap: () {
        ref.read(workflowEditorProvider.notifier).selectNode(child.id);
      },
      child: WorkflowNodeWidget(
        node: child,
        isSelected: isSelected,
        isConnecting: widget.isConnecting,
        isContainerChild: true,
      ),
    );
  }

  Widget _buildFooter(Color nodeColor) {
    return Container(
      height: ContainerDimensions.footerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: nodeColor.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(6),
          bottomRight: Radius.circular(6),
        ),
      ),
      child: Row(
        children: [
          // Scratch-style left bracket indicator
          Container(
            width: ContainerDimensions.bracketWidth,
            height: 16,
            decoration: BoxDecoration(
              color: nodeColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Spacer(),
          const Text(
            'done',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 8),
          _buildDonePort(nodeColor),
        ],
      ),
    );
  }

  Widget _buildDonePort(Color nodeColor) {
    return _ContainerPortWidget(
      portKey: _donePortKey,
      portColor: Colors.cyan,
      isInput: false,
      onTap: () {
        ref.read(workflowEditorProvider.notifier).startConnection(
              widget.node.id,
              'done',
            );
      },
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


/// Port widget for container nodes with hover effects.
class _ContainerPortWidget extends StatefulWidget {
  final GlobalKey portKey;
  final Color portColor;
  final bool isInput;
  final VoidCallback onTap;

  const _ContainerPortWidget({
    required this.portKey,
    required this.portColor,
    required this.isInput,
    required this.onTap,
  });

  @override
  State<_ContainerPortWidget> createState() => _ContainerPortWidgetState();
}

class _ContainerPortWidgetState extends State<_ContainerPortWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) {
          if (mounted) setState(() => _isHovered = true);
        },
        onExit: (_) {
          if (mounted) setState(() => _isHovered = false);
        },
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          key: widget.portKey,
          duration: const Duration(milliseconds: 100),
          width: ContainerDimensions.portCircleSize,
          height: ContainerDimensions.portCircleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isHovered
                ? widget.portColor.withValues(alpha: 0.6)
                : widget.portColor.withValues(alpha: 0.3),
            border: Border.all(
              color: widget.portColor,
              width: 1.5,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.portColor.withValues(alpha: 0.6),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}
