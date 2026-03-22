import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../adaptive_network_image_config.dart';
import 'load_strategy.dart';

/// Strategy 2: Fetch image bytes through a CORS proxy, then display via Image.memory.
///
/// Skipped if no corsProxyUrl is provided. Produces Image.memory — no platform
/// view overhead, best for image lists.
class CorsProxyStrategy extends LoadStrategy {
  final http.Client _client;

  CorsProxyStrategy({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<StrategyResult> load({
    required String url,
    required double? width,
    required double? height,
    required BoxFit fit,
    Map<String, String>? headers,
    String? corsProxyUrl,
    bool preventNativeInteraction = true,
  }) async {
    if (corsProxyUrl == null) {
      adaptiveImageLog('[CorsProxyStrategy] No proxy URL configured — skipping.');
      return StrategyFailure('No CORS proxy URL configured — skipping.');
    }

    adaptiveImageLog('[CorsProxyStrategy] Attempting to fetch: $url');

    try {
      final proxyUrl = '$corsProxyUrl${Uri.encodeComponent(url)}';
      final response = await _client.get(
        Uri.parse(proxyUrl),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final contentType = response.headers['content-type'] ?? '';
        if (!contentType.startsWith('image/')) {
          adaptiveImageLog(
            '[CorsProxyStrategy] Non-image content-type: $contentType',
          );
          return StrategyFailure(
            'CORS proxy returned non-image content-type "$contentType" for: $url',
          );
        }
        adaptiveImageLog(
          '[CorsProxyStrategy] Success: ${response.bodyBytes.length} bytes',
        );
        return StrategySuccess(imageBytes: response.bodyBytes);
      }

      adaptiveImageLog(
        '[CorsProxyStrategy] Failed with status ${response.statusCode}',
      );
      return StrategyFailure(
        'CORS proxy returned status ${response.statusCode} for: $url',
      );
    } on TimeoutException {
      adaptiveImageLog('[CorsProxyStrategy] Timeout fetching: $url');
      return StrategyFailure('CORS proxy request timed out for: $url');
    } catch (e) {
      adaptiveImageLog('[CorsProxyStrategy] Error: $e');
      return StrategyFailure('CORS proxy fetch failed: $e');
    }
  }
}
