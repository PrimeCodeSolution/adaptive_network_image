import 'dart:typed_data';

import 'package:adaptive_network_image/src/adaptive_network_image_config.dart';
import 'package:adaptive_network_image/src/cache/image_cache_manager.dart';
import 'package:adaptive_network_image/src/platform/image_loader.dart';
import 'package:adaptive_network_image/src/strategies/cors_proxy_strategy.dart';
import 'package:adaptive_network_image/src/strategies/direct_img_strategy.dart';
import 'package:adaptive_network_image/src/strategies/iframe_strategy.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('conditional exports select the web loader and cache', () async {
    final loader = PlatformImageLoader();
    addTearDown(loader.dispose);

    await expectLater(
      loader.load(
        url: 'not-an-http-url',
        width: null,
        height: null,
        fit: BoxFit.cover,
      ),
      throwsArgumentError,
    );

    final cache = ImageCacheManager.instance;
    addTearDown(cache.clear);
    cache.clear();
    cache.putStrategy('https://example.com/image.png', ImageLoadStrategy.iframe);
    cache.putBytes(
      'https://example.com/image.png',
      Uint8List.fromList(<int>[1, 2, 3]),
    );

    expect(
      cache.getStrategy('https://example.com/image.png'),
      ImageLoadStrategy.iframe,
    );
    expect(cache.getBytes('https://example.com/image.png'), <int>[1, 2, 3]);
  });

  test('all web strategies can be constructed and disposed', () {
    final strategies = [
      DirectImgStrategy(),
      CorsProxyStrategy(),
      IframeStrategy(),
    ];

    for (final strategy in strategies) {
      expect(strategy.dispose, returnsNormally);
    }
  });
}
