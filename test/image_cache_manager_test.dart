import 'dart:typed_data';

import 'package:adaptive_network_image/src/cache/image_cache_manager_web.dart';
import 'package:adaptive_network_image/src/adaptive_network_image_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ImageCacheManager cache;

  setUp(() {
    cache = ImageCacheManager.instance;
    cache.clear();
  });

  tearDown(() {
    cache.clear();
  });

  group('ImageCacheManager', () {
    group('strategy cache', () {
      test('get returns null for unknown URL', () {
        expect(cache.getStrategy('https://example.com/img.png'), isNull);
      });

      test('put/get roundtrip returns cached strategy', () {
        cache.putStrategy(
          'https://example.com/img.png',
          ImageLoadStrategy.corsProxy,
        );

        expect(
          cache.getStrategy('https://example.com/img.png'),
          ImageLoadStrategy.corsProxy,
        );
      });

      test('put overwrites previous strategy', () {
        cache.putStrategy(
          'https://example.com/img.png',
          ImageLoadStrategy.directImg,
        );
        cache.putStrategy(
          'https://example.com/img.png',
          ImageLoadStrategy.iframe,
        );

        expect(
          cache.getStrategy('https://example.com/img.png'),
          ImageLoadStrategy.iframe,
        );
      });
    });

    group('bytes cache', () {
      test('get returns null for unknown URL', () {
        expect(cache.getBytes('https://example.com/img.png'), isNull);
      });

      test('put/get roundtrip returns cached bytes', () {
        final bytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);
        cache.putBytes('https://example.com/img.png', bytes);

        final result = cache.getBytes('https://example.com/img.png');
        expect(result, isNotNull);
        expect(result, bytes);
      });

      test('put overwrites previous bytes', () {
        final bytes1 = Uint8List.fromList([1, 2, 3]);
        final bytes2 = Uint8List.fromList([4, 5, 6, 7]);
        cache.putBytes('https://example.com/img.png', bytes1);
        cache.putBytes('https://example.com/img.png', bytes2);

        final result = cache.getBytes('https://example.com/img.png');
        expect(result, bytes2);
      });
    });

    group('LRU eviction at entry limit', () {
      test('evicts oldest entries when exceeding 100 entries', () {
        // Fill cache to 100 entries.
        for (var i = 0; i < 100; i++) {
          cache.putBytes(
            'https://example.com/img_$i.png',
            Uint8List.fromList([i]),
          );
        }

        // All 100 should be present.
        expect(
          cache.getBytes('https://example.com/img_0.png'),
          isNotNull,
        );
        expect(
          cache.getBytes('https://example.com/img_99.png'),
          isNotNull,
        );

        // Adding entry 101 should evict the oldest (img_0, but it was
        // just accessed by getBytes above, so it moved to end).
        // The oldest now is img_1.
        cache.putBytes(
          'https://example.com/img_100.png',
          Uint8List.fromList([100]),
        );

        // img_1 (oldest after img_0 was refreshed) should be evicted.
        expect(
          cache.getBytes('https://example.com/img_1.png'),
          isNull,
        );

        // img_0 should still be present (was refreshed by getBytes).
        expect(
          cache.getBytes('https://example.com/img_0.png'),
          isNotNull,
        );

        // Newly added entry should be present.
        expect(
          cache.getBytes('https://example.com/img_100.png'),
          isNotNull,
        );
      });
    });

    group('byte-based eviction', () {
      test('evicts oldest entries when exceeding maxCacheBytes', () {
        // maxCacheBytes is 50 * 1024 * 1024 = 52428800.
        final maxBytes = ImageCacheManager.maxCacheBytes;
        expect(maxBytes, 50 * 1024 * 1024);

        // Insert a large chunk that is just under half the limit.
        final halfLimit = maxBytes ~/ 2;
        final largeBytes1 = Uint8List(halfLimit);
        final largeBytes2 = Uint8List(halfLimit);
        final overflow = Uint8List(halfLimit);

        cache.putBytes('https://example.com/first.png', largeBytes1);
        cache.putBytes('https://example.com/second.png', largeBytes2);

        // Both should be present (total == maxBytes).
        expect(cache.getBytes('https://example.com/first.png'), isNotNull);
        expect(cache.getBytes('https://example.com/second.png'), isNotNull);

        // Adding another large entry should trigger eviction.
        // After accessing first and second above, the order is:
        // second (refreshed last by getBytes), first (refreshed before second).
        // Actually: getBytes('first') moves first to end, then getBytes('second')
        // moves second to end. So order is: first, second.
        // Adding overflow will evict from the front until under limit.
        cache.putBytes('https://example.com/third.png', overflow);

        // first should be evicted (it was oldest after the getBytes calls
        // reordered things — wait, let's think again:
        // After putBytes('first'), putBytes('second'): order = [first, second]
        // getBytes('first') -> remove+reinsert: order = [second, first]
        // getBytes('second') -> remove+reinsert: order = [first, second]
        // putBytes('third'): total would be halfLimit*3 > maxBytes.
        // Evicts from front: evicts 'first', total = halfLimit*2 still > maxBytes
        // if halfLimit*2 > maxBytes... halfLimit = maxBytes/2, so halfLimit*2 = maxBytes.
        // maxBytes is NOT > maxBytes, so eviction stops.
        // Actually: first was evicted, leaving second + third = halfLimit * 2 = maxBytes.
        // That equals the limit, not exceeds it, so no more eviction.
        expect(cache.getBytes('https://example.com/first.png'), isNull);
        expect(cache.getBytes('https://example.com/second.png'), isNotNull);
        expect(cache.getBytes('https://example.com/third.png'), isNotNull);
      });
    });

    group('clear', () {
      test('empties both caches and resets byte count', () {
        cache.putStrategy(
          'https://example.com/img.png',
          ImageLoadStrategy.directImg,
        );
        cache.putBytes(
          'https://example.com/img.png',
          Uint8List.fromList([1, 2, 3]),
        );

        cache.clear();

        expect(cache.getStrategy('https://example.com/img.png'), isNull);
        expect(cache.getBytes('https://example.com/img.png'), isNull);

        // After clearing, we should be able to add new entries without
        // premature eviction (byte count was reset).
        final largeBytes = Uint8List(ImageCacheManager.maxCacheBytes ~/ 2);
        cache.putBytes('https://example.com/a.png', largeBytes);
        cache.putBytes('https://example.com/b.png', largeBytes);

        // Both should fit (total == maxCacheBytes).
        expect(cache.getBytes('https://example.com/a.png'), isNotNull);
        expect(cache.getBytes('https://example.com/b.png'), isNotNull);
      });
    });

    group('LRU reordering on access', () {
      test('getBytes refreshes position so entry is not evicted', () {
        // Fill cache to 100 entries.
        for (var i = 0; i < 100; i++) {
          cache.putBytes(
            'https://example.com/img_$i.png',
            Uint8List.fromList([i]),
          );
        }

        // Access the very first entry, moving it to the end.
        final refreshed = cache.getBytes('https://example.com/img_0.png');
        expect(refreshed, isNotNull);

        // Add two more entries to trigger evictions.
        cache.putBytes(
          'https://example.com/img_100.png',
          Uint8List.fromList([100]),
        );
        cache.putBytes(
          'https://example.com/img_101.png',
          Uint8List.fromList([101]),
        );

        // img_0 should survive because it was refreshed.
        expect(cache.getBytes('https://example.com/img_0.png'), isNotNull);

        // img_1 and img_2 should be evicted (they were the oldest).
        expect(cache.getBytes('https://example.com/img_1.png'), isNull);
        expect(cache.getBytes('https://example.com/img_2.png'), isNull);
      });
    });
  });
}
