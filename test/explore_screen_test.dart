import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/repositories/explore_repository.dart';
import 'package:vixrex/screens/explore_screen.dart';
import 'package:vixrex/widgets/vitrin_store_card.dart';

/// Testler için sahte repository — Supabase'e ihtiyaç duymaz.
class _FakeExploreRepository extends Fake implements ExploreRepository {
  _FakeExploreRepository({
    required this.stores,
    this.favoriteNames = const [],
    this.publishedSlug,
  });
  final List<StoreData> stores;
  final List<String> favoriteNames;
  final String? publishedSlug;

  @override
  Future<List<StoreData>> fetchPublishedStores() async => stores;

  @override
  Future<List<String>> loadFavoriteStoreNames() async => favoriteNames;

  @override
  Future<String?> loadLastPublishedSlug() async => publishedSlug;

  // Premium okuma akışında edit_token yerelde yoksa atlanır — bu test
  // düzeninde premium bilgisi hiç çekilmez (PR #6).
  @override
  Future<String?> loadLastPublishedEditToken() async => null;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'favorite_stores': <String>[]});
  });

  testWidgets('ExploreScreen renders successfully and has correct items', (
    WidgetTester tester,
  ) async {
    final repo = _FakeExploreRepository(
      stores: [
        StoreData(
          name: 'Aymira Giyim',
          description: 'Yeni Sezon Ürünler',
          kategori: 'Giyim',
          whatsapp: '905551234567',
          address: 'Kadıköy',
          slug: 'aymira-giyim',
        ),
        StoreData(
          name: 'Lezzet Durağı',
          description: 'Ev Yemekleri',
          kategori: 'Yiyecek & İçecek',
          whatsapp: '905557654321',
          address: 'Beşiktaş',
          slug: 'lezzet-duragi',
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp(home: ExploreScreen(repository: repo)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text("Vixrex'leri Keşfet"), findsOneWidget);
    expect(
      find.text('Yayındaki tüm Vixrex vitrinlerini inceleyin'),
      findsOneWidget,
    );
    // Adım 3 (tasarım tutarlılığı): ipucu metnindeki üç nokta kaldırıldı,
    // diğer ekranlardaki ipuçlarıyla aynı biçime getirildi.
    expect(find.text('Vitrin, ürün veya il/ilçe ara'), findsOneWidget);
    expect(find.text('Tümü'), findsAtLeastNWidgets(1));
    expect(find.text('Giyim'), findsAtLeastNWidgets(1));
    expect(find.text('Perakende'), findsNothing);
    for (final legacyKategori in [
      'Fırın',
      'Kozmetik',
      'Dekorasyon',
      'Elektronik',
      'Kırtasiye',
    ]) {
      expect(find.text(legacyKategori), findsNothing);
    }
  });

  testWidgets('ExploreScreen search and filters work correctly', (
    WidgetTester tester,
  ) async {
    final repo = _FakeExploreRepository(
      stores: [
        StoreData(
          name: 'Aymira Giyim',
          description: 'Yeni Sezon Ürünler',
          kategori: 'Giyim',
          whatsapp: '905551234567',
          address: 'Kadıköy',
          slug: 'aymira-giyim',
        ),
        StoreData(
          name: 'Lezzet Durağı',
          description: 'Ev Yemekleri',
          kategori: 'Yiyecek & İçecek',
          whatsapp: '905557654321',
          address: 'Beşiktaş',
          slug: 'lezzet-duragi',
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp(home: ExploreScreen(repository: repo)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Aymira Giyim'), findsAtLeastNWidgets(1));

    await tester.enterText(find.byType(TextField), 'Lezzet Durağı');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Aymira Giyim'), findsNothing);
    expect(find.text('Lezzet Durağı'), findsAtLeastNWidgets(1));
  });

  testWidgets('ExploreScreen favorites toggle works', (
    WidgetTester tester,
  ) async {
    final repo = _FakeExploreRepository(
      stores: [
        StoreData(
          name: 'Aymira Giyim',
          description: 'Yeni Sezon Ürünler',
          kategori: 'Giyim',
          whatsapp: '905551234567',
          address: 'Kadıköy',
          slug: 'aymira-giyim',
        ),
        StoreData(
          name: 'Lezzet Durağı',
          description: 'Ev Yemekleri',
          kategori: 'Yiyecek & İçecek',
          whatsapp: '905557654321',
          address: 'Beşiktaş',
          slug: 'lezzet-duragi',
        ),
      ],
      favoriteNames: ['Aymira Giyim'],
    );

    await tester.pumpWidget(MaterialApp(home: ExploreScreen(repository: repo)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final favoriteFilter = find.byTooltip('Favorilerim');
    expect(favoriteFilter, findsOneWidget);

    await tester.tap(favoriteFilter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Aymira Giyim'), findsAtLeastNWidgets(1));
    expect(find.text('Lezzet Durağı'), findsNothing);
  });

  testWidgets('ExploreScreen kendi vitrini etiketi gösterir', (
    WidgetTester tester,
  ) async {
    final repo = _FakeExploreRepository(
      stores: [
        StoreData(
          name: 'Aymira Giyim',
          description: 'Yeni Sezon Ürünler',
          kategori: 'Giyim',
          whatsapp: '905551234567',
          address: 'Kadıköy',
          slug: 'aymira-giyim',
        ),
      ],
      publishedSlug: 'aymira-giyim',
    );

    await tester.pumpWidget(MaterialApp(home: ExploreScreen(repository: repo)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Senin vitrinin'), findsOneWidget);
  });

  testWidgets('Boş sonuçta boş durum gösterilir ve vitrin kartı oluşmaz', (
    WidgetTester tester,
  ) async {
    final repo = _FakeExploreRepository(stores: []);

    await tester.pumpWidget(MaterialApp(home: ExploreScreen(repository: repo)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Adım 3 (tasarım tutarlılığı): boş durum artık AppEmptyState kullanıyor,
    // başlık ve gerekçe iki ayrı metin oldu.
    expect(find.text('Aramanızla eşleşen vitrin yok'), findsOneWidget);
    expect(
      find.text('Farklı bir kelime deneyin veya filtreleri temizleyin.'),
      findsOneWidget,
    );
    expect(find.byType(VitrinStoreCard), findsNothing);
    expect(find.text('Örnek'), findsNothing);
  });

  testWidgets('WhatsApp hızlı mesaj seçenekleri güncel metinleri gösterir', (
    WidgetTester tester,
  ) async {
    final repo = _FakeExploreRepository(
      stores: [
        StoreData(
          name: 'Aymira Giyim',
          description: 'Yeni Sezon Ürünler',
          kategori: 'Giyim',
          whatsapp: '905551234567',
          address: 'Kadıköy',
          slug: 'aymira-giyim',
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp(home: ExploreScreen(repository: repo)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final whatsappButton = find.byIcon(Icons.chat_bubble_rounded).first;
    await tester.ensureVisible(whatsappButton);
    await tester.pumpAndSettle();
    await tester.tap(whatsappButton);
    await tester.pumpAndSettle();

    expect(find.text('Hazır mesaj seçin:'), findsOneWidget);
    expect(find.text('Ürün ve fiyat bilgisi'), findsOneWidget);
    expect(find.text('Sipariş vermek istiyorum'), findsOneWidget);
    expect(find.text('Adres ve çalışma saatleri'), findsOneWidget);
  });

  // Akış 1 paritesi (2026-09-03): niyet sorusundan gelen initialCategory
  // listeyi ön-filtreli açar (Web'deki `/kesfet?kategori=` karşılığı).
  testWidgets('ExploreScreen initialCategory ile ön-filtreli açılır', (
    WidgetTester tester,
  ) async {
    final repo = _FakeExploreRepository(
      stores: [
        StoreData(
          name: 'Aymira Giyim',
          description: 'Yeni Sezon Ürünler',
          kategori: 'Giyim',
          whatsapp: '905551234567',
          address: 'Kadıköy',
          slug: 'aymira-giyim',
          isDemo: true,
        ),
        StoreData(
          name: 'Lezzet Durağı',
          description: 'Ev Yemekleri',
          kategori: 'Yiyecek & İçecek',
          whatsapp: '905557654321',
          address: 'Beşiktaş',
          slug: 'lezzet-duragi',
          isDemo: true,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ExploreScreen(
          repository: repo,
          onlyRentalTemplates: true,
          initialCategory: 'Giyim',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Hazır Vitrin Seç'), findsOneWidget);
    expect(find.text('Aymira Giyim'), findsOneWidget);
    expect(find.text('Lezzet Durağı'), findsNothing);
  });

  testWidgets('ExploreScreen bilinmeyen initialCategory sessizce yoksayar', (
    WidgetTester tester,
  ) async {
    final repo = _FakeExploreRepository(
      stores: [
        StoreData(
          name: 'Aymira Giyim',
          description: 'Yeni Sezon Ürünler',
          kategori: 'Giyim',
          whatsapp: '905551234567',
          address: 'Kadıköy',
          slug: 'aymira-giyim',
          isDemo: true,
        ),
        StoreData(
          name: 'Lezzet Durağı',
          description: 'Ev Yemekleri',
          kategori: 'Yiyecek & İçecek',
          whatsapp: '905557654321',
          address: 'Beşiktaş',
          slug: 'lezzet-duragi',
          isDemo: true,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ExploreScreen(
          repository: repo,
          onlyRentalTemplates: true,
          initialCategory: 'Uzay Üssü',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Süzgeçsiz açılır — hata/boş durum yok, iki vitrin de görünür.
    expect(find.text('Aymira Giyim'), findsOneWidget);
    expect(find.text('Lezzet Durağı'), findsOneWidget);
  });
}
