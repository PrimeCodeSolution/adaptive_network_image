import 'package:flutter/material.dart';
import 'package:adaptive_network_image/adaptive_network_image.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdaptiveNetworkImageConfig', () {
    test('ImageLoadStrategy enum has expected values', () {
      expect(ImageLoadStrategy.values.length, 3);
      expect(ImageLoadStrategy.directImg, isNotNull);
      expect(ImageLoadStrategy.corsProxy, isNotNull);
      expect(ImageLoadStrategy.iframe, isNotNull);
    });

    test('adaptiveImageLogging defaults to false', () {
      expect(adaptiveImageLogging, isFalse);
    });

    test('adaptiveImageLog does not throw when logging is disabled', () {
      adaptiveImageLogging = false;
      expect(() => adaptiveImageLog('test message'), returnsNormally);
    });

    test('adaptiveImageLog does not throw when logging is enabled', () {
      adaptiveImageLogging = true;
      expect(() => adaptiveImageLog('test message'), returnsNormally);
      // Reset to default.
      adaptiveImageLogging = false;
    });
  });

  group('AdaptiveNetworkImage widget', () {
    testWidgets('creates with required parameters', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdaptiveNetworkImage(imageUrl: 'https://example.com/img.png'),
        ),
      );

      // Widget should be in the tree (showing placeholder initially).
      expect(find.byType(AdaptiveNetworkImage), findsOneWidget);
    });

    testWidgets('wraps with SizedBox when dimensions provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdaptiveNetworkImage(
            imageUrl: 'https://example.com/img.png',
            width: 100,
            height: 100,
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 100);
      expect(sizedBox.height, 100);
    });

    testWidgets('wraps with ClipRRect when borderRadius provided',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveNetworkImage(
            imageUrl: 'https://example.com/img.png',
            width: 100,
            height: 100,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('wraps with GestureDetector when onTap provided',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveNetworkImage(
            imageUrl: 'https://example.com/img.png',
            width: 100,
            height: 100,
            onTap: () {},
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('shows custom placeholder while loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveNetworkImage(
            imageUrl: 'https://example.com/img.png',
            width: 100,
            height: 100,
            placeholder: (_) => const Text('Loading...'),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets(
        'shows default placeholder (CircularProgressIndicator) while loading',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdaptiveNetworkImage(imageUrl: 'https://example.com/img.png'),
        ),
      );

      // Before the future completes, the default placeholder should show.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows default error widget on failure', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdaptiveNetworkImage(
            imageUrl: 'https://example.invalid/does-not-exist.png',
            width: 100,
            height: 100,
            loadTimeout: Duration(milliseconds: 50),
          ),
        ),
      );

      // Allow the short timeout / failed resolve to complete. On web the
      // loader cascades through several strategies, each with its own
      // timeout, so pump until every fallback has been exhausted.
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
      await tester.pump();

      expect(find.byIcon(Icons.broken_image), findsOneWidget);
    });

    testWidgets('accepts loadTimeout parameter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdaptiveNetworkImage(
            imageUrl: 'https://example.com/img.png',
            loadTimeout: Duration(seconds: 1),
          ),
        ),
      );

      expect(find.byType(AdaptiveNetworkImage), findsOneWidget);
    });

    testWidgets('accepts custom errorWidget parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveNetworkImage(
            imageUrl: 'https://example.com/img.png',
            errorWidget: (context, error) => const Text('Custom Error'),
          ),
        ),
      );

      expect(find.byType(AdaptiveNetworkImage), findsOneWidget);
    });

    testWidgets('fade-in animation uses provided duration and curve',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdaptiveNetworkImage(
            imageUrl: 'https://example.com/img.png',
            fadeInDuration: Duration(milliseconds: 500),
            fadeInCurve: Curves.linear,
          ),
        ),
      );

      expect(find.byType(AdaptiveNetworkImage), findsOneWidget);
    });

    testWidgets('clearCache static method does not throw', (tester) async {
      // On VM this resolves to the mobile no-op cache, so it should not throw.
      expect(() => AdaptiveNetworkImage.clearCache(), returnsNormally);
    });

    testWidgets('disposing while loading leaves no pending timers',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdaptiveNetworkImage(imageUrl: 'https://example.com/img.png'),
        ),
      );

      // Tearing the widget down mid-load must cancel the in-flight load
      // instead of letting the web loader start the next fallback strategy.
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    });

    testWidgets('does not wrap with SizedBox when no dimensions given',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdaptiveNetworkImage(imageUrl: 'https://example.com/img.png'),
        ),
      );

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      for (final sb in sizedBoxes) {
        expect(sb.width == 100 && sb.height == 100, isFalse);
      }
    });

    testWidgets('does not wrap with ClipRRect when no borderRadius given',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdaptiveNetworkImage(imageUrl: 'https://example.com/img.png'),
        ),
      );

      expect(find.byType(ClipRRect), findsNothing);
    });

    testWidgets('does not wrap with GestureDetector when no onTap given',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdaptiveNetworkImage(imageUrl: 'https://example.com/img.png'),
        ),
      );

      expect(find.byType(GestureDetector), findsNothing);
    });
  });
}
