import 'dart:async';

/// A cache entry with intelligent TTL management.
class _CacheEntry<V> {
  final V value;
  DateTime expiry;
  DateTime lastAccess;
  int accessCount;

  _CacheEntry(this.value, Duration ttl)
      : expiry = DateTime.now().add(ttl),
        lastAccess = DateTime.now(),
        accessCount = 0;

  bool get isExpired => DateTime.now().isAfter(expiry);

  /// Extend the TTL based on access frequency.
  void extendTtl(Duration baseTtl, Duration maxTtl) {
    lastAccess = DateTime.now();
    accessCount++;

    // Calculate extension based on access count (up to 2x base TTL)
    final multiplier = 1.0 + (accessCount * 0.1).clamp(0.0, 1.0);
    final extension = Duration(
      milliseconds: (baseTtl.inMilliseconds * multiplier).round(),
    );

    final newExpiry = DateTime.now().add(extension);
    final maxExpiry = DateTime.now().add(maxTtl);

    expiry = newExpiry.isBefore(maxExpiry) ? newExpiry : maxExpiry;
  }
}

/// A generic cache with intelligent TTL management.
///
/// Features:
/// - Automatic TTL extension on access
/// - Maximum entry limit with LRU eviction
/// - Configurable base and maximum TTL
/// - Optional periodic cleanup
class MetadataCache<K, V> {
  final Duration _baseTtl;
  final Duration _maxTtl;
  final int _maxEntries;

  final Map<K, _CacheEntry<V>> _cache = {};
  Timer? _cleanupTimer;

  MetadataCache({
    Duration baseTtl = const Duration(minutes: 5),
    Duration maxTtl = const Duration(minutes: 30),
    int maxEntries = 100,
    bool enablePeriodicCleanup = false,
    Duration cleanupInterval = const Duration(minutes: 1),
  })  : _baseTtl = baseTtl,
        _maxTtl = maxTtl,
        _maxEntries = maxEntries {
    if (enablePeriodicCleanup) {
      _startPeriodicCleanup(cleanupInterval);
    }
  }

  /// Get a cached value, or null if not found or expired.
  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    // Extend TTL on access
    entry.extendTtl(_baseTtl, _maxTtl);
    return entry.value;
  }

  /// Get a cached value or compute and cache it.
  Future<V> getOrCompute(K key, Future<V> Function() compute) async {
    final cached = get(key);
    if (cached != null) return cached;

    final value = await compute();
    put(key, value);
    return value;
  }

  /// Get a cached value or compute it synchronously.
  V getOrComputeSync(K key, V Function() compute) {
    final cached = get(key);
    if (cached != null) return cached;

    final value = compute();
    put(key, value);
    return value;
  }

  /// Put a value in the cache.
  void put(K key, V value) {
    _evictIfNeeded();
    _cache[key] = _CacheEntry(value, _baseTtl);
  }

  /// Put a value with a custom TTL.
  void putWithTtl(K key, V value, Duration ttl) {
    _evictIfNeeded();
    _cache[key] = _CacheEntry(value, ttl);
  }

  /// Remove a value from the cache.
  V? remove(K key) {
    final entry = _cache.remove(key);
    return entry?.value;
  }

  /// Check if a key exists in the cache (and is not expired).
  bool containsKey(K key) {
    final entry = _cache[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }
    return true;
  }

  /// Clear all entries from the cache.
  void clear() {
    _cache.clear();
  }

  /// Get the number of entries in the cache.
  int get length => _cache.length;

  /// Get all keys in the cache.
  Iterable<K> get keys => _cache.keys;

  /// Evict expired entries.
  void evictExpired() {
    final expiredKeys = <K>[];
    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }
    for (final key in expiredKeys) {
      _cache.remove(key);
    }
  }

  void _evictIfNeeded() {
    // First, remove expired entries
    evictExpired();

    // If still at capacity, remove least recently accessed entries
    if (_cache.length >= _maxEntries) {
      final sorted = _cache.entries.toList()
        ..sort((a, b) => a.value.lastAccess.compareTo(b.value.lastAccess));

      // Remove oldest 25% of entries
      final toRemove = (_cache.length / 4).ceil();
      for (var i = 0; i < toRemove && i < sorted.length; i++) {
        _cache.remove(sorted[i].key);
      }
    }
  }

  void _startPeriodicCleanup(Duration interval) {
    _cleanupTimer = Timer.periodic(interval, (_) => evictExpired());
  }

  /// Dispose of the cache and stop any timers.
  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _cache.clear();
  }
}

/// A typed cache specifically for workflow-related metadata.
class WorkflowMetadataCache {
  final MetadataCache<String, dynamic> _cache;

  WorkflowMetadataCache({
    Duration baseTtl = const Duration(minutes: 5),
    Duration maxTtl = const Duration(minutes: 30),
    int maxEntries = 100,
  }) : _cache = MetadataCache(
          baseTtl: baseTtl,
          maxTtl: maxTtl,
          maxEntries: maxEntries,
        );

  /// Cache WDB column metadata.
  void cacheWdbColumns(String wdbPath, List<String> columns) {
    _cache.put('wdb_columns:$wdbPath', columns);
  }

  /// Get cached WDB column metadata.
  List<String>? getWdbColumns(String wdbPath) {
    return _cache.get('wdb_columns:$wdbPath') as List<String>?;
  }

  /// Cache WDB record IDs.
  void cacheWdbRecordIds(String wdbPath, List<String> recordIds) {
    _cache.put('wdb_records:$wdbPath', recordIds);
  }

  /// Get cached WDB record IDs.
  List<String>? getWdbRecordIds(String wdbPath) {
    return _cache.get('wdb_records:$wdbPath') as List<String>?;
  }

  /// Cache file list entries.
  void cacheFileList(String archivePath, List<String> files) {
    _cache.put('file_list:$archivePath', files);
  }

  /// Get cached file list entries.
  List<String>? getFileList(String archivePath) {
    return _cache.get('file_list:$archivePath') as List<String>?;
  }

  /// Invalidate all cache entries for a specific WDB.
  void invalidateWdb(String wdbPath) {
    _cache.remove('wdb_columns:$wdbPath');
    _cache.remove('wdb_records:$wdbPath');
  }

  /// Clear all cached data.
  void clear() {
    _cache.clear();
  }

  /// Dispose of the cache.
  void dispose() {
    _cache.dispose();
  }
}
