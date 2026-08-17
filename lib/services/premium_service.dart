import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/core/supabase_error_mapper.dart';
import 'package:vixrex/utils/failure.dart';

/// Premium üyelik servisi — VİTRİN bazlı (spec 2026-08-17).
///
/// Premium `stores.premium_expires_at` üzerinde tutulur (esnaf hesap
/// açmaz, vitrinin sahipliği edit_token üzerindendir — PR #1). İstemci
/// premium YAZAMAZ: ödeme yalnız doğrulanmış PayTR callback'i tarafından
/// işlenir (PR #4, record_premium_payment). Bu servis yalnız okur.
///
/// Okuma yolu: `get_store_premium_status` RPC'si edit_token kanıtı ister
/// (create_owner_session ile aynı güven deseni) — başkasının vitrininin
/// premium durumu okunamaz.
///
/// NOT (kapsam): OCR yardımcıları bu dosyada kalmıştır ama ayrı bir
/// özelliktir (ürün katalog OCR) ve bu premium modelinin parçası
/// değildir — PR #6'da dokunulmadı.
class PremiumService {
  final SupabaseClient? _client;

  const PremiumService({SupabaseClient? client}) : _client = client;

  SupabaseClient get _resolveClient => _client ?? Supabase.instance.client;

  /// Kendi vitrininin premium durumunu okur. edit_token gizli anahtardır —
  /// yalnız kendi vitrinine ait token eşleşirse bilgi döner.
  Future<Result<StorePremiumStatus>> getPremiumStatus({
    required String slug,
    required String editToken,
  }) async {
    try {
      final res = await _resolveClient.rpc(
        'get_store_premium_status',
        params: {'p_slug': slug, 'p_edit_token': editToken},
      );
      if (res is! Map) {
        return Result.failure(Failure('Premium durumu alınamadı.'));
      }
      return Result.success(
        StorePremiumStatus.fromJson(res.cast<String, dynamic>()),
      );
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  /// Kendi vitrininin premium olup olmadığını söyler (kolaylık).
  Future<Result<bool>> isPremiumForStore({
    required String slug,
    required String editToken,
  }) async {
    final result = await getPremiumStatus(slug: slug, editToken: editToken);
    if (result.isFailure) return Result.failure(result.failure!);
    return Result.success(result.data!.isPremium);
  }

  /// OCR kullanım sayısını getir.
  Future<Result<int>> getOcrUsageCount(String userId) async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);

      final res =
          await _resolveClient
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

  /// OCR kullanımını sunucu tarafında kontrol et ve artır (atomik RPC).
  Future<Result<OcrUsageCheck>> checkAndIncrementOcrUsage(String userId) async {
    try {
      final res = await _resolveClient.rpc(
        'check_and_increment_ocr_usage',
        params: {'p_user_id': userId},
      );

      final data = res as Map<String, dynamic>;
      return Result.success(
        OcrUsageCheck(
          allowed: data['allowed'] as bool? ?? false,
          remaining: data['remaining'] as int? ?? 0,
          isPremium: data['is_premium'] as bool? ?? false,
          message: data['message'] as String?,
        ),
      );
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
}

/// Bir vitrinin premium durumu (get_store_premium_status yanıtı).
class StorePremiumStatus {
  const StorePremiumStatus({
    required this.storeId,
    required this.isPremium,
    this.premiumExpiresAt,
  });

  factory StorePremiumStatus.fromJson(Map<String, dynamic> json) {
    final raw = json['premium_expires_at'];
    return StorePremiumStatus(
      storeId: json['store_id']?.toString() ?? '',
      isPremium: json['is_premium'] == true,
      premiumExpiresAt: raw is String ? DateTime.tryParse(raw) : null,
    );
  }

  final String storeId;
  final bool isPremium;
  final DateTime? premiumExpiresAt;
}

/// OCR kullanım kontrolü sonucu.
class OcrUsageCheck {
  final bool allowed;
  final int remaining;
  final bool isPremium;
  final String? message;

  const OcrUsageCheck({
    required this.allowed,
    required this.remaining,
    required this.isPremium,
    this.message,
  });
}
