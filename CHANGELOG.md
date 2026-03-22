## 0.1.0

- Multi-strategy CORS image loading with ordered fallback: `directImg`, `corsProxy`, `iframe`.
- Sandboxed iframe strategy with no inline scripts for maximum compatibility.
- LRU cache with byte-based eviction for resolved strategies and image bytes.
- Configurable strategy order, timeout, and fade-in animation.
- URL validation before loading.
- Controllable logging via `adaptiveImageLogging` flag (off by default).
- Platform support: full CORS handling on Web; `Image.network` fallback on mobile and desktop.
