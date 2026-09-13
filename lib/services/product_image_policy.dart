class ProductImagePolicy {
  const ProductImagePolicy._();

  static const int minImages = 3;
  static const int maxImages = 4;

  static List<String> normalize(List<String> imageUrls) {
    return imageUrls
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
  }

  static String? validate(List<String> imageUrls) {
    final normalized = normalize(imageUrls);
    if (normalized.length < minImages) {
      return 'Bir ürün için en az $minImages fotoğraf zorunludur.';
    }
    if (normalized.length > maxImages) {
      return 'Bir ürüne en fazla $maxImages fotoğraf eklenebilir.';
    }
    final invalid = normalized.any(
      (url) => !(url.startsWith('http://') || url.startsWith('https://')),
    );
    if (invalid) {
      return 'Ürün fotoğrafı bağlantıları http:// veya https:// ile başlamalıdır.';
    }
    return null;
  }
}
