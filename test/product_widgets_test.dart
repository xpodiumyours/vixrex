import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/widgets/product/product_editor_sheet.dart';
import 'package:vitrinx/widgets/product/product_management_entry_card.dart';
import 'package:vitrinx/widgets/product/product_management_sheet.dart';

void main() {
  final category = ProductCategory(id: 'cat-1', name: 'Giyim');
  final product = Product(
    id: 'product-1',
    name: 'Keten Gömlek',
    price: '750 TL',
    description: 'Yazlık keten gömlek',
    categoryId: category.id,
    category: category.name,
  );

  testWidgets('ürün yönetimi giriş kartı sayı ve aksiyonu korur', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductManagementEntryCard(
            productCount: 3,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Mevcut Ürün: 3'), findsOneWidget);
    await tester.tap(find.text('Ürünleri Yönet'));
    expect(tapped, isTrue);
  });

  testWidgets('ürün yönetimi ürünleri gösterir ve aramayı korur', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductManagementSheet(
            products: [product],
            categories: [category],
            storeSlug: 'ornek-vitrin',
            showMessage: (_) {},
            onCatalogChanged: (_, __) async {},
          ),
        ),
      ),
    );

    expect(find.text('Keten Gömlek'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'bulunmayan');
    await tester.pump();
    expect(find.text('Aramana uygun ürün bulunamadı.'), findsOneWidget);
  });

  testWidgets('ürün düzenleyici mevcut ürün değerlerini korur', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductEditorSheet(
            product: product,
            categories: [category],
            storeSlug: 'ornek-vitrin',
          ),
        ),
      ),
    );

    final fields =
        tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields[0].controller?.text, 'Keten Gömlek');
    expect(fields[1].controller?.text, '750 TL');
    expect(fields[2].controller?.text, 'Yazlık keten gömlek');
    expect(find.text('Ürünü Düzenle'), findsOneWidget);
  });
}
