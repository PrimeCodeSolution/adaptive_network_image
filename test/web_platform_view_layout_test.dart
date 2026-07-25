@TestOn('browser')
library;

import 'dart:ui_web' as ui_web;

import 'package:adaptive_network_image/src/platform/image_loader_web.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

/// Stands in for the platform view a web strategy returns. Like every
/// [HtmlElementView] it has no intrinsic size and sizes itself to
/// `constraints.biggest`, so an unbounded axis makes it infinitely large.
int _viewCounter = 0;
Widget _platformView() {
  final viewType = 'layout_test_view_${_viewCounter++}';
  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (int id) => web.document.createElement('img'),
  );
  return HtmlElementView(viewType: viewType);
}

void main() {
  const intrinsic = Size(1600, 900);

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(MaterialApp(home: child));
  }

  testWidgets('a bare platform view really does break in a ListView', (
    tester,
  ) async {
    // Guards the premise of every case below: without SizedPlatformView the
    // unbounded height is fatal, which is the bug being fixed.
    await pump(tester, ListView(children: [_platformView()]));

    expect(tester.takeException(), isNotNull);
  });

  testWidgets('lays out inside a ListView', (tester) async {
    await pump(
      tester,
      ListView(
        children: [
          SizedPlatformView(
            intrinsicSize: intrinsic,
            child: _platformView(),
          ),
        ],
      ),
    );

    expect(tester.takeException(), isNull);
    // Width fills the viewport and height follows the image's aspect ratio.
    final size = tester.getSize(find.byType(HtmlElementView));
    expect(size.width, 800);
    expect(size.height, closeTo(800 * 900 / 1600, 0.01));
  });

  testWidgets('lays out inside an unconstrained Column', (tester) async {
    await pump(
      tester,
      Column(
        children: [
          SizedPlatformView(
            intrinsicSize: intrinsic,
            child: _platformView(),
          ),
        ],
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('falls back to a square when the natural size is unknown', (
    tester,
  ) async {
    await pump(
      tester,
      ListView(
        children: [
          SizedPlatformView(intrinsicSize: null, child: _platformView()),
        ],
      ),
    );

    expect(tester.takeException(), isNull);
    final size = tester.getSize(find.byType(HtmlElementView));
    expect(size.width, size.height);
  });

  testWidgets('fills the slot when both axes are bounded', (tester) async {
    await pump(
      tester,
      Center(
        child: SizedBox(
          width: 120,
          height: 60,
          child: SizedPlatformView(
            intrinsicSize: intrinsic,
            child: _platformView(),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(HtmlElementView)), const Size(120, 60));
  });

  testWidgets('uses the natural size when neither axis is bounded', (
    tester,
  ) async {
    // Small enough to fit the test viewport, so an overflow cannot be mistaken
    // for the sizing failure under test.
    const small = Size(160, 90);
    await pump(
      tester,
      ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Column(
            children: [
              SizedPlatformView(intrinsicSize: small, child: _platformView()),
            ],
          ),
        ],
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(HtmlElementView)), small);
  });
}
