import 'dart:collection';
import 'dart:typed_data';

import '../adaptive_network_image_config.dart';

/// Web cache manager with two cache levels:
/// - Strategy resolution cache: remembers which strategy worked for each URL.
/// - Bytes cache: LRU-bounded store for proxy-fetched image bytes.
class ImageCacheManager {
  static final ImageCacheManager instance = ImageCacheManager._();
  ImageCacheManager._();

  static const int _maxBytesEntries = 100;

  /// Maximum total bytes allowed in the cache (50 MB).
  static const int maxCacheBytes = 50 * 1024 * 1024;

  /// Strategy resolution cache.
  final Map<String, ImageLoadStrategy> _strategyCache = {};

  /// LRU bytes cache.
  final LinkedHashMap<String, Uint8List> _bytesCache = LinkedHashMap();

  /// Running total of cached bytes.
  int _totalBytes = 0;

  /// Returns the cached strategy for [url], or null if unknown.
  ImageLoadStrategy? getStrategy(String url) => _strategyCache[url];

  /// Cache which strategy worked for [url].
  void putStrategy(String url, ImageLoadStrategy strategy) {
    _strategyCache[url] = strategy;
  }

  /// Returns cached image bytes for [url], or null.
  /// Moves the entry to the end (most recently used).
  Uint8List? getBytes(String url) {
    final bytes = _bytesCache.remove(url);
    if (bytes != null) {
      _bytesCache[url] = bytes; // Re-insert at end (most recent).
    }
    return bytes;
  }

  /// Cache image bytes for [url]. Evicts oldest entries if over entry or byte limit.
  void putBytes(String url, Uint8List bytes) {
    // Remove existing entry first to refresh position and adjust total.
    final existing = _bytesCache.remove(url);
    if (existing != null) {
      _totalBytes -= existing.length;
    }

    _bytesCache[url] = bytes;
    _totalBytes += bytes.length;

    // Evict oldest entries while over entry count or byte limit.
    while (_bytesCache.length > _maxBytesEntries ||
        _totalBytes > maxCacheBytes) {
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
