import 'dart:typed_data';

import '../adaptive_network_image_config.dart';

/// No-op passthrough on mobile — CORS is not a concern.
class ImageCacheManager {
  static final ImageCacheManager instance = ImageCacheManager._();
  ImageCacheManager._();

  ImageLoadStrategy? getStrategy(String key) => null;
  void putStrategy(String key, ImageLoadStrategy strategy) {}
  void removeStrategy(String key) {}
  Uint8List? getBytes(String key) => null;
  void putBytes(String key, Uint8List bytes) {}
  void clear() {}
}
