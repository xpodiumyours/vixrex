import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/product_rich_data.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/product_attribute_schema_service.dart';
import 'package:vixrex/services/product_image_policy.dart';
import 'package:vixrex/widgets/product/product_editor_sheet.dart';
import 'package:vixrex/widgets/product/product_variant_editor.dart';

void main() {
  setUpAll(() async {
    final source = await rootBundle.loadString(
      'shared/product_attribute_schema.json',
    );
    ProductAttributeSchemaService
        .debugSchemaOverride = ProductAttributeSchema.fromJson(
      Map<String, dynamic>.from(jsonDecode(source) as Map),
    );
  });

  test('yeni Flutter ürün metadata varsayılanı ortak şema v2 olur', () {
    expect(const ProductRichMetadata().schemaVersion, 2);
    expect(ProductRichMetadata.fromJson({}).schemaVersion, 2);
    expect(ProductRichMetadata.fromJson({'schemaVersion': 1}).schemaVersion, 1);
  });

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
    expect(variants.single.imageUrls, [
      'https://cdn.example.com/product-1.webp',
    ]);
  });

  test('varyant galerisi ortak görsel sınırını kullanır', () async {
    final images = List.generate(
      ProductImagePolicy.maxImages + 1,
      (index) => 'https://cdn.example.com/product-$index.webp',
    );
    final variants = await sanitizeProductVariantsForTemplate('fashion', [
      ProductVariantData(
        id: 'black-m',
        options: const {'color': 'Siyah', 'size': 'M'},
        imageUrls: images,
      ),
    ], availableImageUrls: images.toSet());

    expect(variants, hasLength(1));
    expect(variants.single.imageUrls, hasLength(ProductImagePolicy.maxImages));
    expect(ProductImagePolicy.maxImages, 11);
  });

  testWidgets(
    'giyim kategorisi ortak şemadaki ürün, KDV ve varyant alanlarını gösterir',
    (tester) async {
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

      expect(find.text('Marka *'), findsOneWidget);
      expect(find.text('KDV oranı (%)'), findsOneWidget);
      expect(find.text('Renk *'), findsOneWidget);
      expect(find.text('Beden *'), findsOneWidget);
      expect(find.text('Materyal'), findsOneWidget);
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
    },
  );

  final physicalCases = <({String key, String name, List<String> labels})>[
    (
      key: 'electronics',
      name: 'Elektronik',
      labels: ['Model *', 'RAM', 'Depolama kapasitesi'],
    ),
    (
      key: 'beauty',
      name: 'Kozmetik',
      labels: ['Renk / ton', 'Net miktar *', 'İçerik'],
    ),
    (
      key: 'food',
      name: 'Gıda',
      labels: ['Net miktar *', 'İçindekiler', 'Alerjen bilgisi *'],
    ),
    (
      key: 'home',
      name: 'Ev',
      labels: ['Materyal *', 'Genişlik', 'Yükseklik', 'Derinlik'],
    ),
    (
      key: 'automotive',
      name: 'Otomotiv',
      labels: ['Parça / model kodu *', 'Uyumlu marka *', 'Uyumlu model *'],
    ),
  ];

  for (final testCase in physicalCases) {
    testWidgets('${testCase.name} kategorisi kendi ürün alanlarını açar', (
      tester,
    ) async {
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

      expect(find.text('KDV oranı (%)'), findsOneWidget);
      expect(find.text('Stok adedi'), findsOneWidget);
      for (final label in testCase.labels) {
        expect(
          find.text(label),
          findsOneWidget,
          reason: '${testCase.key}: $label',
        );
      }
    });
  }

  testWidgets('bilinmeyen kategori şablonunu generic ürüne çevirmeden durdurur', (
    tester,
  ) async {
    final category = ProductCategory(
      id: 'unknown-1',
      name: 'Tanımsız kategori',
      productTemplateKey: 'unknown-template',
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

    expect(
      find.text(
        'Ürün kategori şablonu doğrulanamadı. Kategori ayarını kontrol edin; Vixrex farklı bir kategori tahmin etmez.',
      ),
      findsOneWidget,
    );
    expect(find.text('Marka *'), findsNothing);
    expect(find.text('KDV oranı (%)'), findsNothing);
  });

  testWidgets(
    'hizmet kategorisi stok ve varyant yerine hizmet alanlarını gösterir',
    (tester) async {
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

      expect(find.text('Hizmet türü *'), findsOneWidget);
      expect(find.text('Fiyat biçimi *'), findsOneWidget);
      expect(find.text('Hizmet yeri *'), findsOneWidget);
      expect(find.text('KDV oranı (%)'), findsNothing);
      expect(find.text('Stok adedi'), findsNothing);
      expect(find.text('Stok durumu'), findsNothing);
      expect(find.text('Varyantlar'), findsNothing);
      expect(find.text('Varyant ekle'), findsNothing);
    },
  );
}
