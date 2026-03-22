import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:adaptive_network_image/src/strategies/load_strategy.dart';
import 'package:flutter_test/flutter_test.dart';

/// Concrete subclass to test the default dispose() no-op.
class _TestStrategy extends LoadStrategy {
  @override
  Future<StrategyResult> load({
    required String url,
    required double? width,
    required double? height,
    required BoxFit fit,
    Map<String, String>? headers,
    String? corsProxyUrl,
  }) async {
    return StrategyFailure('not implemented');
  }
}

void main() {
  group('StrategySuccess', () {
    test('stores widget', () {
      final widget = SizedBox();
      final result = StrategySuccess(widget: widget);

      expect(result, isA<StrategyResult>());
      expect(result.widget, same(widget));
      expect(result.imageBytes, isNull);
    });

    test('stores imageBytes', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final result = StrategySuccess(imageBytes: bytes);

      expect(result, isA<StrategyResult>());
      expect(result.imageBytes, same(bytes));
      expect(result.widget, isNull);
    });

    test('stores both widget and imageBytes', () {
      final widget = SizedBox();
      final bytes = Uint8List.fromList([4, 5, 6]);
      final result = StrategySuccess(widget: widget, imageBytes: bytes);

      expect(result.widget, same(widget));
      expect(result.imageBytes, same(bytes));
    });

    test('allows both null', () {
      final result = StrategySuccess();

      expect(result.widget, isNull);
      expect(result.imageBytes, isNull);
    });
  });

  group('StrategyFailure', () {
    test('stores reason', () {
      final result = StrategyFailure('CORS blocked');

      expect(result, isA<StrategyResult>());
      expect(result.reason, 'CORS blocked');
    });
  });

  group('LoadStrategy', () {
    test('default dispose does not throw', () {
      final strategy = _TestStrategy();
      expect(() => strategy.dispose(), returnsNormally);
    });
  });
}
