import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/xml_product_upload_service.dart';

void main() {
  group('XmlProductUploadService.parse', () {
    const service = XmlProductUploadService();

    test('örnek tedarikçi XML dosyasındaki 5 ürünü okur', () {
      final xml = File('test/test_feed.xml').readAsStringSync();

      final result = service.parse(xml);

      expect(result.isSuccess, isTrue);
      expect(result.validCount, 5);
      expect(result.errorCount, 0);
      expect(result.products.first.brand, 'ModaMarka');
      expect(result.products.first.sku, 'TM-1001');
      expect(result.products.last.sku, 'TM-1005');
    });

    test('external id, barkod, SKU ve stok alanlarını birbirinden ayırır', () {
      const xml = '''
        <products>
          <product>
            <id>SUP-42</id>
            <name>Kimlikli Ürün</name>
            <price>149,90 TL</price>
            <barcode>8690000000042</barcode>
            <sku>SKU-42</sku>
            <stock_quantity>7</stock_quantity>
          </product>
        </products>
      ''';

      final result = service.parse(xml);

      expect(result.isSuccess, isTrue);
      expect(result.validCount, 1);
      final product = result.products.single;
      expect(product.sourceMediaId, 'SUP-42');
      expect(product.barcode, '8690000000042');
      expect(product.sku, 'SKU-42');
      expect(product.stockQuantity, 7);
      expect(product.price, '149.90');
    });

    test('0-2 görselli taslak XML ürünü kabul eder', () {
      const xml = '''
        <products>
          <product>
            <id>IMG-2</id>
            <name>İki Görselli Ürün</name>
            <image1>https://cdn.example.com/a.jpg</image1>
            <image2>https://cdn.example.com/b.jpg</image2>
          </product>
        </products>
      ''';

      final result = service.parse(xml);

      expect(result.validCount, 1);
      expect(result.products.single.imageUrls, hasLength(2));
    });

    test('12 görselli XML satırını reddeder, 11 üst sınırını korur', () {
      final images = List.generate(
        12,
        (index) => '<image${index + 1}>https://cdn.example.com/${index + 1}.jpg</image${index + 1}>',
      ).join();
      final xml = '<products><product><id>IMG-12</id><name>Çok Görselli</name>$images</product></products>';

      final result = service.parse(xml);

      expect(result.isSuccess, isTrue);
      expect(result.validCount, 0);
      expect(result.errorCount, 1);
      expect(result.errors.single.message, contains('en fazla 11'));
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
