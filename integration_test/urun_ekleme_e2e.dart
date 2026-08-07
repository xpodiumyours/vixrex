import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/services/store_local_storage_service.dart';

/// SMOKE TEST — Gerçek E2E değil.
///
/// Controller unit testi (mock ile).
/// Gerçek kullanıcı akışı test etmiyor; sadece controller mantığını doğruluyor.
///
/// `flutter test integration_test/urun_ekleme_e2e.dart`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    StoreLocalStorageService.resetCache();
  });

  testWidgets('ürün ekleme akışı', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = StoreEditorController();
    await controller.initialize('E2E Mağaza');

    // İlk durum: ürün yok
    expect(controller.hasProducts, isFalse);

    // Ürün ekle
    final product = Product(
      id: 'e2e-1',
      name: 'E2E Test Ürünü',
      price: '250',
      description: 'E2E ile eklenen ürün',
    );
    await controller.addProduct(product);

    // Ürün eklendi
    expect(controller.hasProducts, isTrue);
    expect(controller.products, hasLength(1));
    expect(controller.products.first.name, 'E2E Test Ürünü');
    expect(controller.products.first.price, '250');

    controller.dispose();
  });

  testWidgets('çoklu ürün ekleme ve silme', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = StoreEditorController();
    await controller.initialize('E2E Mağaza');

    // 3 ürün ekle
    await controller.addProduct(
      Product(id: 'p1', name: 'Ürün 1', price: '100'),
    );
    await controller.addProduct(
      Product(id: 'p2', name: 'Ürün 2', price: '200'),
    );
    await controller.addProduct(
      Product(id: 'p3', name: 'Ürün 3', price: '300'),
    );
    expect(controller.products, hasLength(3));

    // Ortadakini sil
    await controller.removeProductById('p2');
    expect(controller.products, hasLength(2));
    expect(controller.products.map((p) => p.name), ['Ürün 1', 'Ürün 3']);

    // İlk ürünü güncelle
    await controller.updateProduct(
      0,
      Product(id: 'p1', name: 'Güncellenmiş Ürün', price: '150'),
    );
    expect(controller.products.first.name, 'Güncellenmiş Ürün');
    expect(controller.products.first.price, '150');

    controller.dispose();
  });

  testWidgets('ürün fiyatı doğrulama', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = StoreEditorController();
    await controller.initialize('E2E Mağaza');

    // Farklı fiyat formatları dene
    await controller.addProduct(
      Product(id: 'p1', name: 'Ürün', price: '100'),
    );
    expect(controller.products.first.price, '100');

    await controller.addProduct(
      Product(id: 'p2', name: 'Ürün 2', price: '1.500,00'),
    );
    expect(controller.products.last.price, '1.500,00');

    controller.dispose();
  });
}
