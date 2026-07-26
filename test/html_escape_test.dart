import 'package:adaptive_network_image/src/html_escape.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('escapeHtmlAttribute', () {
    test('escapes characters that can break out of attributes', () {
      expect(
        escapeHtmlAttribute('https://x.test/a.png" onerror="alert(1)'),
        'https://x.test/a.png&quot; onerror=&quot;alert(1)',
      );
      expect(
        escapeHtmlAttribute("a'b&c<d>e"),
        'a&#39;b&amp;c&lt;d&gt;e',
      );
    });

    test('leaves safe URLs unchanged', () {
      expect(
        escapeHtmlAttribute('https://example.com/img.png?x=1&y=2'),
        'https://example.com/img.png?x=1&amp;y=2',
      );
    });
  });
}
