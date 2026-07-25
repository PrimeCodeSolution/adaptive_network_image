import 'package:flutter/widgets.dart';

/// Maps [BoxFit] to the CSS `object-fit` property value.
///
/// CSS has no direct equivalent for [BoxFit.fitWidth] / [BoxFit.fitHeight],
/// so both map to `scale-down` as the closest available approximation.
String boxFitToCss(BoxFit fit) {
  switch (fit) {
    case BoxFit.fill:
      return 'fill';
    case BoxFit.contain:
      return 'contain';
    case BoxFit.cover:
      return 'cover';
    case BoxFit.fitWidth:
      return 'scale-down';
    case BoxFit.fitHeight:
      return 'scale-down';
    case BoxFit.none:
      return 'none';
    case BoxFit.scaleDown:
      return 'scale-down';
  }
}
