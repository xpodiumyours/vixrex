import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitrinx/screens/store_setup_screen.dart';

void main() {
  testWidgets(
    'StoreSetupScreen step 1 renders category grid with all categories',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const MaterialApp(
          home: StoreSetupScreen(),
        ),
      );
      // Run the initial animation
      await tester.pump(const Duration(milliseconds: 600));

      // Step indicator should show Adım 1/3
      expect(find.text('Adım 1/3'), findsOneWidget);

      // Category grid items
      expect(find.text('Giyim & Butik'), findsOneWidget);
      expect(find.text('Gıda & Fırın'), findsOneWidget);
      expect(find.text('Kozmetik'), findsOneWidget);
      expect(find.text('Dekorasyon'), findsOneWidget);
      expect(find.text('Elektronik'), findsOneWidget);
      expect(find.text('Kırtasiye'), findsOneWidget);
      expect(find.text('Diğer'), findsOneWidget);

      // İleri button must be present
      expect(find.text('İleri'), findsOneWidget);
    },
  );
}
