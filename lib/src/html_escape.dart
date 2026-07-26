/// Escapes a value for safe use inside an HTML double-quoted attribute.
String escapeHtmlAttribute(String value) {
  final buffer = StringBuffer();
  for (var i = 0; i < value.length; i++) {
    final char = value[i];
    switch (char) {
      case '&':
        buffer.write('&amp;');
      case '"':
        buffer.write('&quot;');
      case "'":
        buffer.write('&#39;');
      case '<':
        buffer.write('&lt;');
      case '>':
        buffer.write('&gt;');
      default:
        buffer.write(char);
    }
  }
  return buffer.toString();
}
