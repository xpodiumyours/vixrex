class PublicSiteConfig {
  static const String configuredOrigin = String.fromEnvironment(
    'PUBLIC_SITE_URL',
  );

  static String buildPublicLink(
    String path, {
    String? configuredOriginOverride,
    Uri? baseUriOverride,
  }) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final preferredOrigin = _normalizeOrigin(
      configuredOriginOverride ?? configuredOrigin,
    );

    if (preferredOrigin != null) {
      return '$preferredOrigin$normalizedPath';
    }

    final base = baseUriOverride ?? Uri.base;
    final hasWebOrigin =
        (base.scheme == 'http' || base.scheme == 'https') &&
        base.host.isNotEmpty;

    if (!hasWebOrigin) {
      return normalizedPath;
    }

    return '${base.origin}$normalizedPath';
  }

  static String? _normalizeOrigin(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return null;
    }

    return uri.origin;
  }
}
