import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/models/created_product.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/repositories/product_repository.dart';

class SupabaseProductRepository implements ProductRepository {
  final SupabaseClient? _verilenIstemci;
  SupabaseProductRepository({SupabaseClient? client}) : _verilenIstemci = client;
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
    return (response as List)
        .map((row) => _rowToProduct(row, _categoryName(row, categoryMap)))
        .toList();
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
    return (response as List)
        .map((row) => _rowToProduct(row, _categoryName(row, categoryMap)))
        .toList();
  }

  String _categoryName(Map<String, dynamic> row, Map<String, String> categories) {
    final id = row['category_id'];
    return id == null ? '' : categories[id] ?? '';
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
    final result = await _client.rpc('create_store_product_v2', params: {
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
    });
    if (result is Map<String, dynamic> && result['success'] == true) {
      final id = result['id']?.toString().trim() ?? '';
      final slug = result['slug']?.toString().trim() ?? '';
      if (id.isNotEmpty && slug.isNotEmpty) return CreatedProduct(id: id, slug: slug);
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
  Future<void> deleteProduct(String productId, {String? editToken}) async {
    await _client.rpc('delete_store_product', params: {
      'p_product_id': productId,
      if (editToken != null) 'p_edit_token': editToken,
    });
  }

  @override
  Future<void> reorderProducts(String storeId, String editToken, List<String> productIds) async {
    await _client.rpc('reorder_store_products', params: {
      'p_store_id': storeId,
      'p_edit_token': editToken,
      'p_product_ids': productIds,
    });
  }

  @override
  Future<String> getCategoryName(String? categoryId) async {
    if (categoryId == null || categoryId.trim().isEmpty) return '';
    final response = await _client
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
    return {
      for (final row in response as List) row['id'] as String: row['name'] as String,
    };
  }

  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  List<Map<String, dynamic>> _mapList(dynamic value) => value is List
      ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : <Map<String, dynamic>>[];
  String? _text(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
  int? _int(dynamic value) => value is int ? value : int.tryParse(value?.toString() ?? '');
  double? _double(dynamic value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');

  Product _rowToProduct(Map<String, dynamic> row, String categoryName) {
    final metadata = _map(row['metadata']);
    final identifiers = _map(metadata['identifiers']);
    return Product(
      id: row['id'] as String,
      name: row['name'] as String,
      price: row['price_text'] as String? ?? '',
      priceAmount: _double(row['price_amount']),
      description: row['description'] as String? ?? '',
      imageUrls: (row['image_urls'] as List?)?.map((e) => e.toString()).toList() ?? [],
      categoryId: row['category_id'] as String? ?? '',
      category: categoryName.isNotEmpty ? categoryName : 'Tümü',
      stockStatus: row['stock_status'] as String? ?? 'Mevcut',
      stockQuantity: _int(row['stock_quantity']),
      isVisible: row['is_visible'] as bool? ?? true,
      slug: row['slug'] as String?,
      source: row['source_type'] as String?,
      brand: _text(row['brand']),
      barcode: _text(row['barcode']),
      sku: _text(identifiers['sku']),
      vatRate: _int(row['vat_rate']),
      variants: _mapList(row['variants']),
      metadata: metadata,
      oldPriceAmount: _double(row['old_price_amount']),
      badgeTag: _text(row['badge_tag']),
      fulfillmentLocation: _text(row['fulfillment_region']),
    );
  }
}
