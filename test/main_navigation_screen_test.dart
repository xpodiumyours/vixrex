import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/config/chatbot_config.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/repositories/product_repository.dart';
import 'package:vixrex/screens/landing_screen.dart';
import 'package:vixrex/screens/my_vitrin_screen.dart';
import 'package:vixrex/screens/profile_screen.dart';
import 'package:vixrex/screens/vixrex_onboarding_chat_screen.dart';
import 'package:vixrex/screens/vixrex_screen.dart';
import 'package:vixrex/services/store_local_storage_service.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';
import 'package:vixrex/services/product_service.dart';
import 'package:vixrex/widgets/chatbot_badge.dart';
import 'package:vixrex/widgets/vixrex/vixrex_hero.dart';

void main() {
  testWidgets('landing kayıtlı vitrin durumunu Vixrex rozetine aktarır', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    StoreLocalStorageService.resetCache();
    const storage = StoreLocalStorageService();
    await storage.saveVitrinData(StoreData(name: 'Kayıtlı Vitrin'));
    tester.view.physicalSize = const Size(1200, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: LandingScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final badge = tester.widget<ChatbotBadge>(find.byType(ChatbotBadge));
    expect(badge.snapshot?.storeName, 'Kayıtlı Vitrin');
    expect(badge.isLoading, isFalse);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: ChatbotBadge(snapshot: badge.snapshot)),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Sıradaki adım:'), findsOneWidget);
    expect(find.textContaining('hazırlayayım mı'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('kayıtlı vitrin asistanı kaldığı adımdan devam eder', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    StoreLocalStorageService.resetCache();
    const storage = StoreLocalStorageService();
    final savedData = StoreData(name: 'Kayıtlı Vitrin');
    await storage.saveVitrinData(savedData);
    final editorController = StoreEditorController(
      initialData: savedData,
      productService: ProductService(repository: _NoopProductRepository()),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: VixRexOnboardingChatScreen(
          editorController: editorController,
          editorInitialization: Future<void>.value(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Tekrar hoş geldin, Kayıtlı Vitrin'), findsOneWidget);
    expect(find.textContaining('Kayıtlı vitrinin bulundu'), findsOneWidget);
    expect(find.textContaining('WhatsApp numaranı ekleyelim'), findsOneWidget);
    expect(find.textContaining('vitrin oluşturmamı ister misin'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    editorController.dispose();
  });

  testWidgets(
    'gömülü asistan manuel panelle aynı controllerı ve ürünleri korur',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1200, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final editorController = StoreEditorController(
        productService: ProductService(repository: _NoopProductRepository()),
      );
      editorController.data.products.add(
        Product(
          id: 'urun-1',
          name: 'Korunan Ürün',
          price: '250',
          imageUrls: const ['https://example.com/urun.jpg'],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: VixRexScreen(
            snapshot: null,
            editorController: editorController,
            editorInitialization: Future<void>.value(),
            hasShared: false,
            dismissedRecommendationId: null,
            onAction: (_) {},
            onDismissRecommendation: (_) {},
            onSaveField: (_, __) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Oluşturalım'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Asistan Vitrini');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      expect(editorController.data.name, 'Asistan Vitrini');
      expect(editorController.data.products, hasLength(1));
      expect(editorController.data.products.single.name, 'Korunan Ürün');

      final manualScreen = MyVitrinScreen(
        editorController: editorController,
        editorInitialization: Future<void>.value(),
      );

      expect(identical(manualScreen.editorController, editorController), isTrue);
      expect(editorController.data.products, hasLength(1));

      await tester.pumpWidget(const SizedBox.shrink());
      editorController.dispose();
    },
  );

  testWidgets('Vixrex ekranı Türkçe başlıkları gösterir', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1200, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: VixRexScreen(
          snapshot: const VixRexProfileSnapshot(
            nameCompleted: true,
            whatsappCompleted: true,
            addressCompleted: true,
            legalCompleted: true,
            coverCompleted: true,
            galleryCompleted: true,
            descriptionCompleted: true,
            catalogCompleted: true,
            isPublished: true,
            storeName: 'Test Mağazası',
            category: 'Kategori',
            district: 'İlçe',
            publicLink: 'https://vixrex.com/test',
          ),
          hasShared: false,
          dismissedRecommendationId: null,
          onAction: (_) {},
          onDismissRecommendation: (_) {},
          onSaveField: (_, __) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vixrex'), findsWidgets);
    expect(find.text('SIRADAKİ ADIM'), findsOneWidget);
    expect(find.text('Vitrin araçları'), findsNothing);

    await tester.tap(find.byType(VixRexHero));
    await tester.pump();
    final input = tester.widget<TextField>(find.byType(TextField));
    expect(input.focusNode?.hasFocus, isTrue);
  });

  test('Vixrex karşılama metni düz ve desteklenen karakterlerden oluşur', () {
    final text = ChatbotConfig.welcomeMessage.text;

    expect(text, isNot(contains('**')));
    expect(text, isNot(contains('👋')));
    expect(text, contains('Merhaba! Ben Vixrex'));
  });

  testWidgets('ChatbotBadge onOpen tek kapıyı çağırır, overlay açmaz', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: ChatbotBadge(onOpen: () => opened = true)),
        ),
      ),
    );
    await tester.tap(find.byType(ChatbotBadge));
    await tester.pump();

    expect(opened, isTrue);
    expect(find.text('Üyelik / Kullanım'), findsNothing);
    expect(find.text('İşletme Adı Ekle'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profil ekranı Türkçe başlığı gösterir', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));

    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Vixrex Kullanıcısı'), findsOneWidget);
  });
}

class _NoopProductRepository implements ProductRepository {
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
  }) async => 'unused';

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
  }) async {}
}
