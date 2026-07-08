import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/core/supabase_error_mapper.dart';
import 'package:vixrex/models/detected_product.dart';
import 'package:vixrex/utils/text_utils.dart';

/// Excel verisi ile ürün doğrulama servisi.
class OcrExcelVerifier {
  final SupabaseClient? _client;

  const OcrExcelVerifier({SupabaseClient? client}) : _client = client;

  SupabaseClient get _resolveClient => _client ?? Supabase.instance.client;

  /// Ürün listesini veritabanıyla doğrula.
  Future<List<DetectedProduct>> verify(List<DetectedProduct> products) async {
    final verified = <DetectedProduct>[];

    for (final product in products) {
      final normalized = TextUtils.normalizeTurkish(product.name);
      final result = await _searchProduct(normalized);

      result.when(
        success: (match) {
          if (match != null) {
            product.name = match['urun_adi'] as String? ?? product.name;
            product.brand = match['marka'] as String? ?? product.brand;
            product.category = match['kategori'] as String? ?? product.category;
            product.description = match['aciklama'] as String?;
            product.databaseEntryId = match['id'] as String?;
            product.confidence = 0.9;
            product.source = 'database_verified';
          }
          verified.add(product);
        },
        failure: (_) {
          // Veritabanında bulunamadı, mevcut haliyle ekle
          verified.add(product);
        },
      );
    }

    return verified;
  }

  /// Veritabanında ürün ara.
  Future<Result<Map<String, dynamic>?>> _searchProduct(String normalized) async {
    try {
      final res = await _resolveClient
          .from('product_database')
          .select('id, urun_adi, marka, kategori, aciklama, ocr_eslesme_kelimeleri')
          .textSearch('ocr_eslesme_kelimeleri', normalized)
          .limit(1)
          .maybeSingle();

      return Result.success(res);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  /// En iyi eşleşmeyi bul.
  Future<ProductMatch?> findBestMatch(String normalized, {double threshold = 0.7}) async {
    final result = await _searchProduct(normalized);

    return result.when(
      success: (match) {
        if (match == null) return null;
        return ProductMatch(
          urunAdi: match['urun_adi'] as String? ?? '',
          marka: match['marka'] as String? ?? '',
          kategori: match['kategori'] as String? ?? '',
          confidence: threshold,
        );
      },
      failure: (_) => null,
    );
  }

  /// Veritabanına ürün kaydet (yeni ürün için).
  Future<Result<void>> saveProduct(Map<String, dynamic> product) async {
    try {
      await _resolveClient.from('product_database').insert(product);
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }
}

/// Ürün eşleştirme sonucu.
class ProductMatch {
  final String urunAdi;
  final String marka;
  final String kategori;
  final double confidence;

  const ProductMatch({
    required this.urunAdi,
    required this.marka,
    required this.kategori,
    required this.confidence,
  });
}
