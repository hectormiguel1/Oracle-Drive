import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/workflow/workflow_models.dart';
import '../../providers/workflow_provider.dart';
import 'connection_painter.dart' show ConnectionPainter, NodeDimensions;
import 'workflow_node_widget.dart';

/// Main canvas for the visual workflow node editor.
class WorkflowCanvas extends ConsumerStatefulWidget {
  const WorkflowCanvas({super.key});

  @override
  ConsumerState<WorkflowCanvas> createState() => _WorkflowCanvasState();
}

class _WorkflowCanvasState extends ConsumerState<WorkflowCanvas> {
  final TransformationController _transformController = TransformationController();
  Offset? _pendingConnectionEnd;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use selective watches for better performance - only rebuild when specific fields change
    final workflow = ref.watch(editorWorkflowProvider);
    final selectedNodeId = ref.watch(editorSelectedNodeIdProvider);
    final isConnecting = ref.watch(editorIsConnectingProvider);
    final connectingFromNodeId = ref.watch(
      workflowEditorProvider.select((s) => s.connectingFromNodeId),
    );
    final connectingFromPort = ref.watch(
      workflowEditorProvider.select((s) => s.connectingFromPort),
    );
    final portPositions = ref.watch(
      workflowEditorProvider.select((s) => s.portPositions),
    );

    if (workflow == null) {
      return const Center(
        child: Text(
          'No workflow loaded',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          _handleScroll(event);
        }
      },
      child: GestureDetector(
        onTap: () {
          // Deselect when clicking on empty canvas
          ref.read(workflowEditorProvider.notifier).selectNode(null);
          ref.read(workflowEditorProvider.notifier).cancelConnection();
        },
        onPanUpdate: isConnecting
            ? (details) {
                setState(() {
                  _pendingConnectionEnd = details.localPosition;
                });
              }
            : null,
        onPanEnd: isConnecting
            ? (_) {
                ref.read(workflowEditorProvider.notifier).cancelConnection();
                setState(() {
                  _pendingConnectionEnd = null;
                });
              }
            : null,
        child: DragTarget<NodeType>(
          onAcceptWithDetails: (details) {
            final renderBox = context.findRenderObject() as RenderBox;
            final localPosition = renderBox.globalToLocal(details.offset);

            // Adjust for current transform
            final matrix = _transformController.value.clone()..invert();
            final transformed = MatrixUtils.transformPoint(matrix, localPosition);

            ref.read(workflowEditorProvider.notifier).addNode(
              details.data,
              transformed,
            );
          },
          builder: (context, candidateData, rejectedData) {
            return Container(
              color: const Color(0xFF0a0a0a),
              child: InteractiveViewer(
                transformationController: _transformController,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(2000),
                minScale: 0.25,
                maxScale: 3.0,
                onInteractionUpdate: (details) {
                  if (!isConnecting) {
                    final matrix = _transformController.value;
                    final offset = Offset(matrix.entry(0, 3), matrix.entry(1, 3));
                    final scale = matrix.entry(0, 0);
                    ref.read(workflowEditorProvider.notifier).setCanvasTransform(offset, scale);
                  }
                },
                child: SizedBox(
                  width: 5000,
                  height: 5000,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Grid background - const painter for no rebuilds
                      const Positioned.fill(
                        child: CustomPaint(
                          painter: _GridPainter(),
                        ),
                      ),
                      // Nodes (rendered first so connections appear on top)
                      // Filter out child nodes - they render inside their container
                      ...workflow.nodes
                          .where((node) => !workflow.isChildNode(node.id))
                          .map((node) => Positioned(
                            left: node.position.dx,
                            top: node.position.dy,
                            child: WorkflowNodeWidget(
                              node: node,
                              isSelected: node.id == selectedNodeId,
                              isConnecting: isConnecting,
                            ),
                          )),
                      // Connection lines (on top of nodes)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: ConnectionPainter(
                              connections: workflow.connections,
                              nodes: workflow.nodes,
                              portPositions: portPositions,
                            ),
                          ),
                        ),
                      ),
                      // Pending connection line (on top of everything)
                      if (isConnecting && _pendingConnectionEnd != null)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _PendingConnectionPainter(
                                startNodeId: connectingFromNodeId!,
                                startPort: connectingFromPort!,
                                endPoint: _pendingConnectionEnd!,
                                nodes: workflow.nodes,
                                portPositions: portPositions,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleScroll(PointerScrollEvent event) {
    final delta = event.scrollDelta.dy;
    final scaleFactor = delta > 0 ? 0.9 : 1.1;

    final matrix = _transformController.value.clone();
    final currentScale = matrix.entry(0, 0);
    final newScale = (currentScale * scaleFactor).clamp(0.25, 3.0);

    if (newScale != currentScale) {
      final focalPoint = event.localPosition;

      // Scale around focal point
      // ignore: deprecated_member_use
      matrix.translate(focalPoint.dx, focalPoint.dy);
      // ignore: deprecated_member_use
      matrix.scale(newScale / currentScale);
      // ignore: deprecated_member_use
      matrix.translate(-focalPoint.dx, -focalPoint.dy);

      _transformController.value = matrix;
    }
  }
}

/// Paints a subtle grid pattern on the canvas.
/// Made const with static Paint for optimal performance.
class _GridPainter extends CustomPainter {
  const _GridPainter();

  static final _paint = Paint()
    ..color = Colors.white.withValues(alpha: 0.03)
    ..strokeWidth = 1;

  static const _gridSize = 50.0;

  @override
  void paint(Canvas canvas, Size size) {
    // Vertical lines
    for (double x = 0; x < size.width; x += _gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), _paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += _gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}

/// Paints the connection being drawn.
class _PendingConnectionPainter extends CustomPainter {
  final String startNodeId;
  final String startPort;
  final Offset endPoint;
  final List<WorkflowNode> nodes;
  final Map<String, Offset> portPositions;

  _PendingConnectionPainter({
    required this.startNodeId,
    required this.startPort,
    required this.endPoint,
    required this.nodes,
    this.portPositions = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Bug #57 fix: Check for empty nodes list before accessing
    if (nodes.isEmpty) return;

    final startNode = nodes.cast<WorkflowNode?>().firstWhere(
      (n) => n?.id == startNodeId,
      orElse: () => null,
    );

    // Return early if node not found
    if (startNode == null) return;

    // Try to get actual rendered position first
    final key = '$startNodeId:$startPort:false';
    Offset startPoint;
    final actualPosition = portPositions[key];
    if (actualPosition != null) {
      startPoint = actualPosition;
    } else {
      // Fallback to calculated position
      final portIndex = startNode.outputPortIds.indexOf(startPort);
      final portY = NodeDimensions.firstPortY + portIndex * NodeDimensions.portSpacing;
      startPoint = Offset(
        startNode.position.dx + NodeDimensions.outputPortX,
        startNode.position.dy + portY,
      );
    }

    final paint = Paint()
      ..color = Colors.cyan.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw connection with tiny horizontal exit and smooth curve
    final path = Path();
    const exitOffset = 14.0;

    final exitPoint = Offset(startPoint.dx + exitOffset, startPoint.dy);
    final curveDx = endPoint.dx - exitPoint.dx;
    final curveDy = endPoint.dy - exitPoint.dy;

    path.moveTo(startPoint.dx, startPoint.dy);
    path.lineTo(exitPoint.dx, exitPoint.dy);

    if (curveDx > 40) {
      final controlStrength = (curveDx * 0.4).clamp(30.0, 150.0);
      path.cubicTo(
        exitPoint.dx + controlStrength, exitPoint.dy,
        endPoint.dx - controlStrength, endPoint.dy,
        endPoint.dx, endPoint.dy,
      );
    } else {
      final loopOut = (curveDy.abs() * 0.3 + 50).clamp(60.0, 200.0);
      path.cubicTo(
        exitPoint.dx + loopOut, exitPoint.dy,
        endPoint.dx - loopOut, endPoint.dy,
        endPoint.dx, endPoint.dy,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PendingConnectionPainter oldDelegate) =>
      endPoint != oldDelegate.endPoint ||
      startNodeId != oldDelegate.startNodeId ||
      startPort != oldDelegate.startPort ||
      portPositions != oldDelegate.portPositions;
}
