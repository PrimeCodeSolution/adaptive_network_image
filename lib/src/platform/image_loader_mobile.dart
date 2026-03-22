import 'package:flutter/widgets.dart';

import '../adaptive_network_image_config.dart';

class PlatformImageLoader {
  Future<Widget> load({
    required String url,
    required double? width,
    required double? height,
    required BoxFit fit,
    Map<String, String>? headers,
    String? corsProxyUrl,
    bool enableCache = true,
    List<ImageLoadStrategy>? strategies,
    ImageLoadCallback? onStrategyResolved,
  }) async {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      headers: headers,
    );
  }

  void dispose() {}
}
