import 'dart:typed_data';

import '../adaptive_network_image_config.dart';

class ImageCacheManager {
  static final ImageCacheManager instance = ImageCacheManager._();
  ImageCacheManager._();

  ImageLoadStrategy? getStrategy(String key) => throw UnimplementedError();
  void putStrategy(String key, ImageLoadStrategy strategy) =>
      throw UnimplementedError();
  void removeStrategy(String key) => throw UnimplementedError();
  Uint8List? getBytes(String key) => throw UnimplementedError();
  void putBytes(String key, Uint8List bytes) => throw UnimplementedError();
  void clear() => throw UnimplementedError();
}
