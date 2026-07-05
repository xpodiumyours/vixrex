import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/store_data.dart';

void main() {
  group('StoreData.copyWith', () {
    late StoreData base;

    setUp(() {
      base = StoreData(
        name: 'Test Mağaza',
        businessType: 'Butik',
        description: 'Açıklama',
        whatsapp: '05551234567',
        address: 'Test Sokak No:1',
        isStore: true,
        kategori: 'Giyim & Butik',
        workingHours: '09:00-18:00',
        isEsnafMode: false,
      );
    });

    test('copyWith without arguments returns equivalent object', () {
      final copy = base.copyWith();
      expect(copy.name, base.name);
      expect(copy.businessType, base.businessType);
      expect(copy.description, base.description);
      expect(copy.whatsapp, base.whatsapp);
      expect(copy.address, base.address);
      expect(copy.isStore, base.isStore);
      expect(copy.kategori, base.kategori);
      expect(copy.workingHours, base.workingHours);
    });

    test('copyWith updates only specified fields', () {
      final copy = base.copyWith(name: 'Yeni Mağaza');
      expect(copy.name, 'Yeni Mağaza');
      // Diğer alanlar değişmemeli
      expect(copy.businessType, base.businessType);
      expect(copy.description, base.description);
      expect(copy.whatsapp, base.whatsapp);
      expect(copy.isStore, base.isStore);
    });

    test('copyWith does not mutate original', () {
      base.copyWith(name: 'Başka İsim');
      expect(base.name, 'Test Mağaza');
    });

    test('copyWith can change isStore', () {
      final vitrin = base.copyWith(isStore: false);
      expect(vitrin.isStore, isFalse);
      expect(base.isStore, isTrue); // orijinal değişmedi
    });

    test('copyWith products list is a defensive copy', () {
      final product = Product(id: 'p1', name: 'Ürün 1');
      final withProduct = base.copyWith(products: [product]);
      withProduct.products.add(Product(id: 'p2', name: 'Ürün 2'));
      // base.products değişmemeli
      expect(base.products, isEmpty);
    });

    test('copyWith can update location fields', () {
      final withLocation = base.copyWith(
        latitude: 41.0,
        longitude: 29.0,
        locationAccuracyMeters: 15.0,
      );
      expect(withLocation.latitude, 41.0);
      expect(withLocation.longitude, 29.0);
      expect(withLocation.locationAccuracyMeters, 15.0);
      // Orijinal değişmedi
      expect(base.latitude, isNull);
    });
  });

  group('StoreData.fromJson dual-key mapping', () {
    test('reads camelCase keys', () {
      final data = StoreData.fromJson({
        'name': 'Butik',
        'businessType': 'Kadın Giyim',
        'corporateBio': 'Bio metin',
        'shelfImageUrl': 'https://example.com/img.jpg',
        'referencesLink': 'https://refs.com',
        'workingHours': '09:00-17:00',
        'isStore': true,
      });
      expect(data.businessType, 'Kadın Giyim');
      expect(data.corporateBio, 'Bio metin');
      expect(data.shelfImageUrl, 'https://example.com/img.jpg');
      expect(data.referencesLink, 'https://refs.com');
      expect(data.workingHours, '09:00-17:00');
      expect(data.isStore, isTrue);
    });

    test('reads snake_case keys from Supabase response', () {
      final data = StoreData.fromJson({
        'name': 'Mağaza',
        'business_type': 'Erkek Giyim',
        'corporate_bio': 'Kurumsal bio',
        'shelf_image_url': 'https://cdn.example.com/shelf.webp',
        'references_link': 'https://google.com',
        'working_hours': '10:00-20:00',
        'is_store': true,
        'logo_url': 'https://cdn.example.com/logo.png',
      });
      expect(data.businessType, 'Erkek Giyim');
      expect(data.corporateBio, 'Kurumsal bio');
      expect(data.shelfImageUrl, 'https://cdn.example.com/shelf.webp');
      expect(data.referencesLink, 'https://google.com');
      expect(data.workingHours, '10:00-20:00');
      expect(data.isStore, isTrue);
      expect(data.logoUrl, 'https://cdn.example.com/logo.png');
    });

    test('camelCase takes priority over snake_case', () {
      final data = StoreData.fromJson({
        'businessType': 'Öncelikli',
        'business_type': 'İkincil',
      });
      expect(data.businessType, 'Öncelikli');
    });

    test('fromJson locationConsentAt parses ISO string', () {
      final now = DateTime(2025, 6, 1, 12, 0, 0);
      final data = StoreData.fromJson({
        'name': 'X',
        'locationConsentAt': now.toIso8601String(),
      });
      expect(data.locationConsentAt, now);
    });

    test('fromJson returns null locationConsentAt for null input', () {
      final data = StoreData.fromJson({'name': 'X'});
      expect(data.locationConsentAt, isNull);
    });
  });

  group('StoreData.fromJson products parsing', () {
    test('parses products list', () {
      final data = StoreData.fromJson({
        'name': 'X',
        'products': [
          {'id': '1', 'name': 'Ürün A', 'price': '150'},
          {'id': '2', 'name': 'Ürün B', 'price': '200'},
        ],
      });
      expect(data.products.length, 2);
      expect(data.products.first.name, 'Ürün A');
    });

    test('returns empty list when products is null', () {
      final data = StoreData.fromJson({'name': 'X'});
      expect(data.products, isEmpty);
    });
  });
}
