import 'package:flutter/material.dart';

import 'cache/image_cache_manager.dart';
import 'platform/image_loader.dart';
import 'adaptive_network_image_config.dart';

/// A widget that displays an image from an external URL, handling CORS
/// restrictions on Flutter Web via a multi-strategy fallback approach.
///
/// On non-web platforms, this simply wraps [Image.network].
class AdaptiveNetworkImage extends StatefulWidget {
  /// The URL of the image to display.
  final String imageUrl;

  /// Optional fixed width.
  final double? width;

  /// Optional fixed height.
  final double? height;

  /// How the image should fit within its bounds.
  final BoxFit fit;

  /// Builder for a placeholder widget shown while loading.
  final WidgetBuilder? placeholder;

  /// Builder for an error widget shown when all strategies fail.
  final AdaptiveImageErrorBuilder? errorWidget;

  /// Duration of the fade-in animation when the image loads.
  final Duration fadeInDuration;

  /// Curve of the fade-in animation.
  final Curve fadeInCurve;

  /// Optional border radius for clipping.
  final BorderRadius? borderRadius;

  /// Optional HTTP headers for image requests.
  final Map<String, String>? headers;

  /// Optional CORS proxy URL. The image URL will be appended (encoded).
  /// Required for [ImageLoadStrategy.corsProxy] to work.
  final String? corsProxyUrl;

  /// Optional tap callback.
  final VoidCallback? onTap;

  /// Whether to cache strategy resolution and image bytes.
  final bool enableCache;

  /// Ordered list of strategies to attempt. Defaults to all strategies.
  final List<ImageLoadStrategy>? strategies;

  /// Callback invoked when a strategy successfully resolves.
  final ImageLoadCallback? onStrategyResolved;

  /// Whether to prevent native browser interactions (drag, right-click) on web.
  /// Defaults to `true`.
  final bool preventNativeInteraction;

  /// Clears the image strategy and bytes cache.
  static void clearCache() => ImageCacheManager.instance.clear();

  const AdaptiveNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.fadeInCurve = Curves.easeIn,
    this.borderRadius,
    this.headers,
    this.corsProxyUrl,
    this.onTap,
    this.enableCache = true,
    this.strategies,
    this.onStrategyResolved,
    this.preventNativeInteraction = true,
  });

  @override
  State<AdaptiveNetworkImage> createState() => _AdaptiveNetworkImageState();
}

class _AdaptiveNetworkImageState extends State<AdaptiveNetworkImage> {
  late Future<Widget> _imageFuture;
  late PlatformImageLoader _loader;
  int _generation = 0;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _loader = PlatformImageLoader();
    _imageFuture = _loadImage();
  }

  @override
  void didUpdateWidget(AdaptiveNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.corsProxyUrl != widget.corsProxyUrl ||
        oldWidget.fit != widget.fit) {
      _loader.dispose();
      _loader = PlatformImageLoader();
      _imageFuture = _loadImage();
    }
  }

  Future<Widget> _loadImage() {
    final gen = ++_generation;
    return _loader.load(
      url: widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      headers: widget.headers,
      corsProxyUrl: widget.corsProxyUrl,
      enableCache: widget.enableCache,
      strategies: widget.strategies,
      preventNativeInteraction: widget.preventNativeInteraction,
      onStrategyResolved: (strategy) {
        if (gen == _generation && !_disposed) {
          widget.onStrategyResolved?.call(strategy);
        }
      },
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = FutureBuilder<Widget>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return _buildError(context, snapshot.error!);
          }
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: widget.fadeInDuration,
            curve: widget.fadeInCurve,
            builder: (_, value, child) => Opacity(opacity: value, child: child),
            child: snapshot.data!,
          );
        }
        return _buildPlaceholder(context);
      },
    );

    if (widget.width != null || widget.height != null) {
      child = SizedBox(
        width: widget.width,
        height: widget.height,
        child: child,
      );
    }

    if (widget.borderRadius != null) {
      child = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: child,
      );
    }

    if (widget.onTap != null) {
      child = GestureDetector(
        onTap: widget.onTap,
        child: child,
      );
    }

    return child;
  }

  Widget _buildPlaceholder(BuildContext context) {
    if (widget.placeholder != null) {
      return widget.placeholder!(context);
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError(BuildContext context, Object error) {
    if (widget.errorWidget != null) {
      return widget.errorWidget!(context, error);
    }
    return const Center(
      child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
    );
  }
}
