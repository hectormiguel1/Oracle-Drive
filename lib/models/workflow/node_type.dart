import 'package:flutter/material.dart';
import 'node_config.dart';
import 'node_status.dart';

/// Categories of workflow nodes.
enum NodeCategory {
  control('Control Flow', Icons.account_tree),
  wpd('WPD Operations', Icons.archive),
  wbt('WBT Operations', Icons.folder_zip),
  img('IMG Operations', Icons.image),
  wdb('WDB Operations', Icons.storage),
  ztr('ZTR Operations', Icons.translate),
  variable('Variables', Icons.data_object);

  final String displayName;
  final IconData icon;
  const NodeCategory(this.displayName, this.icon);
}

/// Types of nodes available in workflows.
enum NodeType {
  // Control Flow
  start('Start', NodeCategory.control, Icons.play_arrow),
  end('End', NodeCategory.control, Icons.stop),
  condition('Condition', NodeCategory.control, Icons.call_split),
  loop('Loop', NodeCategory.control, Icons.loop),
  forEach('For Each', NodeCategory.control, Icons.repeat),
  fork('Fork', NodeCategory.control, Icons.call_split),
  join('Join', NodeCategory.control, Icons.call_merge),

  // WPD Operations
  wpdUnpack('Unpack WPD', NodeCategory.wpd, Icons.unarchive),
  wpdRepack('Repack WPD', NodeCategory.wpd, Icons.archive),

  // WBT Operations (Immediate nodes for load/extract, lazy for repack)
  wbtLoadFileList('Load WBT File List', NodeCategory.wbt, Icons.list_alt),
  wbtExtractFiles('Extract WBT Files', NodeCategory.wbt, Icons.file_download),
  wbtRepackFiles('Repack WBT Files', NodeCategory.wbt, Icons.file_upload),

  // IMG Operations (texture extraction/injection)
  imgExtract('Extract IMG to DDS', NodeCategory.img, Icons.image_search),
  imgRepack('Repack DDS to IMG', NodeCategory.img, Icons.add_photo_alternate),

  // WDB Operations
  wdbTransform('WDB Transform', NodeCategory.wdb, Icons.transform),
  wdbOpen('Open WDB', NodeCategory.wdb, Icons.folder_open),
  wdbSave('Save WDB', NodeCategory.wdb, Icons.save),
  wdbFindRecord('Find Record', NodeCategory.wdb, Icons.search),
  wdbCopyRecord('Copy Record', NodeCategory.wdb, Icons.content_copy),
  wdbPasteRecord('Paste Record', NodeCategory.wdb, Icons.content_paste),
  wdbRenameRecord('Rename Record', NodeCategory.wdb, Icons.drive_file_rename_outline),
  wdbSetField('Set Field', NodeCategory.wdb, Icons.edit_note),
  wdbDeleteRecord('Delete Record', NodeCategory.wdb, Icons.delete),
  wdbBulkUpdate('Bulk Update', NodeCategory.wdb, Icons.auto_fix_high),

  // ZTR Operations
  ztrOpen('Open ZTR', NodeCategory.ztr, Icons.description),
  ztrSave('Save ZTR', NodeCategory.ztr, Icons.save),
  ztrFindEntry('Find Entry', NodeCategory.ztr, Icons.search),
  ztrModifyText('Modify Text', NodeCategory.ztr, Icons.edit),
  ztrAddEntry('Add Entry', NodeCategory.ztr, Icons.add),
  ztrDeleteEntry('Delete Entry', NodeCategory.ztr, Icons.delete),

  // Variables
  setVariable('Set Variable', NodeCategory.variable, Icons.edit_attributes),
  getVariable('Get Variable', NodeCategory.variable, Icons.download),
  expression('Expression', NodeCategory.variable, Icons.calculate);

  final String displayName;
  final NodeCategory category;
  final IconData icon;

  const NodeType(this.displayName, this.category, this.icon);

  /// Whether this node is an entry point (has no inputs).
  bool get isEntryNode => this == NodeType.start;

  /// Whether this node is a terminal (has no outputs).
  bool get isTerminalNode => this == NodeType.end;

  /// Input port definitions for this node type.
  /// Bug #16 fix: Removed unused 'continue' port from Loop/ForEach - the engine
  /// handles iteration internally by re-executing the loop node after body completion.
  List<PortDefinition> get inputPorts => switch (this) {
        NodeType.start => [],
        NodeType.join => [
            const PortDefinition('input', 'Input', allowMultiple: true),
          ],
        _ => [const PortDefinition('input', 'Input')],
      };

  /// Output port definitions for this node type.
  List<PortDefinition> get outputPorts => switch (this) {
        NodeType.end => [],
        NodeType.condition => [
            const PortDefinition('true', 'True', color: Colors.green),
            const PortDefinition('false', 'False', color: Colors.red),
          ],
        NodeType.forEach => [
            const PortDefinition('body', 'Body'),
            const PortDefinition('done', 'Done'),
          ],
        NodeType.loop => [
            const PortDefinition('body', 'Body'),
            const PortDefinition('done', 'Done'),
          ],
        NodeType.fork => [
            const PortDefinition('output', 'Output', allowMultiple: true),
          ],
        // Bug #1 fix: wdbFindRecord returns 'found'/'notFound' ports
        NodeType.wdbFindRecord => [
            const PortDefinition('found', 'Found', color: Colors.green),
            const PortDefinition('notFound', 'Not Found', color: Colors.orange),
          ],
        // Bug #2 fix: ztrFindEntry returns 'found'/'notFound' ports
        NodeType.ztrFindEntry => [
            const PortDefinition('found', 'Found', color: Colors.green),
            const PortDefinition('notFound', 'Not Found', color: Colors.orange),
          ],
        _ => [const PortDefinition('output', 'Output')],
      };

  /// Whether this node allows multiple connections from its output port.
  bool get allowsMultipleOutputConnections => this == NodeType.fork;

  /// Whether this node requires multiple input connections to be satisfied.
  bool get requiresAllInputs => this == NodeType.join;

  /// Get the configuration schema for this node type.
  NodeConfigSchema get configSchema => NodeConfigRegistry.getSchema(this);

  /// Color for this node type based on category.
  Color get nodeColor => switch (category) {
        NodeCategory.control => const Color(0xFF7C4DFF),
        NodeCategory.wpd => const Color(0xFFE91E63),
        NodeCategory.wbt => const Color(0xFF9C27B0),
        NodeCategory.img => const Color(0xFF8BC34A), // Light green for image ops
        NodeCategory.wdb => const Color(0xFF00BCD4),
        NodeCategory.ztr => const Color(0xFFFF9800),
        NodeCategory.variable => const Color(0xFF4CAF50),
      };

  /// Execution mode for this node type.
  /// Immediate nodes execute as soon as configured, lazy nodes wait for workflow execution.
  NodeExecutionMode get executionMode => switch (this) {
        // WBT operations are immediate - they execute in the editor
        NodeType.wbtLoadFileList => NodeExecutionMode.immediate,
        NodeType.wbtExtractFiles => NodeExecutionMode.immediate,
        // All other nodes are lazy - they execute during workflow run
        _ => NodeExecutionMode.lazy,
      };
}

/// Definition of a port on a node.
class PortDefinition {
  final String id;
  final String displayName;
  final Color? color;
  final bool allowMultiple;

  const PortDefinition(
    this.id,
    this.displayName, {
    this.color,
    this.allowMultiple = false,
  });
}
