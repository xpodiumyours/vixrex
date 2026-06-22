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

  const RevalidationService({http.Client? httpClient}) : _httpClient = httpClient;

  /// Vitrin profil sayfasını ve blog listesini yeniden oluşturur.
  Future<void> revalidateStore(String slug) async {
    await _revalidate(tag: 'store-$slug');
  }

  /// Belirli bir blog makalesini yeniden oluşturur.
  Future<void> revalidateArticle(String storeSlug, String articleSlug) async {
    await _revalidate(tag: 'article-$storeSlug-$articleSlug');
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

  Future<void> _revalidate({required String tag}) async {
    final endpoint = _resolveEndpoint();
    if (endpoint == null) {
      debugPrint('[RevalidationService] PUBLIC_SITE_URL tanımlanmamış; revalidation atlandı.');
      return;
    }

    final secret = const String.fromEnvironment('REVALIDATION_SECRET');
    if (secret.isEmpty) {
      debugPrint('[RevalidationService] REVALIDATION_SECRET tanımlanmamış; revalidation atlandı.');
      return;
    }

    final uri = Uri.parse(endpoint).replace(queryParameters: {'tag': tag});

    try {
      final client = _httpClient ?? http.Client();
      final response = await client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-revalidate-secret': secret,
        },
        body: jsonEncode({'tag': tag}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('[RevalidationService] Revalidated tag=$tag ✓');
      } else {
        debugPrint(
          '[RevalidationService] Revalidation başarısız: HTTP ${response.statusCode} — tag=$tag',
        );
      }
    } catch (e) {
      // Ağ hatası hiçbir zaman kullanıcı işlemini engellemez.
      debugPrint('[RevalidationService] Revalidation hatası: $e — tag=$tag');
    }
  }

  String? _resolveEndpoint() {
    final origin = PublicSiteConfig.buildPublicLink('/api/revalidate');
    // buildPublicLink yalnızca path döndürüyorsa (origin tanımsız), null döner.
    if (!origin.startsWith('http')) return null;
    return origin;
  }
}
