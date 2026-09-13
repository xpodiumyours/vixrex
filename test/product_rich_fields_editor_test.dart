import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/widgets/product/product_editor_sheet.dart';

void main() {
  testWidgets('giyim kategorisi ortak şemadaki ürün alanlarını gösterir', (
    tester,
  ) async {
    final category = ProductCategory(
      id: 'fashion-1',
      name: 'Giyim',
      productTemplateKey: 'fashion',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductEditorSheet(
            categories: [category],
            storeSlug: 'ornek-vitrin',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Marka · önerilen'), findsOneWidget);
    expect(find.text('Renk · önerilen'), findsOneWidget);
    expect(find.text('Beden · önerilen'), findsOneWidget);
    expect(find.text('Materyal · önerilen'), findsOneWidget);
    expect(find.text('Stok adedi'), findsOneWidget);
  });

  testWidgets('hizmet kategorisi stok yerine hizmet alanlarını gösterir', (
    tester,
  ) async {
    final category = ProductCategory(
      id: 'service-1',
      name: 'Hizmetler',
      productTemplateKey: 'service',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductEditorSheet(
            categories: [category],
            storeSlug: 'ornek-vitrin',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hizmet türü · önerilen'), findsOneWidget);
    expect(find.text('Fiyat biçimi · önerilen'), findsOneWidget);
    expect(find.text('Hizmet yeri · önerilen'), findsOneWidget);
    expect(find.text('Stok adedi'), findsNothing);
    expect(find.text('Stok durumu'), findsNothing);
  });
}
