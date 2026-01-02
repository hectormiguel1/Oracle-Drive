import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:oracle_drive/components/widgets/crystal_button.dart';
import 'package:oracle_drive/components/widgets/crystal_container.dart';
import 'package:oracle_drive/components/widgets/crystal_dialog.dart';
import 'package:oracle_drive/components/widgets/crystal_dropdowns.dart';
import 'package:oracle_drive/components/widgets/crystal_text_field.dart';
import 'package:oracle_drive/models/crystalium/cgt_file.dart';
import 'package:oracle_drive/models/crystalium/mcp_file.dart';
import 'package:oracle_drive/theme/crystal_theme.dart';

/// Parameters for adding an offshoot
class AddOffshootParams {
  final String patternName;
  final int stage;
  final int roleId;
  final String? customNodeName;

  AddOffshootParams({
    required this.patternName,
    required this.stage,
    required this.roleId,
    this.customNodeName,
  });
}

/// Widget that renders a preview of an MCP pattern
class PatternPreview extends StatelessWidget {
  final McpPattern? pattern;
  final Color color;
  final double size;

  const PatternPreview({
    super.key,
    required this.pattern,
    required this.color,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    if (pattern == null || pattern!.nodes.isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            'No preview',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PatternPreviewPainter(
          pattern: pattern!,
          color: color,
        ),
      ),
    );
  }
}

class _PatternPreviewPainter extends CustomPainter {
  final McpPattern pattern;
  final Color color;

  _PatternPreviewPainter({
    required this.pattern,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pattern.nodes.isEmpty) return;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Calculate bounds to fit pattern in view
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minZ = double.infinity, maxZ = double.negativeInfinity;

    for (final node in pattern.nodes) {
      minX = math.min(minX, node.x);
      maxX = math.max(maxX, node.x);
      minZ = math.min(minZ, node.z);
      maxZ = math.max(maxZ, node.z);
    }

    // Add some padding
    final rangeX = (maxX - minX).abs();
    final rangeZ = (maxZ - minZ).abs();
    final maxRange = math.max(rangeX, rangeZ);
    final scale = maxRange > 0 ? (size.width - 30) / maxRange : 1.0;

    // Center offset
    final offsetX = (minX + maxX) / 2;
    final offsetZ = (minZ + maxZ) / 2;

    // Project nodes to 2D (top-down view, slight rotation for depth)
    final projectedNodes = <Offset>[];
    for (final node in pattern.nodes) {
      // Simple isometric-like projection
      final x = (node.x - offsetX) * scale;
      final z = (node.z - offsetZ) * scale;
      final y = node.y * scale * 0.3; // Slight vertical offset for depth

      projectedNodes.add(Offset(
        centerX + x * 0.9 - z * 0.3,
        centerY - y - z * 0.5,
      ));
    }

    // Draw connections from center (first node) to all others
    if (projectedNodes.length > 1) {
      final linePaint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      final firstNode = projectedNodes.first;
      for (var i = 1; i < projectedNodes.length; i++) {
        canvas.drawLine(firstNode, projectedNodes[i], linePaint);
      }

      // Draw connections between adjacent nodes (for patterns that form shapes)
      final connectionPaint = Paint()
        ..color = color.withValues(alpha: 0.25)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      for (var i = 1; i < projectedNodes.length; i++) {
        final next = (i + 1) < projectedNodes.length ? i + 1 : 1;
        if (next != i) {
          canvas.drawLine(projectedNodes[i], projectedNodes[next], connectionPaint);
        }
      }
    }

    // Draw nodes
    for (var i = 0; i < projectedNodes.length; i++) {
      final pos = projectedNodes[i];
      final isCenter = i == 0;
      final nodeSize = isCenter ? 8.0 : 6.0;

      // Outer glow
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3);
      canvas.drawCircle(pos, nodeSize + 4, glowPaint);

      // Node body
      final nodePaint = Paint()
        ..color = isCenter ? Colors.white : color;
      canvas.drawCircle(pos, nodeSize, nodePaint);

      // Inner highlight
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.7);
      canvas.drawCircle(pos, nodeSize * 0.4, highlightPaint);
    }

    // Draw node count label
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${pattern.count} nodes',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        centerX - textPainter.width / 2,
        size.height - textPainter.height - 4,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _PatternPreviewPainter oldDelegate) {
    return oldDelegate.pattern != pattern || oldDelegate.color != color;
  }
}

/// Dialog for adding an offshoot to a node.
class AddOffshootDialog extends StatefulWidget {
  final int targetNodeId;
  final List<String> patternNames;
  final McpFile? mcpFile;
  final int? initialStage;
  final int? initialRoleId;

  const AddOffshootDialog({
    super.key,
    required this.targetNodeId,
    required this.patternNames,
    this.mcpFile,
    this.initialStage,
    this.initialRoleId,
  });

  static Future<AddOffshootParams?> show(
    BuildContext context, {
    required int targetNodeId,
    required List<String> patternNames,
    McpFile? mcpFile,
    int? initialStage,
    int? initialRoleId,
  }) {
    return showDialog<AddOffshootParams>(
      context: context,
      builder: (context) => AddOffshootDialog(
        targetNodeId: targetNodeId,
        patternNames: patternNames,
        mcpFile: mcpFile,
        initialStage: initialStage,
        initialRoleId: initialRoleId,
      ),
    );
  }

  @override
  State<AddOffshootDialog> createState() => _AddOffshootDialogState();
}

class _AddOffshootDialogState extends State<AddOffshootDialog> {
  late String _selectedPattern;
  late int _selectedStage;
  late int _selectedRole;
  final _nodeNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedPattern = widget.patternNames.isNotEmpty ? widget.patternNames.first : 'test1';
    _selectedStage = widget.initialStage ?? 1;
    _selectedRole = widget.initialRoleId ?? 0;
  }

  @override
  void dispose() {
    _nodeNameController.dispose();
    super.dispose();
  }

  Color _getRoleColor(int roleId) {
    switch (roleId) {
      case 1: return const Color(0xFFFF6090); // Commando
      case 5: return const Color(0xFF40FF90); // Medic
      case 2: return const Color(0xFF6090FF); // Ravager
      case 3: return const Color(0xFFFF60FF); // Saboteur
      case 0: return const Color(0xFFFFB060); // Sentinel
      case 4: return const Color(0xFF60FFFF); // Synergist
      default: return const Color(0xFFE0E0FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CrystalTheme>()!;
    final selectedMcpPattern = widget.mcpFile?.getPattern(_selectedPattern);
    final roleColor = _getRoleColor(_selectedRole);

    return CrystalDialog(
      title: 'ADD OFFSHOOT',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parent node info
          Row(
            children: [
              Text(
                'PARENT NODE',
                style: TextStyle(
                  color: theme.accent.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 12),
              CrystalContainer(
                skew: 0,
                color: theme.accent.withValues(alpha: 0.15),
                borderColor: theme.accent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(
                    '#${widget.targetNodeId}',
                    style: TextStyle(
                      color: theme.accent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Pattern selection with preview
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pattern dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CrystalDropdown<String>(
                      label: 'PATTERN',
                      value: _selectedPattern,
                      items: widget.patternNames,
                      onChanged: (value) => setState(() => _selectedPattern = value),
                    ),
                    const SizedBox(height: 16),

                    // Node name field
                    Text(
                      'NODE NAME',
                      style: TextStyle(
                        color: theme.accent.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    CrystalTextField(
                      controller: _nodeNameController,
                      hintText: 'Auto-generated if empty',
                      prefixIcon: Icons.label_outline,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Pattern preview
              Column(
                children: [
                  Text(
                    'PREVIEW',
                    style: TextStyle(
                      color: theme.accent.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  CrystalContainer(
                    skew: 0,
                    color: Colors.black26,
                    borderColor: roleColor.withValues(alpha: 0.5),
                    child: PatternPreview(
                      pattern: selectedMcpPattern,
                      color: roleColor,
                      size: 120,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stage and Role in a row
          Row(
            children: [
              Expanded(
                child: CrystalDropdown<int>(
                  label: 'STAGE',
                  value: _selectedStage,
                  items: List.generate(10, (i) => i + 1),
                  itemLabelBuilder: (stage) => 'Stage $stage',
                  onChanged: (value) => setState(() => _selectedStage = value),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CrystalDropdown<int>(
                  label: 'ROLE',
                  value: _selectedRole,
                  items: CrystariumRole.values.map((r) => r.id).toList(),
                  itemLabelBuilder: (id) {
                    final role = CrystariumRole.fromId(id);
                    return '${role.abbreviation} - ${role.fullName}';
                  },
                  onChanged: (value) => setState(() => _selectedRole = value),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        CrystalButton(
          label: 'Cancel',
          icon: Icons.close,
          onPressed: () => Navigator.pop(context),
        ),
        CrystalButton(
          label: 'Add Offshoot',
          icon: Icons.add_circle_outline,
          isPrimary: true,
          onPressed: () {
            final customName = _nodeNameController.text.trim();
            Navigator.pop(
              context,
              AddOffshootParams(
                patternName: _selectedPattern,
                stage: _selectedStage,
                roleId: _selectedRole,
                customNodeName: customName.isEmpty ? null : customName,
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Dialog for editing a node's name.
class EditNodeNameDialog extends StatefulWidget {
  final int nodeId;
  final String currentName;

  const EditNodeNameDialog({
    super.key,
    required this.nodeId,
    required this.currentName,
  });

  static Future<String?> show(
    BuildContext context, {
    required int nodeId,
    required String currentName,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => EditNodeNameDialog(
        nodeId: nodeId,
        currentName: currentName,
      ),
    );
  }

  @override
  State<EditNodeNameDialog> createState() => _EditNodeNameDialogState();
}

class _EditNodeNameDialogState extends State<EditNodeNameDialog> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CrystalTheme>()!;

    return CrystalDialog(
      title: 'EDIT NODE NAME',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Node ID info
          Row(
            children: [
              Text(
                'NODE',
                style: TextStyle(
                  color: theme.accent.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 12),
              CrystalContainer(
                skew: 0,
                color: theme.accent.withValues(alpha: 0.15),
                borderColor: theme.accent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(
                    '#${widget.nodeId}',
                    style: TextStyle(
                      color: theme.accent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Name field
          Text(
            'NODE NAME',
            style: TextStyle(
              color: theme.accent.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          CrystalTextField(
            controller: _nameController,
            hintText: 'Enter node name (max 16 chars)',
            prefixIcon: Icons.label_outline,
          ),
          const SizedBox(height: 8),
          Text(
            'Node names are limited to 16 characters',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
      actions: [
        CrystalButton(
          label: 'Cancel',
          icon: Icons.close,
          onPressed: () => Navigator.pop(context),
        ),
        CrystalButton(
          label: 'Save',
          icon: Icons.save,
          isPrimary: true,
          onPressed: () => Navigator.pop(context, _nameController.text.trim()),
        ),
      ],
    );
  }
}
