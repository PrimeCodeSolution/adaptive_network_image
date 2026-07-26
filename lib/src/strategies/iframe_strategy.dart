import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import '../adaptive_network_image_config.dart';
import '../css_utils.dart';
import '../html_escape.dart';
import 'load_strategy.dart';
import 'natural_size.dart';

/// Counter for generating unique view type IDs.
int _iframeViewIdCounter = 0;

/// Strategy 3: Render the image inside a minimal sandboxed iframe.
///
/// Last resort — heaviest approach but most compatible.
/// Uses only `allow-same-origin` sandbox — no scripts allowed inside the iframe.
/// No inline JavaScript — eliminates the XSS vector.
///
/// Listens for the iframe `load` event from the parent frame, then verifies
/// the inner `<img>` actually loaded before registering the platform view.
class IframeStrategy extends LoadStrategy {
  JSFunction? _loadListener;
  JSFunction? _imgLoadListener;
  JSFunction? _imgErrorListener;
  JSFunction? _contextMenuListener;
  web.HTMLIFrameElement? _iframe;
  web.HTMLImageElement? _innerImg;
  Timer? _timer;
  Completer<StrategyResult>? _completer;

  @override
  Future<StrategyResult> load({
    required String url,
    required double? width,
    required double? height,
    required BoxFit fit,
    Map<String, String>? headers,
    String? corsProxyUrl,
    bool preventNativeInteraction = true,
    Duration timeout = kDefaultLoadTimeout,
  }) async {
    final completer = Completer<StrategyResult>();
    _completer = completer;
    final viewId = _iframeViewIdCounter++;
    final viewType = 'adaptive_network_image_iframe_$viewId';
    final cssFit = boxFitToCss(fit);
    final safeUrl = escapeHtmlAttribute(url);

    adaptiveImageLog('[IframeStrategy] Attempting to load: $url');

    // Minimal HTML with no scripts — just CSS and an img tag.
    // URL is HTML-attribute-escaped to prevent markup injection.
    final srcdoc = '''
<!DOCTYPE html>
<html>
<head><style>
  * { margin: 0; padding: 0; }
  body { width: 100%; height: 100%; overflow: hidden; }
  img { width: 100%; height: 100%; object-fit: $cssFit; display: block;${preventNativeInteraction ? ' pointer-events: none; user-select: none;' : ''} }
</style></head>
<body>
  <img src="$safeUrl"${preventNativeInteraction ? ' draggable="false"' : ''} />
</body>
</html>''';

    final iframe =
        web.document.createElement('iframe') as web.HTMLIFrameElement;
    _iframe = iframe;
    iframe.srcdoc = srcdoc.toJS;
    iframe.style.width = '100%';
    iframe.style.height = '100%';
    iframe.style.border = 'none';
    if (preventNativeInteraction) {
      iframe.style.pointerEvents = 'none';
      iframe.style.setProperty('user-select', 'none');
      void onContextMenu(web.Event event) {
        event.preventDefault();
      }

      _contextMenuListener = onContextMenu.toJS;
      iframe.addEventListener('contextmenu', _contextMenuListener!);
    }
    // Only allow-same-origin — no scripts allowed.
    iframe.sandbox.add('allow-same-origin');

    void completeSuccess() {
      if (completer.isCompleted) return;
      adaptiveImageLog('[IframeStrategy] Image loaded for: $url');
      ui_web.platformViewRegistry.registerViewFactory(
        viewType,
        (int id) => iframe,
      );
      final img = _innerImg;
      completer.complete(StrategySuccess(
        widget: HtmlElementView(viewType: viewType),
        intrinsicSize: img == null ? null : naturalSizeOf(img),
      ));
    }

    void completeFailure(String reason) {
      if (completer.isCompleted) return;
      adaptiveImageLog('[IframeStrategy] $reason');
      completer.complete(StrategyFailure(reason));
    }

    // Listen for the iframe load event from the parent, then verify the
    // inner image actually decoded successfully.
    void onLoad(web.Event _) {
      try {
        final doc = iframe.contentDocument;
        final img = doc?.querySelector('img') as web.HTMLImageElement?;
        if (img == null) {
          completeFailure('Iframe loaded without an image element: $url');
          return;
        }
        _innerImg = img;

        void onImgLoad(web.Event _) => completeSuccess();
        void onImgError(web.Event _) =>
            completeFailure('Failed to load image via iframe <img>: $url');

        _imgLoadListener = onImgLoad.toJS;
        _imgErrorListener = onImgError.toJS;
        img.addEventListener('load', _imgLoadListener!);
        img.addEventListener('error', _imgErrorListener!);

        // Image may already be complete by the time the iframe fires load.
        if (img.complete) {
          if (img.naturalWidth > 0) {
            completeSuccess();
          } else {
            completeFailure('Failed to load image via iframe <img>: $url');
          }
        }
      } catch (e) {
        completeFailure('Unable to inspect iframe image for: $url ($e)');
      }
    }

    final listener = onLoad.toJS;
    _loadListener = listener;
    iframe.addEventListener('load', listener);

    _timer = Timer(timeout, () {
      completeFailure('Timeout loading image via iframe: $url');
    });

    final result = await completer.future;
    _timer?.cancel();
    _timer = null;
    _completer = null;
    return result;
  }

  @override
  void dispose() {
    if (_loadListener != null && _iframe != null) {
      _iframe!.removeEventListener('load', _loadListener!);
    }
    if (_contextMenuListener != null && _iframe != null) {
      _iframe!.removeEventListener('contextmenu', _contextMenuListener!);
    }
    if (_innerImg != null) {
      if (_imgLoadListener != null) {
        _innerImg!.removeEventListener('load', _imgLoadListener!);
      }
      if (_imgErrorListener != null) {
        _innerImg!.removeEventListener('error', _imgErrorListener!);
      }
    }
    _loadListener = null;
    _imgLoadListener = null;
    _imgErrorListener = null;
    _contextMenuListener = null;
    _timer?.cancel();
    _timer = null;
    _iframe?.remove();
    _iframe = null;
    _innerImg = null;
    final completer = _completer;
    _completer = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete(StrategyFailure('cancelled'));
    }
  }
}
