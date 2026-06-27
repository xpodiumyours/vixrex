import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:vitrinx/config/public_site_config.dart';

/// Next.js ISR önbelleğini geçersiz kılmak için kullanılan servis.
///
/// Vitrin veya blog makalesi yayınlandığında ya da güncellendiğinde
/// bu servisi çağırın. Ağ hatası olursa sadece log'a düşülür; kullanıcı
/// işlemi bundan etkilenmez.
class RevalidationService {
  final http.Client? _httpClient;

  const RevalidationService({http.Client? httpClient})
    : _httpClient = httpClient;

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
      debugPrint(
        '[RevalidationService] PUBLIC_SITE_URL tanımlanmamış; revalidation atlandı.',
      );
      return;
    }

    final secret = const String.fromEnvironment('REVALIDATION_SECRET');
    if (secret.isEmpty) {
      debugPrint(
        '[RevalidationService] REVALIDATION_SECRET tanımlanmamış; revalidation atlandı.',
      );
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

      if (response.statusCode == 200) {
        debugPrint(
          '[RevalidationService] Revalidated tags=$cleanTags paths=$cleanPaths ✓',
        );
      } else {
        debugPrint(
          '[RevalidationService] Revalidation başarısız: HTTP ${response.statusCode} — tags=$cleanTags paths=$cleanPaths',
        );
      }
    } catch (e) {
      // Ağ hatası hiçbir zaman kullanıcı işlemini engellemez.
      debugPrint(
        '[RevalidationService] Revalidation hatası: $e — tags=$tags paths=$paths',
      );
    }
  }

  String? _resolveEndpoint() {
    final origin = PublicSiteConfig.buildPublicLink('/api/revalidate');
    // buildPublicLink yalnızca path döndürüyorsa (origin tanımsız), null döner.
    if (!origin.startsWith('http')) return null;
    return origin;
  }
}
