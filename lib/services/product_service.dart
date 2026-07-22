import 'package:flutter/foundation.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/repositories/product_repository.dart';
import 'package:vixrex/repositories/supabase_product_repository.dart';
import 'package:vixrex/utils/failure.dart';

/// Ürün CRUD işlemleri için servis katmanı.
/// Repository ile controller arasındaki köprüdür.
class ProductService {
  ProductRepository? _repository;

  ProductService({ProductRepository? repository}) : _repository = repository;

  ProductRepository get _repo => _repository ??= SupabaseProductRepository();

  /// Mağazanın tüm ürünlerini getirir.
  Future<List<Product>> fetchProducts(String storeId) async {
    try {
      return await _repo.getProductsByStoreId(storeId);
    } catch (e) {
      if (kDebugMode) debugPrint('fetchProducts hatası: $e');
      return [];
    }
  }

  /// Mağazanın görünür ürünlerini getirir.
  Future<List<Product>> fetchVisibleProducts(String storeId) async {
    try {
      return await _repo.getVisibleProductsByStoreId(storeId);
    } catch (e) {
      if (kDebugMode) debugPrint('fetchVisibleProducts hatası: $e');
      return [];
    }
  }

  /// Yeni ürün ekler.
  Future<Result<String>> addProduct({
    required String storeId,
    required String editToken,
    required String name,
    required String slug,
    String description = '',
    String priceText = '',
    double? priceAmount,
    List<String> imageUrls = const [],
    String? categoryId,
    String sourceType = 'manual',
    String? externalProductId,
    bool isVisible = true,
    int sortOrder = 0,
  }) async {
    try {
      final id = await _repo.createProduct(
        storeId: storeId,
        editToken: editToken,
        name: name,
        slug: slug,
        description: description,
        priceText: priceText,
        priceAmount: priceAmount,
        imageUrls: imageUrls,
        categoryId: categoryId,
        sourceType: sourceType,
        externalProductId: externalProductId,
        isVisible: isVisible,
        sortOrder: sortOrder,
      );
      return Result.success(id);
    } catch (e) {
      final msg = _mapError(e);
      if (kDebugMode) debugPrint('addProduct hatası: $msg');
      return Result.failure(Failure(msg));
    }
  }

  /// Ürün günceller.
  Future<Result<void>> updateProduct({
    required String productId,
    String? editToken,
    String? name,
    String? slug,
    String? description,
    String? priceText,
    double? priceAmount,
    List<String>? imageUrls,
    String? categoryId,
    bool? isVisible,
    int? sortOrder,
    int? stockQuantity,
    String? stockStatus,
    bool clearCategory = false,
    bool clearPriceAmount = false,
    bool clearStockQuantity = false,
    bool clearStockStatus = false,
  }) async {
    try {
      await _repo.updateProduct(
        productId: productId,
        editToken: editToken,
        name: name,
        slug: slug,
        description: description,
        priceText: priceText,
        priceAmount: priceAmount,
        imageUrls: imageUrls,
        categoryId: categoryId,
        isVisible: isVisible,
        sortOrder: sortOrder,
        stockQuantity: stockQuantity,
        stockStatus: stockStatus,
        clearCategory: clearCategory,
        clearPriceAmount: clearPriceAmount,
        clearStockQuantity: clearStockQuantity,
        clearStockStatus: clearStockStatus,
      );
      return const Result.success(null);
    } catch (e) {
      final msg = _mapError(e);
      if (kDebugMode) debugPrint('updateProduct hatası: $msg');
      return Result.failure(Failure(msg));
    }
  }

  /// Ürün siler.
  Future<Result<void>> deleteProduct(
    String productId, {
    String? editToken,
  }) async {
    try {
      await _repo.deleteProduct(productId, editToken: editToken);
      return const Result.success(null);
    } catch (e) {
      final msg = _mapError(e);
      if (kDebugMode) debugPrint('deleteProduct hatası: $msg');
      return Result.failure(Failure(msg));
    }
  }

  /// Ürün sırasını günceller.
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
    return 'İşlem başarısız oldu.';
  }
}
