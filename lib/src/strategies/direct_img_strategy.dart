import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import '../adaptive_network_image_config.dart';
import '../css_utils.dart';
import 'load_strategy.dart';
import 'natural_size.dart';

/// Counter for generating unique view type IDs.
int _viewIdCounter = 0;

/// Strategy 1: Render the image via an HTML <img> element using HtmlElementView.
///
/// This is the lightest approach. HTML <img> tags don't enforce CORS unless
/// the `crossOrigin` attribute is set, so this works for most images without
/// any CORS headers on the server.
///
/// Creates the <img> element eagerly, waits for load/error, then registers the
/// platform view factory with the already-loaded element.
class DirectImgStrategy extends LoadStrategy {
  web.HTMLImageElement? _img;
  JSFunction? _loadListener;
  JSFunction? _errorListener;
  JSFunction? _contextMenuListener;
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
    final viewId = _viewIdCounter++;
    final viewType = 'adaptive_network_image_img_$viewId';

    adaptiveImageLog('[DirectImgStrategy] Attempting to load: $url');

    // Create the <img> element eagerly — it starts loading immediately.
    final img = web.document.createElement('img') as web.HTMLImageElement;
    _img = img;
    img.src = url;
    img.style.width = '100%';
    img.style.height = '100%';
    img.style.objectFit = boxFitToCss(fit);
    img.style.display = 'block';
    if (preventNativeInteraction) {
      img.style.pointerEvents = 'none';
      img.style.setProperty('user-select', 'none');
      img.draggable = false;
      void onContextMenu(web.Event event) {
        event.preventDefault();
      }

      _contextMenuListener = onContextMenu.toJS;
      img.addEventListener('contextmenu', _contextMenuListener!);
    }

    void onLoad(web.Event _) {
      adaptiveImageLog('[DirectImgStrategy] Image loaded successfully: $url');
      if (!completer.isCompleted) {
        // Register the factory now with the already-loaded element.
        ui_web.platformViewRegistry.registerViewFactory(
          viewType,
          (int id) => img,
        );
        completer.complete(StrategySuccess(
          widget: HtmlElementView(viewType: viewType),
          intrinsicSize: naturalSizeOf(img),
        ));
      }
    }

    void onError(web.Event _) {
      adaptiveImageLog('[DirectImgStrategy] Failed to load image: $url');
      if (!completer.isCompleted) {
        completer.complete(
          StrategyFailure('Failed to load image via <img>: $url'),
        );
      }
    }

    _loadListener = onLoad.toJS;
    _errorListener = onError.toJS;
    img.addEventListener('load', _loadListener!);
    img.addEventListener('error', _errorListener!);

    // Timeout to avoid hanging forever.
    _timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        adaptiveImageLog('[DirectImgStrategy] Timeout loading image: $url');
        completer.complete(
          StrategyFailure('Timeout loading image via <img>: $url'),
        );
      }
    });

    final result = await completer.future;
    _timer?.cancel();
    _timer = null;
    _completer = null;
    return result;
  }

  @override
  void dispose() {
    if (_img != null) {
      if (_loadListener != null) {
        _img!.removeEventListener('load', _loadListener!);
      }
      if (_errorListener != null) {
        _img!.removeEventListener('error', _errorListener!);
      }
      if (_contextMenuListener != null) {
        _img!.removeEventListener('contextmenu', _contextMenuListener!);
      }
      _img!.remove();
    }
    _loadListener = null;
    _errorListener = null;
    _contextMenuListener = null;
    _img = null;
    _timer?.cancel();
    _timer = null;
    final completer = _completer;
    _completer = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete(StrategyFailure('cancelled'));
    }
  }
}
