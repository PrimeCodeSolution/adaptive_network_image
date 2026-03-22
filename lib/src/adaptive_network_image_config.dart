import 'package:flutter/widgets.dart';

/// The strategy used to load an image on web.
enum ImageLoadStrategy {
  /// Use an HTML `<img>` element via HtmlElementView.
  /// Lightest approach — works for most images without CORS headers.
  directImg,

  /// Fetch the image bytes through a CORS proxy, then display via Image.memory.
  /// Skipped if no corsProxyUrl is provided.
  corsProxy,

  /// Render the image inside a minimal sandboxed iframe.
  /// Last resort — heaviest approach but most compatible.
  iframe,
}

/// Builder for an error widget shown when all strategies fail.
typedef AdaptiveImageErrorBuilder = Widget Function(
  BuildContext context,
  Object error,
);

/// Callback invoked when a strategy successfully loads the image.
typedef ImageLoadCallback = void Function(ImageLoadStrategy strategy);

/// Whether to print debug logs from adaptive_network_image.
///
/// Set to `true` to enable logging for debugging CORS issues.
/// Defaults to `false` for production use.
bool adaptiveImageLogging = false;

/// Logs a message if [adaptiveImageLogging] is enabled.
void adaptiveImageLog(String message) {
  if (adaptiveImageLogging) {
    debugPrint(message);
  }
}
