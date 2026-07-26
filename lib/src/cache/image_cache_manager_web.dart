import 'dart:collection';
import 'dart:typed_data';

import '../adaptive_network_image_config.dart';

/// Web cache manager with two cache levels:
/// - Strategy resolution cache: remembers which strategy worked for each key.
/// - Bytes cache: LRU-bounded store for proxy-fetched image bytes.
class ImageCacheManager {
  static final ImageCacheManager instance = ImageCacheManager._();
  ImageCacheManager._();

  static const int _maxBytesEntries = 100;
  static const int _maxStrategyEntries = 500;

  /// Maximum total bytes allowed in the cache (50 MB).
  static const int maxCacheBytes = 50 * 1024 * 1024;

  /// Strategy resolution cache (LRU-ish via LinkedHashMap insertion order).
  final LinkedHashMap<String, ImageLoadStrategy> _strategyCache =
      LinkedHashMap();

  /// LRU bytes cache.
  final LinkedHashMap<String, Uint8List> _bytesCache = LinkedHashMap();

  /// Running total of cached bytes.
  int _totalBytes = 0;

  /// Returns the cached strategy for [key], or null if unknown.
  ImageLoadStrategy? getStrategy(String key) {
    final strategy = _strategyCache.remove(key);
    if (strategy != null) {
      _strategyCache[key] = strategy;
    }
    return strategy;
  }

  /// Cache which strategy worked for [key].
  void putStrategy(String key, ImageLoadStrategy strategy) {
    _strategyCache.remove(key);
    _strategyCache[key] = strategy;
    while (_strategyCache.length > _maxStrategyEntries) {
      _strategyCache.remove(_strategyCache.keys.first);
    }
  }

  /// Removes a cached strategy for [key], e.g. after a cached retry fails.
  void removeStrategy(String key) {
    _strategyCache.remove(key);
  }

  /// Returns cached image bytes for [key], or null.
  /// Moves the entry to the end (most recently used).
  Uint8List? getBytes(String key) {
    final bytes = _bytesCache.remove(key);
    if (bytes != null) {
      _bytesCache[key] = bytes; // Re-insert at end (most recent).
    }
    return bytes;
  }

  /// Caches image bytes for [key].
  ///
  /// Evicts the oldest entries when either cache limit is exceeded.
  void putBytes(String key, Uint8List bytes) {
    // Remove existing entry first to refresh position and adjust total.
    final existing = _bytesCache.remove(key);
    if (existing != null) {
      _totalBytes -= existing.length;
    }

    _bytesCache[key] = bytes;
    _totalBytes += bytes.length;

    // Evict oldest entries while over entry count or byte limit.
    while (
        _bytesCache.length > _maxBytesEntries || _totalBytes > maxCacheBytes) {
      if (_bytesCache.isEmpty) break;
      final evictedKey = _bytesCache.keys.first;
      final evicted = _bytesCache.remove(evictedKey)!;
      _totalBytes -= evicted.length;
    }
  }

  /// Clear all caches.
  void clear() {
    _strategyCache.clear();
    _bytesCache.clear();
    _totalBytes = 0;
  }
}
