import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/screens/preview_screen.dart';
import 'package:vitrinx/widgets/vitrin_view.dart';

void main() {
  testWidgets('Preview WhatsApp FAB geçersiz numarada açıklayıcı uyarı verir', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PreviewScreen(
          storeData: StoreData(
            name: 'Test Mağaza',
            whatsapp: 'abc',
            isEsnafMode: true,
          ),
        ),
      ),
    );

    final fab = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    expect(fab.onPressed, isNotNull);

    await tester.tap(find.text('WhatsApp Sipariş'));
    await tester.pump();

    expect(find.text('Geçerli bir WhatsApp numarası ekleyin.'), findsOneWidget);
  });

  testWidgets('Public vitrinde geçersiz WhatsApp aksiyonu gizlenir', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: VitrinView(
              storeData: StoreData(name: 'Test Mağaza', whatsapp: 'abc'),
              publicMode: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('WhatsApp'), findsNothing);
  });
}
