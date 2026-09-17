// ÜRETİLMİŞ DOSYA — ELLE DÜZENLEME.
//
// Kaynak : shared/product_image_policy.json
// Üreten : tool/fotograf_kurali_uret.dart
//
// Ürün fotoğrafı sayıları ve kaynak kalite sınırları (tek kaynak).

class ProductImagePolicyValues {
  const ProductImagePolicyValues._();

  static const int minImages = 3;
  static const int maxImages = 10;
  static const int maxSourceMegabytes = 5;
  static const int maxSourceBytes = maxSourceMegabytes * 1024 * 1024;
  static const int minSourceShortEdge = 1200;
}
