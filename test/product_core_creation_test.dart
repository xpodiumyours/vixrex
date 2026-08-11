import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/created_product.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/repositories/product_repository.dart';
import 'package:vixrex/services/product_service.dart';

class _CoreOwnedSlugRepository implements ProductRepository {
  String? receivedName;

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
    receivedName = name;
    return const CreatedProduct(
      id: '11111111-1111-1111-1111-111111111111',
      slug: 'canta-aksesuar-2',
    );
  }

  @override
  Future<void> deleteProduct(String productId, {String? editToken}) async {}

  @override
  Future<String> getCategoryName(String? categoryId) async => '';

  @override
  Future<List<Product>> getProductsByStoreId(String storeId) async => [];

  @override
  Future<List<Product>> getVisibleProductsByStoreId(String storeId) async => [];

  @override
  Future<void> reorderProducts(
    String storeId,
    String editToken,
    List<String> productIds,
  ) async {}

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
  }) async {}
}

void main() {
  test('ürün ekleme canonical slugı yalnız CORE sonucundan alır', () async {
    final repository = _CoreOwnedSlugRepository();
    final service = ProductService(repository: repository);

    final result = await service.addProduct(
      storeId: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      editToken: 'edit-token-12345678901234567890',
      name: 'Çanta & Aksesuar',
    );

    expect(result.isSuccess, isTrue);
    expect(repository.receivedName, 'Çanta & Aksesuar');
    expect(result.data?.id, '11111111-1111-1111-1111-111111111111');
    expect(result.data?.slug, 'canta-aksesuar-2');
  });
}
