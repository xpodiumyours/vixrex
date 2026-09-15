import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/bulk_product_upload_service.dart';

Uint8List _csvBytes(String value) => Uint8List.fromList(utf8.encode(value));

void main() {
  const service = BulkProductUploadService();

  test('Flutter bulk import zengin çekirdek alanlarını ve çoklu görseli taşır', () {
    final result = service.parse(
      _csvBytes(
        'Ürün Adı,Fiyat,Kategori,Stok Adedi,Marka,Barkod,SKU,Görsel URL 1,Görsel URL 2,Görsel URL 3\n'
        'Keten Gömlek,1299,Giyim,10,Örnek Marka,8690000000005,KG-1,https://cdn.example.com/a.jpg,https://cdn.example.com/b.jpg,https://cdn.example.com/c.jpg\n',
      ),
      fileName: 'urunler.csv',
    );

    expect(result.isSuccess, isTrue);
    expect(result.validCount, 1);
    expect(result.errorCount, 0);
    final product = result.products.single;
    expect(product.imageUrls, hasLength(3));
    expect(product.brand, 'Örnek Marka');
    expect(product.barcode, '8690000000005');
    expect(product.sku, 'KG-1');
    expect(product.richMetadata.schemaVersion, 2);
    expect(product.richMetadata.sku, 'KG-1');
    expect(product.stockQuantity, 10);
    expect(product.stockStatus, 'Mevcut');
  });

  test('minimum 3 görsel içe aktarmada zorunlu değildir', () {
    final result = service.parse(
      _csvBytes(
        'Ürün Adı,Görsel URL 1,Görsel URL 2\n'
        'İki Görselli Ürün,https://cdn.example.com/a.jpg,https://cdn.example.com/b.jpg\n',
      ),
      fileName: 'urunler.csv',
    );

    expect(result.isSuccess, isTrue);
    expect(result.validCount, 1);
    expect(result.errorCount, 0);
    expect(result.products.single.imageUrls, hasLength(2));
  });

  test('görselsiz satır parse edilir ve yayın kapısına bırakılır', () {
    final result = service.parse(
      _csvBytes('Ürün Adı,Fiyat\nGörselsiz Ürün,250\n'),
      fileName: 'urunler.csv',
    );

    expect(result.isSuccess, isTrue);
    expect(result.validCount, 1);
    expect(result.errorCount, 0);
    expect(result.products.single.imageUrls, isEmpty);
    expect(result.products.single.imagePath, isNull);
  });

  test('stok 10 ifadesini Tükendi diye yorumlamaz', () {
    final result = service.parse(
      _csvBytes('Ürün Adı,Stok\nStoklu Ürün,10\n'),
      fileName: 'urunler.csv',
    );

    expect(result.products.single.stockQuantity, 10);
    expect(result.products.single.stockStatus, 'Mevcut');
  });

  test('SKU barkod alanına yazılmaz', () {
    final result = service.parse(
      _csvBytes('Ürün Adı,SKU\nKodlu Ürün,SKU-123\n'),
      fileName: 'urunler.csv',
    );

    final product = result.products.single;
    expect(product.sku, 'SKU-123');
    expect(product.richMetadata.sku, 'SKU-123');
    expect(product.barcode, isNull);
  });

  test('geçersiz görsel bağlantısı satırı hata olarak işaretler', () {
    final result = service.parse(
      _csvBytes('Ürün Adı,Görsel URL 1\nHatalı Görsel,cdn.example.com/a.jpg\n'),
      fileName: 'urunler.csv',
    );

    expect(result.isSuccess, isTrue);
    expect(result.validCount, 0);
    expect(result.errorCount, 1);
    expect(result.errors.single.message, contains('http:// veya https://'));
  });

  test('Türkçe binlik ve ondalık fiyat yazımını ortak kuralla okur', () {
    final result = service.parse(
      _csvBytes(
        'Ürün Adı,Fiyat\n'
        'Binlik Fiyat,1.234 TL\n'
        'Ondalıklı Fiyat,"1.234,56 TL"\n',
      ),
      fileName: 'urunler.csv',
    );

    expect(result.isSuccess, isTrue);
    expect(result.validCount, 2);
    expect(result.products[0].price, '1234');
    expect(result.products[1].price, '1234.56');
  });
}
