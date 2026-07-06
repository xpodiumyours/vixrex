import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/category_image_service.dart';
import 'package:vixrex/services/store_local_storage_service.dart';

// ─── Otomatik Doldurma Secenekleri ───────────────────────────────────────────

class AutoFillOptions {
  final bool fillCover;
  final bool fillLogo;
  final bool fillGallery;
  final bool fillProducts;

  const AutoFillOptions({
    this.fillCover = true,
    this.fillLogo = true,
    this.fillGallery = true,
    this.fillProducts = true,
  });

  factory AutoFillOptions.all() => const AutoFillOptions();

  factory AutoFillOptions.galleryOnly() => const AutoFillOptions(
        fillCover: false,
        fillLogo: false,
        fillGallery: true,
        fillProducts: false,
      );

  factory AutoFillOptions.coverOnly() => const AutoFillOptions(
        fillCover: true,
        fillLogo: false,
        fillGallery: false,
        fillProducts: false,
      );

  List<String> get enabledFields {
    final fields = <String>[];
    if (fillCover) fields.add('kapak');
    if (fillLogo) fields.add('logo');
    if (fillGallery) fields.add('galeri');
    if (fillProducts) fields.add('urunler');
    return fields;
  }
}

// ─── Sonuc Modeli ────────────────────────────────────────────────────────────

class AutoFillResult {
  final bool success;
  final List<String> appliedFields;
  final int imageCount;
  final String? error;

  const AutoFillResult({
    required this.success,
    this.appliedFields = const [],
    this.imageCount = 0,
    this.error,
  });

  factory AutoFillResult.error(String message) =>
      AutoFillResult(success: false, error: message);

  /// Kac alanin guncellendigini gosterir
  int get appliedCount => appliedFields.length;

  /// Tahmini puan artisi (her alan ~10 puan)
  int get estimatedScoreBoost => appliedCount * 10;
}

// ─── Auto Fill Service ───────────────────────────────────────────────────────

class AutoFillService {
  static final _supabase = Supabase.instance.client;

  /// Vitrini kategori sablonuyla otomatik doldur (RPC fonksiyonunu kullanir)
  static Future<AutoFillResult> applyCategoryTemplate({
    required String storeId,
    required String categoryKey,
    AutoFillOptions options = const AutoFillOptions(),
    String? selectedCoverUrl,
  }) async {
    try {
      // RPC fonksiyonunu cagir
      final result = await _supabase.rpc(
        'apply_category_template',
        params: {
          'p_store_id': storeId,
          'p_category_key': categoryKey,
          'p_fill_cover': options.fillCover,
          'p_fill_logo': options.fillLogo,
          'p_fill_gallery': options.fillGallery,
          'p_fill_products': options.fillProducts,
        },
      );

      final resultMap = result as Map<String, dynamic>;

      if (resultMap['error'] != null) {
        return AutoFillResult.error(resultMap['error'] as String);
      }

      final success = resultMap['success'] as bool? ?? false;
      final appliedFields = <String>[];

      if (resultMap['cover'] == true) appliedFields.add('kapak');
      if (resultMap['logo'] == true) appliedFields.add('logo');
      if (resultMap['gallery'] == true) appliedFields.add('galeri');
      if (resultMap['products'] == true) appliedFields.add('urunler');

      return AutoFillResult(
        success: success,
        appliedFields: appliedFields,
        imageCount: resultMap['image_count'] as int? ?? 0,
      );
    } catch (e) {
      // RPC calismazsa manuel doldur
      return _applyManual(
        storeId: storeId,
        categoryKey: categoryKey,
        options: options,
        selectedCoverUrl: selectedCoverUrl,
      );
    }
  }

  /// Manuel doldurma (fallback - RPC calismazsa)
  static Future<AutoFillResult> _applyManual({
    required String storeId,
    required String categoryKey,
    required AutoFillOptions options,
    String? selectedCoverUrl,
  }) async {
    try {
      // 1. Gorselleri cek
      final imageSet = await CategoryImageService.getImagesForCategory(
        categoryKey,
      );

      // 2. Mevcut store verisini cek
      final storeResponse = await _supabase
          .from('stores')
          .select('shelf_image_url, logo_url, gallery_items, products')
          .eq('id', storeId)
          .single();

      final updates = <String, dynamic>{};
      final appliedFields = <String>[];

      // 3. Kapak gorseli
      if (options.fillGallery && imageSet.galleryImages.isNotEmpty) {
        final currentGallery = storeResponse['gallery_items'];
        final galleryEmpty = currentGallery == null ||
            (currentGallery is List && currentGallery.isEmpty);

        if (galleryEmpty) {
          final galleryItems = imageSet.galleryImages
              .map((img) => {
                    'imageUrl': img.imageUrl,
                    'title': img.title ?? 'Gorsel',
                  })
              .toList();
          updates['gallery_items'] = galleryItems;
          appliedFields.add('galeri');
        }
      }

      // 4. Kapak (shelf_image_url)
      if (options.fillCover && imageSet.coverImages.isNotEmpty) {
        final currentCover = storeResponse['shelf_image_url'] as String? ?? '';
        if (currentCover.isEmpty) {
          updates['shelf_image_url'] = selectedCoverUrl ?? imageSet.coverImages.first.imageUrl;
          appliedFields.add('kapak');
        }
      }

      // 5. Logo
      if (options.fillLogo && imageSet.logoImages.isNotEmpty) {
        final currentLogo = storeResponse['logo_url'] as String?;
        if (currentLogo == null || currentLogo.isEmpty) {
          updates['logo_url'] = imageSet.logoImages.first.imageUrl;
          appliedFields.add('logo');
        }
      }

      // 6. Urunler
      if (options.fillProducts && imageSet.productImages.isNotEmpty) {
        final currentProducts = storeResponse['products'];
        final productsEmpty = currentProducts == null ||
            (currentProducts is List && currentProducts.isEmpty);

        if (productsEmpty) {
          final templateProducts = _buildTemplateProducts(
            imageSet.productImages,
            categoryKey,
          );
          updates['products'] = templateProducts;
          appliedFields.add('urunler');
        }
      }

      // 7. Guncelle
      if (updates.isNotEmpty) {
        await _supabase.from('stores').update(updates).eq('id', storeId);
        // Update local storage so initialize() sees fresh data
        await _refreshLocalStoreData(storeId);
      }

      return AutoFillResult(
        success: true,
        appliedFields: appliedFields,
        imageCount: imageSet.totalCount,
      );
    } catch (e) {
      return AutoFillResult.error('Doldurma hatasi: $e');
    }
  }

  /// Kategori key'ine gore urun isimleri
  static List<Map<String, dynamic>> _buildTemplateProducts(
    List<CategoryTemplateImage> productImages,
    String categoryKey,
  ) {
    final names = _getTemplateProductNames(categoryKey);

    return productImages.asMap().entries.map((entry) {
      final index = entry.key;
      final image = entry.value;
      final name = index < names.length ? names[index] : 'Urun ${index + 1}';

      return {
        'id': 'template_${DateTime.now().millisecondsSinceEpoch}_$index',
        'name': name,
        'description': '',
        'price': '',
        'imageUrls': [image.imageUrl],
        'isVisible': true,
        'source': 'category_template',
      };
    }).toList();
  }

  static List<String> _getTemplateProductNames(String categoryKey) {
    switch (categoryKey) {
      case 'butik_giyim':
        return ['Elbise', 'Gomlek', 'Pantolon', 'Aksesuar'];
      case 'kuafor_guzellik':
        return ['Sac Kesimi', 'Sac Boyama', 'Bakim Paketi', 'Makyaj'];
      case 'kafe_restoran':
        return ['Kahve', 'Tatli', 'Ana Yemek', 'Icecek'];
      case 'teknik_servis':
        return ['Ekran Degisimi', 'Batarya Degisimi', 'Yazilim Guncelleme', 'Koruyucu Kilif'];
      case 'berber':
        return ['Sakal Tiras', 'Sac Kesimi', 'Cilt Bakimi', 'Bakim Paketi'];
      case 'oto_kuafor':
        return ['Ic Temizlik', 'Dis Yikama', 'Cila', 'Seramik Kaplama'];
      case 'market_bakkal':
        return ['Meyve Sebze', 'Icecek', 'Atistirmalik', 'Temel Gida'];
      case 'pastane_tatlici':
        return ['Pasta', 'Kurabiye', 'Baklava', 'Ekmek'];
      case 'mobilya_dekorasyon':
        return ['Koltuk', 'Masa', 'Aksesuar', 'Aydinlatma'];
      case 'spor_salonu':
        return ['Gunluk Uyelik', 'Aylik Paket', 'Ozel Ders', 'PT Seansi'];
      case 'dis_klinigi':
        return ['Dis Beyazlatma', 'Dolgu', 'Kanal Tedavisi', 'Muayene'];
      case 'eczane':
        return ['Vitamin', 'Bebek Urunleri', 'Kisisel Bakim', 'Saglik Urunleri'];
      default:
        return ['Urun 1', 'Urun 2', 'Urun 3', 'Urun 4'];
    }
  }

  /// Daha once auto-fill yapilip yapilmadigini kontrol et
  static Future<bool> wasAutoFillApplied(String storeId) async {
    final response = await _supabase
        .from('store_category_image_usage')
        .select('id')
        .eq('store_id', storeId)
        .limit(1);

    return (response as List).isNotEmpty;
  }

  /// Supabase'den taze veri çekip yerel depolamaya kaydeder.
  static Future<void> _refreshLocalStoreData(String storeId) async {
    try {
      final response = await _supabase
          .from('stores')
          .select()
          .eq('id', storeId)
          .single();
      final rawJson = jsonEncode(response);
      final decoded = jsonDecode(rawJson);
      if (decoded is Map<String, dynamic>) {
        final data = StoreData.fromJson(decoded);
        await const StoreLocalStorageService().saveVitrinData(data);
      }
    } catch (_) {}
  }
}
