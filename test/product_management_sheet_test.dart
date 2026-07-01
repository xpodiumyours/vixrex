// Karakterizasyon testleri — ProductManagementSheet
//
// Bu dosya _ProductManagementSheetState'in statik yardımcı metodunu
// (_applyFilter) davranışsal olarak belgeler.

import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/widgets/product/product_management_sheet.dart';

void main() {
  group('ProductManagementSheet — arama filtresi', () {
    late List<Product> products;

    setUp(() {
      products = [
        Product(
          id: 'p1',
          name: 'Pamuklu Gömlek',
          price: '250',
          description: 'Günlük giyim için pamuklu gömlek',
          categoryId: 'cat-giyim',
          category: 'Giyim',
          stockStatus: 'Mevcut',
        ),
        Product(
          id: 'p2',
          name: 'Akıllı Telefon',
          price: '15000',
          description: 'Son model akıllı telefon',
          categoryId: 'cat-elektronik',
          category: 'Elektronik',
          stockStatus: 'Mevcut',
        ),
        Product(
          id: 'p3',
          name: 'Deri Çanta',
          price: '800',
          description: 'El yapımı deri çanta',
          categoryId: 'cat-aksesuar',
          category: 'Aksesuar',
          stockStatus: 'Son birkaç adet',
        ),
      ];
    });

    test('boş sorgu tüm ürünleri döner', () {
      final result = ProductManagementSheet.applyFilter(products, '', '');
      expect(result.length, 3);
    });

    test('ürün adına göre filtreleme çalışır', () {
      final result = ProductManagementSheet.applyFilter(
        products,
        'gömlek',
        '',
      );
      expect(result.length, 1);
      expect(result.first.id, 'p1');
    });

    test('açıklamaya göre filtreleme çalışır', () {
      final result = ProductManagementSheet.applyFilter(
        products,
        'el yapımı',
        '',
      );
      expect(result.length, 1);
      expect(result.first.id, 'p3');
    });

    test('büyük/küçük harf farkına duyarsız arama', () {
      final result = ProductManagementSheet.applyFilter(
        products,
        'TELEFON',
        '',
      );
      expect(result.length, 1);
      expect(result.first.id, 'p2');
    });

    test('eşleşme yoksa boş liste döner', () {
      final result = ProductManagementSheet.applyFilter(
        products,
        'bisiklet',
        '',
      );
      expect(result, isEmpty);
    });
  });

  group('ProductManagementSheet — kategori filtresi', () {
    late List<Product> products;

    setUp(() {
      products = [
        Product(
          id: 'p1',
          name: 'Gömlek',
          price: '250',
          description: '',
          categoryId: 'cat-giyim',
          category: 'Giyim',
          stockStatus: 'Mevcut',
        ),
        Product(
          id: 'p2',
          name: 'Telefon',
          price: '15000',
          description: '',
          categoryId: 'cat-elektronik',
          category: 'Elektronik',
          stockStatus: 'Mevcut',
        ),
        Product(
          id: 'p3',
          name: 'Kaban',
          price: '1200',
          description: '',
          categoryId: 'cat-giyim',
          category: 'Giyim',
          stockStatus: 'Mevcut',
        ),
      ];
    });

    test('kategori ID boşsa tüm ürünler döner', () {
      final result = ProductManagementSheet.applyFilter(products, '', '');
      expect(result.length, 3);
    });

    test('belirli kategori seçilince sadece o kategorinin ürünleri döner', () {
      final result = ProductManagementSheet.applyFilter(
        products,
        '',
        'cat-giyim',
      );
      expect(result.length, 2);
      expect(result.every((p) => p.categoryId == 'cat-giyim'), isTrue);
    });

    test('kategori ve arama birlikte çalışır', () {
      final result = ProductManagementSheet.applyFilter(
        products,
        'kaban',
        'cat-giyim',
      );
      expect(result.length, 1);
      expect(result.first.id, 'p3');
    });

    test('kategori filtresi eşleşmezse boş liste döner', () {
      final result = ProductManagementSheet.applyFilter(
        products,
        '',
        'cat-yok',
      );
      expect(result, isEmpty);
    });
  });

  group('ProductManagementSheet — görünürlük toggle (model seviyesi)', () {
    test('isVisible false iken toggle sonrası true olur', () {
      final product = Product(
        id: 'p1',
        name: 'Gömlek',
        price: '100',
        description: '',
        categoryId: 'cat-a',
        category: 'Giyim',
        stockStatus: 'Mevcut',
        isVisible: false,
      );
      product.isVisible = true;
      expect(product.isVisible, isTrue);
    });

    test('isVisible true iken toggle sonrası false olur', () {
      final product = Product(
        id: 'p2',
        name: 'Pantolon',
        price: '200',
        description: '',
        categoryId: 'cat-a',
        category: 'Giyim',
        stockStatus: 'Mevcut',
        isVisible: true,
      );
      product.isVisible = false;
      expect(product.isVisible, isFalse);
    });

    test('gizli ürünler _applyFilter tarafından filtrelenmez', () {
      final products = [
        Product(
          id: 'p1',
          name: 'Görünür Ürün',
          price: '100',
          description: '',
          categoryId: 'cat-a',
          category: 'Giyim',
          stockStatus: 'Mevcut',
          isVisible: true,
        ),
        Product(
          id: 'p2',
          name: 'Gizli Ürün',
          price: '200',
          description: '',
          categoryId: 'cat-a',
          category: 'Giyim',
          stockStatus: 'Mevcut',
          isVisible: false,
        ),
      ];
      // applyFilter görünürlük bazlı filtreleme yapmaz; bu UI sorumluluğundadır
      final result = ProductManagementSheet.applyFilter(products, '', '');
      expect(result.length, 2);
    });
  });
}
