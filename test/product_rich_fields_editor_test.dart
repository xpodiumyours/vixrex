import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/product_rich_data.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/widgets/product/product_editor_sheet.dart';
import 'package:vixrex/widgets/product/product_variant_editor.dart';

void main() {
  test('varyant görsellerini ürün galerisiyle sınırlar', () async {
    final variants = await sanitizeProductVariantsForTemplate(
      'fashion',
      const [
        ProductVariantData(
          id: 'black-m',
          options: {'color': 'Siyah', 'size': 'M'},
          imageUrls: [
            'https://cdn.example.com/product-1.webp',
            'https://other.example.com/not-in-gallery.webp',
          ],
        ),
      ],
      availableImageUrls: {'https://cdn.example.com/product-1.webp'},
    );

    expect(variants, hasLength(1));
    expect(
      variants.single.imageUrls,
      ['https://cdn.example.com/product-1.webp'],
    );
  });

  testWidgets('giyim kategorisi ortak şemadaki ürün, KDV ve varyant alanlarını gösterir', (
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
    expect(find.text('KDV oranı (%) · önerilen'), findsOneWidget);
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

  final physicalCases = <({String key, String name, List<String> labels})>[
    (
      key: 'electronics',
      name: 'Elektronik',
      labels: ['Model · önerilen', 'RAM', 'Depolama kapasitesi'],
    ),
    (
      key: 'beauty',
      name: 'Kozmetik',
      labels: ['Renk / ton', 'Net miktar · önerilen', 'İçerik'],
    ),
    (
      key: 'food',
      name: 'Gıda',
      labels: ['Net miktar · önerilen', 'İçindekiler', 'Alerjen bilgisi'],
    ),
    (
      key: 'home',
      name: 'Ev',
      labels: ['Materyal · önerilen', 'Genişlik', 'Yükseklik', 'Derinlik'],
    ),
    (
      key: 'automotive',
      name: 'Otomotiv',
      labels: ['Parça / model kodu · önerilen', 'Uyumlu marka · önerilen', 'Uyumlu model · önerilen'],
    ),
  ];

  for (final testCase in physicalCases) {
    testWidgets('${testCase.name} kategorisi kendi ürün alanlarını açar', (tester) async {
      final category = ProductCategory(
        id: '${testCase.key}-1',
        name: testCase.name,
        productTemplateKey: testCase.key,
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

      expect(find.text('KDV oranı (%) · önerilen'), findsOneWidget);
      expect(find.text('Stok adedi'), findsOneWidget);
      for (final label in testCase.labels) {
        expect(find.text(label), findsOneWidget, reason: '${testCase.key}: $label');
      }
    });
  }

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
    expect(find.text('KDV oranı (%) · önerilen'), findsNothing);
    expect(find.text('Stok adedi'), findsNothing);
    expect(find.text('Stok durumu'), findsNothing);
    expect(find.text('Varyantlar'), findsNothing);
    expect(find.text('Varyant ekle'), findsNothing);
  });
}