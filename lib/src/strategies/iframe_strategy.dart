import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;
import 'dart:js_interop';

import '../css_utils.dart';
import '../adaptive_network_image_config.dart';
import 'load_strategy.dart';

/// Counter for generating unique view type IDs.
int _iframeViewIdCounter = 0;

/// Strategy 3: Render the image inside a minimal sandboxed iframe.
///
/// Last resort — heaviest approach but most compatible.
/// Uses only `allow-same-origin` sandbox — no scripts allowed inside the iframe.
/// No inline JavaScript — eliminates the XSS vector.
///
/// Listens for the iframe `load` event from the parent frame, then
/// registers the platform view factory with the already-loaded iframe.
class IframeStrategy extends LoadStrategy {
  JSFunction? _loadListener;
  web.HTMLIFrameElement? _iframe;
  Timer? _timer;

  @override
  Future<StrategyResult> load({
    required String url,
    required double? width,
    required double? height,
    required BoxFit fit,
    Map<String, String>? headers,
    String? corsProxyUrl,
    bool preventNativeInteraction = true,
  }) async {
    final completer = Completer<StrategyResult>();
    final viewId = _iframeViewIdCounter++;
    final viewType = 'adaptive_network_image_iframe_$viewId';
    final cssFit = boxFitToCss(fit);

    adaptiveImageLog('[IframeStrategy] Attempting to load: $url');

    // Minimal HTML with no scripts — just CSS and an img tag.
    final srcdoc = '''
<!DOCTYPE html>
<html>
<head><style>
  * { margin: 0; padding: 0; }
  body { width: 100%; height: 100%; overflow: hidden; }
  img { width: 100%; height: 100%; object-fit: $cssFit; display: block;${preventNativeInteraction ? ' pointer-events: none; user-select: none;' : ''} }
</style></head>
<body>
  <img src="$url"${preventNativeInteraction ? ' draggable="false"' : ''} />
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
    }
    // Only allow-same-origin — no scripts allowed.
    iframe.sandbox.add('allow-same-origin');

    // Listen for the iframe load event from the parent.
    void onLoad(web.Event _) {
      if (!completer.isCompleted) {
        adaptiveImageLog('[IframeStrategy] Iframe loaded for: $url');
        ui_web.platformViewRegistry.registerViewFactory(
          viewType,
          (int id) => iframe,
        );
        completer.complete(StrategySuccess(
          widget: HtmlElementView(viewType: viewType),
        ));
      }
    }

    final listener = onLoad.toJS;
    _loadListener = listener;
    iframe.addEventListener('load', listener);

    _timer = Timer(const Duration(seconds: 15), () {
      if (!completer.isCompleted) {
        adaptiveImageLog('[IframeStrategy] Timeout loading image: $url');
        completer.complete(
          StrategyFailure('Timeout loading image via iframe: $url'),
        );
      }
    });

    final result = await completer.future;
    _timer?.cancel();
    _timer = null;
    return result;
  }

  @override
  void dispose() {
    if (_loadListener != null && _iframe != null) {
      _iframe!.removeEventListener('load', _loadListener!);
    }
    _loadListener = null;
    _timer?.cancel();
    _timer = null;
    _iframe?.remove();
    _iframe = null;
  }
}
