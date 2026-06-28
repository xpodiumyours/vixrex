import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/models/store_data.dart';

void main() {
  group('StoreData legal acceptance round-trip', () {
    test('legal acknowledgement fields are serialized and restored', () {
      final acceptedAt = DateTime.utc(2026, 6, 28, 12);
      final store = StoreData(
        privacyNoticeAcknowledged: true,
        privacyNoticeAcknowledgedAt: acceptedAt,
        privacyNoticeVersion: 'privacy-v1',
        privacyNoticeHash: 'privacy-hash',
        termsAccepted: true,
        termsAcceptedAt: acceptedAt,
        termsVersion: 'terms-v1',
        termsHash: 'terms-hash',
        publicationConsentAccepted: true,
        publicationConsentAcceptedAt: acceptedAt,
        publicationConsentVersion: 'consent-v1',
        publicationConsentHash: 'consent-hash',
      );

      final restored = StoreData.fromJson(store.toJson());

      expect(restored.privacyNoticeAcknowledged, isTrue);
      expect(restored.privacyNoticeAcknowledgedAt, acceptedAt);
      expect(restored.privacyNoticeVersion, 'privacy-v1');
      expect(restored.termsAccepted, isTrue);
      expect(restored.termsVersion, 'terms-v1');
      expect(restored.publicationConsentAccepted, isTrue);
      expect(restored.publicationConsentVersion, 'consent-v1');
    });
  });

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

  group('StoreOffering and StoreData offerings round-trip', () {
    test('StoreOffering toJson ve fromJson round-trip', () {
      final offering = StoreOffering(
        id: 'off-1',
        title: 'Hizmet',
        description: 'Açıklama',
        price: '100 TL',
      );
      final json = offering.toJson();
      final decoded = StoreOffering.fromJson(json);

      expect(decoded.id, 'off-1');
      expect(decoded.title, 'Hizmet');
      expect(decoded.description, 'Açıklama');
      expect(decoded.price, '100 TL');
    });

    test('StoreData offerings serialization works correctly', () {
      final store = StoreData(
        name: 'Hizmet Vitrini',
        offerings: [
          StoreOffering(
            id: 'off-1',
            title: 'Hizmet 1',
            description: 'Açıklama 1',
            price: '100 TL',
          ),
        ],
      );

      final json = store.toJson();
      final decoded = StoreData.fromJson(json);

      expect(decoded.offerings, hasLength(1));
      expect(decoded.offerings.first.id, 'off-1');
      expect(decoded.offerings.first.title, 'Hizmet 1');
      expect(decoded.offerings.first.description, 'Açıklama 1');
      expect(decoded.offerings.first.price, '100 TL');
    });

    test(
      'StoreData.fromJson parses public Supabase fields (offerings, kategori, workingHours) and limits offerings',
      () {
        final dbPayload = {
          'name': 'Test Mağaza',
          'kategori': 'Giyim & Butik',
          'working_hours': '09:00 - 18:00',
          'offerings': [
            {
              'id': 'off-1',
              'title': 'Hizmet 1',
              'description': 'Açıklama 1',
              'price': '100 TL',
            },
            {
              'id': 'off-2',
              'title': '   ',
              'description': 'Açıklama 2',
              'price': '200 TL',
            },
            ...List.generate(
              7,
              (i) => {
                'id': 'off-${i + 3}',
                'title': 'Hizmet ${i + 3}',
                'description': 'Açıklama',
              },
            ),
          ],
        };

        final decoded = StoreData.fromJson(dbPayload);

        expect(decoded.kategori, 'Giyim & Butik');
        expect(decoded.workingHours, '09:00 - 18:00');
        expect(decoded.offerings, hasLength(6));
        expect(decoded.offerings.first.title, 'Hizmet 1');
        expect(decoded.offerings.any((o) => o.title.trim().isEmpty), isFalse);
      },
    );

    test(
      'StoreOffering has default durationMinutes and isBookable, and serializes/deserializes them',
      () {
        final offering = StoreOffering(
          id: 'off-test',
          title: 'Cilt Bakımı',
          durationMinutes: 45,
          isBookable: true,
        );

        final json = offering.toJson();
        expect(json['durationMinutes'], 45);
        expect(json['isBookable'], true);

        final decoded = StoreOffering.fromJson(json);
        expect(decoded.durationMinutes, 45);
        expect(decoded.isBookable, true);
      },
    );

    test('BookingSettings serializes and deserializes correctly', () {
      final settings = BookingSettings(
        isEnabled: true,
        capacity: 2,
        workingHours: {
          '1': {'start': '08:00', 'end': '20:00', 'active': true},
        },
      );

      final json = settings.toJson();
      expect(json['is_enabled'], true);
      expect(json['capacity'], 2);
      expect(json['working_hours']['1']['start'], '08:00');

      final decoded = BookingSettings.fromJson(json);
      expect(decoded.isEnabled, true);
      expect(decoded.capacity, 2);
      expect(decoded.workingHours['1']['start'], '08:00');
    });

    test('StoreData manages bookingSettings field', () {
      final store = StoreData(
        name: 'Güzellik Salonu',
        bookingSettings: BookingSettings(isEnabled: true, capacity: 3),
      );

      final json = store.toJson();
      expect(json['bookingSettings'], isNotNull);
      expect(json['bookingSettings']['is_enabled'], true);

      final decoded = StoreData.fromJson(json);
      expect(decoded.bookingSettings, isNotNull);
      expect(decoded.bookingSettings!.isEnabled, true);
      expect(decoded.bookingSettings!.capacity, 3);
    });
  });
}
