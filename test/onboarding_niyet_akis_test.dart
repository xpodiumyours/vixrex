import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/models/created_product.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/repositories/product_repository.dart';
import 'package:vixrex/screens/explore_screen.dart';
import 'package:vixrex/screens/vixrex_onboarding_chat_screen.dart';
import 'package:vixrex/services/product_service.dart';
import 'package:vixrex/services/store_local_storage_service.dart';
import 'package:vixrex/widgets/onboarding/kategori_secici.dart';

/// Akış 1 niyet adımının widget kanıtı (2026-09-03).
///
/// Flutter web canvas dışarıdan tıklanamadığı için (headless tarayıcıda
/// sentetik olaylar cam resme ulaşmıyor) bu adımın piksel karesi yok;
/// karşılığında sohbetin kendisi test edilir: karşılama hapına dokununca
/// niyet sorusu (ızgara + serbest metin + geri) çiziliyor, kategori
/// seçimi ön-filtreli Keşfet'i açıyor.
class _BosDepo extends ProductRepository {
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
  }) async => const CreatedProduct(id: 'unused', slug: 'unused');

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

Future<void> _karsilamayiAc(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  FlutterSecureStorage.setMockInitialValues({});
  StoreLocalStorageService.resetCache();
  // Telefon boyu: 800x600 penceresinde boş/hata durumları taşabiliyor.
  tester.view.physicalSize = const Size(1200, 1920);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final editorController = StoreEditorController(
    productService: ProductService(repository: _BosDepo()),
  );
  addTearDown(editorController.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: VixRexOnboardingChatScreen(
        editorController: editorController,
        editorInitialization: Future<void>.value(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('karşılamada üç hızlı seçenek duruyor', (tester) async {
    await _karsilamayiAc(tester);

    expect(find.text('Hazır Vitrin Seç'), findsOneWidget);
    expect(find.text('Sıfırdan Oluştur'), findsOneWidget);
    expect(find.text('Bakınıyorum'), findsOneWidget);
    expect(find.byType(KategoriSecici), findsNothing);
  });

  testWidgets('Hazır Vitrin Seç niyet sorusunu açar (Web C1 karşılığı)', (
    tester,
  ) async {
    await _karsilamayiAc(tester);

    await tester.tap(find.text('Hazır Vitrin Seç'));
    await tester.pumpAndSettle();

    // Soru balonu + ızgara + veya + giriş ipucu + geri — Web'dekiyle aynı öğeler.
    expect(find.textContaining('Ne iş yapıyorsun?'), findsOneWidget);
    expect(find.byType(KategoriSecici), findsOneWidget);
    expect(find.text('Giyim'), findsOneWidget);
    expect(find.text('veya'), findsOneWidget);
    expect(find.textContaining('birkaç cümleyle'), findsOneWidget);
    expect(find.text('‹ Geri'), findsOneWidget);
    // Henüz Keşfet'e gidilmedi.
    expect(find.byType(ExploreScreen), findsNothing);
  });

  testWidgets('ızgaradan kategori seçimi ön-filtreli Keşfet açar', (
    tester,
  ) async {
    await _karsilamayiAc(tester);

    await tester.tap(find.text('Hazır Vitrin Seç'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Giyim').first);
    await tester.pumpAndSettle();

    expect(find.byType(ExploreScreen), findsOneWidget);
    // NOT: backend'siz testte liste boş/hata durumuna düşer; 800x600
    // penceresinde AppEmptyState taşıyor (ayrı, önceden-var bulgu) —
    // burada yalnız NAVİGASYON kilitlenir, ön-filtre davranışı
    // explore_screen_test.dart'taki sahte depolu testlerdedir.
  });

  testWidgets('‹ Geri karşılamaya döndürür, satır eklemez', (tester) async {
    await _karsilamayiAc(tester);

    await tester.tap(find.text('Hazır Vitrin Seç'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('‹ Geri'));
    await tester.pumpAndSettle();

    expect(find.text('Hazır Vitrin Seç'), findsOneWidget);
    expect(find.byType(KategoriSecici), findsNothing);
    expect(find.text('‹ Geri'), findsNothing);
  });
}
