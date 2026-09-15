import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/services/product_category_metadata_service.dart';

class ProductCategoryDeletion {
  const ProductCategoryDeletion({
    required this.categoryId,
    required this.replacementCategoryId,
  });

  final String categoryId;
  final String replacementCategoryId;
}

class ProductCategorySyncResult {
  const ProductCategorySyncResult({
    required this.categories,
    required this.products,
  });

  final List<ProductCategory> categories;
  final List<Product> products;
}

class _SyncedCategoryBinding {
  const _SyncedCategoryBinding({
    required this.category,
    required this.remoteId,
    required this.sortOrder,
    required this.templateKey,
  });

  final ProductCategory category;
  final String remoteId;
  final int sortOrder;
  final String templateKey;
}

class ProductCategorySyncService {
  ProductCategorySyncService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  Future<List<ProductCategory>> fetchCategories(String storeId) async {
    if (storeId.trim().isEmpty) return const [];
    try {
      final response = await _supabase
          .from('product_categories')
          .select('id,name,sort_order,product_template_key')
          .eq('store_id', storeId)
          .eq('is_active', true)
          .order('sort_order');
      return (response as List)
          .map(
            (row) =>
                ProductCategory.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    } catch (_) {
      final response = await _supabase
          .from('product_categories')
          .select('id,name,sort_order')
          .eq('store_id', storeId)
          .eq('is_active', true)
          .order('sort_order');
      return (response as List)
          .map(
            (row) =>
                ProductCategory.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    }
  }

  Future<ProductCategorySyncResult> sync({
    required String storeId,
    required String editToken,
    required List<ProductCategory> categories,
    required List<Product> products,
    List<ProductCategoryDeletion> deletions = const [],
  }) async {
    if (storeId.trim().isEmpty || editToken.trim().isEmpty) {
      return ProductCategorySyncResult(
        categories: List.of(categories),
        products: List.of(products),
      );
    }

    final idMap = <String, String>{};
    final bindings = <_SyncedCategoryBinding>[];

    for (var index = 0; index < categories.length; index++) {
      final category = categories[index];
      final templateKey =
          category.productTemplateKey.trim().isEmpty
              ? 'generic'
              : category.productTemplateKey.trim();
      final oldId = category.id;
      String remoteId = oldId;

      if (_isUuid(oldId)) {
        final result = await _supabase.rpc(
          'update_store_category_v2',
          params: {
            'p_category_id': oldId,
            'p_edit_token': editToken,
            'p_name': category.name,
            'p_template_key': templateKey,
            'p_sort_order': index,
          },
        );
        if (result is Map && result['success'] != true) {
          throw Exception('CATEGORY_WRITE_FAILED');
        }
      } else {
        final result = await _supabase.rpc(
          'upsert_store_category_v2',
          params: {
            'p_store_id': storeId,
            'p_edit_token': editToken,
            'p_name': category.name,
            'p_template_key': templateKey,
            'p_sort_order': index,
          },
        );
        if (result is! Map || result['success'] != true) {
          throw Exception('CATEGORY_WRITE_FAILED');
        }
        remoteId = (result['id'] ?? '').toString().trim();
        if (!_isUuid(remoteId)) throw Exception('CATEGORY_WRITE_FAILED');
      }

      idMap[oldId] = remoteId;
      bindings.add(
        _SyncedCategoryBinding(
          category: category,
          remoteId: remoteId,
          sortOrder: index,
          templateKey: templateKey,
        ),
      );
    }

    // Bütün kategori RPC'leri başarılı olduktan sonra aynı nesnelere canonical
    // kimlikleri geri yaz. Böylece açık Flutter editör ekranı geçici local id
    // ile kalıp sonraki kayıtta aynı kategoriyi/ürünü yeniden oluşturmaya çalışmaz.
    for (final binding in bindings) {
      binding.category.id = binding.remoteId;
      binding.category.sortOrder = binding.sortOrder;
      binding.category.productTemplateKey = binding.templateKey;
    }
    final syncedCategories =
        bindings.map((binding) => binding.category).toList();

    for (final product in products) {
      final mapped = idMap[product.categoryId];
      if (mapped != null) product.categoryId = mapped;
      final matches = syncedCategories.where(
        (item) => item.id == product.categoryId,
      );
      if (matches.isNotEmpty) {
        final category = matches.first;
        product.category = category.name;
        product.richMetadata = alignProductMetadataToCategory(
          product.richMetadata,
          category,
        );
      }
    }

    for (final deletion in deletions) {
      final categoryId = idMap[deletion.categoryId] ?? deletion.categoryId;
      if (!_isUuid(categoryId)) continue;
      final replacementId =
          idMap[deletion.replacementCategoryId] ??
          deletion.replacementCategoryId;
      if (!_isUuid(replacementId)) continue;
      final result = await _supabase.rpc(
        'delete_store_category_v2',
        params: {
          'p_category_id': categoryId,
          'p_replacement_id': replacementId,
          'p_edit_token': editToken,
        },
      );
      if (result is Map && result['success'] != true) {
        throw Exception('CATEGORY_DELETE_FAILED');
      }
    }

    return ProductCategorySyncResult(
      categories: syncedCategories,
      products: products,
    );
  }

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value.trim());
  }
}
