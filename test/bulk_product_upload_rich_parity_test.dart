import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/bulk_product_upload_service.dart';

Uint8List _csvBytes(String value) => Uint8List.fromList(utf8.encode(value));

void main() {
  const service = BulkProductUploadService();

  test('Flutter bulk import 3 fotoğraf ve zengin çekirdek alanlarını taşır', () {
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

  test('Flutter bulk import 3 fotoğraftan az yeni ürünü kayda hazırlamaz', () {
    final result = service.parse(
      _csvBytes(
        'Ürün Adı,Görsel URL 1,Görsel URL 2,Görsel URL 3\n'
        'Eksik Galeri,https://cdn.example.com/a.jpg,https://cdn.example.com/b.jpg,\n',
      ),
      fileName: 'urunler.csv',
    );

    expect(result.isSuccess, isTrue);
    expect(result.validCount, 0);
    expect(result.errorCount, 1);
    expect(result.errors.single.message, contains('en az 3 fotoğraf'));
  });

  test('stok 10 ifadesini Tükendi diye yorumlamaz', () {
    final result = service.parse(
      _csvBytes(
        'Ürün Adı,Stok,Görsel URL 1,Görsel URL 2,Görsel URL 3\n'
        'Stoklu Ürün,10,https://cdn.example.com/a.jpg,https://cdn.example.com/b.jpg,https://cdn.example.com/c.jpg\n',
      ),
      fileName: 'urunler.csv',
    );

    expect(result.products.single.stockQuantity, 10);
    expect(result.products.single.stockStatus, 'Mevcut');
  });
}
