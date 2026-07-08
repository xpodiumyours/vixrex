import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/core/supabase_error_mapper.dart';

/// Premium üyelik servisi.
class PremiumService {
  final SupabaseClient? _client;

  const PremiumService({SupabaseClient? client}) : _client = client;

  SupabaseClient get _resolveClient => _client ?? Supabase.instance.client;

  /// Kullanıcının premium olup olmadığını kontrol et.
  Future<Result<bool>> isPremium(String userId) async {
    try {
      final res = await _resolveClient
          .from('profiles')
          .select('is_premium, premium_expires_at')
          .eq('id', userId)
          .maybeSingle();

      if (res == null) return const Result.success(false);

      final isPremium = res['is_premium'] as bool? ?? false;
      final expiresAt = res['premium_expires_at'] as String?;

      if (!isPremium) return const Result.success(false);
      if (expiresAt == null) return const Result.success(true);

      final expiry = DateTime.parse(expiresAt);
      return Result.success(expiry.isAfter(DateTime.now()));
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  /// OCR kullanım sayısını getir.
  Future<Result<int>> getOcrUsageCount(String userId) async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);

      final res = await _resolveClient
          .from('ocr_usage')
          .select('usage_count')
          .eq('user_id', userId)
          .eq('usage_date', today)
          .maybeSingle();

      if (res == null) return const Result.success(0);

      final count = res['usage_count'] as int? ?? 0;
      return Result.success(count);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  /// OCR kullanım sayısını artır.
  Future<Result<void>> incrementOcrUsage(String userId) async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);

      // Mevcut kaydı bul
      final existing = await _resolveClient
          .from('ocr_usage')
          .select('id, usage_count')
          .eq('user_id', userId)
          .eq('usage_date', today)
          .maybeSingle();

      if (existing != null) {
        // Güncelle
        final currentCount = existing['usage_count'] as int? ?? 0;
        await _resolveClient
            .from('ocr_usage')
            .update({'usage_count': currentCount + 1})
            .eq('id', existing['id']);
      } else {
        // Yeni kayıt oluştur
        await _resolveClient.from('ocr_usage').insert({
          'user_id': userId,
          'usage_date': today,
          'usage_count': 1,
        });
      }

      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  /// OCR geçmişini kaydet.
  Future<Result<void>> saveOcrHistory({
    required String userId,
    required String imageUrl,
    required List<Map<String, dynamic>> products,
    required double confidence,
  }) async {
    try {
      await _resolveClient.from('ocr_history').insert({
        'user_id': userId,
        'image_url': imageUrl,
        'products': products,
        'confidence': confidence,
        'product_count': products.length,
      });

      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  /// Premium satın alma (basit implementasyon).
  Future<Result<void>> purchasePremium({
    required String userId,
    required String plan, // 'monthly' veya 'yearly'
  }) async {
    try {
      final expiresAt = plan == 'yearly'
          ? DateTime.now().add(const Duration(days: 365))
          : DateTime.now().add(const Duration(days: 30));

      await _resolveClient
          .from('profiles')
          .update({
            'is_premium': true,
            'premium_expires_at': expiresAt.toIso8601String(),
            'premium_plan': plan,
          })
          .eq('id', userId);

      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }
}
