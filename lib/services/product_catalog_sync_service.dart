import 'package:flutter/foundation.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/services/product_service.dart';
import 'package:vixrex/utils/failure.dart';

/// `StoreEditorController`'ın sahip olduğu ürün kataloğu diff/CRUD mantığı.
///
/// [ProductService] tek-satır uzak yazma yapar (add/update/delete); bu
/// modül liste seviyesinde reconciliation'ı (hangisi yeni, hangisi mevcut,
/// UUID/fiyat ayrıştırma) sahiplenir. Controller-state'e hiç dokunmaz —
/// yalnız değer alır, [Result] döner; yerel `_data` mutasyonu, kaydetme ve
/// bildirim çağıranın (controller'ın) sorumluluğunda kalır.
///
/// 2026-08-12: `store_editor_controller.dart`'tan (1388 satır, AGENTS.md'nin
/// 400 satır sınırının çok üstünde) birebir taşındı — Faz 1. Davranış
/// kasıtlı olarak değiştirilmedi; bilinen tuhaflıklar (bkz. aşağıdaki yorum
/// satırları) burada da aynen korunuyor, düzeltme ayrı bir iştir.
class ProductCatalogSyncService {
  const ProductCatalogSyncService({required ProductService productService})
    : _productService = productService;

  final ProductService _productService;

  /// Yerel [products] listesini (gerçek kaynak) [storeId] için uzak
  /// `products` tablosuyla eşler: uzakta karşılığı olmayanları oluşturur,
  /// olanları günceller. Uzakta olup [products]'ta olmayan satırları ASLA
  /// silmez — kalıcı silme yalnız [deleteProduct] ile, açık kullanıcı
  /// eylemiyle olur (canlı veri koruması).
  ///
  /// Döndürdüğü liste sunucudan gelen id/slug/categoryId ile güncellenmiş
  /// üründür; çağıran bunu `_data.products`'a yazmalıdır.
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
        // Boş isimli satır atlanır ama i (sortOrder) ilerlemeye devam eder —
        // orijinal davranış, değiştirilmedi.
        if (name.isEmpty) continue;

        final rawCatId = product.categoryId.trim();
        final categoryUuid =
            rawCatId.isNotEmpty && _isUuid(rawCatId) ? rawCatId : null;

        if (_isUuid(product.id) && remoteIds.contains(product.id)) {
          final updated = await _productService.updateProduct(
            productId: product.id,
            editToken: editToken,
            name: name,
            description: product.description,
            priceText: product.price,
            priceAmount: _parsePriceAmount(product.price),
            oldPriceAmount: product.oldPriceAmount,
            badgeTag: product.badgeTag,
            fulfillmentRegion: product.fulfillmentLocation,
            clearOldPriceAmount: product.oldPriceAmount == null,
            clearBadgeTag:
                product.badgeTag == null || product.badgeTag!.trim().isEmpty,
            clearFulfillmentRegion:
                product.fulfillmentLocation == null ||
                product.fulfillmentLocation!.trim().isEmpty,
            imageUrls: product.displayImageUrls,
            categoryId: categoryUuid,
            clearCategory: categoryUuid == null || categoryUuid.isEmpty,
            isVisible: true,
            stockStatus: product.stockStatus,
            sortOrder: i,
          );
          if (updated.isFailure) {
            return Result.failure(
              Failure(updated.failure?.message ?? 'Ürün güncellenemedi.'),
            );
          }
          // Henüz senkronlanmamış (uzakta karşılığı olmayan) bir kategori
          // burada sessizce ''a döner — bilinen risk, orijinal davranış.
          product.categoryId = categoryUuid ?? '';
          nextProducts.add(product);
        } else {
          final created = await _productService.addProduct(
            storeId: storeId,
            editToken: editToken,
            name: name,
            description: product.description,
            priceText: product.price,
            priceAmount: _parsePriceAmount(product.price),
            oldPriceAmount: product.oldPriceAmount,
            badgeTag: product.badgeTag,
            fulfillmentRegion: product.fulfillmentLocation,
            imageUrls: product.displayImageUrls,
            categoryId: categoryUuid,
            sourceType: product.source ?? 'manual',
            isVisible: true,
            sortOrder: i,
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
      if (kDebugMode) {
        debugPrint('ProductCatalogSyncService.syncCatalog: $e');
      }
      return Result.failure(
        Failure('Ürünler kaydedilemedi, lütfen tekrar deneyin.'),
      );
    }
  }

  /// Tek bir yeni ürünü uzağa yazar; başarılıysa [product]'ı sunucudan gelen
  /// id/slug ile YERİNDE mutasyona uğratır (çağıran aynı örneği kullanmaya
  /// devam eder — orijinal controller davranışı).
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
      priceAmount: _parsePriceAmount(product.price),
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
    );

    if (result.isFailure ||
        result.data == null ||
        result.data!.id.trim().isEmpty ||
        result.data!.slug.trim().isEmpty) {
      return Result.failure(
        Failure(
          result.failure?.message ?? 'Ürün müşteri vitrine yazılamadı.',
        ),
      );
    }
    product.id = result.data!.id;
    product.slug = result.data!.slug;
    return const Result.success(null);
  }

  /// Mevcut bir ürünü uzakta günceller. [product.id] gerçek bir uzak UUID
  /// değilse (henüz senkronlanmamışsa) sessizce başarı döner — orijinal
  /// controller'daki `_isUuid` kapısıyla aynı davranış.
  Future<Result<void>> updateProduct({
    required String editToken,
    required Product product,
  }) async {
    if (!_isUuid(product.id)) {
      return const Result.success(null);
    }
    final updated = await _productService.updateProduct(
      productId: product.id,
      editToken: editToken,
      name: product.name,
      description: product.description,
      priceText: product.price,
      priceAmount: _parsePriceAmount(product.price),
      oldPriceAmount: product.oldPriceAmount,
      badgeTag: product.badgeTag,
      fulfillmentRegion: product.fulfillmentLocation,
      clearOldPriceAmount: product.oldPriceAmount == null,
      clearBadgeTag:
          product.badgeTag == null || product.badgeTag!.trim().isEmpty,
      clearFulfillmentRegion:
          product.fulfillmentLocation == null ||
          product.fulfillmentLocation!.trim().isEmpty,
      imageUrls: product.displayImageUrls,
      categoryId:
          product.categoryId.isNotEmpty && _isUuid(product.categoryId)
              ? product.categoryId
              : null,
      isVisible: true,
      stockStatus: product.stockStatus,
    );
    if (updated.isFailure) {
      return Result.failure(
        Failure(updated.failure?.message ?? 'Ürün güncellenemedi.'),
      );
    }
    return const Result.success(null);
  }

  /// Uzakta kalıcı ürün siler. [productId] gerçek bir UUID değilse veya
  /// [editToken] boşsa sessizce başarı döner (henüz hiç senkronlanmamış bir
  /// ürünün uzakta zaten karşılığı yoktur) — orijinal davranış.
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

  double? _parsePriceAmount(String raw) {
    var cleaned = raw.trim().replaceAll(RegExp(r'[^\d,.]'), '');
    if (cleaned.isEmpty) return null;
    if (cleaned.contains(',') && cleaned.contains('.')) {
      cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
    } else if (cleaned.contains(',')) {
      cleaned = cleaned.replaceAll(',', '.');
    }
    return double.tryParse(cleaned);
  }
}
