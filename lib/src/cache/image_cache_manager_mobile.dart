import 'dart:typed_data';

import '../adaptive_network_image_config.dart';

/// No-op passthrough on mobile — CORS is not a concern.
class ImageCacheManager {
  static final ImageCacheManager instance = ImageCacheManager._();
  ImageCacheManager._();

  ImageLoadStrategy? getStrategy(String url) => null;
  void putStrategy(String url, ImageLoadStrategy strategy) {}
  Uint8List? getBytes(String url) => null;
  void putBytes(String url, Uint8List bytes) {}
  void clear() {}
}
