import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/core/supabase_error_mapper.dart';

/// Blog yazıları ile ilgili tüm Supabase işlemlerini merkezileştirir.
class ArticleService {
  final SupabaseClient? _client;

  const ArticleService({SupabaseClient? client}) : _client = client;

  SupabaseClient get _resolveClient => _client ?? Supabase.instance.client;

  /// Mağazanın tüm yazılarını getirir.
  Future<Result<List<Map<String, dynamic>>>> fetchArticles(String storeSlug) async {
    try {
      final res = await _resolveClient
          .from('store_articles')
          .select()
          .eq('store_slug', storeSlug)
          .order('created_at', ascending: false);
      return Result.success(List<Map<String, dynamic>>.from(res as List));
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  /// İnceleme bekleyen yazıları getirir (moderasyon için).
  Future<Result<List<Map<String, dynamic>>>> fetchPendingReviewArticles() async {
    try {
      final res = await _resolveClient
          .from('store_articles')
          .select('id, store_slug, title, summary, status, created_at, seo_score, article_type, target_city')
          .eq('status', 'review')
          .order('created_at', ascending: true);
      return Result.success(List<Map<String, dynamic>>.from(res as List));
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  /// Yeni yazı oluşturur.
  Future<Result<void>> createArticle(Map<String, dynamic> payload) async {
    try {
      await _resolveClient.from('store_articles').insert(payload);
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  /// Mevcut yazıyı günceller.
  Future<Result<void>> updateArticle({
    required String id,
    required Map<String, dynamic> payload,
  }) async {
    try {
      await _resolveClient
          .from('store_articles')
          .update(payload)
          .eq('id', id);
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  /// Yazının durumunu günceller (moderasyon).
  Future<Result<void>> updateArticleStatus({
    required String id,
    required String status,
  }) async {
    try {
      await _resolveClient
          .from('store_articles')
          .update({'status': status})
          .eq('id', id);
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }
}
