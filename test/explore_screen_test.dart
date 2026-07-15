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
    expect(find.text('Yayındaki Vixrex profillerini keşfet'), findsOneWidget);
    expect(find.text('Vitrin, ürün veya kategori ara...'), findsOneWidget);
    expect(find.text('Tümü'), findsAtLeastNWidgets(1));
    expect(find.text('Giyim'), findsAtLeastNWidgets(1));
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

    final favoriteFilter = find.textContaining('Favorilerim');
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

    expect(find.text('Aramanızla eşleşen vitrin bulunamadı.'), findsOneWidget);
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
}
