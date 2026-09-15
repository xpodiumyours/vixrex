import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/created_product.dart';
import 'package:vixrex/models/product_rich_data.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/repositories/product_repository.dart';
import 'package:vixrex/services/product_catalog_sync_service.dart';
import 'package:vixrex/services/product_category_metadata_service.dart';
import 'package:vixrex/services/product_service.dart';

/// test/sync_catalog_to_remote_test.dart'taki sahte repository'nin küçük bir
/// kopyası — bu dosya artık StoreEditorController/storage kurmadan, modülü
/// doğrudan test ediyor.
class _FakeProductRepository extends ProductRepository {
  final List<Product> remote = [];
  final List<String> createdNames = [];
  final List<String> updatedIds = [];
  final List<String> deletedIds = [];
  double? lastPriceAmount;
  String? lastExternalProductId;
  String? lastSourceType;
  Object? throwOnCreate;
  Object? throwOnUpdate;

  @override
  Future<List<Product>> getProductsByStoreId(String storeId) async =>
      List.of(remote);

  @override
  Future<List<Product>> getVisibleProductsByStoreId(String storeId) async =>
      remote.where((p) => p.isVisible).toList();

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
    if (throwOnCreate != null) throw throwOnCreate!;
    createdNames.add(name);
    lastPriceAmount = priceAmount;
    lastExternalProductId = externalProductId;
    lastSourceType = sourceType;
    final suffix = createdNames.length.toString().padLeft(12, '0');
    final id = '11111111-1111-1111-1111-$suffix';
    final slug = 'core-slug-${createdNames.length}';
    remote.add(
      Product(
        id: id,
        name: name,
        price: priceText,
        description: description,
        imageUrls: imageUrls,
        categoryId: categoryId ?? '',
        isVisible: isVisible,
        slug: slug,
        source: sourceType,
        sourceMediaId: externalProductId,
        oldPriceAmount: oldPriceAmount,
        badgeTag: badgeTag,
        fulfillmentLocation: fulfillmentRegion,
      ),
    );
    return CreatedProduct(id: id, slug: slug);
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
    if (throwOnUpdate != null) throw throwOnUpdate!;
    updatedIds.add(productId);
    if (priceAmount != null) lastPriceAmount = priceAmount;
  }

  @override
  Future<void> deleteProduct(String productId, {String? editToken}) async {
    deletedIds.add(productId);
    remote.removeWhere((p) => p.id == productId);
  }

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
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeProductRepository repo;
  late ProductCatalogSyncService service;

  const storeId = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';
  const editToken = 'edit-token-12345678901234567890';
  const remoteId = '22222222-2222-2222-2222-222222222222';
  const images = [
    'https://cdn.example.com/a.jpg',
    'https://cdn.example.com/b.jpg',
    'https://cdn.example.com/c.jpg',
  ];

  Product testProduct({
    required String id,
    required String name,
    String price = '',
    List<String> imageUrls = const [],
    String? categoryId,
    double? oldPriceAmount,
    String? badgeTag,
    String? fulfillmentLocation,
    String source = 'manual',
    String? sourceMediaId,
  }) {
    final richMetadata = alignProductMetadataToCategory(
      const ProductRichMetadata(templateKey: 'generic'),
      ProductCategory(
        id: categoryId ?? '',
        name: '',
        productTemplateKey: categoryId == null ? 'generic' : 'fashion',
      ),
    );
    return Product(
      id: id,
      name: name,
      price: price,
      imageUrls: imageUrls,
      categoryId: categoryId ?? '',
      oldPriceAmount: oldPriceAmount,
      badgeTag: badgeTag,
      fulfillmentLocation: fulfillmentLocation,
      source: source,
      sourceMediaId: sourceMediaId,
      richMetadata: richMetadata,
    );
  }

  setUp(() {
    repo = _FakeProductRepository();
    service = ProductCatalogSyncService(
      productService: ProductService(repository: repo),
    );
  });

  group('syncCatalog', () {
    test('yeni ürünü create yoluna yazar ve id/slug ile döner', () async {
      final result = await service.syncCatalog(
        storeId: storeId,
        editToken: editToken,
        products: [
          testProduct(
            id: 'local-1',
            name: 'Kazak',
            price: '100',
            imageUrls: images,
          ),
        ],
      );

      expect(result.isSuccess, isTrue);
      expect(repo.createdNames, ['Kazak']);
      expect(result.data!.single.id, startsWith('11111111-'));
      expect(result.data!.single.slug, 'core-slug-1');
    });

    test('haricî kaynak kimliğini Product CORE create yoluna taşır', () async {
      final result = await service.syncCatalog(
        storeId: storeId,
        editToken: editToken,
        products: [
          testProduct(
            id: 'invoice-local-1',
            name: 'Faturadan Ürün',
            imageUrls: images,
            source: 'invoice',
            sourceMediaId: 'invoice-42-line-7',
          ),
        ],
      );

      expect(result.isSuccess, isTrue);
      expect(repo.lastSourceType, 'invoice');
      expect(repo.lastExternalProductId, 'invoice-42-line-7');
    });

    test('mevcut uzak id ile eşleşen ürünü update yoluna yazar', () async {
      repo.remote.add(testProduct(id: remoteId, name: 'Eski Ad'));

      final result = await service.syncCatalog(
        storeId: storeId,
        editToken: editToken,
        products: [
          testProduct(id: remoteId, name: 'Yeni Ad', imageUrls: images),
        ],
      );

      expect(result.isSuccess, isTrue);
      expect(repo.updatedIds, [remoteId]);
      expect(repo.createdNames, isEmpty);
    });

    test('yerelde olmayan uzak ürünü asla silmez', () async {
      repo.remote.add(testProduct(id: remoteId, name: 'Eski'));

      final result = await service.syncCatalog(
        storeId: storeId,
        editToken: editToken,
        products: [testProduct(id: 'local-1', name: 'Yeni', imageUrls: images)],
      );

      expect(result.isSuccess, isTrue);
      expect(repo.deletedIds, isEmpty);
      expect(repo.remote.any((p) => p.id == remoteId), isTrue);
    });

    test(
      'boş isimli satırı atlar ama sortOrder ilerlemeye devam eder',
      () async {
        final result = await service.syncCatalog(
          storeId: storeId,
          editToken: editToken,
          products: [
            testProduct(id: 'local-1', name: '   '),
            testProduct(id: 'local-2', name: 'Gerçek Ürün', imageUrls: images),
          ],
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.length, 1);
        expect(result.data!.single.name, 'Gerçek Ürün');
      },
    );

    test('Atmosfer alanlarını (fiyat/eski fiyat/rozet/bölge) iletir', () async {
      final result = await service.syncCatalog(
        storeId: storeId,
        editToken: editToken,
        products: [
          testProduct(
            id: 'local-1',
            name: 'Kazak',
            price: '549 TL',
            imageUrls: images,
            oldPriceAmount: 799,
            badgeTag: '-31%',
            fulfillmentLocation: 'Çekmeköy',
          ),
        ],
      );

      expect(result.isSuccess, isTrue);
      expect(repo.lastPriceAmount, 549);
    });

    test('virgüllü/noktalı fiyat metnini doğru ayrıştırır', () async {
      await service.syncCatalog(
        storeId: storeId,
        editToken: editToken,
        products: [
          testProduct(
            id: 'local-1',
            name: 'A',
            price: '1.234,56 TL',
            imageUrls: images,
          ),
        ],
      );
      expect(repo.lastPriceAmount, 1234.56);
    });

    test(
      'uzak yazma tek ürün için başarısız olursa o mesajla hemen durur',
      () async {
        repo.throwOnCreate = Exception('STORE_NOT_FOUND');

        final result = await service.syncCatalog(
          storeId: storeId,
          editToken: editToken,
          products: [
            testProduct(id: 'local-1', name: 'Kazak', imageUrls: images),
          ],
        );

        expect(result.isFailure, isTrue);
        expect(result.failure!.message, 'Mağaza bulunamadı.');
      },
    );
  });

  group('addProduct', () {
    test('başarılıysa ürünü sunucu id/slug ile yerinde günceller', () async {
      final product = testProduct(
        id: 'local-1',
        name: 'Kazak',
        imageUrls: images,
      );

      final result = await service.addProduct(
        storeId: storeId,
        editToken: editToken,
        product: product,
        sortOrder: 0,
      );

      expect(result.isSuccess, isTrue);
      expect(product.id, startsWith('11111111-'));
      expect(product.slug, 'core-slug-1');
    });

    test('uzak yazma başarısız olursa hata döner', () async {
      repo.throwOnCreate = Exception('boom');
      final product = testProduct(
        id: 'local-1',
        name: 'Kazak',
        imageUrls: images,
      );

      final result = await service.addProduct(
        storeId: storeId,
        editToken: editToken,
        product: product,
        sortOrder: 0,
      );

      expect(result.isFailure, isTrue);
    });
  });

  group('updateProduct', () {
    test('id gerçek UUID değilse uzağa hiç yazmadan başarı döner', () async {
      final result = await service.updateProduct(
        editToken: editToken,
        product: testProduct(id: 'local-1', name: 'Kazak'),
      );

      expect(result.isSuccess, isTrue);
      expect(repo.updatedIds, isEmpty);
    });

    test('id UUID ise uzağı günceller', () async {
      final result = await service.updateProduct(
        editToken: editToken,
        product: testProduct(id: remoteId, name: 'Kazak', imageUrls: images),
      );

      expect(result.isSuccess, isTrue);
      expect(repo.updatedIds, [remoteId]);
    });
  });

  group('deleteProduct', () {
    test('id gerçek UUID değilse uzağa hiç dokunmadan başarı döner', () async {
      final result = await service.deleteProduct(
        productId: 'local-1',
        editToken: editToken,
      );

      expect(result.isSuccess, isTrue);
      expect(repo.deletedIds, isEmpty);
    });

    test('editToken boşsa uzağa hiç dokunmadan başarı döner', () async {
      final result = await service.deleteProduct(
        productId: remoteId,
        editToken: '',
      );

      expect(result.isSuccess, isTrue);
      expect(repo.deletedIds, isEmpty);
    });

    test('UUID ve dolu token ile uzaktan siler', () async {
      repo.remote.add(testProduct(id: remoteId, name: 'Silinecek'));

      final result = await service.deleteProduct(
        productId: remoteId,
        editToken: editToken,
      );

      expect(result.isSuccess, isTrue);
      expect(repo.deletedIds, [remoteId]);
    });
  });
}
