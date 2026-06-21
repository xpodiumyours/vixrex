import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitrinx/screens/store_setup_screen.dart';

void main() {
  testWidgets(
    'StoreSetupScreen step 1 renders category grid with all categories',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const MaterialApp(home: StoreSetupScreen()));
      // Run the initial animation
      await tester.pump(const Duration(milliseconds: 600));

      // Step indicator should show Adım 1/5
      expect(find.text('Adım 1/5'), findsOneWidget);

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

  testWidgets(
    'StoreSetupScreen step 2 inline location button is enabled only when KVKK consent is checked',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: StoreSetupScreen()));
      await tester.pump(const Duration(milliseconds: 600));

      // Tap category and select business type to advance to Step 2
      await tester.tap(find.text('Giyim & Butik'));
      await tester.pumpAndSettle();

      // Select business type dropdown option
      await tester.ensureVisible(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Diğer Giyim').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Diğer Giyim').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('İleri'));
      await tester.pumpAndSettle();

      expect(find.text('Adım 2/5'), findsOneWidget);

      // Verify KVKK checkbox is unchecked by default
      final checkboxFinder = find.byType(Checkbox);
      expect(checkboxFinder, findsOneWidget);
      var checkbox = tester.widget<Checkbox>(checkboxFinder);
      expect(checkbox.value, isFalse);

      // Verify location icon button is present but disabled (onPressed is null)
      final iconButtonFinder = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.icon is Icon &&
            (widget.icon as Icon).icon == Icons.my_location_rounded,
      );
      expect(iconButtonFinder, findsOneWidget);
      var iconButton = tester.widget<IconButton>(iconButtonFinder);
      expect(iconButton.onPressed, isNull);

      // Toggle checkbox to true
      await tester.ensureVisible(checkboxFinder);
      await tester.pumpAndSettle();
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      checkbox = tester.widget<Checkbox>(checkboxFinder);
      expect(checkbox.value, isTrue);

      // Verify location icon button is now enabled (onPressed is not null)
      iconButton = tester.widget<IconButton>(iconButtonFinder);
      expect(iconButton.onPressed, isNotNull);
    },
  );
}
