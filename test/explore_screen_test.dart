import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/screens/explore_screen.dart';
import 'package:vixrex/services/local_storage_keys.dart';

void main() {
  testWidgets('ExploreScreen renders successfully and has correct items', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'favorite_stores': <String>[]});

    await tester.pumpWidget(const MaterialApp(home: ExploreScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify header title
    expect(find.text("Vixrex'leri Keşfet"), findsOneWidget);
    expect(find.text('Yayındaki Vixrex profillerini keşfet'), findsOneWidget);

    // Verify search text field hint
    expect(find.text('Vitrin, ürün veya kategori ara...'), findsOneWidget);

    // Verify category chips exist
    expect(find.text('Tümü'), findsAtLeastNWidgets(1));
    expect(find.text('Giyim'), findsAtLeastNWidgets(1));
  });

  testWidgets('ExploreScreen search and filters work correctly', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'favorite_stores': <String>[]});

    await tester.pumpWidget(const MaterialApp(home: ExploreScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify some stores are loaded
    expect(find.text('Aymira Giyim'), findsAtLeastNWidgets(1));

    // Type in search bar
    await tester.enterText(find.byType(TextField), 'Lezzet Durağı');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify only matching stores are displayed
    expect(find.text('Aymira Giyim'), findsNothing);
    expect(find.text('Lezzet Durağı'), findsAtLeastNWidgets(1));
  });

  testWidgets('ExploreScreen favorites toggle works', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'favorite_stores': ['Aymira Giyim'],
    });

    await tester.pumpWidget(const MaterialApp(home: ExploreScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Tap on the Favorite Filter Chip
    final favoriteFilter = find.textContaining('Favorilerim');
    expect(favoriteFilter, findsOneWidget);

    await tester.tap(favoriteFilter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify only favorited store posts are displayed (Aymira Giyim is favorited, Lezzet Durağı is not)
    expect(find.text('Aymira Giyim'), findsAtLeastNWidgets(1));
    expect(find.text('Lezzet Durağı'), findsNothing);
  });

  testWidgets('ExploreScreen kendi vitrini etiketi gösterir', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'favorite_stores': <String>[],
      LocalStorageKeys.lastPublishedSlug: 'aymira-giyim',
    });

    await tester.pumpWidget(const MaterialApp(home: ExploreScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Senin vitrinin'), findsOneWidget);
  });

  testWidgets('fallback kartları örnek olarak işaretlenir ve açılmaz', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'favorite_stores': <String>[]});

    await tester.pumpWidget(const MaterialApp(home: ExploreScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Örnek'), findsWidgets);
    await tester.ensureVisible(find.text('Aymira Giyim'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aymira Giyim'));
    await tester.pumpAndSettle();

    expect(find.byType(ExploreScreen), findsOneWidget);
  });

  testWidgets('WhatsApp hızlı mesaj seçenekleri güncel metinleri gösterir', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'favorite_stores': <String>[]});

    await tester.pumpWidget(const MaterialApp(home: ExploreScreen()));
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
