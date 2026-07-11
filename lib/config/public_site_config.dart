class PublicSiteConfig {
  static const String configuredOrigin = String.fromEnvironment(
    'PUBLIC_SITE_URL',
    defaultValue: 'https://vixrex.app',
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

  /// Canonical public storefront URL for a published slug.
  static String buildVitrinLink(String slug) {
    final trimmed = slug.trim();
    if (trimmed.isEmpty) return buildPublicLink('/v/');
    return buildPublicLink('/v/${Uri.encodeComponent(trimmed)}');
  }

  /// Eski/yanlış linkleri (`vixrex.app/slug`, `#/v/slug`, localhost) → canonical `/v/slug`.
  static String repairPublicLink(String link) {
    final trimmed = link.trim();
    if (trimmed.isEmpty) return trimmed;

    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return trimmed;
    }

    final slug = resolveVitrinSlugFromUri(uri);
    if (slug == null) return trimmed;
    return buildVitrinLink(slug);
  }

  /// Path veya hash fragment'tan (`#/v/slug`) vitrin slug çıkarır.
  static String? resolveVitrinSlugFromUri(Uri uri) {
    final fromPath = resolveVitrinSlugFromPath(uri.path);
    if (fromPath != null) return fromPath;

    final fragment = uri.fragment.trim();
    if (fragment.isEmpty) return null;
    final fragPath = fragment.startsWith('/') ? fragment : '/$fragment';
    return resolveVitrinSlugFromPath(fragPath);
  }

  static const Set<String> _reservedRouteSegments = {
    'app',
    'home',
    'auth',
    'privacy',
    'terms',
    'consent',
    'data-deletion',
    'legal',
    'bookings',
    'v',
    'api',
    'assets',
  };

  /// GoRouter / deep-link: path'ten vitrin slug çıkarır (`/v/x`, `/v/x/`, `/x`).
  static String? resolveVitrinSlugFromPath(String path) {
    final segments =
        path.split('/').where((s) => s.isNotEmpty).toList(growable: false);
    if (segments.isEmpty) return null;

    if (segments.first == 'v' && segments.length >= 2) {
      final slug = Uri.decodeComponent(segments[1]).trim();
      return slug.isEmpty ? null : slug;
    }

    if (segments.length == 1) {
      final candidate = Uri.decodeComponent(segments.first).trim();
      if (candidate.isEmpty) return null;
      if (candidate.contains('.')) return null;
      if (_reservedRouteSegments.contains(candidate.toLowerCase())) {
        return null;
      }
      return candidate;
    }

    return null;
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
