class ProductImagePolicy {
  const ProductImagePolicy._();

  static const int minImages = 3;
  static const int maxImages = 11;
  static const int maxSourceMegabytes = 5;
  static const int maxSourceBytes = maxSourceMegabytes * 1024 * 1024;
  static const int minSourceShortEdge = 1200;

  static List<String> normalize(List<String> imageUrls) {
    return imageUrls
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
  }

  static String? validateDimensions(int width, int height) {
    if (width <= 0 || height <= 0) {
      return 'Ürün fotoğrafının ölçüleri okunamadı.';
    }
    if ((width < height ? width : height) < minSourceShortEdge) {
      return 'Kısa kenar en az $minSourceShortEdge px olmalıdır.';
    }
    return null;
  }

  static String? validateForPublish(List<String> imageUrls) {
    final normalized = normalize(imageUrls);
    if (normalized.length < minImages) {
      return 'Bir ürün için en az $minImages fotoğraf zorunludur.';
    }
    return validate(imageUrls);
  }

  static String? validate(List<String> imageUrls) {
    final normalized = normalize(imageUrls);
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
