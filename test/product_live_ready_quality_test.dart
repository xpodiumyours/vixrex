import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/product_image_policy.dart';
import 'package:vixrex/utils/product_price_parser.dart';

void main() {
  group('ProductImagePolicy live-ready quality gates', () {
    test('requires at least 1200px on the source short edge', () {
      expect(ProductImagePolicy.minSourceShortEdge, 1200);
      expect(ProductImagePolicy.validateDimensions(1200, 1600), isNull);
      expect(ProductImagePolicy.validateDimensions(1600, 1200), isNull);
      expect(
        ProductImagePolicy.validateDimensions(1199, 1600),
        'Kısa kenar en az 1200 px olmalıdır.',
      );
      expect(
        ProductImagePolicy.validateDimensions(1600, 1199),
        'Kısa kenar en az 1200 px olmalıdır.',
      );
      expect(ProductImagePolicy.validateDimensions(0, 1600), isNotNull);
    });

    test('keeps the product image count policy at 3 to 10', () {
      expect(ProductImagePolicy.minImages, 3);
      expect(ProductImagePolicy.maxImages, 10);
      expect(
        ProductImagePolicy.validate(<String>[
          'https://example.com/1.jpg',
          'https://example.com/2.jpg',
          'https://example.com/3.jpg',
        ]),
        isNull,
      );
      expect(
        ProductImagePolicy.validate(<String>[
          'https://example.com/1.jpg',
          'https://example.com/2.jpg',
        ]),
        isNotNull,
      );
    });
  });

  group('product price parser', () {
    test('parses Turkish thousands and decimal notation consistently', () {
      expect(parseProductPriceAmount('1.299 TL'), 1299);
      expect(parseProductPriceAmount('1.299,90 TL'), 1299.9);
      expect(parseProductPriceAmount('1299,90 TL'), 1299.9);
      expect(parseProductPriceAmount('1299.90'), 1299.9);
      expect(parseProductPriceAmount('12.345'), 12345);
    });

    test('returns null for empty or invalid prices', () {
      expect(parseProductPriceAmount(''), isNull);
      expect(parseProductPriceAmount('fiyat yok'), isNull);
    });
  });
}
