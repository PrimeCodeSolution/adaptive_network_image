import 'package:flutter/widgets.dart';
import 'package:adaptive_network_image/src/platform/image_loader_mobile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlatformImageLoader (mobile)', () {
    late PlatformImageLoader loader;

    setUp(() {
      loader = PlatformImageLoader();
    });

    test('load returns an Image.network widget', () async {
      final widget = await loader.load(
        url: 'https://example.com/img.png',
        width: 300,
        height: 200,
        fit: BoxFit.cover,
      );

      expect(widget, isA<Image>());
      final image = widget as Image;
      expect(image.width, 300);
      expect(image.height, 200);
      expect(image.fit, BoxFit.cover);
    });

    test('load passes headers through', () async {
      final headers = {'Authorization': 'Bearer token'};
      final widget = await loader.load(
        url: 'https://example.com/img.png',
        width: null,
        height: null,
        fit: BoxFit.contain,
        headers: headers,
      );

      expect(widget, isA<Image>());
    });

    test('load works with null dimensions', () async {
      final widget = await loader.load(
        url: 'https://example.com/img.png',
        width: null,
        height: null,
        fit: BoxFit.fill,
      );

      expect(widget, isA<Image>());
      final image = widget as Image;
      expect(image.width, isNull);
      expect(image.height, isNull);
    });

    test('dispose does not throw', () {
      expect(() => loader.dispose(), returnsNormally);
    });
  });
}
