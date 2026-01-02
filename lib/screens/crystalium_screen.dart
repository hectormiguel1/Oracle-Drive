import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oracle_drive/components/crystalium/crystalium_dialogs.dart';
import 'package:oracle_drive/components/crystalium/crystalium_header.dart';
import 'package:oracle_drive/components/crystalium/crystalium_sidebar.dart';
import 'package:oracle_drive/components/crystalium/crystalium_visualizer_3d.dart';
import 'package:oracle_drive/components/crystalium/mcp_visualizer.dart';
import 'package:oracle_drive/components/widgets/crystal_panel.dart';
import 'package:oracle_drive/components/widgets/crystal_snackbar.dart';
import 'package:oracle_drive/providers/crystalium_provider.dart';
import 'package:oracle_drive/theme/crystal_theme.dart';
import 'package:path/path.dart' as p;

class CrystaliumScreen extends ConsumerStatefulWidget {
  const CrystaliumScreen({super.key});

  @override
  ConsumerState<CrystaliumScreen> createState() => _CrystaliumScreenState();
}

class _CrystaliumScreenState extends ConsumerState<CrystaliumScreen> {
  // ============================================================
  // UI Callbacks
  // ============================================================

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result != null && result.files.single.path != null) {
      try {
        await ref.read(crystaliumProvider.notifier).loadFile(result.files.single.path!);
      } catch (e) {
        if (mounted) {
          context.showErrorSnackBar("Failed to parse file: $e");
        }
      }
    }
  }

  Future<void> _saveCgtFile() async {
    final state = ref.read(crystaliumProvider);
    if (state.cgtFile == null) return;

    String? outputPath;

    if (state.currentFilePath != null) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Save File'),
          content: Text('Overwrite ${p.basename(state.currentFilePath!)}?'),
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
        outputPath = state.currentFilePath;
      }
    }

    if (outputPath == null) {
      final saveResult = await FilePicker.platform.saveFile(
        dialogTitle: 'Save CGT file',
        fileName: state.currentFilePath != null
            ? p.basename(state.currentFilePath!)
            : 'crystarium.cgt',
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
      await ref.read(crystaliumProvider.notifier).saveCgtFile(outputPath);

      if (mounted) {
        context.showSuccessSnackBar('Saved to ${p.basename(outputPath)}');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to save: $e');
      }
    }
  }

  Future<void> _showAddOffshootDialog({
    int? nodeId,
    int? stage,
    int? roleId,
    bool fromWalkMode = false,
  }) async {
    final state = ref.read(crystaliumProvider);
    final targetNodeId = nodeId ?? state.selectedNodeIdx;

    if (targetNodeId == null) {
      context.showWarningSnackBar('Select a node first to add an offshoot');
      return;
    }

    final params = await AddOffshootDialog.show(
      context,
      targetNodeId: targetNodeId,
      patternNames: state.availablePatternNames,
      initialStage: stage,
      initialRoleId: roleId,
    );

    if (params != null) {
      final newEntry = ref.read(crystaliumProvider.notifier).addOffshoot(
        parentNodeId: targetNodeId,
        patternName: params.patternName,
        stage: params.stage,
        roleId: params.roleId,
        autoFindBranchPoint: !fromWalkMode,
        customNodeName: params.customNodeName,
      );

      if (newEntry != null && mounted) {
        context.showSuccessSnackBar(
          'Added offshoot with ${newEntry.nodeIds.length} nodes at node $targetNodeId',
        );
      }
    }
  }

  Future<void> _showEditNodeNameDialog(int nodeId, String currentName) async {
    final newName = await EditNodeNameDialog.show(
      context,
      nodeId: nodeId,
      currentName: currentName,
    );

    if (newName != null) {
      final success = ref.read(crystaliumProvider.notifier).updateNodeName(nodeId, newName);

      if (mounted) {
        if (success) {
          context.showSuccessSnackBar('Node #$nodeId renamed to "$newName"');
        } else {
          context.showErrorSnackBar('Failed to rename node #$nodeId');
        }
      }
    }
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(crystaliumProvider);
    final theme = Theme.of(context).extension<CrystalTheme>()!;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CrystaliumHeader(
            onLoadFile: _pickFile,
            onSaveFile: _saveCgtFile,
            onAddOffshoot: _showAddOffshootDialog,
            onResetCamera: () => ref.read(crystaliumProvider.notifier).resetCamera(),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: state.viewMode == CrystaliumViewMode.mcp
                ? _buildMcpView(state, theme)
                : _buildCgtView(state, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildMcpView(CrystaliumState state, CrystalTheme theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.mcpFile != null) ...[
          const McpPatternList(),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: CrystalPanel(
            padding: const EdgeInsets.all(8),
            child: state.selectedPattern != null
                ? McpVisualizer(pattern: state.selectedPattern!)
                : _buildPlaceholder("Select an MCP pattern to visualize", theme),
          ),
        ),
      ],
    );
  }

  Widget _buildCgtView(CrystaliumState state, CrystalTheme theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.cgtFile != null) ...[
          const CgtEntrySidebar(),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: CrystalPanel(
            padding: const EdgeInsets.all(8),
            child: state.cgtFile != null
                ? CrystaliumVisualizer3D(
                    key: ValueKey(state.visualizerKey),
                    cgtFile: state.cgtFile!,
                    mcpPatterns: state.cgtPatterns,
                    selectedEntry: state.selectedEntry,
                    selectedNodeIdx: state.selectedNodeIdx,
                    onNodeNavigation: ref.read(crystaliumProvider.notifier).handleNodeNavigation,
                    onNodeSelected: (nodeId) {
                      ref.read(crystaliumProvider.notifier).selectNode(nodeId);
                    },
                    onAddOffshoot: (nodeId, stage, roleId) {
                      _showAddOffshootDialog(
                        nodeId: nodeId,
                        stage: stage,
                        roleId: roleId,
                        fromWalkMode: true,
                      );
                    },
                    onEditNodeName: _showEditNodeNameDialog,
                  )
                : _buildPlaceholder("Load a CGT file to visualize the layout", theme),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(String text, CrystalTheme theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_graph, size: 48, color: Colors.white12),
          const SizedBox(height: 16),
          Text(
            text,
            style: const TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
