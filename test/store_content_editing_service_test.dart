import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/store_content_editing_service.dart';

void main() {
  final service = const StoreContentEditingService();

  StoreData yeniData() => StoreData(kategori: 'Diğer', status: 'Açık');

  group('writeField', () {
    test('trim edilen ve edilmeyen alanlar farklı davranır', () {
      final data = yeniData();

      // 'whatsapp' trim'lenmez (orijinal davranış, controller'dan taşındı).
      service.writeField(data, 'whatsapp', '  0555 111 22 33  ');
      expect(data.whatsapp, '  0555 111 22 33  ');

      // 'telefon' trim'lenir.
      service.writeField(data, 'telefon', '  0555 999 88 77  ');
      expect(data.phone, '0555 999 88 77');
    });

    test('bool alan (puanGoster) doğru yazılır', () {
      final data = yeniData();
      service.writeField(data, 'puanGoster', true);
      expect(data.showStorefrontRating, isTrue);
    });

    test('isletmeAdi doğru alana yazar', () {
      final data = yeniData();
      service.writeField(data, 'isletmeAdi', 'Test İşletmesi');
      expect(data.name, 'Test İşletmesi');
    });

    test('bilinmeyen anahtar hata fırlatır — sessizce yutulmaz', () {
      final data = yeniData();
      expect(
        () => service.writeField(data, 'uydurma-alan', 'x'),
        throwsArgumentError,
      );
    });
  });

  group('writeAboutSection', () {
    test('tüm alanları yazar ve values en fazla 3 tutar', () {
      final data = yeniData();
      service.writeAboutSection(
        data,
        kicker: '  Hakkımızda  ',
        title: '  Biz Kimiz  ',
        body: 'Uzun bir hikaye',
        imageUrl: '  https://x.com/a.png  ',
        imageCaption: '  Ekip fotoğrafı  ',
        values: [
          StoreAboutValue(id: 'a1', title: '1'),
          StoreAboutValue(id: 'a2', title: '2'),
          StoreAboutValue(id: 'a3', title: '3'),
          StoreAboutValue(id: 'a4', title: '4'),
        ],
      );

      expect(data.aboutKicker, 'Hakkımızda');
      expect(data.aboutTitle, 'Biz Kimiz');
      expect(data.corporateBio, 'Uzun bir hikaye');
      expect(data.aboutImageUrl, 'https://x.com/a.png');
      expect(data.aboutImageCaption, 'Ekip fotoğrafı');
      expect(data.aboutValues, hasLength(3));
    });
  });

  group('writeGallerySectionMeta', () {
    test('kicker ve title trim edilerek yazılır', () {
      final data = yeniData();
      service.writeGallerySectionMeta(
        data,
        kicker: '  Galeri  ',
        title: '  Vitrin  ',
      );
      expect(data.gallerySectionKicker, 'Galeri');
      expect(data.gallerySectionTitle, 'Vitrin');
    });
  });

  group('writeFeaturedCampaign', () {
    test('tüm alanları trim ederek yazar', () {
      final data = yeniData();
      service.writeFeaturedCampaign(
        data,
        label: '  Yeni  ',
        title: '  Kampanya  ',
        description: '  Açıklama  ',
        priceText: '  100 TL  ',
        imageUrl: '  https://x.com/b.png  ',
      );
      expect(data.featuredBannerLabel, 'Yeni');
      expect(data.featuredBannerTitle, 'Kampanya');
      expect(data.featuredBannerDescription, 'Açıklama');
      expect(data.featuredBannerPriceText, '100 TL');
      expect(data.featuredBannerImageUrl, 'https://x.com/b.png');
    });
  });
}
