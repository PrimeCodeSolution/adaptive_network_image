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
