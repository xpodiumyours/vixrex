import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/store_publish_validator.dart';

StoreData _validStoreWith(Product product) {
  return StoreData(
    name: 'Test Mağaza',
    whatsapp: '05551234567',
    description: 'Test açıklama',
    address: 'Test Sokak No:1',
    provinceName: 'İstanbul',
    provinceCode: '34',
    districtName: 'Kadıköy',
    districtCode: '3447',
    kategori: 'Giyim & Butik',
    isStore: true,
    products: [product],
    privacyNoticeAcknowledged: true,
    privacyNoticeVersion: 'privacy-v1',
    privacyNoticeHash: 'privacy-hash',
    termsAccepted: true,
    termsVersion: 'terms-v1',
    termsHash: 'terms-hash',
    publicationConsentAccepted: true,
    publicationConsentVersion: 'consent-v1',
    publicationConsentHash: 'consent-hash',
  );
}

Product _productWithImages(List<String> imageUrls) {
  return Product(
    id: 'test-product',
    name: 'Test Ürün',
    category: 'Genel',
    imageUrls: imageUrls,
  );
}

void main() {
  const validator = StorePublishValidator();

  test('yayın kontrolü 11 ürün görseline izin verir', () {
    final product = _productWithImages(
      List.generate(11, (index) => 'https://example.com/urun-$index.jpg'),
    );

    expect(validator.validateStore(_validStoreWith(product)), isNull);
  });

  test('yayın kontrolü 12 ürün görselini reddeder', () {
    final product = _productWithImages(
      List.generate(12, (index) => 'https://example.com/urun-$index.jpg'),
    );

    expect(
      validator.validateStore(_validStoreWith(product)),
      contains('en fazla 11'),
    );
  });

  test('yayın kontrolü geçersiz ürün görseli adresini reddeder', () {
    final product = _productWithImages(['ftp://example.com/urun.jpg']);

    expect(
      validator.validateStore(_validStoreWith(product)),
      contains('http:// veya https://'),
    );
  });
}
