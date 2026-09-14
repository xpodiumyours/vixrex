import 'package:vixrex/models/product_rich_data.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/services/product_attribute_schema_service.dart';

/// Kategori adı üzerinden tahmin yapmaz. Yalnız kategoride açıkça kayıtlı
/// productTemplateKey değerini ürün metadata sözleşmesine taşır.
///
/// Editör fiziksel kategoriler arasında geçerken formdaki değerleri geçici
/// olarak koruyabilir. Supabase'e yazmadan hemen önce
/// [sanitizeProductMetadataForWrite] yalnız aktif şablonun alanlarını geçirir.
ProductRichMetadata alignProductMetadataToCategory(
  ProductRichMetadata current,
  ProductCategory category,
) {
  final templateKey =
      category.productTemplateKey.trim().isEmpty
          ? 'generic'
          : category.productTemplateKey.trim();
  final isService = templateKey == 'service';

  return ProductRichMetadata(
    schemaVersion: current.schemaVersion,
    itemKind: isService ? 'service' : 'physical',
    templateKey: templateKey,
    sku: isService ? null : current.sku,
    mpn: isService ? null : current.mpn,
    attributes: isService ? const [] : current.attributes,
    service: isService ? current.service : null,
  );
}

/// Flutter'dan Product CORE'a giden metadata'yı ortak ürün şemasına göre
/// sınırlar. Böylece farklı fiziksel kategoriden kalan görünmeyen alanlar DB'ye
/// sızmaz; Next.js API ile aynı kategori sözleşmesi uygulanır.
Future<ProductRichMetadata> sanitizeProductMetadataForWrite(
  ProductRichMetadata current,
) async {
  final schema = await const ProductAttributeSchemaService().load();
  final template = schema.templateByKeyOrNull(current.templateKey);
  if (template == null) {
    throw const FormatException('Ürün kategori şablonu doğrulanamadı.');
  }

  if (template.isService) {
    return ProductRichMetadata(
      schemaVersion: schema.version,
      itemKind: 'service',
      templateKey: template.key,
      service: current.service,
    );
  }

  final allowedAttributeKeys =
      schema
          .attributesForTemplate(template.key)
          .where((definition) => definition.storage == 'metadata.attributes')
          .map((definition) => definition.key)
          .toSet();

  return ProductRichMetadata(
    schemaVersion: schema.version,
    itemKind: 'physical',
    templateKey: template.key,
    sku: current.sku,
    mpn: current.mpn,
    attributes:
        current.attributes
            .where((item) => allowedAttributeKeys.contains(item.key))
            .toList(),
  );
}
