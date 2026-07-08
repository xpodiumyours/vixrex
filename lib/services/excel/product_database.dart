import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/core/supabase_error_mapper.dart';
import 'package:vixrex/models/product_database_entry.dart';
import 'package:vixrex/utils/text_utils.dart';

/// Ürün veritabanı servisi.
class ProductDatabase {
  final SupabaseClient? _client;

  const ProductDatabase({SupabaseClient? client}) : _client = client;

  SupabaseClient get _resolveClient => _client ?? Supabase.instance.client;

  /// Veritabanından ürün ara.
  Future<Result<List<ProductDatabaseEntry>>> search(String query) async {
    try {
      final normalized = TextUtils.normalizeTurkish(query);
      final res = await _resolveClient
          .from('product_database')
          .select('id, urun_adi, normalize_urun_adi, marka, marka_alias, kategori, alt_kategori, aciklama, anahtar_kelimeler, ocr_eslesme_kelimeleri, ambalaj_tipi, hacim_miktar, birim')
          .textSearch('ocr_eslesme_kelimeleri', normalized)
          .limit(5);

      final entries = (res as List)
          .map((json) => ProductDatabaseEntry.fromJson(json as Map<String, dynamic>))
          .toList();

      return Result.success(entries);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  /// En iyi eşleşmeyi bul.
  Future<Result<ProductDatabaseEntry?>> findBestMatch(String query) async {
    final result = await search(query);

    return result.when(
      success: (entries) {
        if (entries.isEmpty) return Result.success(null);

        // En yüksek skorlu olanı seç
        entries.sort((a, b) => b.matchScore(query).compareTo(a.matchScore(query)));
        final best = entries.first;

        // Minimum eşik kontrolü
        if (best.matchScore(query) < 0.5) {
          return const Result.success(null);
        }

        return Result.success(best);
      },
      failure: (failure) => Result.failure(failure),
    );
  }

  /// Yeni ürün kaydet.
  Future<Result<void>> saveEntry(ProductDatabaseEntry entry) async {
    try {
      await _resolveClient.from('product_database').insert(entry.toJson());
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  /// Çoklu ürün kaydet.
  Future<Result<void>> saveEntries(List<ProductDatabaseEntry> entries) async {
    try {
      final jsonList = entries.map((e) => e.toJson()).toList();
      await _resolveClient.from('product_database').insert(jsonList);
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  /// Kategorilere göre ürün listele.
  Future<Result<List<ProductDatabaseEntry>>> getByCategory(String category) async {
    try {
      final res = await _resolveClient
          .from('product_database')
          .select('id, urun_adi, normalize_urun_adi, marka, marka_alias, kategori, alt_kategori, aciklama, anahtar_kelimeler, ocr_eslesme_kelimeleri, ambalaj_tipi, hacim_miktar, birim')
          .eq('kategori', category)
          .order('urun_adi');

      final entries = (res as List)
          .map((json) => ProductDatabaseEntry.fromJson(json as Map<String, dynamic>))
          .toList();

      return Result.success(entries);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }
}
