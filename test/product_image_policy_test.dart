import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/product_image_policy.dart';

void main() {
  final images = List<String>.generate(
    12,
    (index) => 'https://example.com/${index + 1}.jpg',
  );

  test('ürün görsel politikası 3-11 fotoğraf kabul eder', () {
    expect(ProductImagePolicy.minImages, 3);
    expect(ProductImagePolicy.maxImages, 11);
    expect(ProductImagePolicy.validate(images.take(3).toList()), isNull);
    expect(ProductImagePolicy.validate(images.take(11).toList()), isNull);
  });

  test('ürün görsel politikası 0-2 fotoğrafı reddeder', () {
    expect(ProductImagePolicy.validate(const []), isNotNull);
    expect(ProductImagePolicy.validate(images.take(1).toList()), isNotNull);
    expect(ProductImagePolicy.validate(images.take(2).toList()), isNotNull);
  });

  test('ürün görsel politikası 11 üzerini reddeder', () {
    expect(ProductImagePolicy.validate(images), isNotNull);
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
