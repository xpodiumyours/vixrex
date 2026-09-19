import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/product_rich_data.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/services/bulk_product_field_update_service.dart';
import 'package:vixrex/services/product_category_metadata_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('hizmet kategorisine geçiş fiziksel ürün verisini korur', () {
    final current = ProductRichMetadata(
      templateKey: 'fashion',
      itemKind: 'physical',
      sku: 'SKU-1',
      mpn: 'MPN-1',
      attributes: const [
        ProductAttributeValue(key: 'color', label: 'Renk', value: 'Siyah'),
      ],
    );
    final serviceCategory = ProductCategory(
      id: 'category-service',
      name: 'Kurulum',
      productTemplateKey: 'service',
    );

    final aligned = alignProductMetadataToCategory(current, serviceCategory);

    expect(aligned.templateKey, 'service');
    expect(aligned.itemKind, 'service');
    expect(aligned.sku, isNotNull);
    expect(aligned.mpn, isNotNull);
    expect(aligned.attributes, isNotEmpty);
  });

  test('toplu kategori değişimi hizmete geçerken fiziksel metadata korur', () {
    final product = Product(
      id: 'p1',
      name: 'Telefon',
      categoryId: 'old',
      category: 'Eski',
      richMetadata: const ProductRichMetadata(
        templateKey: 'electronics',
        itemKind: 'physical',
        sku: 'T-1',
      ),
    );
    final target = ProductCategory(
      id: 'new',
      name: 'Hizmetler',
      productTemplateKey: 'service',
    );

    final updated = const BulkProductFieldUpdateService().applyCategory([
      product,
    ], target);

    expect(updated.single.categoryId, 'new');
    expect(updated.single.category, 'Hizmetler');
    expect(updated.single.richMetadata.templateKey, 'service');
    expect(updated.single.richMetadata.itemKind, 'service');
    expect(updated.single.richMetadata.sku, isNotNull);
  });

  test(
    'fiziksel ürün şablonları arasında form verisini geçici olarak korur',
    () {
      const current = ProductRichMetadata(
        templateKey: 'fashion',
        itemKind: 'physical',
        sku: 'SKU-2',
        mpn: 'MPN-2',
        attributes: [
          ProductAttributeValue(key: 'color', label: 'Renk', value: 'Siyah'),
          ProductAttributeValue(key: 'size', label: 'Beden', value: 'M'),
        ],
      );
      final target = ProductCategory(
        id: 'electronics',
        name: 'Elektronik',
        productTemplateKey: 'electronics',
      );

      final aligned = alignProductMetadataToCategory(current, target);

      expect(aligned.itemKind, 'physical');
      expect(aligned.templateKey, 'electronics');
      expect(aligned.sku, 'SKU-2');
      expect(aligned.mpn, 'MPN-2');
      expect(
        aligned.attributes.map((item) => item.key),
        containsAll(['color', 'size']),
      );
      expect(aligned.service, isNull);
    },
  );

  test('DB yazma kapısı esnafın girdiği alanları silmeden geçirir', () async {
    const current = ProductRichMetadata(
      schemaVersion: 1,
      templateKey: 'electronics',
      itemKind: 'physical',
      sku: 'SKU-3',
      mpn: 'MPN-3',
      attributes: [
        ProductAttributeValue(key: 'color', label: 'Renk', value: 'Siyah'),
        ProductAttributeValue(key: 'size', label: 'Beden', value: 'M'),
        ProductAttributeValue(key: 'ram', label: 'RAM', value: '16 GB'),
        ProductAttributeValue(
          key: 'vatRate',
          label: 'KDV oranı (%)',
          value: '20',
        ),
      ],
    );

    final sanitized = await sanitizeProductMetadataForWrite(current);
    final keys = sanitized.attributes.map((item) => item.key).toSet();

    expect(sanitized.schemaVersion, 4);
    expect(sanitized.templateKey, 'electronics');
    expect(sanitized.itemKind, 'physical');
    expect(sanitized.sku, 'SKU-3');
    expect(sanitized.mpn, 'MPN-3');
    expect(keys, containsAll(['color', 'ram', 'vatRate']));
    expect(keys, contains('size'));
  });

  test('DB yazma kapısı bilinmeyen kategori şablonunu reddeder', () async {
    const current = ProductRichMetadata(
      templateKey: 'unknown-template',
      itemKind: 'physical',
    );

    await expectLater(
      sanitizeProductMetadataForWrite(current),
      throwsA(isA<FormatException>()),
    );
  });
}
