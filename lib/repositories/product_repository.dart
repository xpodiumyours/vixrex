import 'package:vixrex/models/created_product.dart';
import 'package:vixrex/models/product_rich_data.dart';
import 'package:vixrex/models/store_product.dart';

/// Ürün veri erişim operasyonları için repository arayüzü.
abstract class ProductRepository {
  Future<List<Product>> getProductsByStoreId(String storeId);

  Future<List<Product>> getVisibleProductsByStoreId(String storeId);

  Future<CreatedProduct> createProduct({
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
  });

  /// Additive rich path. Default implementation keeps old fake/test
  /// repositories and legacy clients source-compatible.
  Future<CreatedProduct> createRichProduct({
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
  }) {
    return createProduct(
      storeId: storeId,
      editToken: editToken,
      name: name,
      description: description,
      priceText: priceText,
      priceAmount: priceAmount,
      oldPriceAmount: oldPriceAmount,
      badgeTag: badgeTag,
      fulfillmentRegion: fulfillmentRegion,
      imageUrls: imageUrls,
      categoryId: categoryId,
      sourceType: sourceType,
      externalProductId: externalProductId,
      isVisible: isVisible,
      sortOrder: sortOrder,
    );
  }

  Future<void> updateProduct({
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
    bool clearCategory = false,
    bool clearPriceAmount = false,
    bool clearOldPriceAmount = false,
    bool clearBadgeTag = false,
    bool clearFulfillmentRegion = false,
    bool clearStockQuantity = false,
    bool clearStockStatus = false,
  });

  /// Additive rich update. Default implementation intentionally falls back to
  /// the legacy CORE method when a repository has not adopted rich writes.
  Future<void> updateRichProduct({
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
  }) {
    return updateProduct(
      productId: productId,
      editToken: editToken,
      name: name,
      description: description,
      priceText: priceText,
      priceAmount: priceAmount,
      oldPriceAmount: oldPriceAmount,
      badgeTag: badgeTag,
      fulfillmentRegion: fulfillmentRegion,
      imageUrls: imageUrls,
      categoryId: categoryId,
      isVisible: isVisible,
      sortOrder: sortOrder,
      stockQuantity: stockQuantity,
      stockStatus: stockStatus,
      clearCategory: clearCategory,
      clearPriceAmount: clearPriceAmount,
      clearOldPriceAmount: clearOldPriceAmount,
      clearBadgeTag: clearBadgeTag,
      clearFulfillmentRegion: clearFulfillmentRegion,
      clearStockQuantity: clearStockQuantity,
      clearStockStatus: clearStockStatus,
    );
  }

  Future<void> deleteProduct(String productId, {String? editToken});

  Future<void> reorderProducts(
    String storeId,
    String editToken,
    List<String> productIds,
  );

  Future<String> getCategoryName(String? categoryId);
}
