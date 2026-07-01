/// URL normalisation and building helpers used across the vitrin feature.
///
/// All methods are pure functions with no side-effects, making them easy to
/// unit-test independently of any widget tree.
class VitrinUrlHelper {
  VitrinUrlHelper._();

  /// Normalises an arbitrary URL string to an `http` or `https` URL.
  ///
  /// Returns the empty string when [value] is blank, unparseable, or uses a
  /// non-http/https scheme.  If the value has no scheme but contains a dot,
  /// `https://` is prepended automatically.
  static String normalizeExternalUrl(String value) {
    final text = value.trim();
    if (text.isEmpty) return '';

    final uri = Uri.tryParse(text);
    if (uri == null) return '';

    if (uri.hasScheme) {
      final scheme = uri.scheme.toLowerCase();
      if (scheme == 'http' || scheme == 'https') return text;
      return '';
    }

    if (!text.contains('.')) return '';
    return 'https://$text';
  }

  /// Builds a full Instagram profile URL from a username handle or an
  /// existing instagram.com URL.
  static String buildInstagramUrl(String value) {
    final text = value.trim();
    if (text.contains('instagram.com')) return normalizeExternalUrl(text);
    final username = text.replaceFirst('@', '').replaceAll('/', '').trim();
    return 'https://instagram.com/$username';
  }

  /// Builds a Google Maps URL for directions or a place search.
  ///
  /// When [latitude] and [longitude] are provided a directions URL is built;
  /// otherwise a text search URL using [address] is returned.
  static String buildMapsUrl(
    String address, {
    double? latitude,
    double? longitude,
  }) {
    if (latitude != null && longitude != null) {
      return Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': '$latitude,$longitude',
      }).toString();
    }
    return Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': address.trim(),
    }).toString();
  }

  /// Returns the effective website action URL shown to public visitors.
  ///
  /// In public mode the generated [publicLink] is preferred; otherwise the
  /// store's own [websiteUrl] is normalised and returned.
  static String publicWebsiteActionUrl({
    required String? publicLink,
    required bool publicMode,
    required String websiteUrl,
  }) {
    final generatedLink = publicLink?.trim() ?? '';
    final normalizedGenerated = normalizeExternalUrl(generatedLink);
    if (publicMode && normalizedGenerated.isNotEmpty) {
      return normalizedGenerated;
    }
    return normalizeExternalUrl(websiteUrl);
  }
}
