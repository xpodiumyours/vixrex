class PublicSiteConfig {
  /// Vitrinlerin yayınlandığı adres. Uygulamanın kendi adresi DEĞİL.
  static const String varsayilanKoken = 'https://vixrex-public.vercel.app';

  static const String configuredOrigin = String.fromEnvironment(
    'PUBLIC_SITE_URL',
    defaultValue: varsayilanKoken,
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

    // Ayar BOŞ geldiyse burası çalışır.
    //
    // `String.fromEnvironment` yalnız anahtar hiç yoksa varsayılanı kullanır;
    // derleme `--dart-define=PUBLIC_SITE_URL=` diye boş bir değer geçerse
    // "değer var" sayılır ve varsayılan devreye girmez. 2026-08-07'de tam
    // olarak bu oldu: uygulama vitrin linklerini KENDİ adresiyle kurdu,
    // sahip önizlemesi `vixrex-app.vercel.app/api/owner-session?...` gibi
    // var olmayan bir yola gitti ve karşılama sayfasına düştü.
    //
    // Bu yüzden Uri.base'e düşmeden önce sabit köken denenir. Uri.base yalnız
    // sabit de geçersizse (teoride imkânsız) son çare olarak kalır.
    final sabitKoken = _normalizeOrigin(varsayilanKoken);
    if (sabitKoken != null) {
      return '$sabitKoken$normalizedPath';
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

  /// Sahip önizleme giriş adresi (implementation_plan.md §5.2, Commit 4/5):
  /// tek kullanımlık kodu Next.js `/api/owner-session` sunucu rotasına taşır.
  /// Kalıcı `edit_token` bu adrese asla yazılmaz (koruma #7).
  static String buildOwnerSessionEntryLink(String slug, String code) {
    final trimmedSlug = slug.trim();
    final trimmedCode = code.trim();
    if (trimmedSlug.isEmpty || trimmedCode.isEmpty) {
      return buildPublicLink('/api/owner-session');
    }
    final query =
        Uri(queryParameters: {'slug': trimmedSlug, 'ocode': trimmedCode}).query;
    return '${buildPublicLink('/api/owner-session')}?$query';
  }

  /// Path-only product page (`/v/{slug}/urun/{productSlug}`) — Next.js ile aynı.
  static String buildProductPath(String storeSlug, String productSlug) {
    final store = storeSlug.trim();
    final product = productSlug.trim();
    if (store.isEmpty || product.isEmpty) return buildVitrinLink(store);
    return '/v/${Uri.encodeComponent(store)}/urun/${Uri.encodeComponent(product)}';
  }

  static String buildProductLink(String storeSlug, String productSlug) =>
      buildPublicLink(buildProductPath(storeSlug, productSlug));

  /// Path-only booking entry (`/v/{slug}/randevu`) — Next.js ile aynı.
  static String buildBookingPath(String slug) {
    final trimmed = slug.trim();
    if (trimmed.isEmpty) return '/v/randevu';
    return '/v/${Uri.encodeComponent(trimmed)}/randevu';
  }

  /// Path-only appointment tracker (`/v/{slug}/randevu/{token}`).
  static String buildBookingTrackerPath(String slug, String token) {
    final s = slug.trim();
    final t = token.trim();
    if (s.isEmpty || t.isEmpty) return buildBookingPath(s);
    return '/v/${Uri.encodeComponent(s)}/randevu/${Uri.encodeComponent(t)}';
  }

  static String buildBookingLink(String slug) =>
      buildPublicLink(buildBookingPath(slug));

  static String buildBookingTrackerLink(String slug, String token) =>
      buildPublicLink(buildBookingTrackerPath(slug, token));

  /// Eski/yanlış linkleri (bare slug, hash route, localhost) → canonical `/v/slug`.
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
    final segments = path
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
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
