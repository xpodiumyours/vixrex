import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/models/store_data.dart';

void main() {
  group('StoreData gallery fallback', () {
    test('galleryItems boşsa shelfImageUrl kapak olarak kullanılır', () {
      final store = StoreData(shelfImageUrl: 'https://example.com/cover.jpg');

      expect(store.displayGalleryItems, hasLength(1));
      expect(store.coverImageUrl, 'https://example.com/cover.jpg');
    });

    test(
      'galleryItems varsa shelfImageUrl yerine ilk galeri görseli kapak olur',
      () {
        final store = StoreData(
          shelfImageUrl: 'https://example.com/legacy.jpg',
          galleryItems: [
            StoreGalleryItem(
              id: '1',
              imageUrl: 'https://example.com/gallery-1.jpg',
              title: 'Kapak',
            ),
          ],
        );

        expect(store.displayGalleryItems, hasLength(1));
        expect(store.coverImageUrl, 'https://example.com/gallery-1.jpg');
      },
    );

    test('galleryItems en fazla 12 görsel döndürür', () {
      final store = StoreData(
        galleryItems: List.generate(
          14,
          (index) => StoreGalleryItem(
            id: '$index',
            imageUrl: 'https://example.com/gallery-$index.jpg',
          ),
        ),
      );

      expect(store.displayGalleryItems, hasLength(12));
    });

    test('dummy örnek vitrin dolu galeri ve mağaza bilgileriyle gelir', () {
      final store = StoreData.dummy();

      expect(store.name, 'Aymira Giyim');
      expect(store.businessType, 'Kadın giyim / butik');
      expect(store.whatsapp, isNotEmpty);
      expect(store.instagram, isNotEmpty);
      expect(store.address, isNotEmpty);
      expect(store.displayGalleryItems, hasLength(4));
      expect(store.coverImageUrl, startsWith('https://images.unsplash.com/'));
    });
  });

  group('StoreData geolocation support', () {
    test('toJson ve fromJson konum verilerini doğru taşır', () {
      final consentTime = DateTime.utc(2026, 6, 3, 12, 0, 0);
      final store = StoreData(
        name: 'Konumlu Mağaza',
        latitude: 41.0082,
        longitude: 28.9784,
        locationAccuracyMeters: 10.5,
        locationConsentAt: consentTime,
        locationSource: 'geolocator',
      );

      final json = store.toJson();
      expect(json['latitude'], 41.0082);
      expect(json['longitude'], 28.9784);
      expect(json['locationAccuracyMeters'], 10.5);
      expect(json['locationConsentAt'], consentTime.toIso8601String());
      expect(json['locationSource'], 'geolocator');

      final fromJsonStore = StoreData.fromJson(json);
      expect(fromJsonStore.latitude, 41.0082);
      expect(fromJsonStore.longitude, 28.9784);
      expect(fromJsonStore.locationAccuracyMeters, 10.5);
      expect(fromJsonStore.locationConsentAt, consentTime);
      expect(fromJsonStore.locationSource, 'geolocator');
    });
  });
}
