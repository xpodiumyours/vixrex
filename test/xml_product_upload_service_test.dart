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
