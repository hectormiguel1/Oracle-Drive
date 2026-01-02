import 'package:flutter/material.dart';
import 'package:oracle_drive/components/widgets/crystal_button.dart';
import 'package:oracle_drive/components/widgets/crystal_container.dart';
import 'package:oracle_drive/components/widgets/crystal_dialog.dart';
import 'package:oracle_drive/components/widgets/crystal_dropdowns.dart';
import 'package:oracle_drive/components/widgets/crystal_text_field.dart';
import 'package:oracle_drive/models/crystalium/cgt_file.dart';
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

/// Dialog for adding an offshoot to a node.
class AddOffshootDialog extends StatefulWidget {
  final int targetNodeId;
  final List<String> patternNames;
  final int? initialStage;
  final int? initialRoleId;

  const AddOffshootDialog({
    super.key,
    required this.targetNodeId,
    required this.patternNames,
    this.initialStage,
    this.initialRoleId,
  });

  static Future<AddOffshootParams?> show(
    BuildContext context, {
    required int targetNodeId,
    required List<String> patternNames,
    int? initialStage,
    int? initialRoleId,
  }) {
    return showDialog<AddOffshootParams>(
      context: context,
      builder: (context) => AddOffshootDialog(
        targetNodeId: targetNodeId,
        patternNames: patternNames,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CrystalTheme>()!;

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
            hintText: 'Leave empty for auto-generated name',
            prefixIcon: Icons.label_outline,
          ),
          const SizedBox(height: 20),

          // Pattern dropdown
          CrystalDropdown<String>(
            label: 'PATTERN',
            value: _selectedPattern,
            items: widget.patternNames,
            onChanged: (value) => setState(() => _selectedPattern = value),
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
