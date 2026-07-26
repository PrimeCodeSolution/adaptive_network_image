import 'dart:typed_data';

import 'package:flutter/widgets.dart';

/// Default timeout used by image load strategies.
const Duration kDefaultLoadTimeout = Duration(seconds: 15);

/// Result of attempting to load an image via a strategy.
sealed class StrategyResult {}

/// The strategy succeeded.
class StrategySuccess extends StrategyResult {
  /// A ready-to-display widget (used by directImg and iframe strategies).
  final Widget? widget;

  /// Raw image bytes (used by corsProxy strategy).
  final Uint8List? imageBytes;

  /// The image's natural pixel size, when the strategy could determine it.
  ///
  /// Platform views have no intrinsic size of their own, so this is what lets
  /// [widget] be laid out under unbounded constraints.
  final Size? intrinsicSize;

  StrategySuccess({this.widget, this.imageBytes, this.intrinsicSize});
}

/// The strategy failed and the cascade should continue.
class StrategyFailure extends StrategyResult {
  final String reason;

  StrategyFailure(this.reason);
}

/// Abstract interface for an image loading strategy.
abstract class LoadStrategy {
  /// Attempt to load the image at [url].
  ///
  /// Returns [StrategySuccess] if the image was loaded, or
  /// [StrategyFailure] if this strategy cannot handle the image.
  ///
  /// [headers] are only honored by strategies that perform an HTTP fetch
  /// (currently [corsProxy]). HTML `<img>` / iframe strategies ignore them.
  Future<StrategyResult> load({
    required String url,
    required double? width,
    required double? height,
    required BoxFit fit,
    Map<String, String>? headers,
    String? corsProxyUrl,
    bool preventNativeInteraction = true,
    Duration timeout = kDefaultLoadTimeout,
  });

  /// Dispose any resources held by this strategy.
  void dispose() {}
}
