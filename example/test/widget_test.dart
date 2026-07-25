import 'package:adaptive_network_image_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App renders demo page', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Adaptive Network Image Demo'), findsOneWidget);
  });
}
