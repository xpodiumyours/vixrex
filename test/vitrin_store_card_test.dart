import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/premium_service.dart';
import 'package:vixrex/widgets/vitrin_store_card.dart';

void main() {
  late StoreData testStore;

  setUp(() {
    testStore = StoreData(
      name: 'Test Mağazası',
      description: 'Test Açıklaması',
      kategori: 'Giyim & Butik',
      whatsapp: '0555 123 45 67',
      address: 'Test Adresi',
      slug: 'test-magazasi',
    );
  });

  Widget buildCard({
    required StoreData store,
    bool isExample = false,
    bool isFavorited = false,
    bool isOwnStore = false,
    VoidCallback? onTap,
    required VoidCallback onFavoritePressed,
    required VoidCallback onWhatsAppPressed,
    VoidCallback? onRentPressed,
    StorePremiumStatus? premiumStatus,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: GridView.count(
          crossAxisCount: 2,
          children: [
            VitrinStoreCard(
              store: store,
              isExample: isExample,
              isFavorited: isFavorited,
              isOwnStore: isOwnStore,
              onTap: onTap,
              onFavoritePressed: onFavoritePressed,
              onWhatsAppPressed: onWhatsAppPressed,
              onRentPressed: onRentPressed,
              premiumStatus: premiumStatus,
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('1. Mağaza adı ve açıklaması gösteriliyor', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildCard(
        store: testStore,
        onFavoritePressed: () {},
        onWhatsAppPressed: () {},
      ),
    );

    expect(find.text('Test Mağazası'), findsOneWidget);
    // Kart kategori etiketini büyük harfe çevirerek gösterir
    // (VitrinStoreCard içindeki categoryLabel .toUpperCase()).
    expect(find.text('Giyim & Butik'.toUpperCase()), findsOneWidget);
  });

  testWidgets('2. isExample true olduğunda Örnek etiketi gösteriliyor', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildCard(
        store: testStore,
        isExample: true,
        onFavoritePressed: () {},
        onWhatsAppPressed: () {},
      ),
    );

    expect(find.text('Örnek'), findsOneWidget);
  });

  testWidgets(
    '3. isOwnStore true olduğunda Senin vitrinin etiketi gösteriliyor',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildCard(
          store: testStore,
          isOwnStore: true,
          onFavoritePressed: () {},
          onWhatsAppPressed: () {},
        ),
      );

      expect(find.text('Senin vitrinin'), findsOneWidget);
    },
  );

  testWidgets(
    '3b. Kendi vitrininde premium aktifse süre bilgisi gösteriliyor',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildCard(
          store: testStore,
          isOwnStore: true,
          premiumStatus: StorePremiumStatus(
            storeId: 'x',
            isPremium: true,
            premiumExpiresAt: _day(25),
          ),
          onFavoritePressed: () {},
          onWhatsAppPressed: () {},
        ),
      );

      expect(find.text('Premium aktif · 25 gün kaldı'), findsOneWidget);
    },
  );

  testWidgets(
    '3c. Kendi vitrininde premium değilse yayın yönlendirmesi gösteriliyor',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildCard(
          store: testStore,
          isOwnStore: true,
          premiumStatus: const StorePremiumStatus(
            storeId: 'x',
            isPremium: false,
          ),
          onFavoritePressed: () {},
          onWhatsAppPressed: () {},
        ),
      );

      expect(
        find.text('Premium değil · Aylık 299 TL ile yayınla'),
        findsOneWidget,
      );
    },
  );

  testWidgets('3d. premium bilgisi yalnız KENDİ vitrininde gösterilir', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildCard(
        store: testStore,
        isOwnStore: false,
        premiumStatus: StorePremiumStatus(
          storeId: 'x',
          isPremium: true,
          premiumExpiresAt: _day(25),
        ),
        onFavoritePressed: () {},
        onWhatsAppPressed: () {},
      ),
    );

    expect(find.textContaining('Premium aktif'), findsNothing);
  });

  testWidgets('4. Favori butonu callback’i çalışıyor', (
    WidgetTester tester,
  ) async {
    var favoritePressed = false;
    await tester.pumpWidget(
      buildCard(
        store: testStore,
        onFavoritePressed: () => favoritePressed = true,
        onWhatsAppPressed: () {},
      ),
    );

    final favButton = find.byIcon(Icons.favorite_border_rounded);
    expect(favButton, findsOneWidget);
    await tester.tap(favButton);
    await tester.pump();

    expect(favoritePressed, isTrue);
  });

  testWidgets('5. WhatsApp butonu callback’i çalışıyor', (
    WidgetTester tester,
  ) async {
    var whatsappPressed = false;
    await tester.pumpWidget(
      buildCard(
        store: testStore,
        onFavoritePressed: () {},
        onWhatsAppPressed: () => whatsappPressed = true,
      ),
    );

    final waButton = find.byIcon(Icons.chat_bubble_rounded);
    expect(waButton, findsOneWidget);
    await tester.tap(waButton);
    await tester.pump();

    expect(whatsappPressed, isTrue);
  });

  testWidgets('6. Kartın onTap davranışı doğru çalışıyor', (
    WidgetTester tester,
  ) async {
    var cardTapped = false;
    await tester.pumpWidget(
      buildCard(
        store: testStore,
        onTap: () => cardTapped = true,
        onFavoritePressed: () {},
        onWhatsAppPressed: () {},
      ),
    );

    await tester.tap(find.text('Test Mağazası'));
    await tester.pump();

    expect(cardTapped, isTrue);
  });

  testWidgets(
    '7. Kiralık kartta onRentPressed varsa İncele/Kirala ayrı butonlar',
    (WidgetTester tester) async {
      final demoStore = StoreData(
        name: 'Demo Vitrin',
        kategori: 'Kafe / Lokanta',
        slug: 'kiralik-kafe',
        isDemo: true,
      );
      var incelendi = false;
      var kiralandi = false;

      await tester.pumpWidget(
        buildCard(
          store: demoStore,
          onTap: () => incelendi = true,
          onFavoritePressed: () {},
          onWhatsAppPressed: () {},
          onRentPressed: () => kiralandi = true,
        ),
      );

      expect(find.text('İncele'), findsOneWidget);
      expect(find.text('Kirala'), findsOneWidget);
      // Eski tek-buton metni artık görünmemeli.
      expect(find.text('Vitrini İncele'), findsNothing);

      await tester.tap(find.text('Kirala'));
      await tester.pump();
      expect(kiralandi, isTrue);
      expect(incelendi, isFalse);

      await tester.tap(find.text('İncele'));
      await tester.pump();
      expect(incelendi, isTrue);
    },
  );

  testWidgets(
    '8. Kiralık kartta onRentPressed YOKSA eski tek-buton davranışı korunur',
    (WidgetTester tester) async {
      final demoStore = StoreData(
        name: 'Demo Vitrin',
        kategori: 'Kafe / Lokanta',
        slug: 'kiralik-kafe',
        isDemo: true,
      );
      var incelendi = false;

      await tester.pumpWidget(
        buildCard(
          store: demoStore,
          onTap: () => incelendi = true,
          onFavoritePressed: () {},
          onWhatsAppPressed: () {},
        ),
      );

      expect(find.text('Vitrini İncele'), findsOneWidget);
      expect(find.text('Kirala'), findsNothing);

      await tester.tap(find.text('Vitrini İncele'));
      await tester.pump();
      expect(incelendi, isTrue);
    },
  );
}

/// Testte kullanılmak üzere bugünden N gün + 6 saat sonrasını döndürür
/// (saf). Fazladan 6 saat: `difference().inDays` kesmesi (truncation)
/// nedeniyle tam 25 gün sonrası 24 gün olarak görünebilir.
DateTime _day(int days) => DateTime.now().add(Duration(days: days, hours: 6));
