import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/core/supabase_error_mapper.dart';

/// Blog yazıları ile ilgili tüm Supabase işlemlerini merkezileştirir.
class ArticleService {
  final SupabaseClient? _client;

  const ArticleService({SupabaseClient? client}) : _client = client;

  SupabaseClient get _resolveClient => _client ?? Supabase.instance.client;

  /// Mağazanın tüm yazılarını getirir.
  Future<Result<List<Map<String, dynamic>>>> fetchArticles(
    String storeSlug,
  ) async {
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

  /// Yayındaki merkezi Vixrex yazılarını sınırlı sayıda getirir.
  /// Katman 3: bütün kütüphane istemciye tek seferde yüklenmez.
  Future<Result<List<Map<String, dynamic>>>> fetchVixrexLibrary({
    int limit = 20,
  }) async {
    try {
      final safeLimit = limit.clamp(1, 50);
      final res = await _resolveClient
          .from('vixrex_blog_articles')
          .select(
            'id, slug, title, summary, cover_image_url, reading_minutes, primary_topic, purpose, published_at',
          )
          .eq('status', 'published')
          .order('published_at', ascending: false)
          .limit(safeLimit);
      return Result.success(List<Map<String, dynamic>>.from(res as List));
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  /// Merkezi Vixrex yazısını bu vitrinin bloguna TASLAK olarak çeker.
  /// Yetki ve published→draft kuralı DB RPC içinde yeniden doğrulanır.
  Future<Result<Map<String, dynamic>>> importVixrexBlogArticle({
    required String storeSlug,
    required String sourceArticleId,
    required String mode,
  }) async {
    try {
      final res = await _resolveClient.rpc(
        'import_vixrex_blog_article_to_store',
        params: {
          'p_store_slug': storeSlug,
          'p_source_article_id': sourceArticleId,
          'p_mode': mode,
          'p_session_token': null,
        },
      );
      if (res is! Map) {
        throw const FormatException('Geçersiz blog import yanıtı.');
      }
      return Result.success(Map<String, dynamic>.from(res));
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  /// İnceleme bekleyen yazıları getirir (moderasyon için).
  Future<Result<List<Map<String, dynamic>>>>
  fetchPendingReviewArticles() async {
    try {
      final res = await _resolveClient
          .from('store_articles')
          .select(
            'id, store_slug, title, summary, status, created_at, seo_score, article_type, target_city',
          )
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
      await _resolveClient.from('store_articles').update(payload).eq('id', id);
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
