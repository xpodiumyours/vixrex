import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/product_image_policy.dart';
import 'package:vixrex/utils/product_price_parser.dart';

void main() {
  group('ProductImagePolicy live-ready quality gates', () {
    test('requires at least 1200px on the source short edge', () {
      expect(ProductImagePolicy.minSourceShortEdge, 1200);
      expect(ProductImagePolicy.validateDimensions(width: 1200, height: 1600), isNull);
      expect(ProductImagePolicy.validateDimensions(width: 1600, height: 1200), isNull);
      expect(
        ProductImagePolicy.validateDimensions(width: 1199, height: 1600),
        isNotNull,
      );
      expect(
        ProductImagePolicy.validateDimensions(width: 1600, height: 1199),
        isNotNull,
      );
      expect(
        ProductImagePolicy.validateDimensions(width: 0, height: 1600),
        isNotNull,
      );
    });

    test('keeps the product image count policy at 3 to 10', () {
      expect(ProductImagePolicy.minImages, 3);
      expect(ProductImagePolicy.maxImages, 10);
      expect(
        ProductImagePolicy.validateImageUrls(<String>[
          'https://example.com/1.jpg',
          'https://example.com/2.jpg',
          'https://example.com/3.jpg',
        ]),
        isNull,
      );
      expect(
        ProductImagePolicy.validateImageUrls(<String>[
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
