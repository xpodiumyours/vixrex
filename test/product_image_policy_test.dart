import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/product_image_policy.dart';

void main() {
  const images = [
    'https://example.com/1.jpg',
    'https://example.com/2.jpg',
    'https://example.com/3.jpg',
    'https://example.com/4.jpg',
  ];

  test('ürün görsel politikası 3-4 fotoğraf kabul eder', () {
    expect(ProductImagePolicy.minImages, 3);
    expect(ProductImagePolicy.maxImages, 4);
    expect(ProductImagePolicy.validate(images.take(3).toList()), isNull);
    expect(ProductImagePolicy.validate(images), isNull);
  });

  test('ürün görsel politikası 0-2 fotoğrafı reddeder', () {
    expect(ProductImagePolicy.validate(const []), isNotNull);
    expect(ProductImagePolicy.validate(images.take(1).toList()), isNotNull);
    expect(ProductImagePolicy.validate(images.take(2).toList()), isNotNull);
  });

  test('ürün görsel politikası 4 üzerini reddeder', () {
    expect(
      ProductImagePolicy.validate([
        ...images,
        'https://example.com/5.jpg',
      ]),
      isNotNull,
    );
  });

  test('tekrarlı URL tek fotoğraf sayılır', () {
    expect(
      ProductImagePolicy.validate([
        images[0],
        images[0],
        images[1],
        images[2],
      ]),
      isNull,
    );
    expect(
      ProductImagePolicy.normalize([
        images[0],
        images[0],
        images[1],
        images[2],
      ]),
      hasLength(3),
    );
  });
}
