import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/created_product.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/repositories/product_repository.dart';
import 'package:vixrex/services/product_image_cleanup_service.dart';
import 'package:vixrex/services/product_service.dart';

class _FakeCleanup extends ProductImageCleanupService {
  _FakeCleanup(this.value) : super();

  final ProductImageSnapshot? value;
  int cleanupCalls = 0;

  @override
  Future<ProductImageSnapshot?> snapshot(String productId) async => value;

  @override
  Future<int> cleanupUnreferenced({
    required String storeId,
    required List<String> candidateUrls,
  }) async {
    cleanupCalls++;
    return candidateUrls.length;
  }
}

class _FakeRepository extends ProductRepository {
  int updateCalls = 0;

  @override
  Future<List<Product>> getProductsByStoreId(String storeId) async => [];

  @override
  Future<List<Product>> getVisibleProductsByStoreId(String storeId) async => [];

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
  }) => throw UnimplementedError();

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
    updateCalls++;
  }

  @override
  Future<void> deleteProduct(String productId, {String? editToken}) async {}

  @override
  Future<void> reorderProducts(
    String storeId,
    String editToken,
    List<String> productIds,
  ) async {}

  @override
  Future<String> getCategoryName(String? categoryId) async => '';
}

void main() {
  const oldImages = [
    'https://example.com/legacy-1.jpg',
    'https://example.com/legacy-2.jpg',
  ];

  test('legacy 1-2 fotoğraflı ürün görseller değişmediyse düzenlenebilir', () async {
    final repository = _FakeRepository();
    final cleanup = _FakeCleanup(
      const ProductImageSnapshot(storeId: 'store-1', imageUrls: oldImages),
    );
    final service = ProductService(
      repository: repository,
      imageCleanupService: cleanup,
    );

    final result = await service.updateProduct(
      productId: 'product-1',
      name: 'Yeni ad',
      imageUrls: oldImages,
    );

    expect(result.isSuccess, isTrue);
    expect(repository.updateCalls, 1);
    expect(cleanup.cleanupCalls, 0);
  });

  test('legacy ürün fotoğraf listesi değişirse 3 fotoğraf kuralı uygulanır', () async {
    final repository = _FakeRepository();
    final cleanup = _FakeCleanup(
      const ProductImageSnapshot(storeId: 'store-1', imageUrls: oldImages),
    );
    final service = ProductService(
      repository: repository,
      imageCleanupService: cleanup,
    );

    final result = await service.updateProduct(
      productId: 'product-1',
      imageUrls: const [
        'https://example.com/new-1.jpg',
        'https://example.com/new-2.jpg',
      ],
    );

    expect(result.isFailure, isTrue);
    expect(repository.updateCalls, 0);
  });
}
