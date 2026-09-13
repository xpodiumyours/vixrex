import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/widgets/product/product_editor_sheet.dart';

void main() {
  testWidgets('giyim kategorisi ortak şemadaki ürün ve varyant alanlarını gösterir', (
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
    expect(find.text('Varyantlar'), findsOneWidget);
    expect(find.text('Varyant ekle'), findsOneWidget);

    await tester.ensureVisible(find.text('Varyant ekle'));
    await tester.tap(find.text('Varyant ekle'));
    await tester.pumpAndSettle();

    expect(find.text('Varyant 1'), findsOneWidget);
    expect(find.text('Varyant SKU'), findsOneWidget);
    expect(find.text('Varyant barkodu'), findsOneWidget);
    expect(find.text('Varyant fiyatı'), findsOneWidget);
  });

  testWidgets('hizmet kategorisi stok ve varyant yerine hizmet alanlarını gösterir', (
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
    expect(find.text('Varyantlar'), findsNothing);
    expect(find.text('Varyant ekle'), findsNothing);
  });
}
