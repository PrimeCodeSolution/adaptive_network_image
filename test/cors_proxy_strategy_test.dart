import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:adaptive_network_image/src/strategies/cors_proxy_strategy.dart';
import 'package:adaptive_network_image/src/strategies/load_strategy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('CorsProxyStrategy', () {
    test('returns StrategyFailure when corsProxyUrl is null', () async {
      final strategy = CorsProxyStrategy(client: MockClient((_) async {
        return http.Response('', 200);
      }));

      final result = await strategy.load(
        url: 'https://example.com/img.png',
        width: null,
        height: null,
        fit: BoxFit.cover,
        corsProxyUrl: null,
      );

      expect(result, isA<StrategyFailure>());
      expect(
        (result as StrategyFailure).reason,
        contains('No CORS proxy URL configured'),
      );
    });

    test('returns StrategySuccess on 200 with image content-type', () async {
      final mockClient = MockClient((request) async {
        return http.Response.bytes(
          [0x89, 0x50, 0x4E, 0x47], // PNG magic bytes
          200,
          headers: {'content-type': 'image/png'},
        );
      });

      final strategy = CorsProxyStrategy(client: mockClient);
      final result = await strategy.load(
        url: 'https://example.com/img.png',
        width: null,
        height: null,
        fit: BoxFit.cover,
        corsProxyUrl: 'https://proxy.example.com/?url=',
      );

      expect(result, isA<StrategySuccess>());
      final success = result as StrategySuccess;
      expect(success.imageBytes, isNotNull);
      expect(success.imageBytes!.length, 4);
    });

    test('returns StrategyFailure on non-200 status', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final strategy = CorsProxyStrategy(client: mockClient);
      final result = await strategy.load(
        url: 'https://example.com/img.png',
        width: null,
        height: null,
        fit: BoxFit.cover,
        corsProxyUrl: 'https://proxy.example.com/?url=',
      );

      expect(result, isA<StrategyFailure>());
      expect(
        (result as StrategyFailure).reason,
        contains('status 404'),
      );
    });

    test('returns StrategyFailure on non-image content-type', () async {
      final mockClient = MockClient((request) async {
        return http.Response.bytes(
          [0x3C, 0x68, 0x74, 0x6D, 0x6C], // "<html"
          200,
          headers: {'content-type': 'text/html'},
        );
      });

      final strategy = CorsProxyStrategy(client: mockClient);
      final result = await strategy.load(
        url: 'https://example.com/img.png',
        width: null,
        height: null,
        fit: BoxFit.cover,
        corsProxyUrl: 'https://proxy.example.com/?url=',
      );

      expect(result, isA<StrategyFailure>());
      expect(
        (result as StrategyFailure).reason,
        contains('non-image content-type'),
      );
    });

    test('returns StrategyFailure on timeout', () async {
      final mockClient = MockClient((request) {
        throw TimeoutException('Connection timed out');
      });

      final strategy = CorsProxyStrategy(client: mockClient);
      final result = await strategy.load(
        url: 'https://example.com/img.png',
        width: null,
        height: null,
        fit: BoxFit.cover,
        corsProxyUrl: 'https://proxy.example.com/?url=',
      );

      expect(result, isA<StrategyFailure>());
    });

    test('returns StrategyFailure on network error', () async {
      final mockClient = MockClient((request) {
        throw http.ClientException('Connection refused');
      });

      final strategy = CorsProxyStrategy(client: mockClient);
      final result = await strategy.load(
        url: 'https://example.com/img.png',
        width: null,
        height: null,
        fit: BoxFit.cover,
        corsProxyUrl: 'https://proxy.example.com/?url=',
      );

      expect(result, isA<StrategyFailure>());
      expect(
        (result as StrategyFailure).reason,
        contains('CORS proxy fetch failed'),
      );
    });

    test('constructs correct proxy URL with encoded image URL', () async {
      Uri? capturedUri;
      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        return http.Response.bytes(
          [0x89, 0x50, 0x4E, 0x47],
          200,
          headers: {'content-type': 'image/png'},
        );
      });

      final strategy = CorsProxyStrategy(client: mockClient);
      await strategy.load(
        url: 'https://example.com/img.png?size=large',
        width: null,
        height: null,
        fit: BoxFit.cover,
        corsProxyUrl: 'https://proxy.example.com/?url=',
      );

      expect(capturedUri, isNotNull);
      expect(
        capturedUri.toString(),
        contains(Uri.encodeComponent('https://example.com/img.png?size=large')),
      );
    });

    test('returns StrategyFailure on empty response body', () async {
      final mockClient = MockClient((request) async {
        return http.Response.bytes(
          [], // empty body
          200,
          headers: {'content-type': 'image/png'},
        );
      });

      final strategy = CorsProxyStrategy(client: mockClient);
      final result = await strategy.load(
        url: 'https://example.com/img.png',
        width: null,
        height: null,
        fit: BoxFit.cover,
        corsProxyUrl: 'https://proxy.example.com/?url=',
      );

      // Empty body with 200 status still fails because bodyBytes.isNotEmpty is false.
      expect(result, isA<StrategyFailure>());
      expect(
        (result as StrategyFailure).reason,
        contains('status 200'),
      );
    });
  });
}
