import 'package:supabase_flutter/supabase_flutter.dart';

/// Blog yazıları ile ilgili tüm Supabase işlemlerini merkezileştirir.
class ArticleService {
  final SupabaseClient? _client;

  const ArticleService({SupabaseClient? client}) : _client = client;

  SupabaseClient get _resolveClient => _client ?? Supabase.instance.client;

  /// Mağazanın tüm yazılarını getirir.
  Future<List<Map<String, dynamic>>> fetchArticles(String storeSlug) async {
    final res = await _resolveClient
        .from('store_articles')
        .select()
        .eq('store_slug', storeSlug)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }

  /// İnceleme bekleyen yazıları getirir (moderasyon için).
  Future<List<Map<String, dynamic>>> fetchPendingReviewArticles() async {
    final res = await _resolveClient
        .from('store_articles')
        .select('id, store_slug, title, summary, status, created_at, seo_score, article_type, target_city')
        .eq('status', 'review')
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(res as List);
  }

  /// Yeni yazı oluşturur.
  Future<void> createArticle(Map<String, dynamic> payload) async {
    await _resolveClient.from('store_articles').insert(payload);
  }

  /// Mevcut yazıyı günceller.
  Future<void> updateArticle({
    required String id,
    required Map<String, dynamic> payload,
  }) async {
    await _resolveClient
        .from('store_articles')
        .update(payload)
        .eq('id', id);
  }

  /// Yazının durumunu günceller (moderasyon).
  Future<void> updateArticleStatus({
    required String id,
    required String status,
  }) async {
    await _resolveClient
        .from('store_articles')
        .update({'status': status})
        .eq('id', id);
  }
}
