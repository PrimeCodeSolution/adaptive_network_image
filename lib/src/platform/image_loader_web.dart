import 'package:flutter/widgets.dart';

import '../adaptive_network_image_config.dart';
import '../cache/image_cache_manager.dart';
import '../strategies/cors_proxy_strategy.dart';
import '../strategies/direct_img_strategy.dart';
import '../strategies/iframe_strategy.dart';
import '../strategies/load_strategy.dart';

class PlatformImageLoader {
  final Map<ImageLoadStrategy, LoadStrategy> _strategies = {
    ImageLoadStrategy.directImg: DirectImgStrategy(),
    ImageLoadStrategy.corsProxy: CorsProxyStrategy(),
    ImageLoadStrategy.iframe: IframeStrategy(),
  };

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
  }) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw ArgumentError(
        'Invalid image URL: "$url". Must be an http or https URL.',
      );
    }

    final cache = ImageCacheManager.instance;
    final strategyOrder = strategies ?? ImageLoadStrategy.values.toList();

    adaptiveImageLog('[WebImageLoader] Loading: $url');
    adaptiveImageLog(
      '[WebImageLoader] Strategy order: '
      "${strategyOrder.map((s) => s.name).join(', ')}",
    );

    // Check cache for known-working strategy.
    if (enableCache) {
      final cachedStrategy = cache.getStrategy(url);
      if (cachedStrategy != null && strategyOrder.contains(cachedStrategy)) {
        adaptiveImageLog(
          '[WebImageLoader] Cache hit — using ${cachedStrategy.name}',
        );

        // Check bytes cache for proxy strategy.
        if (cachedStrategy == ImageLoadStrategy.corsProxy) {
          final cachedBytes = cache.getBytes(url);
          if (cachedBytes != null) {
            adaptiveImageLog(
              '[WebImageLoader] Bytes cache hit — ${cachedBytes.length} bytes',
            );
            onStrategyResolved?.call(cachedStrategy);
            return Image.memory(
              cachedBytes,
              width: width,
              height: height,
              fit: fit,
            );
          }
        }

        // Try the cached strategy directly.
        final impl = _strategies[cachedStrategy]!;
        final result = await impl.load(
          url: url,
          width: width,
          height: height,
          fit: fit,
          headers: headers,
          corsProxyUrl: corsProxyUrl,
          preventNativeInteraction: preventNativeInteraction,
        );
        if (result is StrategySuccess) {
          onStrategyResolved?.call(cachedStrategy);
          return _buildFromResult(result, width, height, fit);
        }
        adaptiveImageLog(
          '[WebImageLoader] Cached strategy failed — falling through to cascade',
        );
      }
    }

    // Cascade through strategies.
    final errors = <String>[];
    for (final strategyEnum in strategyOrder) {
      final impl = _strategies[strategyEnum];
      if (impl == null) continue;

      adaptiveImageLog(
        '[WebImageLoader] Trying strategy: ${strategyEnum.name}',
      );

      final result = await impl.load(
        url: url,
        width: width,
        height: height,
        fit: fit,
        headers: headers,
        corsProxyUrl: corsProxyUrl,
        preventNativeInteraction: preventNativeInteraction,
      );

      if (result is StrategySuccess) {
        adaptiveImageLog(
          '[WebImageLoader] Strategy ${strategyEnum.name} succeeded',
        );
        if (enableCache) {
          cache.putStrategy(url, strategyEnum);
          if (result.imageBytes != null) {
            cache.putBytes(url, result.imageBytes!);
          }
        }
        onStrategyResolved?.call(strategyEnum);
        return _buildFromResult(result, width, height, fit);
      }

      if (result is StrategyFailure) {
        adaptiveImageLog(
          '[WebImageLoader] Strategy ${strategyEnum.name} failed: '
          '${result.reason}',
        );
        errors.add('${strategyEnum.name}: ${result.reason}');
      }
    }

    final errorMsg =
        'All image load strategies failed for "$url":\n${errors.join('\n')}';
    adaptiveImageLog('[WebImageLoader] $errorMsg');
    throw Exception(errorMsg);
  }

  Widget _buildFromResult(
    StrategySuccess result,
    double? width,
    double? height,
    BoxFit fit,
  ) {
    if (result.widget != null) {
      return SizedPlatformView(
        intrinsicSize: result.intrinsicSize,
        child: result.widget!,
      );
    }
    if (result.imageBytes != null) {
      return Image.memory(
        result.imageBytes!,
        width: width,
        height: height,
        fit: fit,
      );
    }
    throw StateError('StrategySuccess had neither widget nor imageBytes');
  }

  void dispose() {
    for (final strategy in _strategies.values) {
      strategy.dispose();
    }
  }
}

/// Gives a platform view a definite size under any incoming constraints.
///
/// [HtmlElementView] has no intrinsic size and sizes itself to
/// `constraints.biggest`, so an unbounded axis makes it infinitely large and
/// the render pass throws. That happens in ordinary layouts such as a
/// [ListView] or an unconstrained [Column], where height is unbounded.
@visibleForTesting
class SizedPlatformView extends StatelessWidget {
  const SizedPlatformView({
    required this.intrinsicSize,
    required this.child,
    super.key,
  });

  /// The image's natural size, when the strategy could report it.
  final Size? intrinsicSize;

  final Widget child;

  /// Last resort when both axes are unbounded and the natural size is unknown.
  /// Arbitrary, but visible and finite, which beats throwing.
  static const Size _fallbackSize = Size.square(300);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The parent pins both axes, so filling it is safe and preserves the
        // behaviour of an explicitly sized AdaptiveNetworkImage.
        if (constraints.hasBoundedWidth && constraints.hasBoundedHeight) {
          return SizedBox.expand(child: child);
        }

        // Exactly one axis is unbounded. Derive it from the image's shape, the
        // way Image.network would.
        if (constraints.hasBoundedWidth || constraints.hasBoundedHeight) {
          return AspectRatio(aspectRatio: _aspectRatio, child: child);
        }

        // Neither axis is bounded, so nothing can be derived from the parent.
        final size = intrinsicSize ?? _fallbackSize;
        return SizedBox(width: size.width, height: size.height, child: child);
      },
    );
  }

  double get _aspectRatio {
    final size = intrinsicSize;
    if (size == null || size.width <= 0 || size.height <= 0) return 1;
    return size.width / size.height;
  }
}
