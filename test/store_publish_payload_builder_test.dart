import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/store_publish_service.dart';

void main() {
  const builder = StorePublishPayloadBuilder();

  group('StorePublishPayloadBuilder slug', () {
    test('Türkçe karakterleri ve boşlukları güvenli slug değerine çevirir', () {
      expect(
        builder.generateSlug('  Aymira Giyim Şişli  '),
        'aymira-giyim-sisli',
      );
      expect(
        builder.generateSlug('Çanta & Aksesuar / Özel'),
        'canta-aksesuar-ozel',
      );
      expect(builder.generateSlug(''), 'magazaniz');
      expect(builder.generateSlug('!!!'), 'magazaniz');
    });
  });

  group('StorePublishPayloadBuilder payload', () {
    test('store update payload alanlarını trimleyerek hazırlar', () {
      final data = StoreData(
        name: '  Aymira Giyim  ',
        businessType: ' Butik ',
        description: '  Yeni sezon ürünler  ',
        corporateBio: '  Mahalle butiği  ',
        whatsapp: '  0555 111 22 33  ',
        instagram: '  @aymira  ',
        website: '  https://example.com  ',
        address: '  Kadıköy, İstanbul  ',
        theme: ' Premium ',
        status: ' Açık ',
        referencesLink: '  https://example.com/referans  ',
        galleryItems: [
          StoreGalleryItem(
            id: '  cover  ',
            imageUrl: '  https://example.com/cover.jpg  ',
            title: '  Kapak  ',
            description: '  Ana reyon  ',
          ),
        ],
        marketplaceLinks: [
          MarketplaceLink(
            id: '1',
            platform: ' Trendyol ',
            url: ' https://trendyol.com/magaza ',
          ),
        ],
        privacyNoticeAcknowledged: true,
        privacyNoticeVersion: 'privacy-v1',
        privacyNoticeHash: 'privacy-hash',
        termsAccepted: true,
        termsVersion: 'terms-v1',
        termsHash: 'terms-hash',
        publicationConsentAccepted: true,
        publicationConsentVersion: 'consent-v1',
        publicationConsentHash: 'consent-hash',
      );

      final payload = builder.toStoreUpdateMap(data);

      expect(payload['name'], 'Aymira Giyim');
      expect(payload['business_type'], 'Butik');
      expect(payload['description'], 'Yeni sezon ürünler');
      expect(payload['corporate_bio'], 'Mahalle butiği');
      expect(payload['whatsapp'], '0555 111 22 33');
      expect(payload['instagram'], '@aymira');
      expect(payload['website'], 'https://example.com');
      expect(payload['address'], 'Kadıköy, İstanbul');
      expect(payload['theme'], 'Premium');
      expect(payload['status'], 'Açık');
      expect(payload['references_link'], 'https://example.com/referans');
      expect(payload['shelf_image_url'], 'https://example.com/cover.jpg');
      expect(payload['is_published'], isTrue);
      expect(payload['privacy_notice_acknowledged'], isTrue);
      expect(payload['privacy_notice_version'], 'privacy-v1');
      expect(payload['terms_accepted'], isTrue);
      expect(payload['explicit_consent_given'], isTrue);
      expect(payload['publication_consent_version'], 'consent-v1');
    });

    test('insert payload slug ve edit token ekler', () {
      final payload = builder.toStoreInsertMap(
        StoreData(name: 'Aymira'),
        'aymira',
        'edit-token',
      );

      expect(payload['slug'], 'aymira');
      expect(payload['edit_token'], 'edit-token');
      expect(payload['is_published'], isTrue);
    });

    test('store update payload konum verilerini ekler', () {
      final consentTime = DateTime.utc(2026, 6, 3, 12, 0, 0);
      final data = StoreData(
        name: 'Aymira',
        latitude: 41.0082,
        longitude: 28.9784,
        locationAccuracyMeters: 10.5,
        locationConsentAt: consentTime,
        locationSource: 'geolocator',
      );

      final payload = builder.toStoreUpdateMap(data);

      expect(payload['latitude'], 41.0082);
      expect(payload['longitude'], 28.9784);
      expect(payload['location_accuracy_meters'], 10.5);
      expect(payload['location_consent_at'], consentTime.toIso8601String());
      expect(payload['location_source'], 'geolocator');
    });
  });

  group('StorePublishPayloadBuilder gallery items', () {
    test('galeri öğelerini trimler ve en fazla 12 öğe döndürür', () {
      final data = StoreData(
        galleryItems: List.generate(
          14,
          (index) => StoreGalleryItem(
            id: ' $index ',
            imageUrl: ' https://example.com/$index.jpg ',
            title: ' Başlık $index ',
            description: ' Açıklama $index ',
          ),
        ),
      );

      final items = builder.galleryItemsToJson(data);

      expect(items, hasLength(12));
      expect(items.first, {
        'id': '0',
        'imageUrl': 'https://example.com/0.jpg',
        'title': 'Başlık 0',
        'description': 'Açıklama 0',
      });
    });

    test('galeri boşsa eski shelfImageUrl fallback olarak gönderilir', () {
      final data = StoreData(shelfImageUrl: ' https://example.com/legacy.jpg ');

      final items = builder.galleryItemsToJson(data);

      expect(items, [
        {
          'id': 'legacy-shelf-image',
          'imageUrl': 'https://example.com/legacy.jpg',
          'title': '',
          'description': '',
        },
      ]);
    });
  });

  group('StorePublishPayloadBuilder marketplace links', () {
    test('sadece platform ve url dolu marketplace linklerini gönderir', () {
      final data = StoreData(
        marketplaceLinks: [
          MarketplaceLink(
            id: '1',
            platform: ' Trendyol ',
            url: ' https://trendyol.com/magaza ',
            subtitle: ' Alt Başlık ',
          ),
          MarketplaceLink(id: '2', platform: ' Hepsiburada ', url: ''),
          MarketplaceLink(id: '3', platform: '', url: 'https://example.com'),
        ],
      );

      final links = builder.marketplaceLinksToJson(data);

      expect(links, [
        {
          'platform': 'Trendyol',
          'url': 'https://trendyol.com/magaza',
          'subtitle': 'Alt Başlık',
        },
      ]);
    });
  });

  group('StorePublishPayloadBuilder offerings', () {
    test(
      'hizmetleri trimler, bos basliklari atlar ve en fazla 6 adet dondurur',
      () {
        final data = StoreData(
          offerings: [
            StoreOffering(
              id: '1',
              title: ' Kesim ',
              description: ' Hizmet ',
              price: ' 100 TL ',
            ),
            StoreOffering(id: '2', title: '', description: '', price: ''),
            ...List.generate(
              7,
              (i) => StoreOffering(
                id: 'offering-${i + 3}',
                title: 'Hizmet ${i + 3}',
                description: 'Açıklama',
              ),
            ),
          ],
        );

        final items = builder.offeringsToJson(data);

        expect(items, hasLength(6));
        expect(items.first, {
          'id': '1',
          'title': 'Kesim',
          'description': 'Hizmet',
          'price': '100 TL',
          'durationMinutes': 30,
          'isBookable': false,
        });
      },
    );
  });

  group('StorePublishPayloadBuilder products', () {
    test('ürünlere SEO slug ve kaynak alanlarını ekler', () {
      final data = StoreData(
        products: [
          Product(
            id: ' ig-1789 ',
            name: ' Şık Triko Hırka ',
            price: ' 750 TL ',
            description: ' Yeni sezon triko ',
            category: ' Triko ',
            source: ' instagram ',
            sourceMediaId: ' 1789 ',
            sourcePermalink: ' https://instagram.com/p/demo ',
            importedAt: ' 2026-06-26T10:00:00Z ',
          ),
        ],
      );

      final products = builder.productsToJson(data);

      expect(products, [
        {
          'id': 'ig-1789',
          'name': 'Şık Triko Hırka',
          'price': '750 TL',
          'description': 'Yeni sezon triko',
          'imagePath': null,
          'imageUrls': [],
          'categoryId': '',
          'category': 'Triko',
          'stockStatus': 'Mevcut',
          'isVisible': true,
          'slug': 'sik-triko-hirka-ig-1789',
          'source': 'instagram',
          'sourceMediaId': '1789',
          'sourcePermalink': 'https://instagram.com/p/demo',
          'importedAt': '2026-06-26T10:00:00Z',
        },
      ]);
    });
  });
}
