import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_game_code.dart';
import '../../models/wdb_model.dart';
import '../../models/workflow/node_status.dart';
import '../../models/workflow/workflow_models.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/wdb_provider.dart';
import '../../providers/workflow_provider.dart';
import '../../src/services/native_service.dart';
import '../../src/workflow/execution/immediate_executor.dart';
import '../widgets/crystal_button.dart';
import '../widgets/crystal_dialog.dart';
import '../widgets/crystal_panel.dart';
import '../widgets/crystal_snackbar.dart';
import '../widgets/crystal_text_field.dart';
import '../widgets/style.dart';
import 'wbt_file_selector.dart';

/// Panel for editing selected node properties.
class PropertyPanel extends ConsumerWidget {
  const PropertyPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(workflowEditorProvider);
    final selectedNode = editorState.selectedNode;

    return CrystalPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.tune, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text('Properties', style: CrystalStyles.sectionHeader),
            ],
          ),
          const SizedBox(height: 12),
          // Content
          Expanded(
            child: selectedNode == null
                ? _buildEmptyState()
                : _NodePropertyEditor(node: selectedNode),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app_outlined, color: Colors.white24, size: 48),
          const SizedBox(height: 12),
          Text(
            'Select a node to edit',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _NodePropertyEditor extends ConsumerStatefulWidget {
  final WorkflowNode node;

  const _NodePropertyEditor({required this.node});

  @override
  ConsumerState<_NodePropertyEditor> createState() => _NodePropertyEditorState();
}

class _NodePropertyEditorState extends ConsumerState<_NodePropertyEditor> {
  late Map<String, TextEditingController> _controllers;
  late TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(covariant _NodePropertyEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node.id != widget.node.id) {
      _disposeControllers();
      _initControllers();
    }
  }

  void _initControllers() {
    _controllers = {};
    // Initialize label controller
    _labelController = TextEditingController(text: widget.node.label ?? '');
    // Initialize config field controllers
    for (final field in widget.node.type.configSchema.fields) {
      final value = widget.node.config[field.key]?.toString() ?? '';
      _controllers[field.key] = TextEditingController(text: value);
    }
  }

  void _disposeControllers() {
    _labelController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schema = widget.node.type.configSchema;
    final nodeColor = widget.node.type.nodeColor;

    return ListView(
      children: [
        // Node header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: nodeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: nodeColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(widget.node.type.icon, color: nodeColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.node.type.displayName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.node.type.category.displayName,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Label field
        _buildLabelField(),
        const SizedBox(height: 8),
        // Action buttons for specific node types
        if (_hasWdbActions()) ...[
          _buildWdbActions(),
          const SizedBox(height: 8),
        ],
        const Divider(color: Colors.white12),
        const SizedBox(height: 8),
        // Config fields
        if (schema.fields.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No configuration required',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          )
        else
          ...schema.fields.map((field) => _buildField(field)),
        // Execute button for immediate nodes
        if (widget.node.type.executionMode == NodeExecutionMode.immediate) ...[
          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),
          _buildImmediateExecuteButton(),
        ],
        // Bulk update preview for wdbBulkUpdate nodes
        if (widget.node.type == NodeType.wdbBulkUpdate) ...[
          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),
          _buildBulkUpdatePreview(),
        ],
      ],
    );
  }

  /// Builds a preview widget showing how many rows will be affected by the bulk update.
  Widget _buildBulkUpdatePreview() {
    // Use ref.read() to avoid unnecessary rebuilds on unrelated state changes
    final editorState = ref.read(workflowEditorProvider);
    final workflow = editorState.workflow;
    final gameCode = ref.read(selectedGameProvider);
    final workspaceDir = ref.read(workflowExecutorProvider).workspaceDir;

    // Find the WDB source path by tracing connections
    String? wdbFilePath;
    if (workflow != null) {
      wdbFilePath = workflow.findWdbSourcePath(widget.node.id);
    }

    if (wdbFilePath == null || wdbFilePath.isEmpty) {
      return _buildPreviewInfo(
        icon: Icons.info_outline,
        color: Colors.grey,
        message: 'Connect to a WDB node to see affected rows',
      );
    }

    // Resolve the path
    String resolvedPath = wdbFilePath;
    if (workspaceDir != null &&
        !resolvedPath.startsWith('/') &&
        !resolvedPath.contains(':\\')) {
      resolvedPath = '$workspaceDir/$resolvedPath';
    }

    // Load WDB data and compute preview
    return FutureBuilder<_BulkUpdatePreviewData>(
      future: _computeBulkUpdatePreview(resolvedPath, gameCode),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildPreviewInfo(
            icon: Icons.sync,
            color: Colors.blue,
            message: 'Loading preview...',
            isLoading: true,
          );
        }

        if (snapshot.hasError) {
          return _buildPreviewInfo(
            icon: Icons.error_outline,
            color: Colors.red,
            message: 'Error: ${snapshot.error}',
          );
        }

        // Bug #55 fix: Add null check for snapshot.data
        final data = snapshot.data;
        if (data == null) {
          return _buildPreviewInfo(
            icon: Icons.warning_amber,
            color: Colors.orange,
            message: 'No preview data available',
          );
        }
        final filter = widget.node.config['filter'] as String?;
        final hasFilter = filter != null && filter.trim().isNotEmpty;

        if (hasFilter) {
          return _buildPreviewInfo(
            icon: data.affectedRows == data.totalRows
                ? Icons.select_all
                : Icons.filter_alt,
            color: Colors.cyan,
            message: '${data.affectedRows} / ${data.totalRows} rows affected',
            subtitle: data.filterError ?? 'Filter: $filter',
            isError: data.filterError != null,
          );
        } else {
          return _buildPreviewInfo(
            icon: Icons.select_all,
            color: Colors.green,
            message: '${data.totalRows} rows affected (all rows)',
            subtitle: 'No filter applied',
          );
        }
      },
    );
  }

  Widget _buildPreviewInfo({
    required IconData icon,
    required Color color,
    required String message,
    String? subtitle,
    bool isLoading = false,
    bool isError = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          if (isLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            )
          else
            Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isError ? Colors.orange[300] : Colors.white54,
                      fontSize: 10,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<_BulkUpdatePreviewData> _computeBulkUpdatePreview(
    String wdbPath,
    AppGameCode gameCode,
  ) async {
    try {
      final wdbData = await NativeService.instance.parseWdb(wdbPath, gameCode);
      final totalRows = wdbData.rows.length;
      final filter = widget.node.config['filter'] as String?;

      if (filter == null || filter.trim().isEmpty) {
        return _BulkUpdatePreviewData(
          totalRows: totalRows,
          affectedRows: totalRows,
        );
      }

      // Try to evaluate the filter expression
      int affectedRows = 0;
      String? filterError;

      try {
        affectedRows = _evaluateFilterCount(wdbData.rows, filter.trim());
      } catch (e) {
        // If filter evaluation fails, show error but still return total
        filterError = 'Cannot evaluate filter: $e';
        affectedRows = totalRows; // Assume all rows if filter can't be evaluated
      }

      return _BulkUpdatePreviewData(
        totalRows: totalRows,
        affectedRows: affectedRows,
        filterError: filterError,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Evaluates a filter expression against WDB rows and returns the count of matching rows.
  /// Supports simple expressions like:
  /// - ${_row.record}.startsWith("mcr_")
  /// - ${_row.record}.contains("k9")
  /// - ${_row.record} == "specific_id"
  int _evaluateFilterCount(List<Map<String, dynamic>> rows, String filter) {
    int count = 0;

    // Parse the filter expression
    // Common patterns:
    // ${_row.record}.startsWith("prefix")
    // ${_row.record}.contains("substr")
    // ${_row.record}.endsWith("suffix")
    // ${_row.column_name} == value

    // Pattern: ${_row.column}.startsWith("value")
    final startsWithPattern = RegExp(r'\$\{_row\.(\w+)\}\.startsWith\(["' "'" r'](.+?)["' "'" r']\)');
    // Pattern: ${_row.column}.contains("value")
    final containsPattern = RegExp(r'\$\{_row\.(\w+)\}\.contains\(["' "'" r'](.+?)["' "'" r']\)');
    // Pattern: ${_row.column}.endsWith("value")
    final endsWithPattern = RegExp(r'\$\{_row\.(\w+)\}\.endsWith\(["' "'" r'](.+?)["' "'" r']\)');
    // Pattern: ${_row.column} == "value"
    final equalsPattern = RegExp(r'\$\{_row\.(\w+)\}\s*==\s*["' "'" r'](.+?)["' "'" r']');
    // Pattern: ${_row.column} != "value"
    final notEqualsPattern = RegExp(r'\$\{_row\.(\w+)\}\s*!=\s*["' "'" r'](.+?)["' "'" r']');

    final startsWithMatch = startsWithPattern.firstMatch(filter);
    final containsMatch = containsPattern.firstMatch(filter);
    final endsWithMatch = endsWithPattern.firstMatch(filter);
    final equalsMatch = equalsPattern.firstMatch(filter);
    final notEqualsMatch = notEqualsPattern.firstMatch(filter);

    for (final row in rows) {
      bool matches = false;

      if (startsWithMatch != null) {
        final column = startsWithMatch.group(1)!;
        final prefix = startsWithMatch.group(2)!;
        final value = row[column]?.toString() ?? '';
        matches = value.startsWith(prefix);
      } else if (containsMatch != null) {
        final column = containsMatch.group(1)!;
        final substr = containsMatch.group(2)!;
        final value = row[column]?.toString() ?? '';
        matches = value.contains(substr);
      } else if (endsWithMatch != null) {
        final column = endsWithMatch.group(1)!;
        final suffix = endsWithMatch.group(2)!;
        final value = row[column]?.toString() ?? '';
        matches = value.endsWith(suffix);
      } else if (equalsMatch != null) {
        final column = equalsMatch.group(1)!;
        final expected = equalsMatch.group(2)!;
        final value = row[column]?.toString() ?? '';
        matches = value == expected;
      } else if (notEqualsMatch != null) {
        final column = notEqualsMatch.group(1)!;
        final expected = notEqualsMatch.group(2)!;
        final value = row[column]?.toString() ?? '';
        matches = value != expected;
      } else {
        // Unsupported filter expression
        throw Exception('Unsupported filter syntax');
      }

      if (matches) count++;
    }

    return count;
  }

  Widget _buildImmediateExecuteButton() {
    final isValid = _isConfigValid();
    final editorState = ref.watch(workflowEditorProvider);
    final status = editorState.immediateNodeStatuses[widget.node.id] ??
        NodeExecutionStatus.pending;
    final isExecuting = status == NodeExecutionStatus.executing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CrystalButton(
          label: isExecuting ? 'Executing...' : 'Load Files',
          icon: isExecuting ? Icons.sync : Icons.play_arrow,
          isPrimary: true,
          onPressed: isValid && !isExecuting ? _executeImmediateNode : null,
        ),
        if (!isValid) ...[
          const SizedBox(height: 8),
          Text(
            'Fill in all required fields to enable',
            style: TextStyle(color: Colors.orange[300], fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
        if (status == NodeExecutionStatus.success) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 6),
              Text(
                'Files loaded successfully',
                style: TextStyle(color: Colors.green[300], fontSize: 11),
              ),
            ],
          ),
        ],
        if (status == NodeExecutionStatus.failure) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  editorState.immediateNodeErrors[widget.node.id] ?? 'Failed',
                  style: TextStyle(color: Colors.red[300], fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildLabelField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Label',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        _buildTextField(
          value: widget.node.label ?? '',
          placeholder: widget.node.type.displayName,
          controller: _labelController,
          onChanged: (value) {
            ref.read(workflowEditorProvider.notifier).updateNodeLabel(
                  widget.node.id,
                  value.isEmpty ? null : value,
                );
          },
        ),
      ],
    );
  }

  /// Check if the current node type has WDB actions available.
  bool _hasWdbActions() {
    final nodeType = widget.node.type;
    return nodeType == NodeType.wdbOpen ||
        nodeType == NodeType.wdbSave ||
        nodeType == NodeType.wdbTransform;
  }

  /// Build action buttons for WDB nodes.
  Widget _buildWdbActions() {
    return CrystalButton(
      label: 'Open in Database',
      icon: Icons.storage,
      onPressed: _openWdbInDatabase,
    );
  }

  /// Open the WDB file in the Database screen.
  Future<void> _openWdbInDatabase() async {
    // Get the file path from node config based on node type
    String? filePath;
    if (widget.node.type == NodeType.wdbOpen) {
      filePath = widget.node.config['filePath'] as String?;
    } else if (widget.node.type == NodeType.wdbSave) {
      filePath = widget.node.config['outputPath'] as String?;
    } else if (widget.node.type == NodeType.wdbTransform) {
      filePath = widget.node.config['filePath'] as String?;
    }

    if (filePath == null || filePath.isEmpty) {
      if (mounted) {
        context.showErrorSnackBar('No file path configured');
      }
      return;
    }

    // Resolve relative path if needed
    final workspaceDir = ref.read(workflowExecutorProvider).workspaceDir;
    String resolvedPath = filePath;
    if (workspaceDir != null && !filePath.startsWith('/')) {
      resolvedPath = '$workspaceDir/$filePath';
    }

    final gameCode = ref.read(selectedGameProvider);

    try {
      // Load the WDB
      ref.read(wdbPathProvider(gameCode).notifier).state = resolvedPath;
      ref.read(wdbIsProcessingProvider(gameCode).notifier).state = true;
      ref.read(wdbDataProvider(gameCode).notifier).state = null;
      ref.read(wdbFilterProvider(gameCode).notifier).state = '';

      final data = await NativeService.instance.parseWdb(resolvedPath, gameCode);
      ref.read(wdbDataProvider(gameCode).notifier).state = data;
      ref.read(wdbIsProcessingProvider(gameCode).notifier).state = false;

      // Navigate to Database screen (index 2)
      ref.read(navigationIndexProvider.notifier).state = 2;

      if (mounted) {
        context.showSuccessSnackBar('Opened ${data.sheetName} (${data.rows.length} records)');
      }
    } catch (e) {
      ref.read(wdbIsProcessingProvider(gameCode).notifier).state = false;
      if (mounted) {
        context.showErrorSnackBar('Failed to open WDB: $e');
      }
    }
  }

  Widget _buildField(ConfigField field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  field.label,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (field.required)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    'Required',
                    style: TextStyle(
                      color: Colors.red.shade300,
                      fontSize: 9,
                    ),
                  ),
                ),
            ],
          ),
          if (field.helpText != null) ...[
            const SizedBox(height: 2),
            Text(
              field.helpText!,
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
              ),
            ),
          ],
          const SizedBox(height: 4),
          _buildFieldInput(field),
        ],
      ),
    );
  }

  Widget _buildFieldInput(ConfigField field) {
    switch (field.type) {
      case ConfigFieldType.text:
      case ConfigFieldType.expression:
      case ConfigFieldType.variable:
      case ConfigFieldType.record:
        return _buildTextField(
          value: widget.node.config[field.key]?.toString() ?? '',
          placeholder: field.placeholder ?? '',
          controller: _controllers[field.key],
          onChanged: (value) => _updateConfig(field.key, value),
          isExpression: field.type == ConfigFieldType.expression,
        );

      case ConfigFieldType.column:
        return _buildColumnField(
          value: widget.node.config[field.key]?.toString() ?? '',
          onChanged: (value) => _updateConfig(field.key, value),
        );

      case ConfigFieldType.number:
        return _buildTextField(
          value: widget.node.config[field.key]?.toString() ?? '',
          placeholder: field.placeholder ?? '0',
          controller: _controllers[field.key],
          onChanged: (value) {
            final numValue = num.tryParse(value);
            _updateConfig(field.key, numValue ?? 0);
          },
          keyboardType: TextInputType.number,
        );

      case ConfigFieldType.boolean:
        final value = widget.node.config[field.key] ?? false;
        return _buildCheckbox(
          value: value is bool ? value : false,
          onChanged: (v) => _updateConfig(field.key, v),
        );

      case ConfigFieldType.dropdown:
        return _buildDropdown(
          value: widget.node.config[field.key]?.toString() ?? '',
          options: field.options ?? [],
          onChanged: (v) => _updateConfig(field.key, v),
        );

      case ConfigFieldType.filePath:
        return _buildFilePathField(
          value: widget.node.config[field.key]?.toString() ?? '',
          controller: _controllers[field.key],
          onChanged: (v) => _updateConfig(field.key, v),
        );

      case ConfigFieldType.directoryPath:
        return _buildDirectoryPathField(
          value: widget.node.config[field.key]?.toString() ?? '',
          controller: _controllers[field.key],
          onChanged: (v) => _updateConfig(field.key, v),
        );

      case ConfigFieldType.nodeReference:
        return _buildNodeReferenceField(
          value: widget.node.config[field.key]?.toString() ?? '',
          onChanged: (v) => _updateConfig(field.key, v),
          nodeType: NodeType.wbtLoadFileList, // Filter to WBT load nodes
        );

      case ConfigFieldType.wbtFileSelection:
        return _buildWbtFileSelectionField(
          selectedIndices: (widget.node.config[field.key] as List<dynamic>?)
                  ?.cast<int>()
                  .toList() ??
              [],
          onChanged: (indices) => _updateConfig(field.key, indices),
        );

      case ConfigFieldType.operationsList:
        return _buildOperationsListField(
          operations: widget.node.config[field.key] as List<dynamic>? ?? [],
          onChanged: (ops) => _updateConfig(field.key, ops),
        );
    }
  }

  Widget _buildTextField({
    required String value,
    String placeholder = '',
    TextEditingController? controller,
    required ValueChanged<String> onChanged,
    bool isExpression = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isExpression
              ? Colors.purple.withValues(alpha: 0.3)
              : Colors.white12,
        ),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontFamily: isExpression ? 'monospace' : null,
        ),
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          prefixIcon: isExpression
              ? Icon(Icons.code, color: Colors.purple.shade300, size: 16)
              : null,
          prefixIconConstraints: const BoxConstraints(minWidth: 32),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildCheckbox({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: value
                  ? Colors.cyan.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: value ? Colors.cyan : Colors.white24,
              ),
            ),
            child: value
                ? const Icon(Icons.check, color: Colors.cyan, size: 14)
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            value ? 'Enabled' : 'Disabled',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<DropdownOption> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value.isEmpty ? null : value,
          isExpanded: true,
          dropdownColor: CrystalColors.panelBackground,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          icon: Icon(Icons.arrow_drop_down, color: Colors.cyan.withValues(alpha: 0.7)),
          hint: const Text(
            'Select...',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          items: options
              .map((opt) => DropdownMenuItem(
                    value: opt.value,
                    child: Text(opt.label),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildFilePathField({
    required String value,
    TextEditingController? controller,
    required ValueChanged<String> onChanged,
  }) {
    // Get workspace directory for initial path
    final workspaceDir = ref.read(workflowExecutorProvider).workspaceDir;

    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            value: value,
            placeholder: workspaceDir != null
                ? 'Relative to workspace...'
                : 'Select a file...',
            controller: controller,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () async {
            final result = await FilePicker.platform.pickFiles(
              initialDirectory: workspaceDir,
            );
            if (result != null && result.files.isNotEmpty) {
              var path = result.files.single.path ?? '';
              // If workspace is set and path is within it, make it relative
              if (workspaceDir != null && path.startsWith(workspaceDir)) {
                path = path.substring(workspaceDir.length);
                if (path.startsWith('/') || path.startsWith('\\')) {
                  path = path.substring(1);
                }
              }
              // Update the controller text directly
              controller?.text = path;
              onChanged(path);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.folder_open, color: Colors.white70, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildDirectoryPathField({
    required String value,
    TextEditingController? controller,
    required ValueChanged<String> onChanged,
  }) {
    final workspaceDir = ref.read(workflowExecutorProvider).workspaceDir;

    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            value: value,
            placeholder: workspaceDir != null
                ? 'Relative to workspace...'
                : 'Select a directory...',
            controller: controller,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () async {
            final result = await FilePicker.platform.getDirectoryPath(
              initialDirectory: workspaceDir,
            );
            if (result != null) {
              var path = result;
              // If workspace is set and path is within it, make it relative
              if (workspaceDir != null && path.startsWith(workspaceDir)) {
                path = path.substring(workspaceDir.length);
                if (path.startsWith('/') || path.startsWith('\\')) {
                  path = path.substring(1);
                }
              }
              controller?.text = path;
              onChanged(path);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.folder, color: Colors.white70, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildNodeReferenceField({
    required String value,
    required ValueChanged<String?> onChanged,
    required NodeType nodeType,
  }) {
    // Use ref.read() to avoid unnecessary rebuilds when unrelated state changes
    // (like node position updates). We only need the workflow to find available nodes.
    final editorState = ref.read(workflowEditorProvider);
    final workflow = editorState.workflow;

    // Get all nodes of the specified type
    final availableNodes = workflow?.nodes
            .where((n) => n.type == nodeType && n.id != widget.node.id)
            .toList() ??
        [];

    if (availableNodes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Add a "${nodeType.displayName}" node first',
                style: TextStyle(color: Colors.orange[300], fontSize: 11),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: availableNodes.any((n) => n.id == value) ? value : null,
          isExpanded: true,
          dropdownColor: CrystalColors.panelBackground,
          icon: Icon(Icons.arrow_drop_down,
              color: Colors.purple.withValues(alpha: 0.7)),
          style: const TextStyle(color: Colors.white, fontSize: 12),
          hint: const Text(
            'Select source node...',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          items: availableNodes.map((node) {
            return DropdownMenuItem(
              value: node.id,
              child: Row(
                children: [
                  Icon(node.type.icon, color: node.type.nodeColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      node.label ?? node.type.displayName,
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildWbtFileSelectionField({
    required List<int> selectedIndices,
    required ValueChanged<List<int>> onChanged,
  }) {
    // Get the source node ID from config
    final sourceNodeId = widget.node.config['sourceNode'] as String?;
    final gameCode = ref.watch(selectedGameProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WbtFileSelector(
          nodeId: widget.node.id,
          sourceNodeId: sourceNodeId,
          selectedIndices: selectedIndices,
          onSelectionChanged: onChanged,
          gameCode: gameCode,
        ),
        const SizedBox(height: 8),
        // Extract button
        CrystalButton(
          label: 'Extract Selected',
          icon: Icons.file_download,
          onPressed: selectedIndices.isEmpty
              ? null
              : () => _executeWbtExtraction(),
        ),
      ],
    );
  }

  Future<void> _executeWbtExtraction() async {
    final gameCode = ref.read(selectedGameProvider);
    final executor = ImmediateNodeExecutor(ref);

    try {
      await executor.executeNode(widget.node, gameCode);
      if (mounted) {
        context.showSuccessSnackBar('Extraction completed');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Extraction failed: $e');
      }
    }
  }

  Widget _buildColumnField({
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    // Find the WDB source by tracing connections
    // Use ref.read() instead of ref.watch() to avoid unnecessary rebuilds
    // when unrelated state changes (like node position updates)
    final editorState = ref.read(workflowEditorProvider);
    final workflow = editorState.workflow;

    String? wdbFilePath;
    if (workflow != null) {
      // First check if this node has its own filePath (like wdbTransform)
      wdbFilePath = widget.node.config['filePath'] as String?;

      // If not, trace connections to find the WDB source
      if (wdbFilePath == null || wdbFilePath.isEmpty) {
        wdbFilePath = workflow.findWdbSourcePath(widget.node.id);
      }
    }

    // Fetch WDB metadata
    final gameCode = ref.watch(selectedGameProvider);
    final workspaceDir = ref.watch(workflowExecutorProvider).workspaceDir;

    final metadataRequest = WdbMetadataRequest(
      filePath: wdbFilePath,
      workspaceDir: workspaceDir,
      gameCode: gameCode,
    );
    final columnsAsync = ref.watch(wdbMetadataProvider(metadataRequest));

    return columnsAsync.when(
      data: (columns) {
        if (columns == null || columns.isEmpty) {
          // No columns - show text field with hint
          return _buildTextField(
            value: value,
            placeholder: wdbFilePath == null
                ? 'Connect to WDB node first...'
                : 'Enter column name...',
            onChanged: onChanged,
          );
        }

        // Show column dropdown
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: columns.any((c) => c.originalName == value) ? value : null,
              isExpanded: true,
              dropdownColor: CrystalColors.panelBackground,
              icon: Icon(Icons.arrow_drop_down, color: Colors.cyan.withValues(alpha: 0.7)),
              style: const TextStyle(color: Colors.white, fontSize: 12),
              hint: const Text(
                'Select column...',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              items: columns.map((col) {
                return DropdownMenuItem(
                  value: col.originalName,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          col.displayName,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getColumnTypeColor(col.type).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          col.type.name,
                          style: TextStyle(
                            color: _getColumnTypeColor(col.type),
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) onChanged(newValue);
              },
            ),
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.cyan.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.cyan.withValues(alpha: 0.7)),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Loading columns...',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
      error: (e, s) => _buildTextField(
        value: value,
        placeholder: 'Enter column name...',
        onChanged: onChanged,
      ),
    );
  }

  Color _getColumnTypeColor(WdbColumnType type) {
    switch (type) {
      case WdbColumnType.int:
        return Colors.blue;
      case WdbColumnType.float:
        return Colors.purple;
      case WdbColumnType.string:
        return Colors.green;
      case WdbColumnType.bool:
        return Colors.orange;
      case WdbColumnType.array:
        return Colors.pink;
      case WdbColumnType.crystalRole:
      case WdbColumnType.crystalNodeType:
        return Colors.cyan;
      case WdbColumnType.unknown:
        return Colors.grey;
    }
  }

  Widget _buildOperationsListField({
    required List<dynamic> operations,
    required ValueChanged<List<dynamic>> onChanged,
  }) {
    final ops = operations
        .map((o) => WdbOperation.fromJson(o as Map<String, dynamic>))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Operations list
        Container(
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white12),
          ),
          child: ops.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No operations yet.\nClick + to add one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ),
                )
              : ReorderableListView.builder(
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  itemCount: ops.length,
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex--;
                    final item = ops.removeAt(oldIndex);
                    ops.insert(newIndex, item);
                    onChanged(ops.map((o) => o.toJson()).toList());
                  },
                  itemBuilder: (context, index) {
                    final op = ops[index];
                    return _OperationTile(
                      key: ValueKey('op_$index'),
                      operation: op,
                      index: index,
                      onEdit: () => _showOperationDialog(
                        context,
                        op,
                        (edited) {
                          ops[index] = edited;
                          onChanged(ops.map((o) => o.toJson()).toList());
                        },
                      ),
                      onDelete: () {
                        ops.removeAt(index);
                        onChanged(ops.map((o) => o.toJson()).toList());
                      },
                    );
                  },
                ),
        ),
        const SizedBox(height: 8),
        // Add button
        CrystalButton(
          label: 'Add Operation',
          icon: Icons.add,
          onPressed: () => _showAddOperationDialog(context, (op) {
            ops.add(op);
            onChanged(ops.map((o) => o.toJson()).toList());
          }),
        ),
      ],
    );
  }

  void _showAddOperationDialog(BuildContext context, ValueChanged<WdbOperation> onAdd) {
    final filePath = widget.node.config['filePath'] as String?;
    showDialog(
      context: context,
      builder: (context) => _AddOperationDialog(
        onAdd: onAdd,
        wdbFilePath: filePath,
      ),
    );
  }

  void _showOperationDialog(
    BuildContext context,
    WdbOperation operation,
    ValueChanged<WdbOperation> onSave,
  ) {
    final filePath = widget.node.config['filePath'] as String?;
    showDialog(
      context: context,
      builder: (context) => _EditOperationDialog(
        operation: operation,
        onSave: onSave,
        wdbFilePath: filePath,
      ),
    );
  }

  void _updateConfig(String key, dynamic value) {
    final newConfig = Map<String, dynamic>.from(widget.node.config);
    newConfig[key] = value;
    ref.read(workflowEditorProvider.notifier).updateNodeConfig(
          widget.node.id,
          newConfig,
        );
  }

  /// Execute this immediate node manually.
  Future<void> _executeImmediateNode() async {
    final executor = ImmediateNodeExecutor(ref);
    final gameCode = ref.read(selectedGameProvider);

    try {
      await executor.executeNode(widget.node, gameCode);
      if (mounted) {
        context.showSuccessSnackBar('Executed successfully');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Execution failed: $e');
      }
    }
  }

  /// Check if node config is valid for execution.
  bool _isConfigValid() {
    final schema = widget.node.type.configSchema;
    final errors = schema.validate(widget.node.config);
    return errors.isEmpty;
  }
}

/// Tile for displaying a single operation.
class _OperationTile extends StatelessWidget {
  final WdbOperation operation;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _OperationTile({
    super.key,
    required this.operation,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.drag_handle, color: Colors.white24, size: 16),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onEdit,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      operation.type.displayName,
                      style: TextStyle(
                        color: Colors.cyan,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      operation.toString(),
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 16),
            onPressed: onDelete,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

/// Dialog for adding a new operation.
class _AddOperationDialog extends StatefulWidget {
  final ValueChanged<WdbOperation> onAdd;
  final String? wdbFilePath;

  const _AddOperationDialog({
    required this.onAdd,
    this.wdbFilePath,
  });

  @override
  State<_AddOperationDialog> createState() => _AddOperationDialogState();
}

class _AddOperationDialogState extends State<_AddOperationDialog> {
  WdbOperationType _selectedType = WdbOperationType.copy;

  @override
  Widget build(BuildContext context) {
    return CrystalDialog(
      title: 'Add Operation',
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: WdbOperationType.values.map((type) {
            final isSelected = type == _selectedType;
            return InkWell(
              onTap: () => setState(() => _selectedType = type),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.cyan.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected ? Colors.cyan : Colors.white12,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.displayName,
                      style: TextStyle(
                        color: isSelected ? Colors.cyan : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      type.description,
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        CrystalButton(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        CrystalButton(
          label: 'Next',
          isPrimary: true,
          onPressed: () {
            final op = WdbOperation(type: _selectedType, params: {});
            Navigator.pop(context);
            // Show edit dialog to fill in params
            showDialog(
              context: context,
              builder: (ctx) => _EditOperationDialog(
                operation: op,
                onSave: widget.onAdd,
                wdbFilePath: widget.wdbFilePath,
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Dialog for editing an operation's parameters.
class _EditOperationDialog extends ConsumerStatefulWidget {
  final WdbOperation operation;
  final ValueChanged<WdbOperation> onSave;
  final String? wdbFilePath;

  const _EditOperationDialog({
    required this.operation,
    required this.onSave,
    this.wdbFilePath,
  });

  @override
  ConsumerState<_EditOperationDialog> createState() => _EditOperationDialogState();
}

class _EditOperationDialogState extends ConsumerState<_EditOperationDialog> {
  late Map<String, TextEditingController> _controllers;
  String? _selectedColumn;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    for (final key in _getParamKeys()) {
      _controllers[key] = TextEditingController(
        text: widget.operation.params[key]?.toString() ?? '',
      );
    }
    _selectedColumn = widget.operation.params['column'] as String?;
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _getParamKeys() {
    switch (widget.operation.type) {
      case WdbOperationType.copy:
        return ['sourceRecordId'];
      case WdbOperationType.paste:
        return ['afterRecordId', 'newRecordId'];
      case WdbOperationType.rename:
        return ['recordId', 'newRecordId'];
      case WdbOperationType.setField:
        return ['recordId', 'column', 'value'];
      case WdbOperationType.delete:
        return ['recordId'];
    }
  }

  String _getLabelForKey(String key) {
    switch (key) {
      case 'sourceRecordId':
        return 'Source Record ID';
      case 'afterRecordId':
        return 'Insert After Record ID';
      case 'newRecordId':
        return 'New Record ID';
      case 'recordId':
        return 'Record ID';
      case 'column':
        return 'Column Name';
      case 'value':
        return 'Value';
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fetch WDB metadata for column dropdown
    final gameCode = ref.watch(selectedGameProvider);
    final workspaceDir = ref.watch(workflowExecutorProvider).workspaceDir;

    final metadataRequest = WdbMetadataRequest(
      filePath: widget.wdbFilePath,
      workspaceDir: workspaceDir,
      gameCode: gameCode,
    );
    final columnsAsync = ref.watch(wdbMetadataProvider(metadataRequest));

    return CrystalDialog(
      title: widget.operation.type.displayName,
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _getParamKeys().map((key) {
            // Use dropdown for column field in setField operation
            if (key == 'column' && widget.operation.type == WdbOperationType.setField) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getLabelForKey(key),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildColumnDropdown(columnsAsync),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getLabelForKey(key),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  CrystalTextField(
                    controller: _controllers[key],
                    hintText: _getLabelForKey(key),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        CrystalButton(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        CrystalButton(
          label: 'Save',
          isPrimary: true,
          onPressed: () {
            final params = <String, dynamic>{};
            for (final key in _getParamKeys()) {
              if (key == 'column' && widget.operation.type == WdbOperationType.setField) {
                if (_selectedColumn != null && _selectedColumn!.isNotEmpty) {
                  params[key] = _selectedColumn;
                }
              } else {
                final value = _controllers[key]?.text ?? '';
                if (value.isNotEmpty) {
                  // Try to parse as number
                  final numVal = num.tryParse(value);
                  params[key] = numVal ?? value;
                }
              }
            }
            widget.onSave(widget.operation.copyWith(params: params));
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Widget _buildColumnDropdown(AsyncValue<List<WdbColumn>?> columnsAsync) {
    return columnsAsync.when(
      data: (columns) {
        if (columns == null || columns.isEmpty) {
          // Fallback to text field if no columns available
          return CrystalTextField(
            controller: _controllers['column'],
            hintText: 'Enter column name (no metadata available)',
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedColumn,
              isExpanded: true,
              dropdownColor: CrystalColors.panelBackground,
              icon: Icon(Icons.arrow_drop_down, color: Colors.cyan.withValues(alpha: 0.7)),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              hint: const Text(
                'Select column...',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
              items: columns.map((col) {
                return DropdownMenuItem(
                  value: col.originalName,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          col.displayName,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getTypeColor(col.type).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          col.type.name,
                          style: TextStyle(
                            color: _getTypeColor(col.type),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedColumn = value);
              },
            ),
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.cyan.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.cyan.withValues(alpha: 0.7)),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Loading columns...',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
      error: (e, s) => CrystalTextField(
        controller: _controllers['column'],
        hintText: 'Enter column name (failed to load)',
      ),
    );
  }

  Color _getTypeColor(WdbColumnType type) {
    switch (type) {
      case WdbColumnType.int:
        return Colors.blue;
      case WdbColumnType.float:
        return Colors.purple;
      case WdbColumnType.string:
        return Colors.green;
      case WdbColumnType.bool:
        return Colors.orange;
      case WdbColumnType.array:
        return Colors.pink;
      case WdbColumnType.crystalRole:
      case WdbColumnType.crystalNodeType:
        return Colors.cyan;
      case WdbColumnType.unknown:
        return Colors.grey;
    }
  }
}

/// Data class for bulk update preview information.
class _BulkUpdatePreviewData {
  final int totalRows;
  final int affectedRows;
  final String? filterError;

  _BulkUpdatePreviewData({
    required this.totalRows,
    required this.affectedRows,
    this.filterError,
  });
}
