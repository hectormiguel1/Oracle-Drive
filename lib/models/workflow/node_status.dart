import 'package:flutter/material.dart';

/// Execution status for individual workflow nodes.
enum NodeExecutionStatus {
  /// Node has not been executed yet.
  pending('Pending', Colors.grey, Icons.radio_button_unchecked),

  /// Node is currently executing.
  executing('Executing', Colors.amber, Icons.sync),

  /// Node executed successfully.
  success('Success', Colors.green, Icons.check_circle),

  /// Node execution failed.
  failure('Failure', Colors.red, Icons.error);

  final String displayName;
  final Color color;
  final IconData icon;

  const NodeExecutionStatus(this.displayName, this.color, this.icon);
}

/// Execution mode for workflow nodes.
enum NodeExecutionMode {
  /// Node executes when the workflow is run (deferred execution).
  lazy('Lazy', 'Executes when workflow runs', Icons.schedule),

  /// Node executes immediately when configured/validated.
  immediate('Immediate', 'Executes immediately when configured', Icons.flash_on);

  final String displayName;
  final String description;
  final IconData icon;

  const NodeExecutionMode(this.displayName, this.description, this.icon);
}
