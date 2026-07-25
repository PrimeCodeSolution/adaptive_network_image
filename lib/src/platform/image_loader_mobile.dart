import 'dart:async';

import 'package:flutter/widgets.dart';

import '../adaptive_network_image_config.dart';
import '../strategies/load_strategy.dart';

class PlatformImageLoader {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  Timer? _timer;
  Completer<void>? _completer;

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
    bool preventNativeInteraction = true,
    Duration loadTimeout = kDefaultLoadTimeout,
  }) async {
    // Web-only knobs are intentionally ignored on IO platforms. CORS is not a
    // concern, and browser interaction controls do not apply.
    final provider = NetworkImage(url, headers: headers);
    final configuration = ImageConfiguration(
      size: (width != null && height != null) ? Size(width, height) : null,
    );
    final stream = provider.resolve(configuration);
    final completer = Completer<void>();
    _stream = stream;
    _completer = completer;

    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        info.dispose();
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      onError: (Object error, StackTrace? stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
    );
    _listener = listener;

    stream.addListener(listener);
    _timer = Timer(loadTimeout, () {
      if (!completer.isCompleted) {
        completer.completeError(
          TimeoutException('Timed out loading image: $url', loadTimeout),
        );
      }
    });

    try {
      await completer.future;
    } finally {
      _cleanup();
    }

    return Image(
      image: provider,
      width: width,
      height: height,
      fit: fit,
    );
  }

  void _cleanup() {
    final stream = _stream;
    final listener = _listener;
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
    _timer?.cancel();
    _timer = null;
    _stream = null;
    _listener = null;
    _completer = null;
  }

  void dispose() {
    final completer = _completer;
    _cleanup();
    if (completer != null && !completer.isCompleted) {
      completer.completeError(
        StateError('Image load cancelled'),
        StackTrace.current,
      );
    }
  }
}
