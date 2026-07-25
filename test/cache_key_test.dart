import 'package:adaptive_network_image/src/cache/cache_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildImageCacheKey', () {
    test('returns URL when no proxy or headers are provided', () {
      expect(
        buildImageCacheKey('https://example.com/a.png'),
        'https://example.com/a.png',
      );
    });

    test('includes proxy URL', () {
      expect(
        buildImageCacheKey(
          'https://example.com/a.png',
          corsProxyUrl: 'https://proxy.test/?u=',
        ),
        'https://example.com/a.png|proxy=https://proxy.test/?u=',
      );
    });

    test('includes sorted headers so key order is stable', () {
      final keyA = buildImageCacheKey(
        'https://example.com/a.png',
        headers: {
          'Authorization': 'Bearer a',
          'Accept': 'image/png',
        },
      );
      final keyB = buildImageCacheKey(
        'https://example.com/a.png',
        headers: {
          'Accept': 'image/png',
          'Authorization': 'Bearer a',
        },
      );

      expect(keyA, keyB);
      expect(keyA, contains('Accept=image/png'));
      expect(keyA, contains('Authorization=Bearer a'));
    });

    test('different headers produce different keys', () {
      final keyA = buildImageCacheKey(
        'https://example.com/a.png',
        headers: {'Authorization': 'Bearer a'},
      );
      final keyB = buildImageCacheKey(
        'https://example.com/a.png',
        headers: {'Authorization': 'Bearer b'},
      );

      expect(keyA, isNot(equals(keyB)));
    });
  });
}
