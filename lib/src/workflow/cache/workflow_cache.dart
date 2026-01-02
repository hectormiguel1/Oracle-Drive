import '../../../models/workflow/workflow.dart';

/// Cached workflow entry with lazy parsing.
class CachedWorkflow {
  final String id;
  final String jsonData;
  final String? workspacePath;

  // Cached parsed workflow
  Workflow? _cachedWorkflow;
  int? _cachedJsonHash;

  CachedWorkflow({
    required this.id,
    required this.jsonData,
    this.workspacePath,
  });

  /// Get the parsed workflow, using cache if available.
  ///
  /// The workflow is lazily parsed on first access and cached.
  /// The cache is invalidated if the JSON data changes.
  Workflow get workflow {
    final currentHash = jsonData.hashCode;
    if (_cachedWorkflow != null && _cachedJsonHash == currentHash) {
      return _cachedWorkflow!;
    }

    _cachedWorkflow = Workflow.fromJsonString(jsonData);
    if (workspacePath != null) {
      _cachedWorkflow!.workspacePath = workspacePath;
    }
    _cachedJsonHash = currentHash;
    return _cachedWorkflow!;
  }

  /// Check if the workflow has been parsed.
  bool get isParsed => _cachedWorkflow != null;

  /// Invalidate the cached workflow.
  void invalidate() {
    _cachedWorkflow = null;
    _cachedJsonHash = null;
  }

  /// Update the cached workflow.
  void updateCache(Workflow workflow) {
    _cachedWorkflow = workflow;
    _cachedJsonHash = jsonData.hashCode;
  }
}

/// A cache for parsed workflows.
///
/// Provides lazy parsing and caching of workflows to improve performance
/// when repeatedly accessing the same workflows.
class WorkflowParsingCache {
  final Map<String, CachedWorkflow> _cache = {};
  final int _maxEntries;

  WorkflowParsingCache({int maxEntries = 50}) : _maxEntries = maxEntries;

  /// Add a workflow to the cache.
  void add(String id, String jsonData, {String? workspacePath}) {
    _evictIfNeeded();
    _cache[id] = CachedWorkflow(
      id: id,
      jsonData: jsonData,
      workspacePath: workspacePath,
    );
  }

  /// Get a cached workflow entry.
  CachedWorkflow? getEntry(String id) => _cache[id];

  /// Get a parsed workflow from the cache.
  Workflow? getWorkflow(String id) => _cache[id]?.workflow;

  /// Check if a workflow is in the cache.
  bool contains(String id) => _cache.containsKey(id);

  /// Remove a workflow from the cache.
  void remove(String id) {
    _cache.remove(id);
  }

  /// Invalidate a cached workflow (force re-parsing on next access).
  void invalidate(String id) {
    _cache[id]?.invalidate();
  }

  /// Clear all cached workflows.
  void clear() {
    _cache.clear();
  }

  /// Get the number of cached workflows.
  int get length => _cache.length;

  void _evictIfNeeded() {
    if (_cache.length >= _maxEntries) {
      // Remove unparsed entries first, then oldest entries
      final unparsed = _cache.entries
          .where((e) => !e.value.isParsed)
          .map((e) => e.key)
          .toList();

      if (unparsed.isNotEmpty) {
        for (final key in unparsed.take((_maxEntries / 4).ceil())) {
          _cache.remove(key);
        }
      } else {
        // Remove oldest 25% of entries
        final keys = _cache.keys.toList();
        for (final key in keys.take((_maxEntries / 4).ceil())) {
          _cache.remove(key);
        }
      }
    }
  }
}
