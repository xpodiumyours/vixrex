import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/bulk_product_upload_service.dart';
import 'package:vixrex/services/xml_product_upload_service.dart';
import 'package:vixrex/controllers/bulk_product_upload_controller.dart';

void main() {
  const service = BulkProductUploadService();
  Uint8List csv(String value) => Uint8List.fromList(utf8.encode(value));

  test('CSV ve XML geçersiz görseli satır hatası olarak bildirir', () {
    final csvResult = service.parse(
      csv('Ürün Adı,Görsel URL\nÜrün,ftp://cdn.example/1.jpg'),
      fileName: 'urun.csv',
    );
    expect(csvResult.products, isEmpty);
    expect(csvResult.errors.single.row, 2);
    final xmlResult = const XmlProductUploadService().parse(
      '<products><product><name>Ürün</name><image>ftp://cdn.example/1.jpg</image></product></products>',
    );
    expect(xmlResult.products, isEmpty);
    expect(xmlResult.errors.single.row, 1);
  });

  test('XML ayrıştırma ve kayıt hatalarını kaynak sırasıyla birleştirir', () {
    final parsed = const XmlProductUploadService().parse(
      '<products><product><price>2</price></product><product><name>Bir</name></product><product><name>İki</name></product></products>',
    );
    final result = parsed.mergeSaveResult(
      XmlUploadResult.success(
        total: 2,
        inserted: 1,
        errors: 1,
        errorDetails: [
          const XmlParseError(row: 2, message: 'PRODUCT_CREATE_FAILED'),
        ],
      ),
    );
    expect(result.total, 3);
    expect(result.inserted, 1);
    expect(result.errors, 2);
    expect(result.errorDetails.map((error) => error.row), [1, 3]);
  });

  test('XML alan sırası fiyat ve SKU önceliğini bozmaz', () {
    final result = const XmlProductUploadService().parse(
      '<products><product><name>Ürün</name><listprice>9999</listprice><price>1.299 TL</price><barkod>00123</barkod><sku>S-1</sku></product></products>',
    );
    expect(result.products.single.price, '1299');
    expect(result.products.single.sku, 'S-1');
    expect(result.products.single.barcode, '00123');
  });

  test('CSV binlik fiyat ve boş stok adedi hücresini korur', () {
    final result = service.parse(
      csv('Ürün Adı,Fiyat,Stok,Stok Adedi\nÜrün,1.299 TL,10,'),
      fileName: 'urun.csv',
    );
    expect(result.products.single.price, '1299');
    expect(result.products.single.stockQuantity, 10);
  });

  test('CSV zengin alanları ve görselsiz taslağı korur', () {
    final result = service.parse(
      csv(
        'Ürün Adı,Fiyat,Stok,Marka,Barkod,SKU\nÜrün,125,10,Marka,00123,S-1\n,125,0,,,',
      ),
      fileName: 'urun.csv',
    );
    expect(result.isSuccess, isTrue);
    expect(result.products, hasLength(1));
    expect(result.errors.single.row, 3);
    final product = result.products.single;
    expect(product.imageUrls, isEmpty);
    expect(product.brand, 'Marka');
    expect(product.barcode, '00123');
    expect(product.sku, 'S-1');
    expect(product.stockQuantity, 10);
    expect(product.stockStatus, 'Mevcut');
  });

  test('XML barkod, stok adedi ve iki görseli korur', () {
    final result = const XmlProductUploadService().parse(
      '<products><product><name>Ürün</name><brand>Marka</brand><barcode>00123</barcode><sku>S-1</sku><stockquantity>10</stockquantity><image1>https://cdn.example/1.jpg</image1><image2>https://cdn.example/2.jpg</image2></product></products>',
    );
    expect(result.products.single.barcode, '00123');
    expect(result.products.single.stockQuantity, 10);
    expect(result.products.single.imageUrls, hasLength(2));
  });

  test('başarısız kayıt listeyi korur ve başarı göstermez', () async {
    final controller = BulkProductUploadController();
    addTearDown(controller.dispose);
    await controller.parseFile(
      csv('Ürün Adı,Fiyat\nÜrün,125'),
      fileName: 'urun.csv',
    );
    expect(await controller.saveProducts(onSave: (_) async => false), isFalse);
    expect(controller.state, BulkUploadState.review);
    expect(controller.products, hasLength(1));
    expect(controller.savedCount, 0);
    expect(await controller.saveProducts(onSave: (_) async => true), isTrue);
    expect(controller.state, BulkUploadState.saved);
    expect(controller.savedCount, 1);
  });
}
