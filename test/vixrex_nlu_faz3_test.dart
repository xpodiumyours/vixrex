import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/config/vixrex_niyet_sozlugu.g.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_executor.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_field_validator.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_intent_resolver.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_nlu_pipeline.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_value_extractor.dart';

void main() {
  group('Faz 3 – 32 isteğe-bağlı alan sözlük ve niyet', () {
    final resolver = VixrexIntentResolver();
    const istegeBagli = [
      'kisaTanitim',
      'konumMetni',
      'isletmeTuru',
      'telefon',
      'eposta',
      'haritaEtiketi',
      'instagram',
      'website',
      'enlem',
      'boylam',
      'kategoriBolumBaslik',
      'urunBolumBaslik',
      'bantEtiket',
      'bantBaslik',
      'bantAciklama',
      'bantGorsel',
      'bantFiyat',
      'hakkindaUstBaslik',
      'hakkindaGorsel',
      'hakkindaGorselAlt',
      'galeriUstBaslik',
      'galeriBaslik',
      'galeriAksiyonMetni',
      'galeriAksiyonLinki',
      'blogUstBaslik',
      'blogBaslik',
      'sssUstBaslik',
      'sssBaslik',
      'sssAciklama',
      'puanGoster',
      'yolTarifiGoster',
      'referansLinki',
    ];

    test('32 alan sözlükte var', () {
      for (final k in istegeBagli) {
        expect(vixrexNiyetAlanByAnahtar.containsKey(k), true, reason: k);
      }
    });

    test('32 alan niyetle tanınır (örnekler)', () {
      expect(
        resolver.resolve('Kısa tanıtımı Merhaba yap')?.anahtar,
        'kisaTanitim',
      );
      expect(
        resolver.resolve('Konum metnini Kadıköy yap')?.anahtar,
        'konumMetni',
      );
      expect(
        resolver.resolve('İşletme türünü Erkek Kuaförü yap')?.anahtar,
        'isletmeTuru',
      );
      expect(
        resolver.resolve('Telefonu 0212 123 45 67 yap')?.anahtar,
        'telefon',
      );
      expect(resolver.resolve('E-postamı test@a.com yap')?.anahtar, 'eposta');
      expect(
        resolver.resolve('Harita etiketini Çarşı içi yap')?.anahtar,
        'haritaEtiketi',
      );
      expect(resolver.resolve('Instagramı aymira yap')?.anahtar, 'instagram');
      expect(
        resolver.resolve('Web sitemi https://a.com yap')?.anahtar,
        'website',
      );
      expect(resolver.resolve('Enlemi 41.0 yap')?.anahtar, 'enlem');
      expect(resolver.resolve('Boylamı 29.0 yap')?.anahtar, 'boylam');
      expect(resolver.resolve('Puanı göster')?.anahtar, 'puanGoster');
      expect(
        resolver.resolve('Yol tarifini gizle')?.anahtar,
        'yolTarifiGoster',
      );
    });

    test('çok-alanlı resolveAll', () {
      final all = resolver.resolveAll(
        'telefonu 02121234567 yap, instagramı aymira yap',
      );
      final keys = all.map((e) => e.anahtar).toSet();
      expect(keys.contains('telefon'), true);
      expect(keys.contains('instagram'), true);
    });
  });

  group('Faz 3 – validator kalan tipler', () {
    test('eposta, telefon, url, sayi, acikKapali', () {
      expect(
        VixrexFieldValidator.validate(
          vixrexNiyetAlanByAnahtar['eposta']!,
          'test@a.com',
        ).ok,
        true,
      );
      expect(
        VixrexFieldValidator.validate(
          vixrexNiyetAlanByAnahtar['eposta']!,
          'not-email',
        ).ok,
        false,
      );
      expect(
        VixrexFieldValidator.validate(
          vixrexNiyetAlanByAnahtar['telefon']!,
          '0212 123 45 67',
        ).ok,
        true,
      );
      expect(
        VixrexFieldValidator.validate(
          vixrexNiyetAlanByAnahtar['website']!,
          'https://a.com',
        ).ok,
        true,
      );
      expect(
        VixrexFieldValidator.validate(
          vixrexNiyetAlanByAnahtar['website']!,
          'ftp://a.com',
        ).ok,
        false,
      );
      expect(
        VixrexFieldValidator.validate(
          vixrexNiyetAlanByAnahtar['enlem']!,
          '41.0',
        ).ok,
        true,
      );
      expect(
        VixrexFieldValidator.validate(
          vixrexNiyetAlanByAnahtar['enlem']!,
          '100',
        ).ok,
        false,
      );
      expect(
        VixrexFieldValidator.validate(
          vixrexNiyetAlanByAnahtar['puanGoster']!,
          'açık',
        ).ok,
        true,
      );
      expect(
        VixrexFieldValidator.validate(
          vixrexNiyetAlanByAnahtar['puanGoster']!,
          'göster',
        ).ok,
        true,
      );
      expect(
        VixrexFieldValidator.validate(
          vixrexNiyetAlanByAnahtar['yolTarifiGoster']!,
          'gizle',
        ).ok,
        true,
      );
    });

    test('uzun metin max', () {
      expect(
        VixrexFieldValidator.validate(
          vixrexNiyetAlanByAnahtar['kisaTanitim']!,
          'a' * 301,
        ).ok,
        false,
      );
      expect(
        VixrexFieldValidator.validate(
          vixrexNiyetAlanByAnahtar['bantAciklama']!,
          'a' * 201,
        ).ok,
        false,
      );
      expect(
        VixrexFieldValidator.validate(
          vixrexNiyetAlanByAnahtar['sssAciklama']!,
          'a' * 201,
        ).ok,
        false,
      );
    });
  });

  group('Faz 3 – executor kalan 32', () {
    test(
      'kisaTanitim, konumMetni, isletmeTuru, haritaEtiketi, bant*, hakkindaUstBaslik/Gorsel, galeri*, blog*, sss*, puan/yol, referans',
      () {
        final c = StoreEditorController(initialData: StoreData());
        const exec = VixrexExecutor();
        expect(
          exec.execute(
            controller: c,
            alan: vixrexNiyetAlanByAnahtar['kisaTanitim']!,
            deger: 'Tanitim',
          ),
          true,
        );
        expect(c.data.description, 'Tanitim');
        expect(
          exec.execute(
            controller: c,
            alan: vixrexNiyetAlanByAnahtar['konumMetni']!,
            deger: 'Kadıköy',
          ),
          true,
        );
        expect(c.data.heroLocationText, 'Kadıköy');
        expect(
          exec.execute(
            controller: c,
            alan: vixrexNiyetAlanByAnahtar['isletmeTuru']!,
            deger: 'Erkek',
          ),
          true,
        );
        expect(c.data.businessType, 'Erkek');
        expect(
          exec.execute(
            controller: c,
            alan: vixrexNiyetAlanByAnahtar['haritaEtiketi']!,
            deger: 'Çarşı',
          ),
          true,
        );
        expect(c.data.mapLabel, 'Çarşı');
        expect(
          exec.execute(
            controller: c,
            alan: vixrexNiyetAlanByAnahtar['bantEtiket']!,
            deger: 'Etiket',
          ),
          true,
        );
        expect(c.data.featuredBannerLabel, 'Etiket');
        expect(
          exec.execute(
            controller: c,
            alan: vixrexNiyetAlanByAnahtar['bantBaslik']!,
            deger: 'Baslik',
          ),
          true,
        );
        expect(c.data.featuredBannerTitle, 'Baslik');
        expect(
          exec.execute(
            controller: c,
            alan: vixrexNiyetAlanByAnahtar['bantAciklama']!,
            deger: 'Acik',
          ),
          true,
        );
        expect(c.data.featuredBannerDescription, 'Acik');
        expect(
          exec.execute(
            controller: c,
            alan: vixrexNiyetAlanByAnahtar['bantGorsel']!,
            deger: 'https://a.com/b.jpg',
          ),
          true,
        );
        expect(c.data.featuredBannerImageUrl, 'https://a.com/b.jpg');
        expect(
          exec.execute(
            controller: c,
            alan: vixrexNiyetAlanByAnahtar['hakkindaUstBaslik']!,
            deger: 'Ust',
          ),
          true,
        );
        expect(c.data.aboutKicker, 'Ust');
        expect(
          exec.execute(
            controller: c,
            alan: vixrexNiyetAlanByAnahtar['hakkindaGorsel']!,
            deger: 'https://a.com/h.jpg',
          ),
          true,
        );
        expect(c.data.aboutImageUrl, 'https://a.com/h.jpg');
        expect(
          exec.execute(
            controller: c,
            alan: vixrexNiyetAlanByAnahtar['galeriUstBaslik']!,
            deger: 'G Ust',
          ),
          true,
        );
        expect(c.data.gallerySectionKicker, 'G Ust');
        expect(
          exec.execute(
            controller: c,
            alan: vixrexNiyetAlanByAnahtar['puanGoster']!,
            deger: true,
          ),
          true,
        );
        expect(c.data.showStorefrontRating, true);
        expect(
          exec.execute(
            controller: c,
            alan: vixrexNiyetAlanByAnahtar['enlem']!,
            deger: 41.0,
          ),
          true,
        );
        expect(c.data.latitude, 41.0);
      },
    );
  });

  group('Faz 3 – pipeline çok-alanlı', () {
    test('iki alan tek cümlede', () async {
      SharedPreferences.setMockInitialValues({});
      final pipeline = VixrexNluPipeline();
      final c = StoreEditorController(initialData: StoreData());
      final result = await pipeline.handle(
        input: 'telefonu 0212 123 45 67 yap, instagramı aymira yap',
        controller: c,
        onValidate: (alan, ham) async {
          final v = VixrexFieldValidator.validate(alan, ham);
          return (ok: v.ok, hata: v.hata, normalizedDeger: v.normalizedDeger);
        },
      );
      expect(result.outcome, VixrexNluPipelineOutcome.handled);
      expect(
        c.data.phone.replaceAll(RegExp(r'[^0-9]'), '').contains('2121234567'),
        true,
      );
      expect(c.data.instagram.contains('aymira'), true);
    });

    test('değer ayıklama her alan için kendi değerini alır', () {
      final ex = VixrexValueExtractor();
      final vPhone = ex.extract(
        'telefonu 0212 123 45 67 yap, instagramı @aymira yap',
        vixrexNiyetAlanByAnahtar['telefon']!,
      );
      expect(
        vPhone?.replaceAll(RegExp(r'[^0-9]'), '').contains('2121234567'),
        true,
        reason: 'vPhone=$vPhone',
      );
      final v2 = ex.extract(
        'instagramı @aymira yap',
        vixrexNiyetAlanByAnahtar['instagram']!,
      );
      expect(v2 != null && v2.contains('aymira'), true, reason: 'v2=$v2');
    });
  });
}
