import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// The decoded pixel size of [img], or null when the browser reports none.
///
/// A zero dimension means the image has not decoded yet, or has no intrinsic
/// size at all (an SVG without `width`/`height`, for example).
Size? naturalSizeOf(web.HTMLImageElement img) {
  final width = img.naturalWidth;
  final height = img.naturalHeight;
  if (width <= 0 || height <= 0) return null;
  return Size(width.toDouble(), height.toDouble());
}
