import 'package:vixrex/models/product_rich_data.dart';
import 'package:vixrex/models/store_product.dart';

/// Kategori adı üzerinden tahmin yapmaz. Yalnız kategoride açıkça kayıtlı
/// productTemplateKey değerini ürün metadata sözleşmesine taşır.
///
/// Var olan ürün detayları burada silinmez. Flutter zengin alan editörü tüm
/// şablon alanlarını düzenleyene kadar kategori değişimi veri kaybına yol
/// açmamalıdır; public/owner sunum katmanları yalnız aktif şablonun alanlarını
/// gösterir.
ProductRichMetadata alignProductMetadataToCategory(
  ProductRichMetadata current,
  ProductCategory category,
) {
  final templateKey =
      category.productTemplateKey.trim().isEmpty
          ? 'generic'
          : category.productTemplateKey.trim();
  return ProductRichMetadata(
    schemaVersion: current.schemaVersion,
    itemKind: templateKey == 'service' ? 'service' : 'physical',
    templateKey: templateKey,
    sku: current.sku,
    mpn: current.mpn,
    attributes: current.attributes,
    service: current.service,
  );
}
