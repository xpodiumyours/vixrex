import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/screens/preview_screen.dart';
import 'package:vixrex/widgets/vitrin_view.dart';

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
          isDemo: true,
        ),
      ),
    );

    final fab = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    expect(fab.onPressed, isNotNull);

    await tester.tap(find.text('WhatsApp Sipariş'));
    await tester.pump();

    expect(
      find.text(
        'Geçerli bir Türkiye cep telefonu numarası girin. Örn: 0555 123 45 67',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'Preview WhatsApp FAB isDemo=true modunda bilgilendirme snackbarı gösterir',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PreviewScreen(
            storeData: StoreData(
              name: 'Test Mağaza',
              whatsapp: '0555 123 45 67',
              isEsnafMode: true,
            ),
            isDemo: true,
          ),
        ),
      );

      await tester.tap(find.text('WhatsApp Sipariş'));
      await tester.pump();

      expect(
        find.text(
          "Müşterileriniz bu butona bastığında '0555 123 45 67' numaralı WhatsApp hattınıza yönlendirilir.",
        ),
        findsOneWidget,
      );
    },
  );

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
