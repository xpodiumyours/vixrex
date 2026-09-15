import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/models/store_product.dart';

class ProductBatchImportError {
  const ProductBatchImportError({required this.index, required this.error});

  final int index;
  final String error;
}

class ProductBatchImportResult {
  const ProductBatchImportResult({
    required this.isSuccess,
    this.errorMessage,
    this.total = 0,
    this.inserted = 0,
    this.updated = 0,
    this.unchanged = 0,
    this.errors = 0,
    this.errorDetails = const [],
  });

  final bool isSuccess;
  final String? errorMessage;
  final int total;
  final int inserted;
  final int updated;
  final int unchanged;
  final int errors;
  final List<ProductBatchImportError> errorDetails;

  int get changed => inserted + updated;

  factory ProductBatchImportResult.failure(String message) =>
      ProductBatchImportResult(isSuccess: false, errorMessage: message);
}

/// Flutter Excel/CSV gibi toplu girişleri aynı Supabase Product CORE batch
/// sözleşmesine taşır. Mevcut ürün kimliği Product.sourceMediaId üzerinden
/// external_product_id olarak korunur; yoksa DB barkod -> SKU sırasına düşer.
class ProductBatchImportService {
  ProductBatchImportService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  Future<ProductBatchImportResult> save({
    required List<Product> products,
    required String storeId,
    required String editToken,
    String defaultSourceType = 'bulk_import',
  }) async {
    if (storeId.trim().isEmpty || editToken.trim().isEmpty) {
      return ProductBatchImportResult.failure('Vitrin oturumu bulunamadı.');
    }
    if (products.isEmpty) {
      return ProductBatchImportResult.failure('Kaydedilecek ürün yok.');
    }

    try {
      final payload =
          products
              .map(
                (product) => _toPayload(
                  product,
                  defaultSourceType: defaultSourceType,
                ),
              )
              .toList();

      final result = await _supabase.rpc(
        'batch_create_products',
        params: {
          'p_store_id': storeId,
          'p_edit_token': editToken,
          'p_products': payload,
        },
      );

      if (result is! Map || result['success'] != true) {
        return ProductBatchImportResult.failure(
          'Toplu ürün kaydı başarısız oldu.',
        );
      }

      final errorDetails = <ProductBatchImportError>[];
      final rawErrors = result['error_details'];
      if (rawErrors is List) {
        for (final raw in rawErrors) {
          if (raw is! Map) continue;
          errorDetails.add(
            ProductBatchImportError(
              index: _asInt(raw['index']),
              error: raw['error']?.toString() ?? 'Ürün kaydedilemedi.',
            ),
          );
        }
      }

      return ProductBatchImportResult(
        isSuccess: true,
        total: _asInt(result['total']),
        inserted: _asInt(result['inserted']),
        updated: _asInt(result['updated']),
        unchanged: _asInt(result['unchanged']),
        errors: _asInt(result['errors']),
        errorDetails: errorDetails,
      );
    } catch (e) {
      return ProductBatchImportResult.failure('Toplu ürün kaydı başarısız: $e');
    }
  }

  Map<String, dynamic> _toPayload(
    Product product, {
    required String defaultSourceType,
  }) {
    final payload = <String, dynamic>{
      'name': product.name.trim(),
      'source_type':
          product.source?.trim().isNotEmpty == true
              ? product.source!.trim()
              : defaultSourceType,
    };

    void putString(String key, String? value) {
      final clean = value?.trim() ?? '';
      if (clean.isNotEmpty) payload[key] = clean;
    }

    putString('external_product_id', product.sourceMediaId);
    putString('description', product.description);
    putString('price_text', product.price);
    if (product.displayImageUrls.isNotEmpty) {
      payload['image_urls'] = product.displayImageUrls;
    }
    final category = product.category.trim();
    if (category.isNotEmpty && category.toLowerCase() != 'tümü') {
      payload['category_name'] = category;
    }
    if (product.stockQuantity != null) {
      payload['stock_quantity'] = product.stockQuantity;
    }
    putString('stock_status', product.stockStatus);
    putString('brand', product.brand);
    putString('barcode', product.barcode);
    putString('sku', product.sku);
    if (product.hasRichMetadata) {
      payload['metadata'] = product.richMetadata.toJson();
    }
    if (product.variants.isNotEmpty) {
      payload['variants'] =
          product.variants.map((variant) => variant.toJson()).toList();
    }
    if (product.oldPriceAmount != null) {
      payload['old_price_amount'] = product.oldPriceAmount;
    }
    putString('badge_tag', product.badgeTag);
    putString('fulfillment_region', product.fulfillmentLocation);
    return payload;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
