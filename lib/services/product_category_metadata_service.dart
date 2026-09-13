import 'package:vixrex/models/product_rich_data.dart';
import 'package:vixrex/models/store_product.dart';

/// Kategori adı üzerinden tahmin yapmaz. Yalnız kategoride açıkça kayıtlı
/// productTemplateKey değerini ürün metadata sözleşmesine taşır.
///
/// Fiziksel ürün ile hizmet semantiği birbirine karışmaz. Fiziksel şablonlar
/// arasında görünmeyen ayrıntılar korunur; aktif şablon hangi alanların
/// gösterileceğini ortak şemadan belirler.
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
