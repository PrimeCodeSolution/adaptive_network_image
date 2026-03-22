# adaptive_network_image

A Flutter widget that displays images from external URLs on the web, handling CORS restrictions with a multi-strategy fallback approach. On mobile and desktop, it falls back to `Image.network`.

## How It Works

`AdaptiveNetworkImage` tries up to three strategies in order until one succeeds:

1. **directImg** -- Renders an HTML `<img>` element via `HtmlElementView`. Lightest approach; works when the server sends appropriate CORS headers.
2. **corsProxy** -- Fetches image bytes through a CORS proxy, then displays via `Image.memory`. Requires a `corsProxyUrl` to be provided. Skipped otherwise.
3. **iframe** -- Renders the image inside a sandboxed `<iframe>` with no inline scripts. Heaviest approach but most compatible.

The first strategy that loads successfully is used. Resolved strategies are cached so subsequent renders skip straight to what worked.

## Quick Start

```sh
flutter pub add adaptive_network_image
```

```dart
import 'package:adaptive_network_image/adaptive_network_image.dart';

AdaptiveNetworkImage(
  imageUrl: 'https://example.com/photo.jpg',
  width: 300,
  height: 200,
  fit: BoxFit.cover,
)
```

## Configuration

| Parameter | Type | Default | Description |
|---|---|---|---|
| `imageUrl` | `String` | **required** | URL of the image to display. |
| `width` | `double?` | `null` | Fixed width constraint. |
| `height` | `double?` | `null` | Fixed height constraint. |
| `fit` | `BoxFit` | `BoxFit.cover` | How the image fits within its bounds. |
| `placeholder` | `WidgetBuilder?` | `null` | Builder for a widget shown while loading. Defaults to a `CircularProgressIndicator`. |
| `errorWidget` | `AdaptiveImageErrorBuilder?` | `null` | Builder for a widget shown when all strategies fail. Defaults to a broken-image icon. |
| `fadeInDuration` | `Duration` | `300ms` | Duration of the fade-in animation. |
| `fadeInCurve` | `Curve` | `Curves.easeIn` | Curve of the fade-in animation. |
| `borderRadius` | `BorderRadius?` | `null` | Clips the image with the given border radius. |
| `headers` | `Map<String, String>?` | `null` | HTTP headers sent with image requests. |
| `corsProxyUrl` | `String?` | `null` | CORS proxy base URL. The image URL is appended (encoded). Required for the `corsProxy` strategy. |
| `onTap` | `VoidCallback?` | `null` | Callback invoked when the image is tapped. |
| `enableCache` | `bool` | `true` | Whether to cache strategy resolution and image bytes. |
| `strategies` | `List<ImageLoadStrategy>?` | `null` | Ordered list of strategies to attempt. Defaults to all three. |
| `onStrategyResolved` | `ImageLoadCallback?` | `null` | Callback invoked when a strategy successfully loads the image. |

## Strategy Trade-offs

| Strategy | Weight | Requires | Notes |
|---|---|---|---|
| `directImg` | Lightest | Server CORS headers | Best performance; may fail if the server blocks cross-origin requests. |
| `corsProxy` | Medium | `corsProxyUrl` | Full pixel access via `Image.memory`; adds a proxy hop. |
| `iframe` | Heaviest | Nothing | Always works, but creates a sandboxed iframe per image. |

You can restrict or reorder strategies:

```dart
AdaptiveNetworkImage(
  imageUrl: url,
  strategies: [ImageLoadStrategy.corsProxy, ImageLoadStrategy.iframe],
  corsProxyUrl: 'https://my-proxy.example.com/',
)
```

## Platform Support

| Platform | Behavior |
|---|---|
| **Web** | Multi-strategy CORS handling (directImg, corsProxy, iframe). |
| **Android / iOS** | Falls back to `Image.network`. |
| **macOS / Windows / Linux** | Falls back to `Image.network`. |

## Cache

Image bytes and resolved strategies are cached in an LRU cache with byte-based eviction. To clear the cache manually:

```dart
AdaptiveNetworkImage.clearCache();
```

Disable caching per widget with `enableCache: false`.

## Logging

Enable debug logging to diagnose CORS issues:

```dart
adaptiveImageLogging = true;
```

Logs are printed via `debugPrint` and are off by default.

## License

MIT -- see [LICENSE](LICENSE) for details.
