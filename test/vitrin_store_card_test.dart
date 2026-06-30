import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/widgets/vitrin_store_card.dart';

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
    expect(find.text('Giyim & Butik'), findsOneWidget);
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
}
