import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/utils/address_validator.dart';

// Adres, müşterinin dükkânı bulmasını sağlayan tek bilgi.
// Yarım adres, adres olmamasından beterdir: müşteri yola çıkar, bulamaz.

void main() {
  group('AddressValidator — reddedilenler', () {
    test('boş adres reddedilir', () {
      expect(AddressValidator.gecerliMi(''), isFalse);
      expect(AddressValidator.gecerliMi(null), isFalse);
      expect(AddressValidator.gecerliMi('   '), isFalse);
    });

    test('boş sallamalar reddedilir', () {
      for (final kotu in ['asd', 'asdasd', 'aaaa', 'xxx', 'deneme']) {
        expect(AddressValidator.gecerliMi(kotu), isFalse, reason: kotu);
      }
    });

    test('yeterince uzun ama sokak/numara içermeyen metin reddedilir', () {
      expect(AddressValidator.gecerliMi('buralarda bir yerde'), isFalse);
    });

    test('hata mesajı ne yapılacağını söyler, örnek verir', () {
      final mesaj = AddressValidator.hataMesaji('asd');
      expect(mesaj, isNotNull);
      expect(mesaj, contains('Örnek'));
    });
  });

  group('AddressValidator — kabul edilenler', () {
    test('kapı numaralı normal adres kabul edilir', () {
      expect(AddressValidator.gecerliMi('Atatürk Cad. No:24'), isTrue);
    });

    test('mahalle ve sokak yazılı adres kabul edilir', () {
      expect(AddressValidator.gecerliMi('Yeni Mahalle Gül Sokak'), isTrue);
    });

    test('sanayi ve çarşı adresleri kabul edilir', () {
      expect(AddressValidator.gecerliMi('Yeni Sanayi Sitesi B Blok'), isTrue);
      expect(AddressValidator.gecerliMi('Kapalı Çarşı, Kuyumcular'), isTrue);
    });

    test('yalnız kapı numarası olan köy adresi kabul edilir', () {
      // Köyde cadde adı olmayabilir; numara varsa yeter.
      expect(AddressValidator.gecerliMi('Merkez Küme Evler 12'), isTrue);
    });

    test('geçerli adreste hata mesajı dönmez', () {
      expect(AddressValidator.hataMesaji('Atatürk Cad. No:24'), isNull);
    });
  });
}
