import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/vitrin_cart_service.dart';

VitrinCartItem _urun(String ad) => VitrinCartItem(
  productSlug: 'ortak-urun',
  productName: ad,
  variantKey: 'standart',
  variantText: '',
  priceText: '100 TL',
  priceAmount: 100,
  imageUrl: '',
  maxQuantity: 10,
  quantity: 1,
);

void main() {
  final cart = VitrinCartService.instance;

  setUp(() {
    cart.setActiveStore('magaza-a');
    cart.clear();
    cart.setActiveStore('magaza-b');
    cart.clear();
  });

  test('aynı ürün slug’ı iki mağazada birleşmez ve özet doğru mağazadan üretilir', () {
    cart.setActiveStore('magaza-a');
    cart.add(_urun('A Ürünü'));

    cart.setActiveStore('magaza-b');
    expect(cart.items, isEmpty);
    cart.add(_urun('B Ürünü'));
    cart.add(_urun('B Ürünü'));

    expect(cart.totalQuantity(), 2);
    expect(cart.items.single.productName, 'B Ürünü');

    cart.setActiveStore('magaza-a');
    expect(cart.totalQuantity(), 1);
    expect(cart.items.single.productName, 'A Ürünü');

    final ozet = cart.buildWhatsAppText(
      storeName: 'B Mağazası',
      storeSlug: 'magaza-b',
    );
    expect(ozet, contains('B Ürünü'));
    expect(ozet, isNot(contains('A Ürünü')));
    expect(ozet, contains('Toplam urun adedi: 2'));
  });

  test('clear yalnız aktif mağazanın sepetini temizler', () {
    cart.setActiveStore('magaza-a');
    cart.add(_urun('A Ürünü'));
    cart.setActiveStore('magaza-b');
    cart.add(_urun('B Ürünü'));

    cart.setActiveStore('magaza-a');
    cart.clear();

    expect(cart.items, isEmpty);
    cart.setActiveStore('magaza-b');
    expect(cart.totalQuantity(), 1);
    expect(cart.items.single.productName, 'B Ürünü');
  });
}
