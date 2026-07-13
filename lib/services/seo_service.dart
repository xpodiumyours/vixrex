import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vixrex/config/public_site_config.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/utils/whatsapp_link_helper.dart';

/// Next.js ISR önbelleğini geçersiz kılmak ve SEO şemaları üretmek için kullanılan servis.
class SeoService {
  final http.Client? _httpClient;

  const SeoService({http.Client? httpClient}) : _httpClient = httpClient;

  /// Vitrin profil sayfasını ve blog listesini yeniden oluşturur.
  Future<void> revalidateStore(String slug) async {
    await _revalidate(tags: ['store-$slug', 'products-$slug']);
  }

  /// Belirli bir blog makalesini yeniden oluşturur.
  Future<void> revalidateArticle(String storeSlug, String articleSlug) async {
    await _revalidate(tags: ['article-$storeSlug-$articleSlug']);
  }

  /// Ürün detay sayfasını, ürün listesini ve gerekirse sitemap'i yeniler.
  Future<void> revalidateProduct({
    required String storeSlug,
    required String productSlug,
    bool sitemapChanged = false,
  }) async {
    final tags = <String>[
      'store-$storeSlug',
      'products-$storeSlug',
      'product-$storeSlug-$productSlug',
      if (sitemapChanged) 'sitemap',
    ];

    await _revalidate(tags: tags, paths: ['/v/$storeSlug/urun/$productSlug']);
  }

  /// Vitrin + blog listesi + makale sayfasını birlikte yeniler.
  Future<void> revalidateAll({
    required String storeSlug,
    String? articleSlug,
  }) async {
    final futures = <Future>[revalidateStore(storeSlug)];
    if (articleSlug != null && articleSlug.isNotEmpty) {
      futures.add(revalidateArticle(storeSlug, articleSlug));
    }
    await Future.wait(futures, eagerError: false);
  }

  Future<void> _revalidate({
    required List<String> tags,
    List<String> paths = const [],
  }) async {
    final endpoint = _resolveEndpoint();
    if (endpoint == null) {
      return;
    }

    final secret = const String.fromEnvironment('REVALIDATION_SECRET');
    if (secret.isEmpty) {
      return;
    }

    final cleanTags =
        tags.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
    final cleanPaths =
        paths
            .map((path) => path.trim())
            .where((path) => path.isNotEmpty)
            .toList();

    if (cleanTags.isEmpty && cleanPaths.isEmpty) {
      return;
    }

    try {
      final client = _httpClient ?? http.Client();
      final response = await client
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'x-revalidate-secret': secret,
            },
            body: jsonEncode({'tags': cleanTags, 'paths': cleanPaths}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        // Revalidation failed; silently ignore.
      }
    } catch (_) {
      // Network errors never block the user flow.
    }
  }

  String? _resolveEndpoint() {
    final origin = PublicSiteConfig.buildPublicLink('/api/revalidate');
    if (!origin.startsWith('http')) return null;
    return origin;
  }

  /// SEO Schema JSON-LD üreticisi
  static Map<String, dynamic> buildStoreSchemas(StoreData store, {String? publicUrl}) {
    final name = store.name.trim();
    final description = _effectiveDescription(store);
    final url = publicUrl?.trim() ?? '';
    final imageUrl = _effectiveImageUrl(store);
    final normalizedPhone = WhatsAppLinkHelper.normalizeTurkeyMobile(
      store.whatsapp,
    );
    final hasPhysicalLocation =
        store.address.trim().isNotEmpty &&
        store.latitude != null &&
        store.longitude != null;
    final entityId = url.isEmpty ? null : '$url#business';

    final Map<String, dynamic> entity = {
      '@type': hasPhysicalLocation ? 'LocalBusiness' : 'Organization',
      if (entityId != null) '@id': entityId,
      'name': name,
      if (description.isNotEmpty) 'description': description,
      if (url.isNotEmpty) 'url': url,
      if (imageUrl.isNotEmpty) 'image': imageUrl,
      if (store.logoUrl?.trim().isNotEmpty ?? false)
        'logo': store.logoUrl!.trim(),
      if (normalizedPhone != null) 'telephone': '+$normalizedPhone',
    };

    if (hasPhysicalLocation) {
      entity['address'] = {
        '@type': 'PostalAddress',
        'streetAddress': store.address.trim(),
        'addressCountry': 'TR',
      };
      entity['geo'] = {
        '@type': 'GeoCoordinates',
        'latitude': store.latitude,
        'longitude': store.longitude,
      };
      entity['hasMap'] =
          'https://www.google.com/maps/search/?api=1&query='
          '${store.latitude},${store.longitude}';

      final hours = _openingHours(store.workingHours);
      if (hours != null) {
        entity['openingHoursSpecification'] = hours;
      }
    }

    final graph = <Map<String, dynamic>>[entity];
    if (url.isNotEmpty) {
      graph.add({
        '@type': 'WebPage',
        '@id': '$url#webpage',
        'url': url,
        'name': name.isEmpty ? 'Vixrex' : '$name | Vixrex',
        if (description.isNotEmpty) 'description': description,
        'about': {'@id': entityId},
        if (imageUrl.isNotEmpty)
          'primaryImageOfPage': {'@type': 'ImageObject', 'url': imageUrl},
      });
    }

    return {'@context': 'https://schema.org', '@graph': graph};
  }

  static String _effectiveDescription(StoreData store) {
    final description = store.description.trim();
    if (description.isNotEmpty) return description;
    return store.corporateBio.trim();
  }

  static String _effectiveImageUrl(StoreData store) {
    final coverUrl = store.coverImageUrl.trim();
    if (coverUrl.isNotEmpty) return coverUrl;
    return store.logoUrl?.trim() ?? '';
  }

  static Map<String, dynamic>? _openingHours(String rawHours) {
    final match = RegExp(
      r'^(\d{2}:\d{2})\s*-\s*(\d{2}:\d{2})$',
    ).firstMatch(rawHours.trim());
    if (match == null) return null;

    return {
      '@type': 'OpeningHoursSpecification',
      'dayOfWeek': const [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ],
      'opens': match.group(1),
      'closes': match.group(2),
    };
  }
}
