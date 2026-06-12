import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/services/store_publish_validator.dart';
import 'package:vitrinx/models/store_data.dart';

// Helper: geçerli bir mağaza verisi oluşturur.
StoreData validStore({List<Product>? products}) {
  return StoreData(
    name: 'Test Mağaza',
    whatsapp: '05551234567',
    description: 'Test açıklama',
    address: 'Test Sokak No:1',
    kategori: 'Giyim & Butik',
    isStore: true,
    products: products ?? [],
  );
}

// Helper: geçerli bir vitrin verisi oluşturur.
StoreData validVitrin() {
  return StoreData(
    name: 'Test Vitrin',
    whatsapp: '05559876543',
    description: 'Test vitrin açıklama',
    address: 'Test Mahalle',
    isStore: false,
    marketplaceLinks: [],
  );
}

void main() {
  const validator = StorePublishValidator();

  group('StorePublishValidator.validate dispatching', () {
    test('isStore=true calls validateStore', () {
      final result = validator.validate(validStore());
      expect(result, isNull);
    });

    test('isStore=false calls validateVitrin', () {
      final result = validator.validate(validVitrin());
      expect(result, isNull);
    });
  });

  group('StorePublishValidator.validateStore', () {
    test('valid store returns null', () {
      expect(validator.validateStore(validStore()), isNull);
    });

    test('missing name returns error', () {
      final data = validStore();
      data.name = '';
      expect(validator.validateStore(data), isNotNull);
      expect(validator.validateStore(data), contains('mağaza adı'));
    });

    test('missing whatsapp returns error', () {
      final data = validStore();
      data.whatsapp = '';
      expect(validator.validateStore(data), contains('telefon'));
    });

    test('missing description returns error', () {
      final data = validStore();
      data.description = '';
      expect(validator.validateStore(data), contains('kısa açıklama'));
    });

    test('missing address returns error', () {
      final data = validStore();
      data.address = '';
      expect(validator.validateStore(data), contains('adres'));
    });

    test('missing kategori returns error', () {
      final data = validStore();
      data.kategori = '';
      expect(validator.validateStore(data), contains('kategori'));
    });

    test('product with empty name returns error', () {
      final data = validStore(products: [Product(id: 'p1', name: '')]);
      expect(validator.validateStore(data), contains('ürün'));
    });

    test('product with valid name passes', () {
      final data = validStore(products: [Product(id: 'p1', name: 'Gömlek')]);
      expect(validator.validateStore(data), isNull);
    });

    test('whitespace-only name treated as empty', () {
      final data = validStore();
      data.name = '   ';
      expect(validator.validateStore(data), isNotNull);
    });
  });

  group('StorePublishValidator.validateVitrin', () {
    test('valid vitrin returns null', () {
      expect(validator.validateVitrin(validVitrin()), isNull);
    });

    test('missing name returns error', () {
      final data = validVitrin();
      data.name = '';
      expect(validator.validateVitrin(data), isNotNull);
    });

    test('missing whatsapp returns error', () {
      final data = validVitrin();
      data.whatsapp = '';
      expect(validator.validateVitrin(data), isNotNull);
    });

    test('missing description returns error', () {
      final data = validVitrin();
      data.description = '';
      expect(validator.validateVitrin(data), isNotNull);
    });

    test('missing address returns error', () {
      final data = validVitrin();
      data.address = '';
      expect(validator.validateVitrin(data), isNotNull);
    });

    test('no marketplace links still passes', () {
      final data = validVitrin();
      data.marketplaceLinks.clear();
      expect(validator.validateVitrin(data), isNull);
    });

    test('marketplace link with empty url still passes', () {
      final data = validVitrin();
      data.marketplaceLinks = [
        MarketplaceLink(id: '1', platform: 'Trendyol', url: ''),
      ];
      expect(validator.validateVitrin(data), isNull);
    });

    test('marketplace link with only platform, no url still passes', () {
      final data = validVitrin();
      data.marketplaceLinks = [
        MarketplaceLink(id: '1', platform: '', url: 'trendyol.com'),
      ];
      expect(validator.validateVitrin(data), isNull);
    });

    test('error message mentions the field(s) missing', () {
      final data = validVitrin();
      data.name = '';
      data.whatsapp = '';
      final msg = validator.validateVitrin(data)!;
      expect(msg, contains('mağaza adı'));
      expect(msg, contains('WhatsApp'));
    });
  });
}
