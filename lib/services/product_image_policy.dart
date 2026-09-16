import 'package:vixrex/config/product_image_policy.g.dart';

class ProductImagePolicy {
  const ProductImagePolicy._();

  static const int minImages = ProductImagePolicyValues.minImages;
  static const int maxImages = ProductImagePolicyValues.maxImages;
  static const int maxSourceMegabytes =
      ProductImagePolicyValues.maxSourceMegabytes;
  static const int maxSourceBytes = ProductImagePolicyValues.maxSourceBytes;
  static const int minSourceShortEdge =
      ProductImagePolicyValues.minSourceShortEdge;

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
