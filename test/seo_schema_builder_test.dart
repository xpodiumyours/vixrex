import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/services/seo_schema_builder.dart';

void main() {
  group('buildStoreSchemas', () {
    test(
      'adds opening hours, public url, and breadcrumbs to LocalBusiness and @graph schema',
      () {
        final store = StoreData(
          name: 'Nova Kuafor',
          description: 'Yerel kuafor vitrini',
          workingHours: '09:00 - 20:00',
          kategori: 'Güzellik',
        );

        final schemas = buildStoreSchemas(
          store,
          publicUrl: 'https://vitrinx.app/v/nova-kuafor',
        );

        final graph = schemas['@graph'] as List;
        final localBusiness = graph[0] as Map<String, dynamic>;
        final breadcrumbList = graph[1] as Map<String, dynamic>;

        // Check LocalBusiness
        expect(localBusiness['@type'], 'LocalBusiness');
        expect(localBusiness['url'], 'https://vitrinx.app/v/nova-kuafor');
        expect(
          localBusiness['openingHoursSpecification'],
          isA<Map<String, dynamic>>(),
        );

        final openingHours =
            localBusiness['openingHoursSpecification'] as Map<String, dynamic>;
        expect(openingHours['opens'], '09:00');
        expect(openingHours['closes'], '20:00');

        // Check BreadcrumbList
        expect(breadcrumbList['@type'], 'BreadcrumbList');
        final items = breadcrumbList['itemListElement'] as List;
        expect(items.length, 3);
        expect(items[0]['name'], 'VitrinX');
        expect(items[1]['name'], 'Güzellik');
        expect(items[2]['name'], 'Nova Kuafor');
        expect(items[2]['item'], 'https://vitrinx.app/v/nova-kuafor');
      },
    );

    test('does not add opening hours when working hour format is invalid', () {
      final store = StoreData(
        name: 'Nova Kuafor',
        description: 'Yerel kuafor vitrini',
        workingHours: 'sabah aksam',
      );

      final schemas = buildStoreSchemas(store);
      final graph = schemas['@graph'] as List;
      final localBusiness = graph[0] as Map<String, dynamic>;

      expect(localBusiness.containsKey('openingHoursSpecification'), isFalse);
    });

    test('adds price range from numeric product prices', () {
      final store = StoreData(
        name: 'Nova Kuafor',
        description: 'Yerel kuafor vitrini',
        products: [
          Product(id: 'p1', name: 'Sac kesimi', price: '250 TL'),
          Product(id: 'p2', name: 'Boya', price: '1200 TL'),
        ],
      );

      final schemas = buildStoreSchemas(store);
      final graph = schemas['@graph'] as List;
      final localBusiness = graph[0] as Map<String, dynamic>;

      expect(localBusiness['priceRange'], r'$$');
    });

    test('adds hasMap and areaServed from coordinates and address', () {
      final store = StoreData(
        name: 'Nova Kuafor',
        description: 'Yerel kuafor vitrini',
        address: 'Moda Cd. No:12, Kadikoy, Istanbul',
        latitude: 40.9876,
        longitude: 29.0123,
      );

      final schemas = buildStoreSchemas(store);
      final graph = schemas['@graph'] as List;
      final localBusiness = graph[0] as Map<String, dynamic>;

      expect(localBusiness['hasMap'], contains('query=40.9876,29.0123'));
      expect(localBusiness['areaServed']['name'], 'Istanbul');
    });

    test('does not emit fake 0.00 offer for non-numeric product prices', () {
      final store = StoreData(
        name: 'Nova Kuafor',
        description: 'Yerel kuafor vitrini',
        products: [
          Product(id: 'p1', name: 'Ozel paket', price: 'Magazada sorunuz'),
        ],
      );

      final schemas = buildStoreSchemas(store);
      final graph = schemas['@graph'] as List;
      final localBusiness = graph[0] as Map<String, dynamic>;
      final productSchema =
          graph[2] as Map<String, dynamic>; // graph[1] is breadcrumbs

      expect(localBusiness.containsKey('priceRange'), isFalse);
      expect(productSchema.containsKey('offers'), isFalse);
    });

    test('does not add aggregateRating without real rating data', () {
      final store = StoreData(
        name: 'Nova Kuafor',
        description: 'Yerel kuafor vitrini',
        workingHours: '09:00-20:00',
      );

      final schemas = buildStoreSchemas(store);
      final graph = schemas['@graph'] as List;
      final localBusiness = graph[0] as Map<String, dynamic>;

      expect(localBusiness.containsKey('aggregateRating'), isFalse);
    });
  });
}
