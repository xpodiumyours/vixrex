import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/product_rich_data.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/services/bulk_product_field_update_service.dart';
import 'package:vixrex/services/product_category_metadata_service.dart';

void main() {
  test('hizmet kategorisi fiziksel ürün metadata kalıntılarını temizler', () {
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
    expect(aligned.sku, isNull);
    expect(aligned.mpn, isNull);
    expect(aligned.attributes, isEmpty);
  });

  test('toplu kategori değişimi hizmete geçerken fiziksel metadata bırakmaz', () {
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
    expect(updated.single.richMetadata.sku, isNull);
  });

  test('fiziksel ürün şablonları arasında ortak fiziksel metadata korunur', () {
    const current = ProductRichMetadata(
      templateKey: 'fashion',
      itemKind: 'physical',
      sku: 'SKU-2',
      mpn: 'MPN-2',
      attributes: [
        ProductAttributeValue(key: 'color', label: 'Renk', value: 'Siyah'),
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
    expect(aligned.service, isNull);
  });
}
