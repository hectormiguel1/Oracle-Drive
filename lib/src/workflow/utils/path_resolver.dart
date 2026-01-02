import 'package:path/path.dart' as p;

/// Service for resolving file paths in workflow execution.
///
/// Handles:
/// - Variable interpolation (${varName})
/// - Relative to absolute path conversion
/// - Platform-specific path separators
class PathResolver {
  /// The workspace directory for resolving relative paths.
  final String? workspaceDir;

  /// Variables available for interpolation.
  final Map<String, dynamic> Function() variableProvider;

  PathResolver({
    this.workspaceDir,
    required this.variableProvider,
  });

  /// Create a PathResolver with a static variable map.
  factory PathResolver.withVariables({
    String? workspaceDir,
    required Map<String, dynamic> variables,
  }) {
    return PathResolver(
      workspaceDir: workspaceDir,
      variableProvider: () => variables,
    );
  }

  /// Resolve a path, handling:
  /// - Variable interpolation (${varName})
  /// - Relative to absolute conversion
  /// - Platform-specific separators
  String resolve(String rawPath) {
    if (rawPath.isEmpty) return rawPath;

    // 1. Normalize path separators
    var resolved = rawPath.replaceAll('\\', '/');

    // 2. Interpolate variables
    resolved = interpolateVariables(resolved);

    // 3. Check if it's an absolute path after interpolation
    if (p.isAbsolute(resolved)) {
      return p.normalize(resolved);
    }

    // 4. Convert relative to absolute if workspace is set
    if (workspaceDir != null && workspaceDir!.isNotEmpty) {
      resolved = p.normalize(p.join(workspaceDir!, resolved));
    }

    return resolved;
  }

  /// Interpolate variable references in a string.
  ///
  /// Replaces ${varName} patterns with their values from the variable provider.
  String interpolateVariables(String input) {
    if (!input.contains(r'${')) return input;

    final variables = variableProvider();

    return input.replaceAllMapped(
      RegExp(r'\$\{([^}]+)\}'),
      (match) {
        final varName = match.group(1)!;

        // Handle nested property access (e.g., ${obj.prop})
        final parts = varName.split('.');
        dynamic value = variables[parts.first];

        for (int i = 1; i < parts.length && value != null; i++) {
          if (value is Map) {
            value = value[parts[i]];
          } else {
            value = null;
          }
        }

        return value?.toString() ?? match.group(0)!;
      },
    );
  }

  /// Check if a path contains unresolved variable references.
  bool hasUnresolvedVariables(String path) {
    return path.contains(r'${');
  }

  /// Create a new PathResolver with a different workspace directory.
  PathResolver withWorkspace(String? newWorkspaceDir) {
    return PathResolver(
      workspaceDir: newWorkspaceDir,
      variableProvider: variableProvider,
    );
  }

  /// Create a new PathResolver with additional variables.
  PathResolver withAdditionalVariables(Map<String, dynamic> additionalVars) {
    return PathResolver(
      workspaceDir: workspaceDir,
      variableProvider: () => {...variableProvider(), ...additionalVars},
    );
  }

  /// Extract the filename from a path.
  String getFileName(String path) {
    return p.basename(path);
  }

  /// Extract the directory from a path.
  String getDirectory(String path) {
    return p.dirname(path);
  }

  /// Join path segments.
  String join(String path1, String path2) {
    return p.join(path1, path2);
  }

  /// Check if a path is absolute.
  bool isAbsolute(String path) {
    return p.isAbsolute(path);
  }
}
