import 'node_type.dart';

/// Types of configuration fields.
enum ConfigFieldType {
  text('Text'),
  number('Number'),
  boolean('Boolean'),
  dropdown('Dropdown'),
  filePath('File Path'),
  directoryPath('Directory Path'),
  expression('Expression'),
  column('Column'),
  variable('Variable'),
  record('Record'),
  operationsList('Operations List'),
  nodeReference('Node Reference'),
  wbtFileSelection('WBT File Selection');

  final String displayName;
  const ConfigFieldType(this.displayName);
}

/// Types of WDB operations for transform nodes.
enum WdbOperationType {
  copy('Copy Record', 'Copy a record to clipboard'),
  paste('Paste Record', 'Paste clipboard after a record'),
  rename('Rename Record', 'Rename a record ID'),
  setField('Set Field', 'Set a field value on a record'),
  delete('Delete Record', 'Delete a record');

  final String displayName;
  final String description;
  const WdbOperationType(this.displayName, this.description);
}

/// A single WDB operation in a transform node.
class WdbOperation {
  final WdbOperationType type;
  final Map<String, dynamic> params;

  const WdbOperation({required this.type, required this.params});

  factory WdbOperation.fromJson(Map<String, dynamic> json) {
    return WdbOperation(
      type: WdbOperationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => WdbOperationType.copy,
      ),
      params: Map<String, dynamic>.from(json['params'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'params': params,
      };

  WdbOperation copyWith({WdbOperationType? type, Map<String, dynamic>? params}) {
    return WdbOperation(
      type: type ?? this.type,
      params: params ?? Map.from(this.params),
    );
  }

  @override
  String toString() {
    switch (type) {
      case WdbOperationType.copy:
        return 'Copy "${params['sourceRecordId'] ?? '?'}"';
      case WdbOperationType.paste:
        final after = params['afterRecordId'];
        final newId = params['newRecordId'];
        return 'Paste${newId != null ? ' as "$newId"' : ''}${after != null ? ' after "$after"' : ''}';
      case WdbOperationType.rename:
        return 'Rename "${params['recordId'] ?? '?'}" → "${params['newRecordId'] ?? '?'}"';
      case WdbOperationType.setField:
        return 'Set ${params['recordId'] ?? '?'}.${params['column'] ?? '?'} = ${params['value'] ?? '?'}';
      case WdbOperationType.delete:
        return 'Delete "${params['recordId'] ?? '?'}"';
    }
  }
}

/// A field in a node's configuration schema.
class ConfigField {
  final String key;
  final String label;
  final ConfigFieldType type;
  final bool required;
  final dynamic defaultValue;
  final List<DropdownOption>? options;
  final String? placeholder;
  final String? helpText;

  const ConfigField({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.defaultValue,
    this.options,
    this.placeholder,
    this.helpText,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'type': type.name,
        'required': required,
        if (defaultValue != null) 'defaultValue': defaultValue,
        if (options != null) 'options': options!.map((o) => o.toJson()).toList(),
        if (placeholder != null) 'placeholder': placeholder,
        if (helpText != null) 'helpText': helpText,
      };
}

/// An option for dropdown fields.
class DropdownOption {
  final String value;
  final String label;

  const DropdownOption(this.value, this.label);

  Map<String, dynamic> toJson() => {'value': value, 'label': label};
}

/// Schema defining the configuration fields for a node type.
class NodeConfigSchema {
  final List<ConfigField> fields;

  const NodeConfigSchema(this.fields);

  /// Get default configuration values.
  Map<String, dynamic> get defaultConfig {
    final config = <String, dynamic>{};
    for (final field in fields) {
      if (field.defaultValue != null) {
        config[field.key] = field.defaultValue;
      }
    }
    return config;
  }

  /// Validate a configuration against this schema.
  List<String> validate(Map<String, dynamic> config) {
    final errors = <String>[];
    for (final field in fields) {
      if (field.required) {
        final value = config[field.key];
        if (value == null) {
          errors.add('${field.label} is required');
        } else if (value is String && value.isEmpty) {
          errors.add('${field.label} is required');
        } else if (value is List && value.isEmpty) {
          errors.add('${field.label} is required');
        }
      }
    }
    return errors;
  }
}

/// Registry of configuration schemas for each node type.
class NodeConfigRegistry {
  static NodeConfigSchema getSchema(NodeType type) => switch (type) {
        // Control Flow
        NodeType.start => const NodeConfigSchema([]),
        NodeType.end => const NodeConfigSchema([]),
        NodeType.condition => const NodeConfigSchema([
            ConfigField(
              key: 'expression',
              label: 'Condition',
              type: ConfigFieldType.expression,
              required: true,
              placeholder: 'e.g., \${recordCount} > 0',
              helpText: 'Expression that evaluates to true or false',
            ),
          ]),
        NodeType.loop => const NodeConfigSchema([
            ConfigField(
              key: 'count',
              label: 'Iterations',
              type: ConfigFieldType.expression,
              required: true,
              defaultValue: '10',
              helpText: 'Number of times to loop',
            ),
            ConfigField(
              key: 'indexVariable',
              label: 'Index Variable',
              type: ConfigFieldType.text,
              defaultValue: 'i',
              helpText: 'Variable name for loop index',
            ),
          ]),
        NodeType.forEach => const NodeConfigSchema([
            ConfigField(
              key: 'collection',
              label: 'Collection',
              type: ConfigFieldType.expression,
              required: true,
              placeholder: 'e.g., \${wdb.rows}',
              helpText: 'Collection to iterate over',
            ),
            ConfigField(
              key: 'itemVariable',
              label: 'Item Variable',
              type: ConfigFieldType.text,
              defaultValue: 'item',
              helpText: 'Variable name for current item',
            ),
            ConfigField(
              key: 'indexVariable',
              label: 'Index Variable',
              type: ConfigFieldType.text,
              defaultValue: 'index',
              helpText: 'Variable name for current index',
            ),
          ]),
        NodeType.fork => const NodeConfigSchema([
            ConfigField(
              key: 'label',
              label: 'Label',
              type: ConfigFieldType.text,
              helpText: 'Optional label for this fork point',
            ),
          ]),
        NodeType.join => const NodeConfigSchema([
            ConfigField(
              key: 'label',
              label: 'Label',
              type: ConfigFieldType.text,
              helpText: 'Optional label for this join point',
            ),
          ]),

        // WPD Operations
        NodeType.wpdUnpack => const NodeConfigSchema([
            ConfigField(
              key: 'inputFile',
              label: 'WPD File',
              type: ConfigFieldType.filePath,
              required: true,
              helpText: 'Path to the WPD archive to unpack',
            ),
            ConfigField(
              key: 'outputDir',
              label: 'Output Directory',
              type: ConfigFieldType.filePath,
              helpText: 'Directory to extract files (default: same as WPD file)',
            ),
            ConfigField(
              key: 'storeAs',
              label: 'Store Output Dir As',
              type: ConfigFieldType.text,
              defaultValue: 'extractedDir',
              helpText: 'Variable to store the output directory path',
            ),
          ]),
        NodeType.wpdRepack => const NodeConfigSchema([
            ConfigField(
              key: 'inputDir',
              label: 'Input Directory',
              type: ConfigFieldType.filePath,
              required: true,
              helpText: 'Directory containing files to pack',
            ),
            ConfigField(
              key: 'outputFile',
              label: 'Output WPD File',
              type: ConfigFieldType.filePath,
              helpText: 'Output WPD file path (default: directory name + .wpd)',
            ),
            ConfigField(
              key: 'storeAs',
              label: 'Store Output File As',
              type: ConfigFieldType.text,
              defaultValue: 'packedFile',
              helpText: 'Variable to store the output file path',
            ),
          ]),

        // WBT Operations (Immediate nodes)
        NodeType.wbtLoadFileList => const NodeConfigSchema([
            ConfigField(
              key: 'fileListPath',
              label: 'File List Path',
              type: ConfigFieldType.filePath,
              required: true,
              helpText: 'Path to the WBT file list (e.g., white_img.win32.bin)',
            ),
            ConfigField(
              key: 'binPath',
              label: 'Container (.bin) Path',
              type: ConfigFieldType.filePath,
              required: true,
              helpText: 'Path to the WBT container file (e.g., _white_img.win32.bin)',
            ),
          ]),
        NodeType.wbtExtractFiles => const NodeConfigSchema([
            ConfigField(
              key: 'sourceNode',
              label: 'Source WBT Node',
              type: ConfigFieldType.nodeReference,
              required: true,
              helpText: 'The Load WBT File List node to extract from',
            ),
            ConfigField(
              key: 'selectedFiles',
              label: 'Files to Extract',
              type: ConfigFieldType.wbtFileSelection,
              required: true,
              helpText: 'Select files and folders to extract',
            ),
            ConfigField(
              key: 'outputDir',
              label: 'Output Directory',
              type: ConfigFieldType.directoryPath,
              required: true,
              helpText: 'Directory to extract files to',
            ),
          ]),
        NodeType.wbtRepackFiles => const NodeConfigSchema([
            ConfigField(
              key: 'fileListPath',
              label: 'File List Path',
              type: ConfigFieldType.filePath,
              required: true,
              helpText: 'Path to the original WBT file list (e.g., white_img.win32.bin)',
            ),
            ConfigField(
              key: 'binPath',
              label: 'Container (.bin) Path',
              type: ConfigFieldType.filePath,
              required: true,
              helpText: 'Path to the WBT container file (e.g., _white_img.win32.bin)',
            ),
            ConfigField(
              key: 'repackMode',
              label: 'Repack Mode',
              type: ConfigFieldType.dropdown,
              required: true,
              defaultValue: 'directory',
              options: [
                DropdownOption('directory', 'Directory (all files)'),
                DropdownOption('single', 'Single File'),
                DropdownOption('multiple', 'Multiple Files'),
              ],
              helpText: 'How to specify files to repack',
            ),
            // For directory mode
            ConfigField(
              key: 'inputDir',
              label: 'Input Directory',
              type: ConfigFieldType.directoryPath,
              helpText: 'Directory containing modified files to repack (for directory mode)',
            ),
            // For single file mode
            ConfigField(
              key: 'targetPathInArchive',
              label: 'Target Path in Archive',
              type: ConfigFieldType.text,
              placeholder: 'e.g., chr/c000/model.trb',
              helpText: 'Virtual path in the archive where the file will be injected',
            ),
            ConfigField(
              key: 'fileToInject',
              label: 'File to Inject',
              type: ConfigFieldType.filePath,
              helpText: 'Path to the file on disk to inject into the archive',
            ),
            // For multiple files mode
            ConfigField(
              key: 'fileMappings',
              label: 'File Mappings',
              type: ConfigFieldType.text,
              placeholder: 'archive/path1.trb:local/file1.trb,archive/path2.trb:local/file2.trb',
              helpText: 'Comma-separated list of archivePath:localPath pairs',
            ),
          ]),

        // IMG Operations
        NodeType.imgExtract => const NodeConfigSchema([
            ConfigField(
              key: 'headerPath',
              label: 'Header File Path',
              type: ConfigFieldType.filePath,
              required: true,
              helpText: 'Path to the IMG header file (e.g., texture.imgb or .trb file with embedded header)',
            ),
            ConfigField(
              key: 'imgbPath',
              label: 'IMGB Data File Path',
              type: ConfigFieldType.filePath,
              required: true,
              helpText: 'Path to the IMGB data file containing texture data',
            ),
            ConfigField(
              key: 'outputDdsPath',
              label: 'Output DDS Path',
              type: ConfigFieldType.filePath,
              required: true,
              helpText: 'Path where the extracted DDS file will be saved',
            ),
            ConfigField(
              key: 'storeAs',
              label: 'Store Output Path As',
              type: ConfigFieldType.text,
              defaultValue: 'extractedDds',
              helpText: 'Variable to store the output DDS file path',
            ),
          ]),
        NodeType.imgRepack => const NodeConfigSchema([
            ConfigField(
              key: 'headerPath',
              label: 'Header File Path',
              type: ConfigFieldType.filePath,
              required: true,
              helpText: 'Path to the IMG header file (will be modified in place)',
            ),
            ConfigField(
              key: 'imgbPath',
              label: 'IMGB Data File Path',
              type: ConfigFieldType.filePath,
              required: true,
              helpText: 'Path to the IMGB data file (will be modified in place)',
            ),
            ConfigField(
              key: 'inputDdsPath',
              label: 'Input DDS Path',
              type: ConfigFieldType.filePath,
              required: true,
              helpText: 'Path to the DDS file to inject into the IMGB',
            ),
          ]),

        // WDB Operations
        NodeType.wdbTransform => const NodeConfigSchema([
            ConfigField(
              key: 'filePath',
              label: 'File Path',
              type: ConfigFieldType.filePath,
              required: true,
              helpText: 'Path to the WDB file to transform',
            ),
            ConfigField(
              key: 'outputPath',
              label: 'Output Path',
              type: ConfigFieldType.filePath,
              helpText: 'Save to different file (leave empty to overwrite)',
            ),
            ConfigField(
              key: 'operations',
              label: 'Operations',
              type: ConfigFieldType.operationsList,
              required: true,
              helpText: 'List of operations to perform on the WDB',
            ),
          ]),
        NodeType.wdbOpen => const NodeConfigSchema([
            ConfigField(
              key: 'filePath',
              label: 'File Path',
              type: ConfigFieldType.filePath,
              required: true,
              helpText: 'Path to the WDB file',
            ),
            ConfigField(
              key: 'storeAs',
              label: 'Store As Variable',
              type: ConfigFieldType.text,
              defaultValue: 'wdb',
              helpText: 'Variable name to store the WDB data',
            ),
          ]),
        NodeType.wdbSave => const NodeConfigSchema([
            ConfigField(
              key: 'wdbVariable',
              label: 'WDB Variable',
              type: ConfigFieldType.variable,
              required: true,
              defaultValue: 'wdb',
              helpText: 'Variable containing WDB data',
            ),
            ConfigField(
              key: 'outputPath',
              label: 'Output Path',
              type: ConfigFieldType.filePath,
              helpText: 'Path to save (leave empty to overwrite source)',
            ),
            ConfigField(
              key: 'format',
              label: 'Format',
              type: ConfigFieldType.dropdown,
              defaultValue: 'wdb',
              options: [
                DropdownOption('wdb', 'WDB (Binary)'),
                DropdownOption('json', 'JSON'),
              ],
            ),
          ]),
        NodeType.wdbFindRecord => const NodeConfigSchema([
            ConfigField(
              key: 'wdbVariable',
              label: 'WDB Variable',
              type: ConfigFieldType.variable,
              required: true,
              defaultValue: 'wdb',
            ),
            ConfigField(
              key: 'recordId',
              label: 'Record ID',
              type: ConfigFieldType.expression,
              required: true,
              placeholder: 'e.g., mcr_k954',
              helpText: 'ID of the record to find',
            ),
            ConfigField(
              key: 'storeAs',
              label: 'Store As Variable',
              type: ConfigFieldType.text,
              defaultValue: 'foundRecord',
              helpText: 'Variable to store the found record',
            ),
          ]),
        NodeType.wdbCopyRecord => const NodeConfigSchema([
            ConfigField(
              key: 'wdbVariable',
              label: 'WDB Variable',
              type: ConfigFieldType.variable,
              required: true,
              defaultValue: 'wdb',
            ),
            ConfigField(
              key: 'sourceRecordId',
              label: 'Source Record ID',
              type: ConfigFieldType.expression,
              required: true,
              placeholder: 'e.g., mcr_k954',
              helpText: 'ID of the record to copy',
            ),
            ConfigField(
              key: 'storeAs',
              label: 'Store As Variable',
              type: ConfigFieldType.text,
              defaultValue: 'copiedRecord',
              helpText: 'Variable to store the copied record',
            ),
          ]),
        NodeType.wdbPasteRecord => const NodeConfigSchema([
            ConfigField(
              key: 'wdbVariable',
              label: 'WDB Variable',
              type: ConfigFieldType.variable,
              required: true,
              defaultValue: 'wdb',
            ),
            ConfigField(
              key: 'recordVariable',
              label: 'Record Variable',
              type: ConfigFieldType.variable,
              required: true,
              defaultValue: 'copiedRecord',
              helpText: 'Variable containing the record to paste',
            ),
            ConfigField(
              key: 'afterRecordId',
              label: 'Insert After Record ID',
              type: ConfigFieldType.expression,
              placeholder: 'e.g., mcr_k895',
              helpText: 'Insert after this record (empty = end)',
            ),
          ]),
        NodeType.wdbRenameRecord => const NodeConfigSchema([
            ConfigField(
              key: 'wdbVariable',
              label: 'WDB Variable',
              type: ConfigFieldType.variable,
              required: true,
              defaultValue: 'wdb',
            ),
            ConfigField(
              key: 'recordId',
              label: 'Current Record ID',
              type: ConfigFieldType.expression,
              required: true,
              helpText: 'ID of the record to rename',
            ),
            ConfigField(
              key: 'newRecordId',
              label: 'New Record ID',
              type: ConfigFieldType.expression,
              required: true,
              placeholder: 'e.g., mcr_k904',
              helpText: 'New ID for the record',
            ),
          ]),
        NodeType.wdbSetField => const NodeConfigSchema([
            ConfigField(
              key: 'wdbVariable',
              label: 'WDB Variable',
              type: ConfigFieldType.variable,
              required: true,
              defaultValue: 'wdb',
            ),
            ConfigField(
              key: 'recordId',
              label: 'Record ID',
              type: ConfigFieldType.expression,
              required: true,
              placeholder: 'e.g., mcr_k904',
              helpText: 'ID of the record to modify',
            ),
            ConfigField(
              key: 'column',
              label: 'Column',
              type: ConfigFieldType.column,
              required: true,
              helpText: 'Column to modify',
            ),
            ConfigField(
              key: 'value',
              label: 'Value',
              type: ConfigFieldType.expression,
              required: true,
              helpText: 'New value for the field',
            ),
          ]),
        NodeType.wdbDeleteRecord => const NodeConfigSchema([
            ConfigField(
              key: 'wdbVariable',
              label: 'WDB Variable',
              type: ConfigFieldType.variable,
              required: true,
              defaultValue: 'wdb',
            ),
            ConfigField(
              key: 'recordId',
              label: 'Record ID',
              type: ConfigFieldType.expression,
              required: true,
              helpText: 'ID of the record to delete',
            ),
          ]),
        NodeType.wdbBulkUpdate => const NodeConfigSchema([
            ConfigField(
              key: 'wdbVariable',
              label: 'WDB Variable',
              type: ConfigFieldType.variable,
              required: true,
              defaultValue: 'wdb',
            ),
            ConfigField(
              key: 'column',
              label: 'Column',
              type: ConfigFieldType.column,
              required: true,
            ),
            ConfigField(
              key: 'operation',
              label: 'Operation',
              type: ConfigFieldType.dropdown,
              required: true,
              defaultValue: 'multiply',
              options: [
                DropdownOption('multiply', 'Multiply'),
                DropdownOption('divide', 'Divide'),
                DropdownOption('add', 'Add'),
                DropdownOption('subtract', 'Subtract'),
                DropdownOption('set', 'Set'),
              ],
            ),
            ConfigField(
              key: 'value',
              label: 'Value',
              type: ConfigFieldType.expression,
              required: true,
            ),
            ConfigField(
              key: 'filter',
              label: 'Filter Expression',
              type: ConfigFieldType.expression,
              placeholder: 'e.g., \${row.record}.startsWith("mcr_")',
              helpText: 'Optional filter to limit affected rows',
            ),
          ]),

        // ZTR Operations
        NodeType.ztrOpen => const NodeConfigSchema([
            ConfigField(
              key: 'filePath',
              label: 'File Path',
              type: ConfigFieldType.filePath,
              required: true,
              helpText: 'Path to the ZTR file',
            ),
            ConfigField(
              key: 'storeAs',
              label: 'Store As Variable',
              type: ConfigFieldType.text,
              defaultValue: 'ztr',
              helpText: 'Variable name to store the ZTR data',
            ),
          ]),
        NodeType.ztrSave => const NodeConfigSchema([
            ConfigField(
              key: 'ztrVariable',
              label: 'ZTR Variable',
              type: ConfigFieldType.variable,
              required: true,
              defaultValue: 'ztr',
            ),
            ConfigField(
              key: 'outputPath',
              label: 'Output Path',
              type: ConfigFieldType.filePath,
              helpText: 'Path to save (leave empty to overwrite source)',
            ),
          ]),
        NodeType.ztrFindEntry => const NodeConfigSchema([
            ConfigField(
              key: 'ztrVariable',
              label: 'ZTR Variable',
              type: ConfigFieldType.variable,
              required: true,
              defaultValue: 'ztr',
            ),
            ConfigField(
              key: 'entryId',
              label: 'Entry ID',
              type: ConfigFieldType.expression,
              required: true,
              helpText: 'ID of the entry to find',
            ),
            ConfigField(
              key: 'storeAs',
              label: 'Store As Variable',
              type: ConfigFieldType.text,
              defaultValue: 'foundEntry',
            ),
          ]),
        NodeType.ztrModifyText => const NodeConfigSchema([
            ConfigField(
              key: 'ztrVariable',
              label: 'ZTR Variable',
              type: ConfigFieldType.variable,
              required: true,
              defaultValue: 'ztr',
            ),
            ConfigField(
              key: 'entryId',
              label: 'Entry ID',
              type: ConfigFieldType.expression,
              required: true,
            ),
            ConfigField(
              key: 'newText',
              label: 'New Text',
              type: ConfigFieldType.expression,
              required: true,
              helpText: 'New text content for the entry',
            ),
          ]),
        NodeType.ztrAddEntry => const NodeConfigSchema([
            ConfigField(
              key: 'ztrVariable',
              label: 'ZTR Variable',
              type: ConfigFieldType.variable,
              required: true,
              defaultValue: 'ztr',
            ),
            ConfigField(
              key: 'entryId',
              label: 'Entry ID',
              type: ConfigFieldType.expression,
              required: true,
            ),
            ConfigField(
              key: 'text',
              label: 'Text',
              type: ConfigFieldType.expression,
              required: true,
            ),
            // Bug #42 fix: Add missing 'afterEntryId' field used by executor
            ConfigField(
              key: 'afterEntryId',
              label: 'Insert After Entry ID',
              type: ConfigFieldType.expression,
              placeholder: 'e.g., entry_001',
              helpText: 'Insert after this entry (empty = add at end)',
            ),
          ]),
        NodeType.ztrDeleteEntry => const NodeConfigSchema([
            ConfigField(
              key: 'ztrVariable',
              label: 'ZTR Variable',
              type: ConfigFieldType.variable,
              required: true,
              defaultValue: 'ztr',
            ),
            ConfigField(
              key: 'entryId',
              label: 'Entry ID',
              type: ConfigFieldType.expression,
              required: true,
            ),
          ]),

        // CGT Operations (Crystalium - FF13 only)
        NodeType.cgtOpen => const NodeConfigSchema([
            ConfigField(
              key: 'filePath',
              label: 'CGT File Path',
              type: ConfigFieldType.filePath,
              required: true,
              helpText: 'Path to the CGT file',
            ),
            ConfigField(
              key: 'storeAs',
              label: 'Store As Variable',
              type: ConfigFieldType.text,
              defaultValue: 'cgt',
              helpText: 'Variable name to store the CGT data',
            ),
          ]),
        NodeType.cgtSave => const NodeConfigSchema([
            ConfigField(
              key: 'cgtVariable',
              label: 'CGT Variable',
              type: ConfigFieldType.variable,
              required: true,
              defaultValue: 'cgt',
            ),
            ConfigField(
              key: 'outputPath',
              label: 'Output Path',
              type: ConfigFieldType.filePath,
              helpText: 'Path to save (leave empty to overwrite source)',
            ),
          ]),
        NodeType.cgtAddOffshoot => const NodeConfigSchema([
            ConfigField(
              key: 'cgtVariable',
              label: 'CGT Variable',
              type: ConfigFieldType.variable,
              required: true,
              defaultValue: 'cgt',
            ),
            ConfigField(
              key: 'parentNodeId',
              label: 'Parent Node ID',
              type: ConfigFieldType.expression,
              required: true,
              helpText: 'ID of the parent node to branch from',
            ),
            ConfigField(
              key: 'patternName',
              label: 'Pattern Name',
              type: ConfigFieldType.text,
              required: true,
              helpText: 'MCP pattern name (e.g., "test3", "test7")',
            ),
            ConfigField(
              key: 'stage',
              label: 'Stage',
              type: ConfigFieldType.number,
              required: true,
              defaultValue: 1,
              helpText: 'Progression stage (1-10)',
            ),
            ConfigField(
              key: 'roleId',
              label: 'Role',
              type: ConfigFieldType.dropdown,
              required: true,
              defaultValue: '0',
              options: [
                DropdownOption('0', 'Commando (COM)'),
                DropdownOption('1', 'Ravager (RAV)'),
                DropdownOption('2', 'Sentinel (SEN)'),
                DropdownOption('3', 'Saboteur (SAB)'),
                DropdownOption('4', 'Synergist (SYN)'),
                DropdownOption('5', 'Medic (MED)'),
              ],
              helpText: 'Combat role for the new node',
            ),
          ]),
        NodeType.cgtAddChain => const NodeConfigSchema([
            ConfigField(
              key: 'cgtVariable',
              label: 'CGT Variable',
              type: ConfigFieldType.variable,
              required: true,
              defaultValue: 'cgt',
            ),
            ConfigField(
              key: 'parentNodeId',
              label: 'Parent Node ID',
              type: ConfigFieldType.expression,
              required: true,
              helpText: 'ID of the parent node to start the chain from',
            ),
            ConfigField(
              key: 'chainDefinition',
              label: 'Chain Definition',
              type: ConfigFieldType.expression,
              required: true,
              placeholder: '[{"pattern": "test3", "stage": 1, "role": 0}, ...]',
              helpText: 'JSON array of chain entries with pattern, stage, and role',
            ),
          ]),
        NodeType.cgtUpdateEntry => const NodeConfigSchema([
            ConfigField(
              key: 'cgtVariable',
              label: 'CGT Variable',
              type: ConfigFieldType.variable,
              required: true,
              defaultValue: 'cgt',
            ),
            ConfigField(
              key: 'entryIndex',
              label: 'Entry Index',
              type: ConfigFieldType.expression,
              required: true,
              helpText: 'Index of the entry to update',
            ),
            ConfigField(
              key: 'stage',
              label: 'New Stage',
              type: ConfigFieldType.number,
              helpText: 'Leave empty to keep current value',
            ),
            ConfigField(
              key: 'roleId',
              label: 'New Role',
              type: ConfigFieldType.dropdown,
              options: [
                DropdownOption('', 'Keep Current'),
                DropdownOption('0', 'Commando (COM)'),
                DropdownOption('1', 'Ravager (RAV)'),
                DropdownOption('2', 'Sentinel (SEN)'),
                DropdownOption('3', 'Saboteur (SAB)'),
                DropdownOption('4', 'Synergist (SYN)'),
                DropdownOption('5', 'Medic (MED)'),
              ],
              helpText: 'Leave empty to keep current value',
            ),
          ]),
        NodeType.cgtUpdateNodeName => const NodeConfigSchema([
            ConfigField(
              key: 'cgtVariable',
              label: 'CGT Variable',
              type: ConfigFieldType.variable,
              required: true,
              defaultValue: 'cgt',
            ),
            ConfigField(
              key: 'nodeId',
              label: 'Node ID',
              type: ConfigFieldType.expression,
              required: true,
              helpText: 'ID of the node to rename',
            ),
            ConfigField(
              key: 'newName',
              label: 'New Name',
              type: ConfigFieldType.expression,
              required: true,
              helpText: 'New name for the node',
            ),
          ]),
        NodeType.cgtFindEntry => const NodeConfigSchema([
            ConfigField(
              key: 'cgtVariable',
              label: 'CGT Variable',
              type: ConfigFieldType.variable,
              required: true,
              defaultValue: 'cgt',
            ),
            ConfigField(
              key: 'nodeId',
              label: 'Node ID',
              type: ConfigFieldType.expression,
              required: true,
              helpText: 'ID of the node to find',
            ),
            ConfigField(
              key: 'storeAs',
              label: 'Store As Variable',
              type: ConfigFieldType.text,
              defaultValue: 'foundEntry',
              helpText: 'Variable to store the found entry',
            ),
          ]),
        NodeType.cgtDeleteEntry => const NodeConfigSchema([
            ConfigField(
              key: 'cgtVariable',
              label: 'CGT Variable',
              type: ConfigFieldType.variable,
              required: true,
              defaultValue: 'cgt',
            ),
            ConfigField(
              key: 'entryIndex',
              label: 'Entry Index',
              type: ConfigFieldType.expression,
              required: true,
              helpText: 'Index of the entry to delete',
            ),
          ]),

        // Variables
        NodeType.setVariable => const NodeConfigSchema([
            ConfigField(
              key: 'name',
              label: 'Variable Name',
              type: ConfigFieldType.text,
              required: true,
            ),
            ConfigField(
              key: 'value',
              label: 'Value',
              type: ConfigFieldType.expression,
              required: true,
            ),
          ]),
        NodeType.getVariable => const NodeConfigSchema([
            ConfigField(
              key: 'name',
              label: 'Variable Name',
              type: ConfigFieldType.variable,
              required: true,
            ),
            ConfigField(
              key: 'storeAs',
              label: 'Store As',
              type: ConfigFieldType.text,
              required: true,
            ),
          ]),
        NodeType.expression => const NodeConfigSchema([
            ConfigField(
              key: 'expression',
              label: 'Expression',
              type: ConfigFieldType.expression,
              required: true,
              helpText: 'Expression to evaluate',
            ),
            ConfigField(
              key: 'storeAs',
              label: 'Store As Variable',
              type: ConfigFieldType.text,
              helpText: 'Variable to store result (optional)',
            ),
          ]),
      };
}
