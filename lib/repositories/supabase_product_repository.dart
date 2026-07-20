import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/repositories/product_repository.dart';

/// Supabase ile ProductRepository implementasyonu.
class SupabaseProductRepository implements ProductRepository {
  final SupabaseClient _client;

  SupabaseProductRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

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
      final catName = row['category_id'] != null
          ? categoryMap[row['category_id']] ?? ''
          : '';
      return _rowToProduct(row, catName);
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
      final catName = row['category_id'] != null
          ? categoryMap[row['category_id']] ?? ''
          : '';
      return _rowToProduct(row, catName);
    }).toList();
  }

  @override
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
  }) async {
    final result = await _client.rpc('create_store_product', params: {
      'p_store_id': storeId,
      'p_edit_token': editToken,
      'p_name': name,
      'p_slug': slug,
      'p_description': description,
      'p_price_text': priceText,
      'p_price_amount': priceAmount,
      'p_image_urls': imageUrls,
      'p_category_id': categoryId,
      'p_source_type': sourceType,
      'p_external_product_id': externalProductId,
      'p_is_visible': isVisible,
      'p_sort_order': sortOrder,
    });

    if (result is Map<String, dynamic> && result['success'] == true) {
      return result['id'] as String;
    }
    throw Exception('Ürün eklenemedi: $result');
  }

  @override
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
  }) async {
    final params = <String, dynamic>{
      'p_product_id': productId,
      if (editToken != null) 'p_edit_token': editToken,
      if (name != null) 'p_name': name,
      if (slug != null) 'p_slug': slug,
      if (description != null) 'p_description': description,
      if (priceText != null) 'p_price_text': priceText,
      if (priceAmount != null) 'p_price_amount': priceAmount,
      if (imageUrls != null) 'p_image_urls': imageUrls,
      if (categoryId != null) 'p_category_id': categoryId,
      if (isVisible != null) 'p_is_visible': isVisible,
      if (sortOrder != null) 'p_sort_order': sortOrder,
      if (stockQuantity != null) 'p_stock_quantity': stockQuantity,
      if (stockStatus != null) 'p_stock_status': stockStatus,
      'p_clear_category': clearCategory,
      'p_clear_price_amount': clearPriceAmount,
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

  // --- Yardımcı metodlar ---

  Future<Map<String, String>> _fetchCategoryMap(String storeId) async {
    final response = await _client
        .from('product_categories')
        .select('id,name')
        .eq('store_id', storeId)
        .eq('is_active', true);

    final map = <String, String>{};
    for (final row in response as List) {
      map[row['id'] as String] = row['name'] as String;
    }
    return map;
  }

  Product _rowToProduct(Map<String, dynamic> row, String categoryName) {
    final imageUrls = (row['image_urls'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return Product(
      id: row['id'] as String,
      name: row['name'] as String,
      price: row['price_text'] as String? ?? '',
      description: row['description'] as String? ?? '',
      imageUrls: imageUrls,
      categoryId: row['category_id'] as String? ?? '',
      category: categoryName.isNotEmpty ? categoryName : 'Tümü',
      stockStatus: row['stock_status'] as String? ?? 'Mevcut',
      isVisible: row['is_visible'] as bool? ?? true,
      slug: row['slug'] as String?,
      source: row['source_type'] as String?,
    );
  }
}
