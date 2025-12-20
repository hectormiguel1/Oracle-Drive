import 'dart:io';
import 'package:ff13_mod_resource/components/crystalium/crystalium_visualizer_3d.dart';
import 'package:ff13_mod_resource/components/crystalium/mcp_visualizer.dart';
import 'package:ff13_mod_resource/components/widgets/crystal_button.dart';
import 'package:ff13_mod_resource/components/widgets/crystal_container.dart';
import 'package:ff13_mod_resource/components/widgets/crystal_dialog.dart';
import 'package:ff13_mod_resource/components/widgets/crystal_dropdowns.dart';
import 'package:ff13_mod_resource/components/widgets/crystal_panel.dart';
import 'package:ff13_mod_resource/components/widgets/crystal_text_field.dart';
import 'package:ff13_mod_resource/models/crystalium/cgt_file.dart';
import 'package:ff13_mod_resource/models/crystalium/mcp_file.dart';
import 'package:ff13_mod_resource/src/utils/crystalium/cgt_modifier.dart';
import 'package:ff13_mod_resource/src/utils/crystalium/cgt_parser.dart';
import 'package:ff13_mod_resource/src/utils/crystalium/cgt_writer.dart';
import 'package:ff13_mod_resource/src/utils/crystalium/mcp_parser.dart';
import 'package:ff13_mod_resource/theme/crystal_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

enum CrystaliumViewMode { mcp, cgt }

class CrystaliumScreen extends ConsumerStatefulWidget {
  const CrystaliumScreen({super.key});

  @override
  ConsumerState<CrystaliumScreen> createState() => _CrystaliumScreenState();
}

class _CrystaliumScreenState extends ConsumerState<CrystaliumScreen> {
  CrystaliumViewMode _viewMode = CrystaliumViewMode.mcp;

  // MCP State
  McpFile? _mcpFile;
  McpPattern? _selectedPattern;

  // CGT State
  CgtFile? _cgtFile;
  McpFile? _cgtPatterns;
  CrystariumEntry? _selectedEntry;
  int? _selectedNodeIdx;
  final Map<int, List<int>> _childrenMap = {};
  int _visualizerKey = 0;
  String? _currentFilePath;

  // Modification state
  CgtModifier? _modifier;
  bool _hasUnsavedChanges = false;

  void _resetCamera() {
    setState(() => _visualizerKey++);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result != null && result.files.single.path != null) {
      final filePath = result.files.single.path!;
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final fileName = result.files.single.name.toLowerCase();

      try {
        if (fileName.endsWith('.mcp')) {
          final mcp = McpParser.parse(bytes);
          setState(() {
            _mcpFile = mcp;
            _viewMode = CrystaliumViewMode.mcp;
            if (mcp.patterns.isNotEmpty) {
              _selectedPattern = mcp.patterns.first;
            }
          });
        } else if (fileName.endsWith('.cgt')) {
          final cgt = CgtParser.parse(bytes);

          McpFile? patterns;
          final patternsPath = p.join(p.dirname(filePath), 'patterns.mcp');
          if (await File(patternsPath).exists()) {
            final pBytes = await File(patternsPath).readAsBytes();
            patterns = McpParser.parse(pBytes);
          }

          final childrenMap = <int, List<int>>{};
          for (var i = 0; i < cgt.nodes.length; i++) {
             final pIdx = cgt.nodes[i].parentIndex;
             if (pIdx != -1) {
               childrenMap.putIfAbsent(pIdx, () => []).add(i);
             }
          }

          setState(() {
            _cgtFile = cgt;
            _cgtPatterns = patterns;
            _viewMode = CrystaliumViewMode.cgt;
            _childrenMap.clear();
            _childrenMap.addAll(childrenMap);
            _currentFilePath = filePath;
            _modifier = CgtModifier(cgtFile: cgt, mcpPatterns: patterns);
            _hasUnsavedChanges = false;

            if (cgt.entries.isNotEmpty) {
              _selectedEntry = cgt.entries.first;
              if (cgt.entries.first.nodeIds.isNotEmpty) {
                 final firstNode = cgt.entries.first.nodeIds.firstWhere((id) => id != 0, orElse: () => -1);
                 if (firstNode != -1) {
                    _selectedNodeIdx = firstNode;
                 } else {
                    _selectedNodeIdx = null;
                 }
              } else {
                 _selectedNodeIdx = null;
              }
            }
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Failed to parse file: $e")));
        }
      }
    }
  }

  Future<void> _saveCgtFile() async {
    if (_cgtFile == null) return;

    String? outputPath;

    if (_currentFilePath != null) {
      // Ask if they want to overwrite or save as new
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Save File'),
          content: Text('Overwrite ${p.basename(_currentFilePath!)}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Save As...'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Overwrite'),
            ),
          ],
        ),
      );

      if (result == true) {
        outputPath = _currentFilePath;
      }
    }

    if (outputPath == null) {
      final saveResult = await FilePicker.platform.saveFile(
        dialogTitle: 'Save CGT file',
        fileName: _currentFilePath != null ? p.basename(_currentFilePath!) : 'crystarium.cgt',
        allowedExtensions: ['cgt'],
        type: FileType.custom,
      );

      if (saveResult == null) return;
      outputPath = saveResult;
      if (!outputPath.toLowerCase().endsWith('.cgt')) {
        outputPath = '$outputPath.cgt';
      }
    }

    try {
      final fileToSave = _modifier != null ? _modifier!.build() : _cgtFile!;
      final bytes = CgtWriter.write(fileToSave);
      await File(outputPath).writeAsBytes(bytes);

      setState(() {
        _currentFilePath = outputPath;
        _hasUnsavedChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to ${p.basename(outputPath!)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddOffshootDialog({int? nodeId, int? stage, int? roleId, bool fromWalkMode = false}) {
    final targetNodeId = nodeId ?? _selectedNodeIdx;
    if (_modifier == null || targetNodeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a node first to add an offshoot')),
      );
      return;
    }

    // Get available patterns
    final patternNames = _cgtPatterns?.patterns.map((p) => p.name).toList() ??
        ['test1', 'test2', 'test3', 'test4', 'test5', 'test6', 'test7', 'test8'];

    String selectedPattern = patternNames.isNotEmpty ? patternNames.first : 'test1';
    int selectedStage = stage ?? 1;
    int selectedRole = roleId ?? 0;
    final isFromWalkMode = fromWalkMode;
    final nodeNameController = TextEditingController();

    final theme = Theme.of(context).extension<CrystalTheme>()!;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                            '#$targetNodeId',
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
                    controller: nodeNameController,
                    hintText: 'Leave empty for auto-generated name',
                    prefixIcon: Icons.label_outline,
                  ),
                  const SizedBox(height: 20),

                  // Pattern dropdown
                  CrystalDropdown<String>(
                    label: 'PATTERN',
                    value: selectedPattern,
                    items: patternNames,
                    onChanged: (value) {
                      setDialogState(() => selectedPattern = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Stage and Role in a row
                  Row(
                    children: [
                      Expanded(
                        child: CrystalDropdown<int>(
                          label: 'STAGE',
                          value: selectedStage,
                          items: List.generate(10, (i) => i + 1),
                          itemLabelBuilder: (stage) => 'Stage $stage',
                          onChanged: (value) {
                            setDialogState(() => selectedStage = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CrystalDropdown<int>(
                          label: 'ROLE',
                          value: selectedRole,
                          items: CrystariumRole.values.map((r) => r.id).toList(),
                          itemLabelBuilder: (id) {
                            final role = CrystariumRole.fromId(id);
                            return '${role.abbreviation} - ${role.fullName}';
                          },
                          onChanged: (value) {
                            setDialogState(() => selectedRole = value);
                          },
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
                    final customName = nodeNameController.text.trim();
                    _addOffshoot(
                      selectedPattern,
                      selectedStage,
                      selectedRole,
                      nodeId: targetNodeId,
                      fromWalkMode: isFromWalkMode,
                      customNodeName: customName.isEmpty ? null : customName,
                    );
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addOffshoot(String patternName, int stage, int roleId, {int? nodeId, bool fromWalkMode = false, String? customNodeName}) {
    final targetNodeId = nodeId ?? _selectedNodeIdx;
    if (_modifier == null || targetNodeId == null) return;

    try {
      final newEntry = _modifier!.addOffshoot(
        parentNodeId: targetNodeId,
        patternName: patternName,
        stage: stage,
        roleId: roleId,
        // When from walk mode, attach to exact node, don't auto-redirect to entry's first node
        autoFindBranchPoint: !fromWalkMode,
        customNodeName: customNodeName,
      );

      if (newEntry != null) {
        // Rebuild the CGT file and update state
        final updatedCgt = _modifier!.build();

        // Rebuild children map
        final childrenMap = <int, List<int>>{};
        for (var i = 0; i < updatedCgt.nodes.length; i++) {
          final pIdx = updatedCgt.nodes[i].parentIndex;
          if (pIdx != -1) {
            childrenMap.putIfAbsent(pIdx, () => []).add(i);
          }
        }

        setState(() {
          _cgtFile = updatedCgt;
          _childrenMap.clear();
          _childrenMap.addAll(childrenMap);
          _hasUnsavedChanges = true;

          // Only reset visualizer key if NOT from walk mode
          // When from walk mode, we want to preserve the current position
          if (!fromWalkMode) {
            _visualizerKey++;
            // Select the new entry
            _selectedEntry = newEntry;
            if (newEntry.nodeIds.isNotEmpty) {
              _selectedNodeIdx = newEntry.nodeIds.first;
            }
          }
          // When from walk mode, keep the current selection - the visualizer will update
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added offshoot with ${newEntry.nodeIds.length} nodes at node $targetNodeId'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add offshoot: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditNodeNameDialog({required int nodeId, required String currentName}) {
    if (_modifier == null) return;

    final theme = Theme.of(context).extension<CrystalTheme>()!;
    final nameController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) {
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
                        '#$nodeId',
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
                controller: nameController,
                hintText: 'Enter node name (max 16 chars)',
                prefixIcon: Icons.label_outline,
              ),
              const SizedBox(height: 8),
              Text(
                'Node names are limited to 16 characters',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                ),
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
              onPressed: () {
                final newName = nameController.text.trim();
                _updateNodeName(nodeId, newName);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _updateNodeName(int nodeId, String newName) {
    if (_modifier == null) return;

    final success = _modifier!.updateNodeName(nodeId, newName);
    if (success) {
      // Rebuild the CGT file
      final updatedCgt = _modifier!.build();

      setState(() {
        _cgtFile = updatedCgt;
        _hasUnsavedChanges = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Node #$nodeId renamed to "$newName"'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to rename node #$nodeId'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleNodeNavigation(LogicalKeyboardKey key) {
    if (_cgtFile == null) return;

    if (_selectedNodeIdx == null) {
       if (_cgtFile!.entries.isNotEmpty) {
           final firstNode = _cgtFile!.entries.first.nodeIds.firstWhere((id) => id != 0, orElse: () => -1);
           if (firstNode != -1) {
              setState(() => _selectedNodeIdx = firstNode);
           }
       }
       return;
    }

    final currentIdx = _selectedNodeIdx!;
    if (currentIdx >= _cgtFile!.nodes.length) return;

    final currentNode = _cgtFile!.nodes[currentIdx];

    if (key == LogicalKeyboardKey.arrowUp) {
      if (currentNode.parentIndex > 0) {
        setState(() => _selectedNodeIdx = currentNode.parentIndex);
      }
    } else if (key == LogicalKeyboardKey.arrowDown) {
      if (_childrenMap.containsKey(currentIdx) && _childrenMap[currentIdx]!.isNotEmpty) {
        setState(() => _selectedNodeIdx = _childrenMap[currentIdx]!.first);
      }
    } else if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight) {
      final parentIdx = currentNode.parentIndex;
      if (parentIdx != -1 && _childrenMap.containsKey(parentIdx)) {
        final siblings = _childrenMap[parentIdx]!;
        final myIndex = siblings.indexOf(currentIdx);
        if (myIndex != -1) {
          int newIndex;
          if (key == LogicalKeyboardKey.arrowLeft) {
            newIndex = (myIndex - 1 + siblings.length) % siblings.length;
          } else {
            newIndex = (myIndex + 1) % siblings.length;
          }
          setState(() => _selectedNodeIdx = siblings[newIndex]);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final crystalTheme = Theme.of(context).extension<CrystalTheme>()!;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(crystalTheme),
          const SizedBox(height: 16),
          Expanded(
            child:
                _viewMode == CrystaliumViewMode.mcp
                    ? _buildMcpView(crystalTheme)
                    : _buildCgtView(crystalTheme),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(CrystalTheme theme) {
    return Row(
      children: [
        CrystalButton(
          label: "Load File",
          icon: Icons.file_open,
          onPressed: _pickFile,
        ),
        if (_viewMode == CrystaliumViewMode.cgt && _cgtFile != null) ...[
          const SizedBox(width: 8),
          CrystalButton(
            label: _hasUnsavedChanges ? "Save*" : "Save",
            icon: Icons.save,
            onPressed: _saveCgtFile,
          ),
          const SizedBox(width: 8),
          CrystalButton(
            label: "Add Offshoot",
            icon: Icons.add_circle_outline,
            onPressed: _showAddOffshootDialog,
          ),
        ],
        const SizedBox(width: 16),
        CrystalButton(
          label: "Reset Cam",
          icon: Icons.center_focus_strong,
          onPressed: _resetCamera,
        ),
        const SizedBox(width: 24),
        _buildModeToggle(theme),
        if (_viewMode == CrystaliumViewMode.mcp && _mcpFile != null) ...[
          const SizedBox(width: 24),
          _buildInfo("MCP Patterns", _mcpFile!.patternCount.toString(), theme),
        ],
        if (_viewMode == CrystaliumViewMode.cgt && _cgtFile != null) ...[
          const SizedBox(width: 24),
          _buildInfo("CGT Entries", _cgtFile!.entryCount.toString(), theme),
          const SizedBox(width: 24),
          _buildInfo("CGT Nodes", _cgtFile!.totalNodes.toString(), theme),
          if (_hasUnsavedChanges) ...[
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Modified',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildModeToggle(CrystalTheme theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildModeButton(CrystaliumViewMode.mcp, "MCP", theme),
          _buildModeButton(CrystaliumViewMode.cgt, "CGT", theme),
        ],
      ),
    );
  }

  Widget _buildModeButton(CrystaliumViewMode mode, String label, CrystalTheme theme) {
    final isSelected = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.accent.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? theme.accent : Colors.white54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildInfo(String label, String value, CrystalTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: theme.accent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ],
    );
  }

  Widget _buildMcpView(CrystalTheme theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_mcpFile != null) ...[
          SizedBox(
            width: 280,
            child: CrystalPanel(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel("AVAILABLE PATTERNS", theme),
                  Expanded(
                    child: _buildMcpList(theme),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: CrystalPanel(
            padding: const EdgeInsets.all(8),
            child: _selectedPattern != null
                ? McpVisualizer(pattern: _selectedPattern!)
                : _buildPlaceholder("Select an MCP pattern to visualize", theme),
          ),
        ),
      ],
    );
  }

  Widget _buildMcpList(CrystalTheme theme) {
    return ListView.separated(
      itemCount: _mcpFile!.patterns.length,
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final pattern = _mcpFile!.patterns[index];
        final isSelected = _selectedPattern == pattern;
        return ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          selected: isSelected,
          selectedTileColor: theme.accent.withValues(alpha: 0.1),
          title: Text(
            pattern.name.isEmpty ? "Pattern $index" : pattern.name,
            style: TextStyle(
              color: isSelected ? theme.accent : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          onTap: () => setState(() => _selectedPattern = pattern),
        );
      },
    );
  }

  Widget _buildCgtView(CrystalTheme theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_cgtFile != null) ...[
          SizedBox(
            width: 300,
            child: CrystalPanel(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel("ENTRIES (STAGES)", theme),
                  Expanded(
                    child: _buildEntryList(theme),
                  ),
                  if (_selectedEntry != null) ...[
                    const Divider(color: Colors.white10, height: 24),
                    _buildSectionLabel("NODES IN ENTRY", theme),
                    Expanded(
                      child: _buildNodeList(theme),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: CrystalPanel(
            padding: const EdgeInsets.all(8),
            child: _cgtFile != null
                ? CrystaliumVisualizer3D(
                    key: ValueKey(_visualizerKey),
                    cgtFile: _cgtFile!,
                    mcpPatterns: _cgtPatterns,
                    selectedEntry: _selectedEntry,
                    selectedNodeIdx: _selectedNodeIdx,
                    onNodeNavigation: _handleNodeNavigation,
                    onNodeSelected: (nodeId) {
                      setState(() => _selectedNodeIdx = nodeId);
                    },
                    onAddOffshoot: (nodeId, stage, roleId) {
                      _showAddOffshootDialog(nodeId: nodeId, stage: stage, roleId: roleId, fromWalkMode: true);
                    },
                    onEditNodeName: (nodeId, currentName) {
                      _showEditNodeNameDialog(nodeId: nodeId, currentName: currentName);
                    },
                  )
                : _buildPlaceholder("Load a CGT file to visualize the layout", theme),
          ),
        ),
      ],
    );
  }

  Widget _buildEntryList(CrystalTheme theme) {
    return ListView.builder(
      itemCount: _cgtFile!.entries.length,
      itemBuilder: (context, index) {
        final entry = _cgtFile!.entries[index];
        final isSelected = _selectedEntry == entry;
        final name = entry.patternName.replaceAll(RegExp(r'\x00'), '');
        final role = CrystariumRole.fromId(entry.roleId);

        return ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          selected: isSelected,
          selectedTileColor: theme.accent.withValues(alpha: 0.1),
          leading: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getRoleColor(entry.roleId),
              shape: BoxShape.circle,
            ),
          ),
          title: Text(
            name.isEmpty ? "Entry $index" : "$index: $name",
            style: TextStyle(
              color: isSelected ? theme.accent : Colors.white,
              fontSize: 13,
            ),
          ),
          subtitle: Text(
            "Stage ${entry.stage} | ${role.abbreviation}",
            style: TextStyle(fontSize: 10, color: Colors.white30),
          ),
          onTap: () => setState(() {
            _selectedEntry = entry;
            _selectedNodeIdx = null;
          }),
        );
      },
    );
  }

  Widget _buildNodeList(CrystalTheme theme) {
    return ListView.builder(
      itemCount: _selectedEntry!.nodeIds.length,
      itemBuilder: (context, index) {
        final nodeIdx = _selectedEntry!.nodeIds[index];
        if (nodeIdx == 0) return const SizedBox.shrink();
        if (nodeIdx >= _cgtFile!.nodes.length) return const SizedBox.shrink();

        final node = _cgtFile!.nodes[nodeIdx];
        final isSelected = _selectedNodeIdx == nodeIdx;
        final hasChildren = _childrenMap.containsKey(nodeIdx) &&
            _childrenMap[nodeIdx]!.isNotEmpty;

        return ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          selected: isSelected,
          selectedTileColor: theme.accent.withValues(alpha: 0.1),
          leading: Icon(
            hasChildren ? Icons.account_tree : Icons.circle,
            size: 12,
            color: isSelected ? theme.accent : Colors.white38,
          ),
          title: Text(
            node.name.replaceAll(RegExp(r'\x00'), ''),
            style: TextStyle(
              color: isSelected ? theme.accent : Colors.white70,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          subtitle: Text(
            'ID: $nodeIdx | Parent: ${node.parentIndex}',
            style: TextStyle(fontSize: 9, color: Colors.white24),
          ),
          onTap: () => setState(() => _selectedNodeIdx = nodeIdx),
        );
      },
    );
  }

  Widget _buildSectionLabel(String text, CrystalTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 4.0),
      child: Text(
        text,
        style: TextStyle(
          color: theme.accent.withValues(alpha: 0.7),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String text, CrystalTheme theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_graph, size: 48, color: Colors.white12),
          const SizedBox(height: 16),
          Text(text, style: const TextStyle(color: Colors.white54, fontSize: 16)),
        ],
      ),
    );
  }

  Color _getRoleColor(int roleId) {
    switch (roleId) {
      case 0: return const Color(0xFFFF4444);
      case 1: return const Color(0xFF44FF44);
      case 2: return const Color(0xFF4444FF);
      case 3: return const Color(0xFFFF44FF);
      case 4: return const Color(0xFFFFFF44);
      case 5: return const Color(0xFF44FFFF);
      default: return Colors.white;
    }
  }
}
