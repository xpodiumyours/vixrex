import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/seo_service.dart';

void main() {
  group('buildStoreSchemas', () {
    test(
      'adds Organization and WebPage when physical location is incomplete',
      () {
        final store = StoreData(
          name: 'Nova Kuafor',
          description: 'Yerel kuafor vitrini',
          workingHours: '09:00 - 20:00',
          kategori: 'Güzellik',
        );

        final schemas = SeoService.buildStoreSchemas(
          store,
          publicUrl: 'https://vixrex-public.vercel.app/v/nova-kuafor',
        );

        final graph = schemas['@graph'] as List;
        final organization = graph[0] as Map<String, dynamic>;
        final webPage = graph[1] as Map<String, dynamic>;

        expect(organization['@type'], 'Organization');
        expect(organization['url'], 'https://vixrex-public.vercel.app/v/nova-kuafor');
        expect(organization.containsKey('openingHoursSpecification'), isFalse);
        expect(webPage['@type'], 'WebPage');
        expect(webPage['about']['@id'], contains('#business'));
      },
    );

    test('adds LocalBusiness details when address and coordinates exist', () {
      final store = StoreData(
        name: 'Nova Kuafor',
        description: 'Yerel kuafor vitrini',
        address: 'Moda Cd. No:12, Kadikoy, Istanbul',
        latitude: 40.9876,
        longitude: 29.0123,
        workingHours: '09:00 - 20:00',
      );

      final schemas = SeoService.buildStoreSchemas(store);
      final graph = schemas['@graph'] as List;
      final localBusiness = graph[0] as Map<String, dynamic>;

      expect(localBusiness['@type'], 'LocalBusiness');
      expect(localBusiness['hasMap'], contains('query=40.9876,29.0123'));
      expect(localBusiness['address']['addressCountry'], 'TR');
      expect(
        localBusiness['openingHoursSpecification'],
        isA<Map<String, dynamic>>(),
      );
    });

    test('does not emit product schemas on a multi-product vitrin page', () {
      final store = StoreData(
        name: 'Nova Kuafor',
        description: 'Yerel kuafor vitrini',
        products: [
          Product(id: 'p1', name: 'Ozel paket', price: 'Magazada sorunuz'),
        ],
      );

      final schemas = SeoService.buildStoreSchemas(store);
      final graph = schemas['@graph'] as List;
      expect(
        graph.where(
          (item) => (item as Map<String, dynamic>)['@type'] == 'Product',
        ),
        isEmpty,
      );
    });

    test('normalizes a valid WhatsApp number for structured data', () {
      final store = StoreData(name: 'Nova Kuafor', whatsapp: '0555 123 45 67');

      final schemas = SeoService.buildStoreSchemas(store);
      final graph = schemas['@graph'] as List;
      final organization = graph[0] as Map<String, dynamic>;

      expect(organization['telephone'], '+905551234567');
    });
  });
}
