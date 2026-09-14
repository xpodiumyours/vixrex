import 'package:flutter/foundation.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/services/product_service.dart';
import 'package:vixrex/utils/failure.dart';
import 'package:vixrex/utils/product_price_parser.dart';

/// Yerel ürün kataloğunu aynı Supabase Product CORE ile eşler.
class ProductCatalogSyncService {
  const ProductCatalogSyncService({required ProductService productService})
    : _productService = productService;

  final ProductService _productService;

  Future<Result<List<Product>>> syncCatalog({
    required String storeId,
    required String editToken,
    required List<Product> products,
  }) async {
    try {
      final remote = await _productService.fetchProducts(storeId);
      final remoteIds = remote.map((p) => p.id).toSet();
      final nextProducts = <Product>[];

      for (var i = 0; i < products.length; i++) {
        final product = products[i];
        final name = product.name.trim();
        if (name.isEmpty) continue;

        final rawCatId = product.categoryId.trim();
        final categoryUuid =
            rawCatId.isNotEmpty && _isUuid(rawCatId) ? rawCatId : null;
        final priceAmount = parseProductPriceAmount(product.price);

        if (_isUuid(product.id) && remoteIds.contains(product.id)) {
          final updated = await _productService.updateProduct(
            productId: product.id,
            editToken: editToken,
            name: name,
            description: product.description,
            priceText: product.price,
            priceAmount: priceAmount,
            oldPriceAmount: product.oldPriceAmount,
            badgeTag: product.badgeTag,
            fulfillmentRegion: product.fulfillmentLocation,
            imageUrls: product.displayImageUrls,
            categoryId: categoryUuid,
            isVisible: true,
            sortOrder: i,
            stockQuantity: product.stockQuantity,
            stockStatus: product.stockStatus,
            brand: product.brand,
            barcode: product.barcode,
            metadata: product.richMetadata,
            variants: product.variants,
            clearCategory: categoryUuid == null,
            clearPriceAmount: priceAmount == null,
            clearOldPriceAmount: product.oldPriceAmount == null,
            clearBadgeTag: product.badgeTag?.trim().isNotEmpty != true,
            clearFulfillmentRegion:
                product.fulfillmentLocation?.trim().isNotEmpty != true,
            clearStockQuantity: product.stockQuantity == null,
            clearStockStatus: product.stockStatus.trim().isEmpty,
            clearBrand: product.brand?.trim().isNotEmpty != true,
            clearBarcode: product.barcode?.trim().isNotEmpty != true,
          );
          if (updated.isFailure) {
            return Result.failure(
              Failure(updated.failure?.message ?? 'Ürün güncellenemedi.'),
            );
          }
          if (categoryUuid != null) product.categoryId = categoryUuid;
          nextProducts.add(product);
        } else {
          final created = await _productService.addProduct(
            storeId: storeId,
            editToken: editToken,
            name: name,
            description: product.description,
            priceText: product.price,
            priceAmount: priceAmount,
            oldPriceAmount: product.oldPriceAmount,
            badgeTag: product.badgeTag,
            fulfillmentRegion: product.fulfillmentLocation,
            imageUrls: product.displayImageUrls,
            categoryId: categoryUuid,
            sourceType: product.source ?? 'manual',
            isVisible: true,
            sortOrder: i,
            brand: product.brand,
            barcode: product.barcode,
            stockQuantity: product.stockQuantity,
            stockStatus: product.stockStatus,
            metadata: product.richMetadata,
            variants: product.variants,
          );
          if (created.isFailure || created.data == null) {
            return Result.failure(
              Failure(created.failure?.message ?? 'Ürün eklenemedi.'),
            );
          }
          product.id = created.data!.id;
          product.slug = created.data!.slug;
          product.categoryId = categoryUuid ?? '';
          nextProducts.add(product);
        }
      }

      return Result.success(nextProducts);
    } catch (e) {
      if (kDebugMode) debugPrint('ProductCatalogSyncService.syncCatalog: $e');
      return Result.failure(
        Failure('Ürünler kaydedilemedi, lütfen tekrar deneyin.'),
      );
    }
  }

  Future<Result<void>> addProduct({
    required String storeId,
    required String editToken,
    required Product product,
    required int sortOrder,
  }) async {
    final result = await _productService.addProduct(
      storeId: storeId,
      editToken: editToken,
      name: product.name,
      description: product.description,
      priceText: product.price,
      priceAmount: parseProductPriceAmount(product.price),
      oldPriceAmount: product.oldPriceAmount,
      badgeTag: product.badgeTag,
      fulfillmentRegion: product.fulfillmentLocation,
      imageUrls: product.displayImageUrls,
      categoryId:
          product.categoryId.isNotEmpty && _isUuid(product.categoryId)
              ? product.categoryId
              : null,
      sourceType: product.source ?? 'manual',
      isVisible: true,
      sortOrder: sortOrder,
      brand: product.brand,
      barcode: product.barcode,
      stockQuantity: product.stockQuantity,
      stockStatus: product.stockStatus,
      metadata: product.richMetadata,
      variants: product.variants,
    );

    if (result.isFailure ||
        result.data == null ||
        result.data!.id.trim().isEmpty ||
        result.data!.slug.trim().isEmpty) {
      return Result.failure(
        Failure(result.failure?.message ?? 'Ürün müşteri vitrine yazılamadı.'),
      );
    }
    product.id = result.data!.id;
    product.slug = result.data!.slug;
    return const Result.success(null);
  }

  Future<Result<void>> updateProduct({
    required String editToken,
    required Product product,
  }) async {
    if (!_isUuid(product.id)) return const Result.success(null);
    final categoryId =
        product.categoryId.isNotEmpty && _isUuid(product.categoryId)
            ? product.categoryId
            : null;
    final priceAmount = parseProductPriceAmount(product.price);
    final updated = await _productService.updateProduct(
      productId: product.id,
      editToken: editToken,
      name: product.name,
      description: product.description,
      priceText: product.price,
      priceAmount: priceAmount,
      oldPriceAmount: product.oldPriceAmount,
      badgeTag: product.badgeTag,
      fulfillmentRegion: product.fulfillmentLocation,
      imageUrls: product.displayImageUrls,
      categoryId: categoryId,
      isVisible: true,
      stockQuantity: product.stockQuantity,
      stockStatus: product.stockStatus,
      brand: product.brand,
      barcode: product.barcode,
      metadata: product.richMetadata,
      variants: product.variants,
      clearCategory: categoryId == null,
      clearPriceAmount: priceAmount == null,
      clearOldPriceAmount: product.oldPriceAmount == null,
      clearBadgeTag: product.badgeTag?.trim().isNotEmpty != true,
      clearFulfillmentRegion:
          product.fulfillmentLocation?.trim().isNotEmpty != true,
      clearStockQuantity: product.stockQuantity == null,
      clearStockStatus: product.stockStatus.trim().isEmpty,
      clearBrand: product.brand?.trim().isNotEmpty != true,
      clearBarcode: product.barcode?.trim().isNotEmpty != true,
    );
    if (updated.isFailure) {
      return Result.failure(
        Failure(updated.failure?.message ?? 'Ürün güncellenemedi.'),
      );
    }
    return const Result.success(null);
  }

  Future<Result<void>> deleteProduct({
    required String productId,
    required String editToken,
  }) async {
    if (!_isUuid(productId) || editToken.isEmpty) {
      return const Result.success(null);
    }
    final deleted = await _productService.deleteProduct(
      productId,
      editToken: editToken,
    );
    if (deleted.isFailure) {
      return Result.failure(
        Failure(deleted.failure?.message ?? 'Ürün silinemedi.'),
      );
    }
    return const Result.success(null);
  }

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value.trim());
  }
}
