import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/xml_product_upload_service.dart';

void main() {
  group('XmlProductUploadService.parse', () {
    const service = XmlProductUploadService();

    test('örnek tedarikçi XML dosyasındaki 5 ürünü zengin alanlarıyla okur', () {
      final xml = File('test/test_feed.xml').readAsStringSync();

      final result = service.parse(xml);

      expect(result.isSuccess, isTrue);
      expect(result.validCount, 5);
      expect(result.errorCount, 0);
      expect(result.products.first.brand, 'ModaMarka');
      expect(result.products.first.sku, 'TM-1001');
      expect(result.products.first.category, 'Giyim');
      expect(result.products.first.stockQuantity, 150);
      expect(result.products.last.sku, 'TM-1005');
      expect(result.products.last.stockQuantity, 25);
    });

    test('numaralı görselleri tanır, protokolü düzeltir ve 10 görselde sınırlar', () {
      const xml = '''
        <products>
          <product>
            <name>Galeri Ürünü</name>
            <image1>//cdn.example.com/1.jpg</image1>
            <image2>https://cdn.example.com/2.jpg</image2>
            <image3>https://cdn.example.com/3.jpg</image3>
            <image4>https://cdn.example.com/4.jpg</image4>
            <image5>https://cdn.example.com/5.jpg</image5>
            <image6>https://cdn.example.com/6.jpg</image6>
            <image7>https://cdn.example.com/7.jpg</image7>
            <image8>https://cdn.example.com/8.jpg</image8>
            <image9>https://cdn.example.com/9.jpg</image9>
            <image10>https://cdn.example.com/10.jpg</image10>
            <image11>https://cdn.example.com/11.jpg</image11>
          </product>
        </products>
      ''';

      final result = service.parse(xml);
      final product = result.products.single;

      expect(product.imageUrls, hasLength(10));
      expect(product.imageUrls.first, 'https://cdn.example.com/1.jpg');
      expect(product.imageUrls.last, 'https://cdn.example.com/10.jpg');
      expect(product.imageUrls, isNot(contains('https://cdn.example.com/11.jpg')));
    });

    test('metin stok ifadesinden adet uydurmaz', () {
      const xml = '''
        <products>
          <product>
            <name>Sınırlı Ürün</name>
            <stock>Son birkaç adet</stock>
          </product>
        </products>
      ''';

      final result = service.parse(xml);
      final product = result.products.single;

      expect(product.stockStatus, 'Son birkaç adet');
      expect(product.stockQuantity, isNull);
    });

    test('adı olmayan ürünü hata olarak bildirir', () {
      const xml = '''
        <products>
          <product>
            <price>99.90</price>
            <sku>TEST-1</sku>
          </product>
        </products>
      ''';

      final result = service.parse(xml);

      expect(result.isSuccess, isTrue);
      expect(result.validCount, 0);
      expect(result.errorCount, 1);
      expect(result.errors.single.row, 1);
    });
  });
}
