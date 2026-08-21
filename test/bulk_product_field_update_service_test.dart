import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/services/bulk_product_field_update_service.dart';

void main() {
  const service = BulkProductFieldUpdateService();

  Product product({
    String id = 'p1',
    String price = '750 TL',
    String stockStatus = 'Mevcut',
    String categoryId = 'cat-1',
    String category = 'Giyim',
    bool isVisible = true,
  }) {
    return Product(
      id: id,
      name: 'Test Ürün',
      price: price,
      categoryId: categoryId,
      category: category,
      stockStatus: stockStatus,
      isVisible: isVisible,
    );
  }

  group('parsePriceAmount', () {
    test('düz sayı + TL soneki', () {
      expect(service.parsePriceAmount('750 TL'), 750.0);
    });

    test('TR ondalık virgülü', () {
      expect(service.parsePriceAmount('1.250,50 TL'), 1250.5);
    });

    test('sayı içermeyen metin null döner', () {
      expect(service.parsePriceAmount('Fiyat için mesaj atın'), isNull);
    });

    test('boş metin null döner', () {
      expect(service.parsePriceAmount(''), isNull);
    });
  });

  group('formatPriceAmount', () {
    test('binlik ayracı ve TR ondalık virgülü ekler', () {
      expect(service.formatPriceAmount(1234.5), '1.234,50 TL');
    });

    test('küsuratsız tutar da iki ondalıkla biçimlenir', () {
      expect(service.formatPriceAmount(750), '750,00 TL');
    });
  });

  group('applyPriceAdjustment', () {
    test('#262 örneği: tüm ürünlere %10 zam', () {
      final result = service.applyPriceAdjustment(
        products: [product(price: '100 TL')],
        mode: PriceAdjustMode.increasePercent,
        value: 10,
      );

      expect(result.skipped, isEmpty);
      expect(result.updated.single.price, '110,00 TL');
    });

    test('yüzde indirim', () {
      final result = service.applyPriceAdjustment(
        products: [product(price: '200 TL')],
        mode: PriceAdjustMode.decreasePercent,
        value: 25,
      );

      expect(result.updated.single.price, '150,00 TL');
    });

    test('sabit tutar ekleme/çıkarma', () {
      final increased = service.applyPriceAdjustment(
        products: [product(price: '100 TL')],
        mode: PriceAdjustMode.increaseAmount,
        value: 50,
      );
      expect(increased.updated.single.price, '150,00 TL');

      final decreased = service.applyPriceAdjustment(
        products: [product(price: '100 TL')],
        mode: PriceAdjustMode.decreaseAmount,
        value: 30,
      );
      expect(decreased.updated.single.price, '70,00 TL');
    });

    test(
      'hepsini aynı tutara eşitle — mevcut fiyat okunamasa da uygulanır',
      () {
        final result = service.applyPriceAdjustment(
          products: [product(price: 'mesaj atın')],
          mode: PriceAdjustMode.setExact,
          value: 199,
        );

        expect(result.skipped, isEmpty);
        expect(result.updated.single.price, '199,00 TL');
      },
    );

    test('fiyatı ayrıştırılamayan ürün artış/azaltmada atlanır, bozulmaz', () {
      final unparseable = product(id: 'p2', price: 'mesaj atın');
      final result = service.applyPriceAdjustment(
        products: [product(id: 'p1', price: '100 TL'), unparseable],
        mode: PriceAdjustMode.increasePercent,
        value: 10,
      );

      expect(result.updated, hasLength(1));
      expect(result.updated.single.id, 'p1');
      expect(result.skipped, hasLength(1));
      expect(result.skipped.single.id, 'p2');
      // Atlanan ürünün fiyat metni AYNEN korunur.
      expect(result.skipped.single.price, 'mesaj atın');
    });

    test('negatif sonuç 0a kırpılır, ürün yine güncellenir', () {
      final result = service.applyPriceAdjustment(
        products: [product(price: '10 TL')],
        mode: PriceAdjustMode.decreaseAmount,
        value: 50,
      );

      expect(result.skipped, isEmpty);
      expect(result.updated.single.price, '0,00 TL');
    });
  });

  test('applyStockStatus yalnız stok alanını değiştirir', () {
    final updated = service.applyStockStatus([
      product(stockStatus: 'Mevcut'),
    ], 'Tükendi');

    expect(updated.single.stockStatus, 'Tükendi');
    expect(updated.single.price, '750 TL');
  });

  test('applyCategory kategori id ve adını birlikte günceller', () {
    final updated = service.applyCategory([
      product(categoryId: 'cat-1', category: 'Giyim'),
    ], ProductCategory(id: 'cat-2', name: 'Ayakkabı'));

    expect(updated.single.categoryId, 'cat-2');
    expect(updated.single.category, 'Ayakkabı');
  });

  test('applyVisibility görünürlüğü topluca değiştirir', () {
    final updated = service.applyVisibility([product(isVisible: true)], false);

    expect(updated.single.isVisible, isFalse);
  });
}
