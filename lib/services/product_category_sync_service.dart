import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/models/product_rich_data.dart';
import 'package:vixrex/models/store_product.dart';

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
          .map((row) => ProductCategory.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (_) {
      final response = await _supabase
          .from('product_categories')
          .select('id,name,sort_order')
          .eq('store_id', storeId)
          .eq('is_active', true)
          .order('sort_order');
      return (response as List)
          .map((row) => ProductCategory.fromJson(Map<String, dynamic>.from(row as Map)))
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
    final syncedCategories = <ProductCategory>[];

    for (var index = 0; index < categories.length; index++) {
      final category = categories[index];
      final templateKey = category.productTemplateKey.trim().isEmpty
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
      syncedCategories.add(
        ProductCategory(
          id: remoteId,
          name: category.name,
          sortOrder: index,
          productTemplateKey: templateKey,
        ),
      );
    }

    final syncedProducts = products.map((product) {
      final next = product.copyWith();
      final mapped = idMap[product.categoryId];
      if (mapped != null) next.categoryId = mapped;
      final matches = syncedCategories.where((item) => item.id == next.categoryId);
      if (matches.isNotEmpty) {
        final category = matches.first;
        next.category = category.name;
        final current = next.richMetadata;
        final currentTemplate = current.templateKey?.trim() ?? '';
        if (currentTemplate.isEmpty || currentTemplate == 'generic') {
          next.richMetadata = ProductRichMetadata(
            schemaVersion: current.schemaVersion,
            itemKind: category.productTemplateKey == 'service' ? 'service' : 'physical',
            templateKey: category.productTemplateKey,
            sku: current.sku,
            mpn: current.mpn,
            attributes: current.attributes,
            service: current.service,
          );
        }
      }
      return next;
    }).toList();

    for (final deletion in deletions) {
      if (!_isUuid(deletion.categoryId)) continue;
      final replacementId = idMap[deletion.replacementCategoryId] ?? deletion.replacementCategoryId;
      if (!_isUuid(replacementId)) continue;
      final result = await _supabase.rpc(
        'delete_store_category_v2',
        params: {
          'p_category_id': deletion.categoryId,
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
      products: syncedProducts,
    );
  }

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value.trim());
  }
}
