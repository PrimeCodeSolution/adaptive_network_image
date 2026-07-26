## 0.1.3

- Raise Dart SDK floor to `>=3.4.0` and Flutter to `>=3.22.0`; bump `web` to `^1.1.1` and `http` to `^1.6.0`.
- Include `corsProxyUrl` and `headers` in cache keys; invalidate cached strategies after a failed retry; bound strategy cache size.
- Reload images when `headers`, `strategies`, `enableCache`, `preventNativeInteraction`, or `loadTimeout` change.
- Escape iframe `srcdoc` URLs; verify the inner `<img>` loaded before treating iframe strategy as success.
- Block browser `contextmenu` when `preventNativeInteraction` is enabled.
- Close owned `http.Client` instances; treat `Content-Type` checks as case-insensitive.
- Add configurable `loadTimeout` (default 15s).
- Await first decoded frame on non-web platforms so placeholders remain until the image is ready.
- Fix a layout crash on web when the image is placed under unbounded constraints, such as inside a `ListView` or an unconstrained `Column`. The platform view now derives its size from the image's natural dimensions instead of always expanding.
- Document headers scope, directImg CORS behavior, and Flutter's built-in `WebHtmlElementStrategy`.

## 0.1.2

- Fix images losing aspect ratio with directImg and iframe strategies when using fixed dimensions.
- Improve example app with BoxFit toggle and colored container borders for visual testing.

## 0.1.1

- Add `preventNativeInteraction` parameter (default `true`) to block native browser drag and right-click on web images, allowing Flutter's gesture system to handle all interactions.
- Improve README to clarify the package is built primarily for web with all-browser support, and uses Flutter's default `Image.network` on other platforms.

## 0.1.0

- Multi-strategy CORS image loading with ordered fallback: `directImg`, `corsProxy`, `iframe`.
- Sandboxed iframe strategy with no inline scripts for maximum compatibility.
- LRU cache with byte-based eviction for resolved strategies and image bytes.
- Configurable strategy order, timeout, and fade-in animation.
- URL validation before loading.
- Controllable logging via `adaptiveImageLogging` flag (off by default).
- Platform support: full CORS handling on Web; `Image.network` fallback on mobile and desktop.
