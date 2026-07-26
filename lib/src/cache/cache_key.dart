/// Builds a cache key that includes URL plus load-affecting configuration.
///
/// Headers and proxy URL can change the fetched bytes (and which strategy is
/// appropriate), so they must be part of the key.
String buildImageCacheKey(
  String url, {
  String? corsProxyUrl,
  Map<String, String>? headers,
}) {
  if (corsProxyUrl == null && (headers == null || headers.isEmpty)) {
    return url;
  }

  final buffer = StringBuffer(url);
  if (corsProxyUrl != null) {
    buffer.write('|proxy=');
    buffer.write(corsProxyUrl);
  }
  if (headers != null && headers.isNotEmpty) {
    final sortedKeys = headers.keys.toList()..sort();
    for (final key in sortedKeys) {
      buffer.write('|');
      buffer.write(key);
      buffer.write('=');
      buffer.write(headers[key]);
    }
  }
  return buffer.toString();
}
