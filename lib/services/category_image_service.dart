import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/config/business_category_config.dart';

// ─── Category Image Template Model ───────────────────────────────────────────

/// Kategori gorsel sablonu - DB'den gelen ham veri
class CategoryTemplateImage {
  final String id;
  final String categoryKey;
  final String categoryLabel;
  final String imageType;
  final String imageUrl;
  final String? thumbnailUrl;
  final String? title;
  final String? description;
  final int displayOrder;

  const CategoryTemplateImage({
    required this.id,
    required this.categoryKey,
    required this.categoryLabel,
    required this.imageType,
    required this.imageUrl,
    this.thumbnailUrl,
    this.title,
    this.description,
    required this.displayOrder,
  });

  factory CategoryTemplateImage.fromJson(Map<String, dynamic> json) {
    return CategoryTemplateImage(
      id: json['id'] as String? ?? '',
      categoryKey: json['category_key'] as String? ?? '',
      categoryLabel: json['category_label'] as String? ?? '',
      imageType: json['image_type'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }
}

/// Bir kategoriye ait tum gorsel seti (kapak, logo, galeri, urun)
class CategoryImageSet {
  final String categoryKey;
  final String categoryLabel;
  final List<CategoryTemplateImage> coverImages;
  final List<CategoryTemplateImage> logoImages;
  final List<CategoryTemplateImage> galleryImages;
  final List<CategoryTemplateImage> productImages;

  const CategoryImageSet({
    required this.categoryKey,
    required this.categoryLabel,
    this.coverImages = const [],
    this.logoImages = const [],
    this.galleryImages = const [],
    this.productImages = const [],
  });

  int get totalCount =>
      coverImages.length +
      logoImages.length +
      galleryImages.length +
      productImages.length;

  /// Galeri gorsellerini StoreGalleryItem formatina donusturur
  List<StoreGalleryItem> toStoreGalleryItems() {
    return galleryImages
        .map(
          (img) => StoreGalleryItem(
            id: 'template_${img.id}',
            imageUrl: img.imageUrl,
            title: img.title ?? 'Gorsel',
          ),
        )
        .toList();
  }
}

/// Kategori secenekleri listesi icin
class CategoryOption {
  final String key;
  final String label;

  const CategoryOption({required this.key, required this.label});

  @override
  bool operator ==(Object other) =>
      other is CategoryOption && key == other.key;

  @override
  int get hashCode => key.hashCode;
}

// ─── Kategori <-> image_key eslestirmesi ────────────────────────────────────

/// StoreData.kategori degerini category_image_templates.category_key'e donusturur
String? mapKategoriToKey(String kategori) {
  if (kategori.trim().isEmpty) return null;
  return BusinessCategoryConfig.fromCategoryLabel(kategori).id;
}

// ─── Service ─────────────────────────────────────────────────────────────────

class CategoryImageService {
  static SupabaseClient? _supabaseClient;
  static SupabaseClient get _client => _supabaseClient ??= Supabase.instance.client;

  /// Bir kategoriye ait tum aktif gorselleri getir
  static Future<CategoryImageSet> getImagesForCategory(String categoryKey) async {
    try {
      final response = await _client
          .from('category_image_templates')
          .select('*')
          .eq('category_key', categoryKey)
          .eq('is_active', true)
          .order('display_order');

      final list = response as List;
      final images = list.map((r) => CategoryTemplateImage.fromJson(r as Map<String, dynamic>)).toList();

      final result = CategoryImageSet(
        categoryKey: categoryKey,
        categoryLabel: images.isNotEmpty ? images.first.categoryLabel : categoryKey,
        coverImages: images.where((i) => i.imageType == 'cover').toList(),
        logoImages: images.where((i) => i.imageType == 'logo_placeholder').toList(),
        galleryImages: images.where((i) => i.imageType == 'gallery').toList(),
        productImages: images.where((i) => i.imageType == 'product').toList(),
      );

      if (result.coverImages.isNotEmpty) {
        return result;
      }
      return getFallbackImageSet(categoryKey);
    } catch (_) {
      return getFallbackImageSet(categoryKey);
    }
  }

  /// 12 Kategori icin %100 dogrulanmis yüksek kaliteli telifsiz varsayilan gorsel seti
  static CategoryImageSet getFallbackImageSet(String categoryKey) {
    final normalized = categoryKey.toLowerCase().trim();
    final fallbackImage = _fallbackUrlMap[normalized] ?? _fallbackUrlMap['butik']!;

    final cover = CategoryTemplateImage(
      id: 'fallback_$normalized',
      categoryKey: normalized,
      categoryLabel: categoryKey,
      imageType: 'cover',
      imageUrl: fallbackImage,
      displayOrder: 1,
    );

    return CategoryImageSet(
      categoryKey: categoryKey,
      categoryLabel: categoryKey,
      coverImages: [cover],
      galleryImages: [cover],
    );
  }

  static const Map<String, String> _fallbackUrlMap = {
    'butik': 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&w=1200&q=80',
    'butik_giyim': 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&w=1200&q=80',
    'kuafor': 'https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=1200&q=80',
    'kuafor_guzellik': 'https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=1200&q=80',
    'kafe_lokanta': 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=1200&q=80',
    'kafe_restoran': 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=1200&q=80',
    'berber': 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&w=1200&q=80',
    'oto_arac': 'https://images.unsplash.com/photo-1520340356584-f9917d1eea6f?auto=format&fit=crop&w=1200&q=80',
    'oto_kuafor': 'https://images.unsplash.com/photo-1520340356584-f9917d1eea6f?auto=format&fit=crop&w=1200&q=80',
    'market_bakkal': 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=80',
    'gida': 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=80',
    'pastane_tatlici': 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?auto=format&fit=crop&w=1200&q=80',
    'firin': 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?auto=format&fit=crop&w=1200&q=80',
    'mobilya_dekorasyon': 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?auto=format&fit=crop&w=1200&q=80',
    'dekorasyon': 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?auto=format&fit=crop&w=1200&q=80',
    'spor_salonu': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=1200&q=80',
    'spor_fitness': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=1200&q=80',
    'dis_klinigi': 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?auto=format&fit=crop&w=1200&q=80',
    'eczane': 'https://images.unsplash.com/photo-1586015555751-63bb77f4322a?auto=format&fit=crop&w=1200&q=80',
    'teknik_servis': 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?auto=format&fit=crop&w=1200&q=80',
  };

  /// Tumu aktif kategorileri listele (distinct)
  static Future<List<CategoryOption>> getAvailableCategories() async {
    try {
      final response = await _client
          .from('category_image_templates')
          .select('category_key, category_label')
          .eq('is_active', true)
          .order('category_label');

      final list = response as List;
      final seen = <String>{};
      final options = <CategoryOption>[];

      for (final row in list) {
        final key = (row as Map<String, dynamic>)['category_key'] as String? ?? '';
        if (key.isNotEmpty && !seen.contains(key)) {
          seen.add(key);
          options.add(
            CategoryOption(
              key: key,
              label: row['category_label'] as String? ?? key,
            ),
          );
        }
      }

      return options;
    } catch (_) {
      return const [];
    }
  }
}
