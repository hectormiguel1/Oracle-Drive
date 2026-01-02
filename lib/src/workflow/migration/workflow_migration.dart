import 'dart:convert';
import 'package:logging/logging.dart';

final _logger = Logger('WorkflowMigration');

/// Current workflow schema version.
const int currentWorkflowSchemaVersion = 1;

/// Abstract base class for workflow migrations.
abstract class WorkflowMigration {
  /// Source version (migrate from).
  int get fromVersion;

  /// Target version (migrate to).
  int get toVersion;

  /// Migrate workflow data from one version to another.
  ///
  /// Returns the migrated data map.
  Map<String, dynamic> migrate(Map<String, dynamic> data);

  /// Description of what this migration does.
  String get description;
}

/// Runner for workflow schema migrations.
class WorkflowMigrationRunner {
  static const int currentVersion = currentWorkflowSchemaVersion;

  final List<WorkflowMigration> _migrations;

  WorkflowMigrationRunner({
    List<WorkflowMigration>? migrations,
  }) : _migrations = migrations ?? _defaultMigrations;

  static final List<WorkflowMigration> _defaultMigrations = [
    // Add migrations here as schema evolves
    // _MigrationV0ToV1(),
  ];

  /// Check if data needs migration.
  bool needsMigration(Map<String, dynamic> data) {
    final version = data['_schemaVersion'] as int? ?? 0;
    return version < currentVersion;
  }

  /// Get the current schema version of the data.
  int getVersion(Map<String, dynamic> data) {
    return data['_schemaVersion'] as int? ?? 0;
  }

  /// Migrate workflow data to the latest schema version.
  ///
  /// Returns a new map with migrated data. The original map is not modified.
  Map<String, dynamic> migrateToLatest(Map<String, dynamic> data) {
    int version = data['_schemaVersion'] as int? ?? 0;

    if (version >= currentVersion) {
      return data;
    }

    _logger.info('Migrating workflow from v$version to v$currentVersion');

    // Create a copy to avoid modifying the original
    var migrated = Map<String, dynamic>.from(data);

    while (version < currentVersion) {
      final migration = _findMigration(version);
      if (migration == null) {
        _logger.warning(
          'No migration found from v$version, skipping to v${version + 1}',
        );
        version++;
        continue;
      }

      _logger.info('Applying migration: ${migration.description}');
      migrated = migration.migrate(migrated);
      version = migration.toVersion;
    }

    // Set the final version
    migrated['_schemaVersion'] = currentVersion;

    return migrated;
  }

  /// Migrate a JSON string to the latest schema version.
  String migrateJsonToLatest(String json) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    final migrated = migrateToLatest(data);
    return jsonEncode(migrated);
  }

  WorkflowMigration? _findMigration(int fromVersion) {
    for (final migration in _migrations) {
      if (migration.fromVersion == fromVersion) {
        return migration;
      }
    }
    return null;
  }

  /// Register a custom migration.
  void registerMigration(WorkflowMigration migration) {
    _migrations.add(migration);
    // Sort by fromVersion to ensure correct order
    _migrations.sort((a, b) => a.fromVersion.compareTo(b.fromVersion));
  }

  /// Get list of all available migrations.
  List<WorkflowMigration> get migrations => List.unmodifiable(_migrations);
}

// ============================================================================
// Example migrations (add as schema evolves)
// ============================================================================

/// Example migration from v0 (no schema version) to v1.
class MigrationV0ToV1 extends WorkflowMigration {
  @override
  int get fromVersion => 0;

  @override
  int get toVersion => 1;

  @override
  String get description => 'Initial schema version';

  @override
  Map<String, dynamic> migrate(Map<String, dynamic> data) {
    // Copy the data
    final migrated = Map<String, dynamic>.from(data);

    // Add schema version
    migrated['_schemaVersion'] = 1;

    // Example: Rename 'vars' to 'variables' if present
    if (migrated.containsKey('vars') && !migrated.containsKey('variables')) {
      migrated['variables'] = migrated.remove('vars');
    }

    return migrated;
  }
}

/// Example migration for renaming node types.
class MigrationRenameNodeTypes extends WorkflowMigration {
  final int _fromVersion;
  final int _toVersion;
  final Map<String, String> _renames;

  MigrationRenameNodeTypes({
    required int fromVersion,
    required int toVersion,
    required Map<String, String> renames,
  })  : _fromVersion = fromVersion,
        _toVersion = toVersion,
        _renames = renames;

  @override
  int get fromVersion => _fromVersion;

  @override
  int get toVersion => _toVersion;

  @override
  String get description => 'Rename node types: $_renames';

  @override
  Map<String, dynamic> migrate(Map<String, dynamic> data) {
    final migrated = Map<String, dynamic>.from(data);

    // Update nodes
    if (migrated.containsKey('nodes')) {
      final nodes = (migrated['nodes'] as List).map((node) {
        final nodeMap = Map<String, dynamic>.from(node as Map);
        final type = nodeMap['type'] as String?;
        if (type != null && _renames.containsKey(type)) {
          nodeMap['type'] = _renames[type];
        }
        return nodeMap;
      }).toList();
      migrated['nodes'] = nodes;
    }

    return migrated;
  }
}

/// Example migration for adding new required fields.
class MigrationAddRequiredFields extends WorkflowMigration {
  final int _fromVersion;
  final int _toVersion;
  final Map<String, dynamic> _fields;

  MigrationAddRequiredFields({
    required int fromVersion,
    required int toVersion,
    required Map<String, dynamic> fields,
  })  : _fromVersion = fromVersion,
        _toVersion = toVersion,
        _fields = fields;

  @override
  int get fromVersion => _fromVersion;

  @override
  int get toVersion => _toVersion;

  @override
  String get description => 'Add required fields: ${_fields.keys}';

  @override
  Map<String, dynamic> migrate(Map<String, dynamic> data) {
    final migrated = Map<String, dynamic>.from(data);

    for (final entry in _fields.entries) {
      if (!migrated.containsKey(entry.key)) {
        migrated[entry.key] = entry.value;
      }
    }

    return migrated;
  }
}

/// Example migration for node config changes.
class MigrationNodeConfigChanges extends WorkflowMigration {
  final int _fromVersion;
  final int _toVersion;
  final String _nodeType;
  final Map<String, dynamic> Function(Map<String, dynamic> config) _transform;
  final String _desc;

  MigrationNodeConfigChanges({
    required int fromVersion,
    required int toVersion,
    required String nodeType,
    required Map<String, dynamic> Function(Map<String, dynamic>) transform,
    required String description,
  })  : _fromVersion = fromVersion,
        _toVersion = toVersion,
        _nodeType = nodeType,
        _transform = transform,
        _desc = description;

  @override
  int get fromVersion => _fromVersion;

  @override
  int get toVersion => _toVersion;

  @override
  String get description => _desc;

  @override
  Map<String, dynamic> migrate(Map<String, dynamic> data) {
    final migrated = Map<String, dynamic>.from(data);

    if (migrated.containsKey('nodes')) {
      final nodes = (migrated['nodes'] as List).map((node) {
        final nodeMap = Map<String, dynamic>.from(node as Map);
        if (nodeMap['type'] == _nodeType) {
          final config = Map<String, dynamic>.from(
            nodeMap['config'] as Map? ?? {},
          );
          nodeMap['config'] = _transform(config);
        }
        return nodeMap;
      }).toList();
      migrated['nodes'] = nodes;
    }

    return migrated;
  }
}
