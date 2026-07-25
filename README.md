# adaptive_network_image

A Flutter package built primarily for **web**, solving CORS restrictions when loading external images. It uses a multi-strategy fallback approach that works across all browsers. On non-web platforms (Android, iOS, macOS, Windows, Linux), it uses Flutter's default `Image.network` -- no extra setup needed.

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
| `preventNativeInteraction` | `bool` | `true` | Prevents native browser interactions (drag, right-click) on web HTML elements. |

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
| **Web (all browsers)** | Multi-strategy CORS handling (directImg, corsProxy, iframe). |
| **Android / iOS** | Uses Flutter's default `Image.network`. |
| **macOS / Windows / Linux** | Uses Flutter's default `Image.network`. |

You can use `AdaptiveNetworkImage` as a drop-in replacement for `Image.network` across all platforms. On web it handles CORS automatically; everywhere else it delegates to Flutter's built-in image loading.

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

## Releasing (maintainers)

1. Update the version in the root `pubspec.yaml` and document user-visible changes in
   `CHANGELOG.md` in a release pull request. Review and merge that pull request before
   tagging. The version committed to `pubspec.yaml` is the release candidate that will
   be confirmed; the publication workflow never invents or modifies a version.
2. From the updated default branch, create and push an annotated, immutable tag named
   exactly `v<pubspec-version>` (for example, `v0.1.3`):

   ```sh
   git switch main
   git pull --ff-only
   git tag -a v0.1.3 -m "Release 0.1.3"
   git push origin v0.1.3
   ```

   Pushing the tag is the production release trigger. The workflow rejects a tag/version
   mismatch, a tag that does not
   resolve to the checked-out commit, and a version already present on pub.dev. Manual
   workflow runs are validation-only dry runs and cannot select or publish a version.
3. In the pub.dev administration page for `adaptive_network_image`, configure a GitHub
   Actions trusted publisher with owner `PrimeCodeSolution`, repository
   `adaptive_network_image`, workflow `release.yml`, and environment `pub.dev`. Do not
   create a `PUB_CREDENTIALS` secret. In GitHub, create the protected `pub.dev`
   environment and configure required maintainer reviewers before allowing deployment.
4. In the workflow run, review the **Release candidate** summary containing the package
   version, tag, and commit. The publish job is named with that tag and waits at the
   protected `pub.dev` environment. A required reviewer confirms the candidate by
   approving that environment deployment. Rejecting it leaves the tag unpublished.
   Publication uses GitHub OIDC, and the GitHub Release is created only after pub.dev
   accepts the package.

If validation or publication fails, fix the underlying issue and cut a new patch version
and tag; do not move or reuse the failed tag. A failed publication does not create a
GitHub Release. If pub.dev accepted the immutable version but a later release-creation
step failed, verify the package on pub.dev and create the GitHub Release for the existing
tag manually rather than attempting to republish it.
