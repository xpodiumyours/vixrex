import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/services/image_optimization_service.dart';
import 'package:vixrex/services/product_image_policy.dart';

class StoreShelfUploadService {
  const StoreShelfUploadService({
    this.imageOptimizationService = const ImageOptimizationService(),
  });

  static const String _bucketName = 'shelf-images';

  /// Depoya yazılan nesnelerin önbellek süresi: 1 yıl.
  ///
  /// Dosya adı zaman damgalı, içerik hiç değişmiyor. Varsayılan bir saatlik
  /// önbellek tekrar eden ziyaretlerde boşuna trafik harcıyordu — ücretsiz
  /// planda aylık 5 GB sınırı var (28 Ağustos 2026 ölçümü).
  /// Web tarafındaki karşılığı: `public_web/src/lib/gorselSikistir.ts`
  static const String _onbellekSaniye = '31536000';

  final ImageOptimizationService imageOptimizationService;

  /// Storage'a görsel yükler ve public URL döner.
  ///
  /// Path formatı: `{safeSlug}/{timestamp}.{extension}`
  Future<String> uploadShelfImage(
    Uint8List bytes,
    String slug, {
    String fileExtension = 'jpg',
    String contentType = 'image/jpeg',
    int minShortEdge = 0,
  }) async {
    final safeSlug = sanitizeSlug(slug);
    final optimizedImage = await imageOptimizationService.optimize(
      bytes,
      fileExtension: sanitizeExtension(fileExtension),
      contentType: contentType,
      minShortEdge: minShortEdge,
    );
    final path =
        '$safeSlug/${DateTime.now().millisecondsSinceEpoch}.'
        '${optimizedImage.extension}';

    try {
      final bucket = Supabase.instance.client.storage.from(_bucketName);
      await bucket.uploadBinary(
        path,
        optimizedImage.bytes,
        fileOptions: FileOptions(
          contentType: optimizedImage.contentType,
          cacheControl: _onbellekSaniye,
          upsert: false,
        ),
      );
      return bucket.getPublicUrl(path);
    } on ImageOptimizationException {
      rethrow;
    } catch (error) {
      throw ImageOptimizationException('Raf fotoğrafı yüklenemedi: $error');
    }
  }

  /// Galeri görseli yükler. Slug içine `/gallery` alt dizini eklenir.
  Future<String> uploadGalleryImage(
    Uint8List bytes,
    String slug, {
    String fileExtension = 'jpg',
    String contentType = 'image/jpeg',
  }) {
    return uploadShelfImage(
      bytes,
      '${sanitizeSlug(slug)}/gallery',
      fileExtension: fileExtension,
      contentType: contentType,
    );
  }

  Future<String> uploadProductImage(
    Uint8List bytes,
    String slug,
    String productId, {
    String fileExtension = 'jpg',
    String contentType = 'image/jpeg',
  }) {
    return uploadShelfImage(
      bytes,
      '${sanitizeSlug(slug)}/products/${sanitizeSlug(productId)}',
      fileExtension: fileExtension,
      contentType: contentType,
      minShortEdge: ProductImagePolicy.minSourceShortEdge,
    );
  }

  /// Slug'ı güvenli hale getirir: başındaki/sonundaki slash'ları temizler.
  /// Boş string gelirse `'magazaniz'` döner.
  ///
  /// Test edilebilmesi için public API olarak açıktır.
  @visibleForTesting
  String sanitizeSlug(String slug) {
    final cleaned = slug.trim().replaceAll(RegExp(r'^/+|/+$'), '');
    if (cleaned.isEmpty) return 'magazaniz';

    final segments =
        cleaned
            .split('/')
            .map(_sanitizePathSegment)
            .where((segment) => segment.isNotEmpty)
            .toList();

    return segments.isEmpty ? 'magazaniz' : segments.join('/');
  }

  String _sanitizePathSegment(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  /// Uzantıyı normalleştirir: `.jpeg` → `jpg`, geçersiz → `jpg`.
  ///
  /// Test edilebilmesi için public API olarak açıktır.
  @visibleForTesting
  String sanitizeExtension(String extension) {
    final cleaned = extension.trim().toLowerCase().replaceAll('.', '');
    if (cleaned == 'jpeg') return 'jpg';
    if (cleaned == 'jpg' || cleaned == 'png' || cleaned == 'webp') {
      return cleaned;
    }
    return 'jpg';
  }
}
