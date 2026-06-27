import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/services/store_publish_service.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/widgets/vitrin_view.dart';

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

    test('invalid whatsapp format returns error', () {
      final data = validStore();
      data.whatsapp = 'abc';
      expect(
        validator.validateStore(data),
        'Geçerli bir Türkiye cep telefonu numarası girin. Örn: 0555 123 45 67',
      );
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
      expect(validator.validateVitrin(data), contains('WhatsApp'));
    });

    test('invalid whatsapp format returns error', () {
      final data = validVitrin();
      data.whatsapp = '05x';
      expect(
        validator.validateVitrin(data),
        'Geçerli bir Türkiye cep telefonu numarası girin. Örn: 0555 123 45 67',
      );
    });

    test('missing description still passes', () {
      final data = validVitrin();
      data.description = '';
      expect(validator.validateVitrin(data), isNull);
    });

    test('missing address returns error', () {
      final data = validVitrin();
      data.address = '';
      expect(validator.validateVitrin(data), isNotNull);
      expect(validator.validateVitrin(data), contains('konum'));
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

    test('error message asks for missing fields', () {
      final data = validVitrin();
      data.name = '';
      data.whatsapp = '';
      final msg = validator.validateVitrin(data)!;
      expect(msg, contains('işletme adı'));
      expect(msg, contains('WhatsApp'));
    });
  });

  group('StorePublishValidator offerings and URL safety', () {
    test('rejects unsafe schemes in marketplace links', () {
      final data = validVitrin();
      for (final scheme in [
        'javascript:alert(1)',
        'data:text/html,123',
        'file:///etc/passwd',
        'tel:05551234567',
        'mailto:test@example.com',
      ]) {
        data.marketplaceLinks = [
          MarketplaceLink(id: '1', platform: 'Trendyol', url: scheme),
        ];
        expect(validator.validateVitrin(data), contains('Geçersiz web adresi'));
      }
    });

    test('rejects empty URL for custom marketplace links', () {
      final data = validVitrin();
      data.marketplaceLinks = [
        MarketplaceLink(id: '1', platform: 'Özel Buton', url: ''),
      ];
      expect(validator.validateVitrin(data), contains('Geçersiz web adresi'));
    });

    test('rejects too many offerings (>6)', () {
      final data = validVitrin();
      data.offerings = List.generate(
        7,
        (i) => StoreOffering(id: '$i', title: 'Hizmet $i'),
      );
      expect(validator.validateVitrin(data), contains('En fazla 6 adet'));
    });

    test('rejects empty title for offerings', () {
      final data = validVitrin();
      data.offerings = [StoreOffering(id: '1', title: '')];
      expect(validator.validateVitrin(data), contains('başlığı boş olamaz'));
    });

    test('rejects offering fields exceeding character limits', () {
      final data = validVitrin();

      // Title limit (60)
      data.offerings = [StoreOffering(id: '1', title: 'A' * 61)];
      expect(validator.validateVitrin(data), contains('başlığı en fazla 60'));

      // Description limit (120)
      data.offerings = [
        StoreOffering(id: '1', title: 'Hizmet', description: 'B' * 121),
      ];
      expect(
        validator.validateVitrin(data),
        contains('açıklaması en fazla 120'),
      );

      // Price limit (30)
      data.offerings = [
        StoreOffering(id: '1', title: 'Hizmet', price: 'C' * 31),
      ];
      expect(validator.validateVitrin(data), contains('fiyatı en fazla 30'));
    });
  });

  group('VitrinView.normalizeExternalUrl normalization and safety', () {
    test('allows valid http/https schemes (case-insensitive)', () {
      expect(
        VitrinView.normalizeExternalUrl('http://example.com'),
        'http://example.com',
      );
      expect(
        VitrinView.normalizeExternalUrl('https://example.com'),
        'https://example.com',
      );
      expect(
        VitrinView.normalizeExternalUrl('HTTPS://example.com'),
        'HTTPS://example.com',
      );
      expect(
        VitrinView.normalizeExternalUrl('HTTP://example.com'),
        'HTTP://example.com',
      );
    });

    test('rejects unsafe schemes', () {
      expect(VitrinView.normalizeExternalUrl('javascript:alert(1)'), '');
      expect(VitrinView.normalizeExternalUrl('data:text/html,123'), '');
      expect(VitrinView.normalizeExternalUrl('file:///passwd'), '');
      expect(VitrinView.normalizeExternalUrl('tel:05551234567'), '');
      expect(VitrinView.normalizeExternalUrl('mailto:test@example.com'), '');
    });

    test('adds https:// scheme for valid domains without scheme', () {
      expect(
        VitrinView.normalizeExternalUrl('google.com'),
        'https://google.com',
      );
      expect(
        VitrinView.normalizeExternalUrl('www.example.org'),
        'https://www.example.org',
      );
    });

    test('rejects text without dot as domain', () {
      expect(VitrinView.normalizeExternalUrl('just-text'), '');
      expect(VitrinView.normalizeExternalUrl('   '), '');
    });
  });
}
