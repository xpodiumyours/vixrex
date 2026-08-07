import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/widgets/product/product_editor_sheet.dart';
import 'package:vixrex/widgets/product/product_management_entry_card.dart';
import 'package:vixrex/widgets/product/product_management_sheet.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final mockClient = MockClient((request) async {
      return http.Response(
        '[]',
        200,
        request: request,
        headers: {'content-type': 'application/json'},
      );
    });

    try {
      await Supabase.instance.dispose();
    } catch (_) {}

    await Supabase.initialize(
      url: 'https://dummyproject.supabase.co',
      anonKey: 'dummyAnonKey',
      httpClient: mockClient,
    );
  });

  tearDown(() async {
    try {
      await Supabase.instance.dispose();
    } catch (_) {}
  });
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
    tester.view.physicalSize = const Size(1000, 900);
    addTearDown(tester.view.resetPhysicalSize);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductManagementSheet(
            products: [product],
            categories: [category],
            storeSlug: 'ornek-vitrin',
            storeId: 'test-store',
            editToken: 'test-edit-token',
            showMessage: (_) {},
            onCatalogChanged: (_, __) async {},
            onProductDelete: (_) async => true,
            onOcrTap: () {},
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

    // Alanlar indeksle değil ETİKETLE aranır. Düzenleyiciye yeni alan
    // eklendiğinde (eski fiyat, rozet, teslim bölgesi) indeks kayıyor ve
    // test yanlış alana bakıyordu.
    String textOfFieldLabeled(String label) {
      final field = tester.widget<TextField>(
        find.ancestor(of: find.text(label), matching: find.byType(TextField)),
      );
      return field.controller?.text ?? '';
    }

    expect(textOfFieldLabeled('Ürün adı *'), 'Keten Gömlek');
    expect(textOfFieldLabeled('Fiyat'), '750 TL');
    expect(textOfFieldLabeled('Kısa açıklama'), 'Yazlık keten gömlek');
    expect(find.text('Ürünü Düzenle'), findsOneWidget);
  });
}
