import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitrinx/screens/my_vitrin_screen.dart';

void main() {
  Future<void> pumpEditor(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MaterialApp(home: MyVitrinScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> selectKuaforAndEnableBooking(WidgetTester tester) async {
    final categoryFinder = find.text('Diğer').first;
    await tester.ensureVisible(categoryFinder);
    await tester.pumpAndSettle();
    await tester.tap(categoryFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kuaför').last);
    await tester.pumpAndSettle();

    final bookingTitle = find.textContaining('Randevu Ayarları');
    await tester.ensureVisible(bookingTitle);
    await tester.tap(bookingTitle);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();
  }

  testWidgets('Profil formunda Öne Çıkanlar bölümü gösterilmez', (
    WidgetTester tester,
  ) async {
    await pumpEditor(tester);

    expect(find.text('Öne Çıkanlar'), findsNothing);
    expect(find.text('Menüden Öne Çıkanlar'), findsNothing);
    expect(find.text('Randevu Hizmetleri'), findsNothing);
  });

  testWidgets('Randevu hizmeti önerisi eklenir ve tekrar eklenemez', (
    WidgetTester tester,
  ) async {
    await pumpEditor(tester);
    await selectKuaforAndEnableBooking(tester);

    expect(find.text('Randevu Hizmetleri'), findsOneWidget);

    final chipFinder = find.textContaining('Saç Kesimi & Yıkama').first;
    await tester.ensureVisible(chipFinder);
    await tester.tap(chipFinder);
    await tester.pump();

    expect(find.text('Saç Kesimi & Yıkama'), findsOneWidget);

    await tester.tap(chipFinder);
    await tester.pump();

    expect(find.text('Bu hizmet zaten eklenmiş.'), findsOneWidget);
  });

  testWidgets('Randevu hizmeti önerisi süre bilgisini korur', (
    WidgetTester tester,
  ) async {
    await pumpEditor(tester);
    await selectKuaforAndEnableBooking(tester);

    final chipFinder = find.textContaining('Saç Kesimi & Yıkama').first;
    await tester.ensureVisible(chipFinder);
    await tester.tap(chipFinder);
    await tester.pump();

    final dropdownValues =
        tester
            .widgetList<DropdownButton<int>>(find.byType(DropdownButton<int>))
            .map((dropdown) => dropdown.value)
            .toList();
    expect(dropdownValues, contains(45));
  });
}
