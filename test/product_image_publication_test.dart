import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/services/product_image_policy.dart';

void main() {
  test('yeni ürün üç fotoğraf politikasıyla başlar', () {
    expect(Product(id: 'new').imagePublishMinimum, 3);
  });
  test('eski kayıt minimum fotoğraf şartı kazanmaz', () {
    final product = Product.fromJson({
      'id': 'old',
      'imageUrls': ['https://cdn.example/1.jpg'],
    });
    expect(product.imagePublishMinimum, 0);
    expect(Product.fromJson(product.toJson()).imagePublishMinimum, 0);
    expect(product.copyWith(name: 'Düzenlendi').imagePublishMinimum, 0);
  });
  test('yeni politika ve taslak durumu kayıtta korunur', () {
    final product = Product(id: 'new', isVisible: false);
    final restored = Product.fromJson(product.toJson());
    expect(restored.imagePublishMinimum, 3);
    expect(restored.isVisible, false);
  });
  test('görselsiz taslak geçerli, yayın için üç farklı fotoğraf gerekir', () {
    expect(ProductImagePolicy.validate([]), isNull);
    expect(ProductImagePolicy.validateForPublish([]), isNotNull);
    expect(
      ProductImagePolicy.validateForPublish(
        List.filled(3, 'https://cdn.example/1.jpg'),
      ),
      isNotNull,
    );
    expect(ProductImagePolicy.validate(['https://']), isNotNull);
  });
}
