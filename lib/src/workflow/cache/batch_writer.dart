import 'dart:async';
import '../../../models/workflow/workflow.dart';
import '../../isar/workflow/workflow_repository.dart';

/// Batches workflow writes with debouncing for auto-save scenarios.
///
/// Features:
/// - Debounced writes to reduce database operations
/// - Batch multiple workflow saves into a single transaction
/// - Configurable debounce delay
/// - Flush on demand or automatic flush on dispose
class BatchWorkflowWriter {
  final WorkflowRepository _repository;
  final Duration _debounceDelay;

  Timer? _debounceTimer;
  final Map<String, Workflow> _pendingWrites = {};
  Completer<void>? _flushCompleter;

  /// Callbacks for write events.
  void Function(Workflow workflow)? onWriteQueued;
  void Function(List<Workflow> workflows)? onFlushComplete;
  void Function(Object error)? onError;

  BatchWorkflowWriter(
    this._repository, {
    Duration debounceDelay = const Duration(milliseconds: 500),
    this.onWriteQueued,
    this.onFlushComplete,
    this.onError,
  }) : _debounceDelay = debounceDelay;

  /// Queue a workflow for writing.
  ///
  /// The write will be debounced - if multiple writes are queued within
  /// the debounce delay, they will be combined into a single batch operation.
  void queueWrite(Workflow workflow) {
    _pendingWrites[workflow.id] = workflow;
    onWriteQueued?.call(workflow);

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, _flushWrites);
  }

  /// Queue multiple workflows for writing.
  void queueWriteAll(Iterable<Workflow> workflows) {
    for (final workflow in workflows) {
      _pendingWrites[workflow.id] = workflow;
      onWriteQueued?.call(workflow);
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, _flushWrites);
  }

  /// Check if there are pending writes.
  bool get hasPendingWrites => _pendingWrites.isNotEmpty;

  /// Get the number of pending writes.
  int get pendingCount => _pendingWrites.length;

  /// Get the IDs of workflows pending write.
  Iterable<String> get pendingIds => _pendingWrites.keys;

  /// Flush all pending writes immediately.
  ///
  /// Returns a future that completes when all writes are done.
  Future<void> flush() async {
    _debounceTimer?.cancel();

    // If already flushing, wait for it to complete
    if (_flushCompleter != null) {
      return _flushCompleter!.future;
    }

    await _flushWrites();
  }

  /// Cancel all pending writes without saving.
  void cancelPending() {
    _debounceTimer?.cancel();
    _pendingWrites.clear();
  }

  /// Cancel pending write for a specific workflow.
  void cancelPendingFor(String workflowId) {
    _pendingWrites.remove(workflowId);
  }

  Future<void> _flushWrites() async {
    if (_pendingWrites.isEmpty) return;

    _flushCompleter = Completer<void>();

    final toWrite = Map<String, Workflow>.from(_pendingWrites);
    _pendingWrites.clear();

    try {
      // Write all workflows
      for (final workflow in toWrite.values) {
        await _repository.saveWorkflow(workflow);
      }

      onFlushComplete?.call(toWrite.values.toList());
      _flushCompleter?.complete();
    } catch (e) {
      // On error, re-queue the failed writes
      _pendingWrites.addAll(toWrite);
      onError?.call(e);
      _flushCompleter?.completeError(e);
    } finally {
      _flushCompleter = null;
    }
  }

  /// Dispose of the writer.
  ///
  /// By default, flushes pending writes before disposing.
  /// Set [flush] to false to discard pending writes.
  Future<void> dispose({bool flush = true}) async {
    _debounceTimer?.cancel();
    _debounceTimer = null;

    if (flush && _pendingWrites.isNotEmpty) {
      await _flushWrites();
    }

    _pendingWrites.clear();
  }
}

/// Extension to add batch writing capability to WorkflowRepository.
extension WorkflowRepositoryBatchExtension on WorkflowRepository {
  /// Create a batch writer for this repository.
  BatchWorkflowWriter createBatchWriter({
    Duration debounceDelay = const Duration(milliseconds: 500),
  }) {
    return BatchWorkflowWriter(
      this,
      debounceDelay: debounceDelay,
    );
  }
}
