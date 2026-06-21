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

    final chipFinder = find.text('🏪 Özel Hizmet Danışmanlığı');
    expect(chipFinder, findsOneWidget);

    await tester.ensureVisible(chipFinder);
    await tester.tap(chipFinder);
    await tester.pump();

    expect(find.text('Özel Hizmet Danışmanlığı'), findsOneWidget);

    await tester.tap(chipFinder);
    await tester.pump();

    expect(find.text('Bu hizmet zaten eklenmiş.'), findsOneWidget);
    expect(find.text('Özel Hizmet Danışmanlığı'), findsOneWidget);
  });
}
