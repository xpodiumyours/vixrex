import 'package:flutter/foundation.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/models/created_product.dart';
import 'package:vixrex/models/product_rich_data.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/repositories/product_repository.dart';
import 'package:vixrex/repositories/supabase_product_repository.dart';
import 'package:vixrex/services/product_image_cleanup_service.dart';
import 'package:vixrex/services/product_image_policy.dart';
import 'package:vixrex/utils/failure.dart';

/// Ürün CRUD işlemleri için servis katmanı.
class ProductService {
  ProductRepository? _repository;
  ProductImageCleanupService? _imageCleanupService;

  ProductService({
    ProductRepository? repository,
    ProductImageCleanupService? imageCleanupService,
  }) : _repository = repository,
       _imageCleanupService = imageCleanupService;

  ProductRepository get _repo => _repository ??= SupabaseProductRepository();
  ProductImageCleanupService get _imageCleanup =>
      _imageCleanupService ??= const ProductImageCleanupService();

  bool _sameImages(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  Future<List<Product>> fetchProducts(String storeId) async {
    try {
      return await _repo.getProductsByStoreId(storeId);
    } catch (e) {
      if (kDebugMode) debugPrint('fetchProducts hatası: $e');
      return [];
    }
  }

  Future<List<Product>> fetchVisibleProducts(String storeId) async {
    try {
      return await _repo.getVisibleProductsByStoreId(storeId);
    } catch (e) {
      if (kDebugMode) debugPrint('fetchVisibleProducts hatası: $e');
      return [];
    }
  }

  Future<Result<CreatedProduct>> addProduct({
    required String storeId,
    required String editToken,
    required String name,
    String description = '',
    String priceText = '',
    double? priceAmount,
    double? oldPriceAmount,
    String? badgeTag,
    String? fulfillmentRegion,
    List<String> imageUrls = const [],
    String? categoryId,
    String sourceType = 'manual',
    String? externalProductId,
    bool isVisible = true,
    int sortOrder = 0,
    String? brand,
    String? barcode,
    int? stockQuantity,
    String? stockStatus,
    ProductRichMetadata? metadata,
    List<ProductVariantData> variants = const [],
  }) async {
    final imageError = ProductImagePolicy.validate(imageUrls);
    if (imageError != null) return Result.failure(Failure(imageError));
    final normalizedImageUrls = ProductImagePolicy.normalize(imageUrls);

    try {
      final created = await _repo.createRichProduct(
        storeId: storeId,
        editToken: editToken,
        name: name,
        description: description,
        priceText: priceText,
        priceAmount: priceAmount,
        oldPriceAmount: oldPriceAmount,
        badgeTag: badgeTag,
        fulfillmentRegion: fulfillmentRegion,
        imageUrls: normalizedImageUrls,
        categoryId: categoryId,
        sourceType: sourceType,
        externalProductId: externalProductId,
        isVisible: isVisible,
        sortOrder: sortOrder,
        brand: brand,
        barcode: barcode,
        stockQuantity: stockQuantity,
        stockStatus: stockStatus,
        metadata: metadata,
        variants: variants,
      );
      return Result.success(created);
    } catch (e) {
      final msg = _mapError(e);
      if (kDebugMode) debugPrint('addProduct hatası: $msg');
      return Result.failure(Failure(msg));
    }
  }

  Future<Result<void>> updateProduct({
    required String productId,
    String? editToken,
    String? name,
    String? description,
    String? priceText,
    double? priceAmount,
    double? oldPriceAmount,
    String? badgeTag,
    String? fulfillmentRegion,
    List<String>? imageUrls,
    String? categoryId,
    bool? isVisible,
    int? sortOrder,
    int? stockQuantity,
    String? stockStatus,
    String? brand,
    String? barcode,
    ProductRichMetadata? metadata,
    List<ProductVariantData>? variants,
    bool clearCategory = false,
    bool clearPriceAmount = false,
    bool clearOldPriceAmount = false,
    bool clearBadgeTag = false,
    bool clearFulfillmentRegion = false,
    bool clearStockQuantity = false,
    bool clearStockStatus = false,
    bool clearBrand = false,
    bool clearBarcode = false,
    bool clearMetadata = false,
    bool clearVariants = false,
  }) async {
    List<String>? normalizedImageUrls;
    ProductImageSnapshot? previousImages;
    if (imageUrls != null) {
      normalizedImageUrls = ProductImagePolicy.normalize(imageUrls);
      previousImages = await _imageCleanup.snapshot(productId);
      final previousNormalized =
          previousImages == null
              ? null
              : ProductImagePolicy.normalize(previousImages.imageUrls);
      final imageListChanged =
          previousNormalized == null ||
          !_sameImages(normalizedImageUrls, previousNormalized);
      if (imageListChanged) {
        final imageError = ProductImagePolicy.validate(normalizedImageUrls);
        if (imageError != null) return Result.failure(Failure(imageError));
      }
    }

    try {
      await _repo.updateRichProduct(
        productId: productId,
        editToken: editToken,
        name: name,
        description: description,
        priceText: priceText,
        priceAmount: priceAmount,
        oldPriceAmount: oldPriceAmount,
        badgeTag: badgeTag,
        fulfillmentRegion: fulfillmentRegion,
        imageUrls: normalizedImageUrls,
        categoryId: categoryId,
        isVisible: isVisible,
        sortOrder: sortOrder,
        stockQuantity: stockQuantity,
        stockStatus: stockStatus,
        brand: brand,
        barcode: barcode,
        metadata: metadata,
        variants: variants,
        clearCategory: clearCategory,
        clearPriceAmount: clearPriceAmount,
        clearOldPriceAmount: clearOldPriceAmount,
        clearBadgeTag: clearBadgeTag,
        clearFulfillmentRegion: clearFulfillmentRegion,
        clearStockQuantity: clearStockQuantity,
        clearStockStatus: clearStockStatus,
        clearBrand: clearBrand,
        clearBarcode: clearBarcode,
        clearMetadata: clearMetadata,
        clearVariants: clearVariants,
      );
      if (previousImages != null && normalizedImageUrls != null) {
        final retained = normalizedImageUrls.toSet();
        final removed =
            previousImages.imageUrls
                .where((url) => !retained.contains(url))
                .toList();
        if (removed.isNotEmpty) {
          await _imageCleanup.cleanupUnreferenced(
            storeId: previousImages.storeId,
            candidateUrls: removed,
          );
        }
      }
      return const Result.success(null);
    } catch (e) {
      final msg = _mapError(e);
      if (kDebugMode) debugPrint('updateProduct hatası: $msg');
      return Result.failure(Failure(msg));
    }
  }

  Future<Result<void>> deleteProduct(
    String productId, {
    String? editToken,
  }) async {
    final previousImages = await _imageCleanup.snapshot(productId);
    try {
      await _repo.deleteProduct(productId, editToken: editToken);
      if (previousImages != null && previousImages.imageUrls.isNotEmpty) {
        await _imageCleanup.cleanupUnreferenced(
          storeId: previousImages.storeId,
          candidateUrls: previousImages.imageUrls,
        );
      }
      return const Result.success(null);
    } catch (e) {
      final msg = _mapError(e);
      if (kDebugMode) debugPrint('deleteProduct hatası: $msg');
      return Result.failure(Failure(msg));
    }
  }

  Future<Result<void>> reorderProducts(
    String storeId,
    String editToken,
    List<String> productIds,
  ) async {
    try {
      await _repo.reorderProducts(storeId, editToken, productIds);
      return const Result.success(null);
    } catch (e) {
      final msg = _mapError(e);
      if (kDebugMode) debugPrint('reorderProducts hatası: $msg');
      return Result.failure(Failure(msg));
    }
  }

  String _mapError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('STORE_NOT_FOUND')) return 'Mağaza bulunamadı.';
    if (msg.contains('UNAUTHORIZED')) return 'Bu işlem için yetkiniz yok.';
    if (msg.contains('PRODUCT_NOT_FOUND')) return 'Ürün bulunamadı.';
    if (msg.contains('SLUG_ALREADY_EXISTS')) {
      return 'Bu ürün adı zaten kullanılıyor.';
    }
    if (msg.contains('CATEGORY_NOT_IN_SAME_STORE')) {
      return 'Kategori bu mağazaya ait değil.';
    }
    if (msg.contains('PRODUCT_TEMPLATE_MISMATCH')) {
      return 'Ürün detayları seçilen kategori tipiyle uyuşmuyor.';
    }
    if (msg.contains('PRODUCT_METADATA_INVALID') ||
        msg.contains('PRODUCT_VARIANTS_INVALID')) {
      return 'Ürün detayları geçersiz.';
    }
    if (msg.contains('PRODUCT_IMAGES_MIN_3')) {
      return 'Bir ürün için en az 3 fotoğraf zorunludur.';
    }
    if (msg.contains('PRODUCT_IMAGES_MAX_11')) {
      return 'Bir ürüne en fazla 11 fotoğraf eklenebilir.';
    }
    return 'İşlem başarısız oldu.';
  }
}
