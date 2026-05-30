import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/services/store_publish_validator.dart';

void main() {
  const validator = StorePublishValidator();

  test('yayın için zorunlu alanlar eksikse kullanıcı mesajı döner', () {
    final message = validator.validate(StoreData());

    expect(message, isNotNull);
    expect(message, contains('mağaza adı'));
    expect(message, contains('WhatsApp numarası'));
    expect(message, contains('kısa açıklama'));
    expect(message, contains('en az 1 pazaryeri linki'));
    expect(message, contains('adres bilgisi'));
  });

  test('zorunlu alanlar tamamlandığında null döner', () {
    final message = validator.validate(
      StoreData(
        name: 'Aymira Giyim',
        whatsapp: '0555 111 22 33',
        description: 'Mahalle butiği',
        address: 'Kadıköy, İstanbul',
        marketplaceLinks: [
          MarketplaceLink(
            id: '1',
            platform: 'Trendyol',
            url: 'https://trendyol.com/magaza',
          ),
        ],
      ),
    );

    expect(message, isNull);
  });
}
