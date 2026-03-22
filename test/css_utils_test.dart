import 'package:flutter/widgets.dart';
import 'package:adaptive_network_image/src/css_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('boxFitToCss', () {
    test('fill returns "fill"', () {
      expect(boxFitToCss(BoxFit.fill), 'fill');
    });

    test('contain returns "contain"', () {
      expect(boxFitToCss(BoxFit.contain), 'contain');
    });

    test('cover returns "cover"', () {
      expect(boxFitToCss(BoxFit.cover), 'cover');
    });

    test('fitWidth returns "scale-down"', () {
      expect(boxFitToCss(BoxFit.fitWidth), 'scale-down');
    });

    test('fitHeight returns "scale-down"', () {
      expect(boxFitToCss(BoxFit.fitHeight), 'scale-down');
    });

    test('none returns "none"', () {
      expect(boxFitToCss(BoxFit.none), 'none');
    });

    test('scaleDown returns "scale-down"', () {
      expect(boxFitToCss(BoxFit.scaleDown), 'scale-down');
    });
  });
}
