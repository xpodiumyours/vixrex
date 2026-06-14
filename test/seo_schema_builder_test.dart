import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/services/seo_schema_builder.dart';

void main() {
  group('buildStoreSchemas', () {
    test('adds opening hours and public url to LocalBusiness schema', () {
      final store = StoreData(
        name: 'Nova Kuafor',
        description: 'Yerel kuafor vitrini',
        workingHours: '09:00 - 20:00',
      );

      final schemas = buildStoreSchemas(
        store,
        publicUrl: 'https://vitrinx.app/v/nova-kuafor',
      );

      final localBusiness = schemas;
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
      expect(openingHours['dayOfWeek'], contains('Sunday'));
    });

    test('does not add opening hours when working hour format is invalid', () {
      final store = StoreData(
        name: 'Nova Kuafor',
        description: 'Yerel kuafor vitrini',
        workingHours: 'sabah aksam',
      );

      final localBusiness = buildStoreSchemas(store);

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
      final productSchema = graph[1] as Map<String, dynamic>;

      expect(localBusiness.containsKey('priceRange'), isFalse);
      expect(productSchema.containsKey('offers'), isFalse);
    });

    test('does not add aggregateRating without real rating data', () {
      final store = StoreData(
        name: 'Nova Kuafor',
        description: 'Yerel kuafor vitrini',
        workingHours: '09:00-20:00',
      );

      final localBusiness = buildStoreSchemas(store);

      expect(localBusiness.containsKey('aggregateRating'), isFalse);
    });
  });
}
