import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitrinx/screens/my_vitrin_screen.dart';

void main() {
  testWidgets('Aynı hizmet önerisinin tekrar eklenmesini engeller ve uyarı gösterir', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(
        home: MyVitrinScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final chipFinder = find.text('🏪 Genel Bilgi & Danışmanlık');
    expect(chipFinder, findsOneWidget);

    await tester.ensureVisible(chipFinder);
    await tester.tap(chipFinder);
    await tester.pump();

    expect(find.text('Genel Bilgi & Danışmanlık'), findsOneWidget);

    await tester.tap(chipFinder);
    await tester.pump();

    expect(find.text('Bu hizmet zaten eklenmiş.'), findsOneWidget);
    expect(find.text('Genel Bilgi & Danışmanlık'), findsOneWidget);
  });

  testWidgets('Öneri çipine dokunulduğunda duration ve isBookable şablon değerlerini doğru eşler', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(
        home: MyVitrinScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Tap on the default suggestion "Genel Bilgi & Danışmanlık"
    final chipFinder = find.text('🏪 Genel Bilgi & Danışmanlık');
    await tester.ensureVisible(chipFinder);
    await tester.tap(chipFinder);
    await tester.pump();

    // The suggested template Genel Bilgi & Danışmanlık has durationMinutes = 30 and isBookable = true
    // Verify that the "Randevuya Açık" switch is turned ON (true)
    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);
    final switchWidget = tester.widget<Switch>(switchFinder);
    expect(switchWidget.value, isTrue);

    // Verify that the duration dropdown has value = 30
    final dropdownFinder = find.byType(DropdownButton<int>);
    expect(dropdownFinder, findsOneWidget);
    final dropdownWidget = tester.widget<DropdownButton<int>>(dropdownFinder);
    expect(dropdownWidget.value, 30);
  });
}
