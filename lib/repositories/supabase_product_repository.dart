import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/models/created_product.dart';
import 'package:vixrex/models/product_rich_data.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/repositories/product_repository.dart';

/// Supabase ile ProductRepository implementasyonu.
class SupabaseProductRepository implements ProductRepository {
  final SupabaseClient? _verilenIstemci;

  SupabaseProductRepository({SupabaseClient? client})
    : _verilenIstemci = client;

  SupabaseClient get _client => _verilenIstemci ?? Supabase.instance.client;

  @override
  Future<List<Product>> getProductsByStoreId(String storeId) async {
    if (storeId.trim().isEmpty) return [];

    final categoryMap = await _fetchCategoryMap(storeId);
    final response = await _client
        .from('products')
        .select()
        .eq('store_id', storeId)
        .eq('is_active', true)
        .order('sort_order');

    return (response as List).map((row) {
      final catName =
          row['category_id'] != null
              ? categoryMap[row['category_id']] ?? ''
              : '';
      return _rowToProduct(Map<String, dynamic>.from(row as Map), catName);
    }).toList();
  }

  @override
  Future<List<Product>> getVisibleProductsByStoreId(String storeId) async {
    if (storeId.trim().isEmpty) return [];

    final categoryMap = await _fetchCategoryMap(storeId);
    final response = await _client
        .from('products')
        .select()
        .eq('store_id', storeId)
        .eq('is_active', true)
        .eq('is_visible', true)
        .order('sort_order');

    return (response as List).map((row) {
      final catName =
          row['category_id'] != null
              ? categoryMap[row['category_id']] ?? ''
              : '';
      return _rowToProduct(Map<String, dynamic>.from(row as Map), catName);
    }).toList();
  }

  @override
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
  }) async {
    final result = await _client.rpc(
      'create_store_product_v2',
      params: {
        'p_store_id': storeId,
        'p_edit_token': editToken,
        'p_name': name,
        'p_description': description,
        'p_price_text': priceText,
        'p_price_amount': priceAmount,
        'p_old_price_amount': oldPriceAmount,
        'p_badge_tag': badgeTag,
        'p_fulfillment_region': fulfillmentRegion,
        'p_image_urls': imageUrls,
        'p_category_id': categoryId,
        'p_source_type': sourceType,
        'p_external_product_id': externalProductId,
        'p_is_visible': isVisible,
        'p_sort_order': sortOrder,
      },
    );
    return _createdFromRpc(result);
  }

  @override
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
  }) async {
    final result = await _client.rpc(
      'create_store_product_v3',
      params: {
        'p_store_id': storeId,
        'p_edit_token': editToken,
        'p_name': name,
        'p_description': description,
        'p_price_text': priceText,
        'p_price_amount': priceAmount,
        'p_old_price_amount': oldPriceAmount,
        'p_badge_tag': badgeTag,
        'p_fulfillment_region': fulfillmentRegion,
        'p_image_urls': imageUrls,
        'p_category_id': categoryId,
        'p_source_type': sourceType,
        'p_external_product_id': externalProductId,
        'p_is_visible': isVisible,
        'p_sort_order': sortOrder,
        'p_brand': brand,
        'p_barcode': barcode,
        'p_stock_quantity': stockQuantity,
        'p_stock_status': stockStatus,
        'p_metadata': metadata?.toJson() ?? const <String, dynamic>{},
        'p_variants': variants.map((item) => item.toJson()).toList(),
      },
    );
    return _createdFromRpc(result);
  }

  CreatedProduct _createdFromRpc(dynamic result) {
    if (result is Map<String, dynamic> && result['success'] == true) {
      final id = result['id']?.toString().trim() ?? '';
      final slug = result['slug']?.toString().trim() ?? '';
      if (id.isNotEmpty && slug.isNotEmpty) {
        return CreatedProduct(id: id, slug: slug);
      }
    }
    throw Exception('Ürün eklenemedi: $result');
  }

  @override
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
  }) async {
    final params = <String, dynamic>{
      'p_product_id': productId,
      if (editToken != null) 'p_edit_token': editToken,
      if (name != null) 'p_name': name,
      if (description != null) 'p_description': description,
      if (priceText != null) 'p_price_text': priceText,
      if (priceAmount != null) 'p_price_amount': priceAmount,
      if (oldPriceAmount != null) 'p_old_price_amount': oldPriceAmount,
      if (badgeTag != null) 'p_badge_tag': badgeTag,
      if (fulfillmentRegion != null) 'p_fulfillment_region': fulfillmentRegion,
      if (imageUrls != null) 'p_image_urls': imageUrls,
      if (categoryId != null) 'p_category_id': categoryId,
      if (isVisible != null) 'p_is_visible': isVisible,
      if (sortOrder != null) 'p_sort_order': sortOrder,
      if (stockQuantity != null) 'p_stock_quantity': stockQuantity,
      if (stockStatus != null) 'p_stock_status': stockStatus,
      'p_clear_category': clearCategory,
      'p_clear_price_amount': clearPriceAmount,
      'p_clear_old_price_amount': clearOldPriceAmount,
      'p_clear_badge_tag': clearBadgeTag,
      'p_clear_fulfillment_region': clearFulfillmentRegion,
      'p_clear_stock_quantity': clearStockQuantity,
      'p_clear_stock_status': clearStockStatus,
    };

    await _client.rpc('update_store_product', params: params);
  }

  @override
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
  }) async {
    final params = <String, dynamic>{
      'p_product_id': productId,
      if (editToken != null) 'p_edit_token': editToken,
      if (name != null) 'p_name': name,
      if (description != null) 'p_description': description,
      if (priceText != null) 'p_price_text': priceText,
      if (priceAmount != null) 'p_price_amount': priceAmount,
      if (imageUrls != null) 'p_image_urls': imageUrls,
      if (categoryId != null) 'p_category_id': categoryId,
      if (isVisible != null) 'p_is_visible': isVisible,
      if (sortOrder != null) 'p_sort_order': sortOrder,
      if (stockQuantity != null) 'p_stock_quantity': stockQuantity,
      if (stockStatus != null) 'p_stock_status': stockStatus,
      if (oldPriceAmount != null) 'p_old_price_amount': oldPriceAmount,
      if (badgeTag != null) 'p_badge_tag': badgeTag,
      if (fulfillmentRegion != null) 'p_fulfillment_region': fulfillmentRegion,
      if (brand != null) 'p_brand': brand,
      if (barcode != null) 'p_barcode': barcode,
      if (metadata != null) 'p_metadata': metadata.toJson(),
      if (variants != null)
        'p_variants': variants.map((item) => item.toJson()).toList(),
      'p_clear_category': clearCategory,
      'p_clear_price_amount': clearPriceAmount,
      'p_clear_stock_quantity': clearStockQuantity,
      'p_clear_stock_status': clearStockStatus,
      'p_clear_old_price_amount': clearOldPriceAmount,
      'p_clear_badge_tag': clearBadgeTag,
      'p_clear_fulfillment_region': clearFulfillmentRegion,
      'p_clear_brand': clearBrand,
      'p_clear_barcode': clearBarcode,
      'p_clear_metadata': clearMetadata,
      'p_clear_variants': clearVariants,
    };

    await _client.rpc('update_store_product_v2', params: params);
  }

  @override
  Future<void> deleteProduct(String productId, {String? editToken}) async {
    await _client.rpc(
      'delete_store_product',
      params: {
        'p_product_id': productId,
        if (editToken != null) 'p_edit_token': editToken,
      },
    );
  }

  @override
  Future<void> reorderProducts(
    String storeId,
    String editToken,
    List<String> productIds,
  ) async {
    await _client.rpc(
      'reorder_store_products',
      params: {
        'p_store_id': storeId,
        'p_edit_token': editToken,
        'p_product_ids': productIds,
      },
    );
  }

  @override
  Future<String> getCategoryName(String? categoryId) async {
    if (categoryId == null || categoryId.trim().isEmpty) return '';
    final response =
        await _client
            .from('product_categories')
            .select('name')
            .eq('id', categoryId)
            .maybeSingle();
    return response?['name'] as String? ?? '';
  }

  Future<Map<String, String>> _fetchCategoryMap(String storeId) async {
    final response = await _client
        .from('product_categories')
        .select('id,name')
        .eq('store_id', storeId)
        .eq('is_active', true);

    final map = <String, String>{};
    for (final raw in response as List) {
      final row = Map<String, dynamic>.from(raw as Map);
      map[row['id'].toString()] = row['name'].toString();
    }
    return map;
  }

  Product _rowToProduct(Map<String, dynamic> row, String categoryName) {
    final imageUrls =
        (row['image_urls'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return Product(
      id: row['id'].toString(),
      name: row['name']?.toString() ?? '',
      price: row['price_text']?.toString() ?? '',
      description: row['description']?.toString() ?? '',
      imageUrls: imageUrls,
      categoryId: row['category_id']?.toString() ?? '',
      category: categoryName.isNotEmpty ? categoryName : 'Tümü',
      stockStatus: row['stock_status']?.toString() ?? 'Mevcut',
      stockQuantity:
          row['stock_quantity'] is num
              ? (row['stock_quantity'] as num).toInt()
              : null,
      isVisible: row['is_visible'] as bool? ?? true,
      slug: row['slug']?.toString(),
      source: row['source_type']?.toString(),
      brand:
          row['brand']?.toString().trim().isNotEmpty == true
              ? row['brand'].toString().trim()
              : null,
      barcode:
          row['barcode']?.toString().trim().isNotEmpty == true
              ? row['barcode'].toString().trim()
              : null,
      richMetadata: ProductRichMetadata.fromJson(row['metadata']),
      variants: parseProductVariants(row['variants']),
      oldPriceAmount:
          row['old_price_amount'] != null
              ? double.tryParse(row['old_price_amount'].toString())
              : null,
      badgeTag:
          row['badge_tag']?.toString().trim().isNotEmpty == true
              ? row['badge_tag'].toString().trim()
              : null,
      fulfillmentLocation:
          row['fulfillment_region']?.toString().trim().isNotEmpty == true
              ? row['fulfillment_region'].toString().trim()
              : null,
    );
  }
}
