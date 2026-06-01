import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitrinx/screens/explore_screen.dart';

void main() {
  testWidgets('ExploreScreen renders successfully and has correct items', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'favorite_stores': <String>[]});

    await tester.pumpWidget(
      const MaterialApp(
        home: ExploreScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify header title
    expect(find.text('VitrinX Keşfet'), findsOneWidget);
    expect(find.text('Çevrendeki esnafların canlı reyonları'), findsOneWidget);

    // Verify search text field hint
    expect(find.text('Ürün, mağaza veya reyon ara...'), findsOneWidget);

    // Verify category chips exist
    expect(find.text('Tümü'), findsAtLeastNWidgets(1));
    expect(find.text('Giyim & Butik'), findsAtLeastNWidgets(1));
  });

  testWidgets('ExploreScreen search and filters work correctly', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'favorite_stores': <String>[]});

    await tester.pumpWidget(
      const MaterialApp(
        home: ExploreScreen(),
      ),
    );
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
      'favorite_stores': ['Aymira Giyim']
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: ExploreScreen(),
      ),
    );
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
}
