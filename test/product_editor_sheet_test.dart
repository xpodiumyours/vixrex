// Karakterizasyon testleri — ProductEditorSheet
//
// Bu dosya _ProductEditorSheetState'in statik yardımcı metotlarını
// ve sabitlerini davranışsal olarak belgeler.

import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/widgets/product/product_editor_sheet.dart';

void main() {
  // Kategori eşleme mantığı public @visibleForTesting ile açık olduğu için
  // doğrudan widget üzerinden test edilir.  State'in statik metodunu çağırmak
  // için ProductEditorSheet.resolveInitialCategoryId kullanılır.

  group('ProductEditorSheet — görsel ekleme limiti', () {
    test('_maxImages sabiti 4 olmalı', () {
      // Widget oluşturulduğunda _maxImages=4 değeri
      // _pickImages ve _buildImageGrid içinde kullanılır.
      // Sabit değerini karakterize etmek için ProductEditorSheet'in
      // kMaxImages alanına erişiyoruz.
      expect(ProductEditorSheet.kMaxImages, 4);
    });
  });

  group('ProductEditorSheet — başlangıç kategori çözümlemesi', () {
    late ProductCategory catA;
    late ProductCategory catB;
    late List<ProductCategory> categories;

    setUp(() {
      catA = ProductCategory(id: 'cat-a', name: 'Giyim', sortOrder: 0);
      catB = ProductCategory(id: 'cat-b', name: 'Elektronik', sortOrder: 1);
      categories = [catA, catB];
    });

    test('categoryId tam eşleşirse o kategori seçilir', () {
      final product = Product(
        id: 'p1',
        name: 'Gömlek',
        price: '100',
        description: '',
        categoryId: 'cat-b',
        category: 'Giyim',
        stockStatus: 'Mevcut',
      );
      final result = ProductEditorSheet.resolveInitialCategoryId(
        product,
        categories,
      );
      expect(result, 'cat-b');
    });

    test('categoryId boşsa category ismiyle eşleştirme yapılır', () {
      final product = Product(
        id: 'p2',
        name: 'Telefon',
        price: '5000',
        description: '',
        categoryId: '',
        category: 'Elektronik',
        stockStatus: 'Mevcut',
      );
      final result = ProductEditorSheet.resolveInitialCategoryId(
        product,
        categories,
      );
      expect(result, 'cat-b');
    });

    test('category ismi büyük/küçük harf farkına duyarsız eşleşir', () {
      final product = Product(
        id: 'p3',
        name: 'Kıyafet',
        price: '200',
        description: '',
        categoryId: '',
        category: 'giyim',
        stockStatus: 'Mevcut',
      );
      final result = ProductEditorSheet.resolveInitialCategoryId(
        product,
        categories,
      );
      expect(result, 'cat-a');
    });

    test('eşleşme yoksa ilk kategori döner', () {
      final product = Product(
        id: 'p4',
        name: 'Araba',
        price: '500000',
        description: '',
        categoryId: '',
        category: 'Araçlar',
        stockStatus: 'Mevcut',
      );
      final result = ProductEditorSheet.resolveInitialCategoryId(
        product,
        categories,
      );
      expect(result, 'cat-a');
    });

    test('kategori listesi boşsa boş string döner', () {
      final product = Product(
        id: 'p5',
        name: 'Ürün',
        price: '',
        description: '',
        categoryId: 'cat-x',
        category: 'Bilinmiyor',
        stockStatus: 'Mevcut',
      );
      final result = ProductEditorSheet.resolveInitialCategoryId(product, []);
      expect(result, '');
    });

    test('product null ise ilk kategori döner', () {
      final result = ProductEditorSheet.resolveInitialCategoryId(
        null,
        categories,
      );
      expect(result, 'cat-a');
    });

    test('product null ve kategori listesi boşsa boş string döner', () {
      final result = ProductEditorSheet.resolveInitialCategoryId(null, []);
      expect(result, '');
    });
  });
}
