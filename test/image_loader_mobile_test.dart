import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:adaptive_network_image/src/platform/image_loader_mobile.dart';
import 'package:flutter_test/flutter_test.dart';

/// 1x1 transparent PNG.
final Uint8List _kTransparentPng = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeHttpClient httpClient;
  late PlatformImageLoader loader;

  setUp(() {
    httpClient = _FakeHttpClient()..responseBytes = _kTransparentPng;
    debugNetworkImageHttpClientProvider = () => httpClient;
    loader = PlatformImageLoader();
  });

  tearDown(() {
    loader.dispose();
    debugNetworkImageHttpClientProvider = null;
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  group('PlatformImageLoader (mobile)', () {
    test('load returns an Image after the first frame is available', () async {
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
      expect(image.image, isA<NetworkImage>());
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
      final image = widget as Image;
      expect((image.image as NetworkImage).headers, headers);
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

    test('dispose cancels an in-flight load', () async {
      httpClient.delay = const Duration(days: 1);
      final pending = loader.load(
        url: 'https://example.com/slow.png',
        width: null,
        height: null,
        fit: BoxFit.cover,
        loadTimeout: const Duration(days: 1),
      );

      // Allow the request to start.
      await Future<void>.delayed(Duration.zero);
      loader.dispose();

      await expectLater(pending, throwsA(isA<StateError>()));
    });

    test('dispose does not throw when idle', () {
      expect(() => loader.dispose(), returnsNormally);
    });
  }, skip: kIsWeb);
}

class _FakeHttpClient extends Fake implements HttpClient {
  Uint8List responseBytes = Uint8List(0);
  Duration delay = Duration.zero;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return _FakeHttpClientRequest(responseBytes);
  }
}

class _FakeHttpClientRequest extends Fake implements HttpClientRequest {
  _FakeHttpClientRequest(this._bytes);

  final Uint8List _bytes;
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse(_bytes);
}

class _FakeHttpHeaders extends Fake implements HttpHeaders {
  final Map<String, List<String>> _values = <String, List<String>>{};

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _values[name] = <String>[value.toString()];
  }

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    (_values[name] ??= <String>[]).add(value.toString());
  }
}

class _FakeHttpClientResponse extends Fake implements HttpClientResponse {
  _FakeHttpClientResponse(this._bytes);

  final Uint8List _bytes;

  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _bytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable(<List<int>>[_bytes]).listen(
      onData,
      onDone: onDone,
      onError: onError,
      cancelOnError: cancelOnError,
    );
  }
}
