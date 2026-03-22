import 'dart:typed_data';

import '../adaptive_network_image_config.dart';

class ImageCacheManager {
  static final ImageCacheManager instance = ImageCacheManager._();
  ImageCacheManager._();

  ImageLoadStrategy? getStrategy(String url) => throw UnimplementedError();
  void putStrategy(String url, ImageLoadStrategy strategy) =>
      throw UnimplementedError();
  Uint8List? getBytes(String url) => throw UnimplementedError();
  void putBytes(String url, Uint8List bytes) => throw UnimplementedError();
  void clear() => throw UnimplementedError();
}
