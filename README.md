# adaptive_network_image

A Flutter package built primarily for **web**, solving CORS restrictions when loading external images. It uses a multi-strategy fallback approach that works across all browsers. On non-web platforms (Android, iOS, macOS, Windows, Linux), it uses Flutter's default network image loading — no extra setup needed.

**[Live example app](https://primecodesolution.github.io/adaptive_network_image/)**

> **Note:** Flutter's built-in [`Image.network`](https://api.flutter.dev/flutter/widgets/Image/Image.network.html) now supports [`WebHtmlElementStrategy`](https://api.flutter.dev/flutter/painting/WebHtmlElementStrategy.html) for a first-party HTML `<img>` CORS bypass. Prefer that for simple cases. Use this package when you need ordered fallbacks (`corsProxy`, `iframe`), strategy/bytes caching, or `preventNativeInteraction`.

## How It Works

`AdaptiveNetworkImage` tries up to three strategies in order until one succeeds:

1. **directImg** — Renders an HTML `<img>` element via `HtmlElementView`. Lightest approach; displays most cross-origin images without needing CORS headers (CORS is only required for canvas/pixel reads, not basic display).
2. **corsProxy** — Fetches image bytes through a CORS proxy, then displays via `Image.memory`. Requires a `corsProxyUrl` to be provided. Skipped otherwise. This is the only strategy that honors custom HTTP `headers`.
3. **iframe** — Renders the image inside a sandboxed `<iframe>` with no inline scripts. Heaviest approach; useful when direct `<img>` embedding is blocked by the host page policy.

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
| `headers` | `Map<String, String>?` | `null` | HTTP headers for the `corsProxy` strategy (and non-web `NetworkImage`). Not applied to HTML `<img>` / iframe strategies. |
| `corsProxyUrl` | `String?` | `null` | CORS proxy base URL. The image URL is appended (encoded). Required for the `corsProxy` strategy. |
| `onTap` | `VoidCallback?` | `null` | Callback invoked when the image is tapped. |
| `enableCache` | `bool` | `true` | Whether to cache strategy resolution and image bytes. |
| `strategies` | `List<ImageLoadStrategy>?` | `null` | Ordered list of strategies to attempt. Defaults to all three. |
| `onStrategyResolved` | `ImageLoadCallback?` | `null` | Callback invoked when a strategy successfully loads the image. |
| `preventNativeInteraction` | `bool` | `true` | Prevents native browser drag / context-menu interactions on web HTML elements so Flutter gestures can handle them. |
| `loadTimeout` | `Duration` | `15s` | Timeout applied to each strategy attempt. |

## Strategy Trade-offs

| Strategy | Weight | Requires | Notes |
|---|---|---|---|
| `directImg` | Lightest | Nothing special | Best performance; may fail under CSP / hotlink protection, not merely missing CORS headers. |
| `corsProxy` | Medium | `corsProxyUrl` | Full pixel access via `Image.memory`; adds a proxy hop; honors `headers`. |
| `iframe` | Heaviest | Nothing | Isolates the image document; verifies the inner `<img>` loaded before succeeding. |

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
| **Web (all browsers)** | Multi-strategy CORS handling (directImg, corsProxy, iframe). |
| **Android / iOS** | Uses Flutter's `NetworkImage` pipeline (placeholder waits for first frame). |
| **macOS / Windows / Linux** | Uses Flutter's `NetworkImage` pipeline (placeholder waits for first frame). |

You can use `AdaptiveNetworkImage` as a drop-in replacement for `Image.network` across all platforms. On web it handles CORS with fallbacks; everywhere else it delegates to Flutter's built-in image loading.

## Cache

Image bytes and resolved strategies are cached in an LRU cache with byte-based eviction. Cache keys include the image URL plus `corsProxyUrl` and `headers` when present, so authenticated / proxied variants do not collide.

To clear the cache manually:

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

MIT — see [LICENSE](LICENSE) for details.

## Releasing (maintainers)

Publishing is driven by the `release` branch. Fast-forwarding it to a commit on `main`
publishes that commit to pub.dev automatically -- there is no manual tagging step and no
approval prompt, so treat a push to `release` as the production release action.

### One-time setup

1. On the pub.dev admin page for `adaptive_network_image`, configure a GitHub Actions
   trusted publisher with owner `PrimeCodeSolution`, repository `adaptive_network_image`,
   workflow `release.yml`, and environment `pub.dev`. Publication uses OIDC, so do not
   create a `PUB_CREDENTIALS` secret.
2. In GitHub, create an environment named `pub.dev`. Leave it without protection rules
   for hands-off releases, or add required reviewers to turn every release into an
   approval gate.
3. In GitHub repository **Settings → Pages**, set **Build and deployment → Source** to
   **GitHub Actions**. The release workflow deploys the example app to
   `https://primecodesolution.github.io/adaptive_network_image/` after each successful
   release.
4. Protect the `release` branch. Anyone who can push to it can publish.

### Cutting a release

1. Bump `version` in the root `pubspec.yaml`, document the changes in `CHANGELOG.md`, and
   merge that pull request to `main`. The committed version is the release candidate; the
   workflow never invents or modifies a version.
2. Fast-forward `release` to the merged commit:

   ```sh
   git switch main
   git pull --ff-only
   git push origin main:release
   ```

That push runs the same gates as CI, publishes to pub.dev, creates the `v<version>` tag
and the GitHub Release from the published commit, then deploys the example app to GitHub
Pages.

The workflow refuses to publish when the version already exists on pub.dev, when the
`v<version>` tag already exists, or when the commit is not contained in `main` -- so the
release branch cannot ship code that bypassed review. Running the workflow manually from
the Actions tab is always a validation-only dry run and can never publish.

### When something fails

Nothing is published unless every gate passes, and the tag and GitHub Release are created
only after pub.dev accepts the package, so a failed run leaves no tag to clean up. Fix the
underlying issue and push to `release` again.

Because pub.dev versions are immutable, a version that was accepted cannot be republished.
If publication succeeded but a later step failed, verify the package on pub.dev and create
the tag and release manually rather than retrying the publish.
