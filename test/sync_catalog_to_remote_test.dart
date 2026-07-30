import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/repositories/product_repository.dart';
import 'package:vixrex/services/product_service.dart';
import 'package:vixrex/services/store_local_storage_service.dart';

class _FakeProductRepository implements ProductRepository {
  final List<Product> remote = [];
  final List<String> createdNames = [];
  final List<String> deletedIds = [];
  double? lastPriceAmount;
  double? lastOldPriceAmount;
  String? lastBadgeTag;
  String? lastFulfillmentRegion;

  @override
  Future<List<Product>> getProductsByStoreId(String storeId) async =>
      List.of(remote);

  @override
  Future<List<Product>> getVisibleProductsByStoreId(String storeId) async =>
      remote.where((p) => p.isVisible).toList();

  @override
  Future<String> createProduct({
    required String storeId,
    required String editToken,
    required String name,
    required String slug,
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
    createdNames.add(name);
    lastPriceAmount = priceAmount;
    lastOldPriceAmount = oldPriceAmount;
    lastBadgeTag = badgeTag;
    lastFulfillmentRegion = fulfillmentRegion;
    final suffix = createdNames.length.toString().padLeft(12, '0');
    final id = '11111111-1111-1111-1111-$suffix';
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
        oldPriceAmount: oldPriceAmount,
        badgeTag: badgeTag,
        fulfillmentLocation: fulfillmentRegion,
      ),
    );
    return id;
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
    if (priceAmount != null) lastPriceAmount = priceAmount;
    if (oldPriceAmount != null) lastOldPriceAmount = oldPriceAmount;
    if (badgeTag != null) lastBadgeTag = badgeTag;
    if (fulfillmentRegion != null) lastFulfillmentRegion = fulfillmentRegion;
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

class _MemoryStorage extends StoreLocalStorageService {
  StoreData? _data;
  PublishedVitrinInfo? _info;

  @override
  Future<StoreData?> loadVitrinData() async => _data;

  @override
  Future<void> saveVitrinData(StoreData data) async {
    _data = data;
  }

  @override
  Future<PublishedVitrinInfo?> loadPublishedVitrinInfo() async => _info;

  @override
  Future<void> savePublishedVitrinInfo({
    required String slug,
    required String publicLink,
    required String name,
    required String editToken,
  }) async {
    _info = PublishedVitrinInfo(
      slug: slug,
      publicLink: publicLink,
      name: name,
      editToken: editToken,
    );
  }
}

void main() {
  late _FakeProductRepository repo;
  late _MemoryStorage storage;
  late StoreEditorController controller;

  setUp(() {
    repo = _FakeProductRepository();
    storage = _MemoryStorage();
    controller = StoreEditorController(
      storage: storage,
      productService: ProductService(repository: repo),
      initialData: StoreData(
        id: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        slug: 'demo-magaza',
        name: 'Demo',
        kategori: 'Diğer',
        status: 'Açık',
      ),
    );
  });

  test('yayın yoksa syncCatalogToRemote hata döner', () async {
    final result = await controller.syncCatalogToRemote(
      products: [Product(id: 'local-1', name: 'Kazak')],
      categories: const [],
    );
    expect(result.isFailure, isTrue);
  });

  test('yeni ürün create_store_product yoluna yazar', () async {
    await storage.saveVitrinData(
      StoreData(
        id: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        slug: 'demo-magaza',
        name: 'Demo',
        kategori: 'Diğer',
        status: 'Açık',
      ),
    );
    await storage.savePublishedVitrinInfo(
      slug: 'demo-magaza',
      publicLink: 'https://vixrex-public.vercel.app/v/demo-magaza',
      name: 'Demo',
      editToken: 'edit-token-12345678901234567890',
    );
    await controller.initialize(null);

    final result = await controller.syncCatalogToRemote(
      products: [Product(id: 'local-1', name: 'Kazak', price: '100')],
      categories: const [],
    );

    expect(result.isSuccess, isTrue);
    expect(repo.createdNames, ['Kazak']);
    expect(controller.data.products.single.name, 'Kazak');
    expect(controller.data.products.single.id, startsWith('11111111-'));
  });

  test('yerelde olmayan remote ürünü otomatik silmez', () async {
    await storage.saveVitrinData(
      StoreData(
        id: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        slug: 'demo-magaza',
        name: 'Demo',
        kategori: 'Diğer',
        status: 'Açık',
      ),
    );
    await storage.savePublishedVitrinInfo(
      slug: 'demo-magaza',
      publicLink: 'https://vixrex-public.vercel.app/v/demo-magaza',
      name: 'Demo',
      editToken: 'edit-token-12345678901234567890',
    );
    repo.remote.add(
      Product(id: '22222222-2222-2222-2222-222222222222', name: 'Eski'),
    );
    await controller.initialize(null);

    final result = await controller.syncCatalogToRemote(
      products: [Product(id: 'local-1', name: 'Yeni')],
      categories: const [],
    );

    expect(result.isSuccess, isTrue);
    expect(repo.deletedIds, isEmpty);
    expect(repo.remote.any((p) => p.id == '22222222-2222-2222-2222-222222222222'), isTrue);
    expect(repo.createdNames, ['Yeni']);
  });

  test('sync create Atmosfer alanlarını yazar', () async {
    await storage.saveVitrinData(
      StoreData(
        id: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        slug: 'demo-magaza',
        name: 'Demo',
        kategori: 'Diğer',
        status: 'Açık',
      ),
    );
    await storage.savePublishedVitrinInfo(
      slug: 'demo-magaza',
      publicLink: 'https://vixrex-public.vercel.app/v/demo-magaza',
      name: 'Demo',
      editToken: 'edit-token-12345678901234567890',
    );
    await controller.initialize(null);

    final result = await controller.syncCatalogToRemote(
      products: [
        Product(
          id: 'local-1',
          name: 'Kazak',
          price: '549 TL',
          oldPriceAmount: 799,
          badgeTag: '-31%',
          fulfillmentLocation: 'Çekmeköy',
        ),
      ],
      categories: const [],
    );

    expect(result.isSuccess, isTrue);
    expect(repo.lastPriceAmount, 549);
    expect(repo.lastOldPriceAmount, 799);
    expect(repo.lastBadgeTag, '-31%');
    expect(repo.lastFulfillmentRegion, 'Çekmeköy');
  });

  test('removeProduct yalnız seçilen ürünü kalıcı siler', () async {
    await storage.saveVitrinData(
      StoreData(
        id: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        slug: 'demo-magaza',
        name: 'Demo',
        kategori: 'Diğer',
        status: 'Açık',
        products: [
          Product(id: '22222222-2222-2222-2222-222222222222', name: 'Silinecek'),
          Product(id: '33333333-3333-3333-3333-333333333333', name: 'Kalacak'),
        ],
      ),
    );
    await storage.savePublishedVitrinInfo(
      slug: 'demo-magaza',
      publicLink: 'https://vixrex-public.vercel.app/v/demo-magaza',
      name: 'Demo',
      editToken: 'edit-token-12345678901234567890',
    );
    repo.remote.addAll([
      Product(id: '22222222-2222-2222-2222-222222222222', name: 'Silinecek'),
      Product(id: '33333333-3333-3333-3333-333333333333', name: 'Kalacak'),
    ]);
    await controller.initialize(null);

    final result = await controller.removeProduct(0);

    expect(result.isSuccess, isTrue);
    expect(repo.deletedIds, ['22222222-2222-2222-2222-222222222222']);
    expect(controller.data.products.map((p) => p.name), ['Kalacak']);
    expect(repo.remote.map((p) => p.name), ['Kalacak']);
  });
}
