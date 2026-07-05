import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/config/business_category_config.dart';

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
  static final _supabase = Supabase.instance.client;

  /// Bir kategoriye ait tum aktif gorselleri getir
  static Future<CategoryImageSet> getImagesForCategory(String categoryKey) async {
    try {
      final response = await _supabase
          .from('category_image_templates')
          .select('*')
          .eq('category_key', categoryKey)
          .eq('is_active', true)
          .order('display_order');

      final list = response as List;
      final images = list.map((r) => CategoryTemplateImage.fromJson(r as Map<String, dynamic>)).toList();

      return CategoryImageSet(
        categoryKey: categoryKey,
        categoryLabel: images.isNotEmpty ? images.first.categoryLabel : categoryKey,
        coverImages: images.where((i) => i.imageType == 'cover').toList(),
        logoImages: images.where((i) => i.imageType == 'logo_placeholder').toList(),
        galleryImages: images.where((i) => i.imageType == 'gallery').toList(),
        productImages: images.where((i) => i.imageType == 'product').toList(),
      );
    } catch (e, stackTrace) {
      debugPrint('CategoryImageService.getImagesForCategory error: $e');
      debugPrint(stackTrace.toString());
      return CategoryImageSet(categoryKey: categoryKey, categoryLabel: categoryKey);
    }
  }

  /// StoreData.kategori'den otomatik key uretip gorselleri getir
  static Future<CategoryImageSet?> getImagesForKategori(String kategori) async {
    final key = mapKategoriToKey(kategori);
    if (key == null) return null;
    return getImagesForCategory(key);
  }

  /// Tumu aktif kategorileri listele (distinct)
  static Future<List<CategoryOption>> getAvailableCategories() async {
    try {
      final response = await _supabase
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
    } catch (e, stackTrace) {
      debugPrint('CategoryImageService.getAvailableCategories error: $e');
      debugPrint(stackTrace.toString());
      return const [];
    }
  }

  /// Belirli bir kategorinin sablon gorseli olup olmadigini kontrol et
  static Future<bool> hasTemplateImages(String kategori) async {
    try {
      final key = mapKategoriToKey(kategori);
      if (key == null) return false;

      final response = await _supabase
          .from('category_image_templates')
          .select('id')
          .eq('category_key', key)
          .eq('is_active', true)
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      debugPrint('CategoryImageService.hasTemplateImages error: $e');
      return false;
    }
  }

  /// Bir kategorideki gorsel sayisini getir
  static Future<int> getTemplateCount(String kategori) async {
    try {
      final key = mapKategoriToKey(kategori);
      if (key == null) return 0;

      final response = await _supabase
          .from('category_image_templates')
          .select('id')
          .eq('category_key', key)
          .eq('is_active', true);

      return (response as List).length;
    } catch (e) {
      debugPrint('CategoryImageService.getTemplateCount error: $e');
      return 0;
    }
  }
}
