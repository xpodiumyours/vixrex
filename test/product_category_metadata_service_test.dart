import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/product_rich_data.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/services/bulk_product_field_update_service.dart';
import 'package:vixrex/services/product_category_metadata_service.dart';

void main() {
  test('kategori tipi metadata templateKey ve itemKind değerini hizalar', () {
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
    expect(aligned.sku, 'SKU-1');
    expect(aligned.mpn, 'MPN-1');
    expect(aligned.attributes.single.key, 'color');
  });

  test('toplu kategori değişimi ürün metadata tipini de değiştirir', () {
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

    final updated = const BulkProductFieldUpdateService().applyCategory(
      [product],
      target,
    );

    expect(updated.single.categoryId, 'new');
    expect(updated.single.category, 'Hizmetler');
    expect(updated.single.richMetadata.templateKey, 'service');
    expect(updated.single.richMetadata.itemKind, 'service');
    expect(updated.single.richMetadata.sku, 'T-1');
  });
}
