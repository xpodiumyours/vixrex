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
}
