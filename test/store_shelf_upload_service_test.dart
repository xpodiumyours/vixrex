import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/services/store_shelf_upload_service.dart';

void main() {
  const service = StoreShelfUploadService();

  group('StoreShelfUploadService.sanitizeSlug', () {
    test('normal slug geçtiği gibi döner', () {
      expect(service.sanitizeSlug('my-store'), 'my-store');
    });

    test('baştaki ve sondaki slash kaldırılır', () {
      expect(service.sanitizeSlug('/my-store/'), 'my-store');
    });

    test('icerideki slash korunur', () {
      expect(service.sanitizeSlug('my-store/gallery'), 'my-store/gallery');
    });

    test('boş string fallback döner', () {
      expect(service.sanitizeSlug(''), 'magazaniz');
    });

    test('sadece whitespace fallback döner', () {
      expect(service.sanitizeSlug('   '), 'magazaniz');
    });

    test('sadece slash fallback döner', () {
      expect(service.sanitizeSlug('///'), 'magazaniz');
    });

    test('whitespace trim edilir', () {
      expect(service.sanitizeSlug('  my-store  '), 'my-store');
    });

    test('slug/products/id formatı korunur', () {
      expect(
        service.sanitizeSlug('butik-aymira/products/p1'),
        'butik-aymira/products/p1',
      );
    });
    test('buyuk harf ve bosluklar storage policy uyumlu hale gelir', () {
      expect(
        service.sanitizeSlug(' Butik Aymira / Products / P1 '),
        'butik-aymira/products/p1',
      );
    });

    test('gecersiz karakterler temizlenir', () {
      expect(
        service.sanitizeSlug('magaza++deneme/gallery item'),
        'magaza-deneme/gallery-item',
      );
    });
  });

  group('StoreShelfUploadService.sanitizeExtension', () {
    test('jpg olduğu gibi döner', () {
      expect(service.sanitizeExtension('jpg'), 'jpg');
    });

    test('png olduğu gibi döner', () {
      expect(service.sanitizeExtension('png'), 'png');
    });

    test('webp olduğu gibi döner', () {
      expect(service.sanitizeExtension('webp'), 'webp');
    });

    test('jpeg → jpg dönüşümü yapılır', () {
      expect(service.sanitizeExtension('jpeg'), 'jpg');
    });

    test('JPEG büyük harf → jpg', () {
      expect(service.sanitizeExtension('JPEG'), 'jpg');
    });

    test('JPG büyük harf → jpg', () {
      expect(service.sanitizeExtension('JPG'), 'jpg');
    });

    test('.jpg nokta ön eki kaldırılır', () {
      expect(service.sanitizeExtension('.jpg'), 'jpg');
    });

    test('.JPEG nokta ve büyük harf normalleştirilir', () {
      expect(service.sanitizeExtension('.JPEG'), 'jpg');
    });

    test('geçersiz uzantı fallback jpg döner', () {
      expect(service.sanitizeExtension('gif'), 'jpg');
    });

    test('boş string fallback jpg döner', () {
      expect(service.sanitizeExtension(''), 'jpg');
    });

    test('bmp fallback jpg döner', () {
      expect(service.sanitizeExtension('bmp'), 'jpg');
    });
  });
}
