import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/models/store_data.dart';

void main() {
  group('Product.copyWith', () {
    late Product base;

    setUp(() {
      base = Product(
        id: 'p1',
        name: 'Gömlek',
        price: '250',
        description: 'Pamuklu gömlek',
        category: 'Giyim',
        stockStatus: 'Mevcut',
      );
    });

    test('copyWith without args returns equivalent', () {
      final copy = base.copyWith();
      expect(copy.id, base.id);
      expect(copy.name, base.name);
      expect(copy.price, base.price);
      expect(copy.description, base.description);
      expect(copy.category, base.category);
      expect(copy.stockStatus, base.stockStatus);
    });

    test('copyWith updates only name', () {
      final copy = base.copyWith(name: 'Pantolon');
      expect(copy.name, 'Pantolon');
      expect(copy.id, base.id);
      expect(copy.price, base.price);
    });

    test('copyWith updates price', () {
      final copy = base.copyWith(price: '300');
      expect(copy.price, '300');
      expect(copy.name, base.name);
    });

    test('copyWith sets imagePath', () {
      final copy = base.copyWith(imagePath: 'https://cdn.example.com/img.jpg');
      expect(copy.imagePath, 'https://cdn.example.com/img.jpg');
    });

    test('copyWith does not mutate original', () {
      base.copyWith(name: 'Başka Ürün');
      expect(base.name, 'Gömlek');
    });

    test('copyWith stockStatus update', () {
      final copy = base.copyWith(stockStatus: 'Tükendi');
      expect(copy.stockStatus, 'Tükendi');
      expect(base.stockStatus, 'Mevcut');
    });
  });

  group('Product.fromJson', () {
    test('parses all fields', () {
      final p = Product.fromJson({
        'id': 'abc',
        'name': 'Ürün',
        'price': '100',
        'description': 'Açıklama',
        'imagePath': 'https://example.com/img.jpg',
        'category': 'Elektronik',
        'stockStatus': 'Son birkaç adet',
      });
      expect(p.id, 'abc');
      expect(p.name, 'Ürün');
      expect(p.price, '100');
      expect(p.description, 'Açıklama');
      expect(p.imagePath, 'https://example.com/img.jpg');
      expect(p.category, 'Elektronik');
      expect(p.stockStatus, 'Son birkaç adet');
    });

    test('uses defaults for missing fields', () {
      final p = Product.fromJson({'id': 'x'});
      expect(p.name, '');
      expect(p.price, '');
      expect(p.category, 'Tümü');
      expect(p.stockStatus, 'Mevcut');
      expect(p.imagePath, isNull);
    });

    test('null imagePath stays null', () {
      final p = Product.fromJson({'id': 'x', 'imagePath': null});
      expect(p.imagePath, isNull);
    });
  });

  group('Product.toJson round-trip', () {
    test('toJson → fromJson yields same values', () {
      final original = Product(
        id: 'p42',
        name: 'Elbise',
        price: '450',
        description: 'Günlük elbise',
        imagePath: 'https://cdn.example.com/dress.jpg',
        category: 'Giyim',
        stockStatus: 'Tükendi',
      );
      final json = original.toJson();
      final restored = Product.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.price, original.price);
      expect(restored.description, original.description);
      expect(restored.imagePath, original.imagePath);
      expect(restored.category, original.category);
      expect(restored.stockStatus, original.stockStatus);
    });
  });
}
