import 'package:vixrex/models/store_product.dart';

/// Ürün veri erişim operasyonları için repository arayüzü.
abstract class ProductRepository {
  /// Mağazanın tüm ürünlerini getirir (sahip görünümü).
  Future<List<Product>> getProductsByStoreId(String storeId);

  /// Mağazanın yalnızca görünür ürünlerini getirir (ziyaretçi görünümü).
  Future<List<Product>> getVisibleProductsByStoreId(String storeId);

  /// Yeni ürün ekler.
  Future<String> createProduct({
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
  });

  /// Ürün günceller.
  /// clearCategory, clearPriceAmount, clearStockQuantity, clearStockStatus
  /// TRUE ise ilgili alan NULL yapılır.
  Future<void> updateProduct({
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
  });

  /// Ürün siler.
  Future<void> deleteProduct(String productId, {String? editToken});

  /// Ürün sırasını günceller.
  Future<void> reorderProducts(String storeId, String editToken, List<String> productIds);

  /// Ürünün aynı mağazadaki kategori adını getirir.
  Future<String> getCategoryName(String? categoryId);
}
