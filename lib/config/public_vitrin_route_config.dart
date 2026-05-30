class PublicVitrinRouteConfig {
  const PublicVitrinRouteConfig._();

  static String? publicSlugFromUri(Uri uri) {
    if (uri.pathSegments.length != 2 || uri.pathSegments.first != 'v') {
      return null;
    }

    final slug = uri.pathSegments.last.trim();
    return slug.isEmpty ? null : slug;
  }
}
