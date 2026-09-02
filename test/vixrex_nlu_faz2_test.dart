import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/config/vixrex_niyet_sozlugu.g.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_executor.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_field_validator.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_intent_resolver.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_value_extractor.dart';

void main() {
  group('Faz 2 – 8 kalite alan sözlük ve niyet', () {
    final resolver = VixrexIntentResolver();
    const kaliteAnahtarlar = {
      'heroRozet',
      'logo',
      'kapakGorseli',
      'mahalle',
      'calismaSaatleri',
      'haritaLinki',
      'hakkindaBaslik',
      'hakkindaMetin',
    };

    test('8 kalite alan sözlükte var', () {
      for (final k in kaliteAnahtarlar) {
        expect(vixrexNiyetAlanByAnahtar.containsKey(k), true, reason: k);
      }
    });

    test('kalite alanlar niyetle tanınır', () {
      expect(resolver.resolve('Rozeti Kadıköyün En İyisi yap')?.anahtar, 'heroRozet');
      expect(resolver.resolve('Logoyu https://a.com/logo.png yap')?.anahtar, 'logo');
      expect(resolver.resolve('Kapak görselini https://a.com/cap.jpg yap')?.anahtar, 'kapakGorseli');
      expect(resolver.resolve('Mahalleyi Caddebostan yap')?.anahtar, 'mahalle');
      expect(resolver.resolve('Çalışma saatlerini 09:00-18:00 yap')?.anahtar, 'calismaSaatleri');
      expect(resolver.resolve('Harita linkini https://maps.google.com/?q=test yap')?.anahtar, 'haritaLinki');
      expect(resolver.resolve('Hakkımızda başlığını Biz Kimiz yap')?.anahtar, 'hakkindaBaslik');
      expect(resolver.resolve('Hakkımızda yazısını Merhaba biz 10 yıldır yapıyoruz yap')?.anahtar, 'hakkindaMetin');
    });

    test('kalite alan değer ayıklama', () {
      final extractor = VixrexValueExtractor();
      expect(
        extractor.extract('Rozeti \'Kadıköyün En İyisi\' yap', vixrexNiyetAlanByAnahtar['heroRozet']!),
        'Kadıköyün En İyisi',
      );
      expect(
        extractor.extract('Mahalleyi Caddebostan yap', vixrexNiyetAlanByAnahtar['mahalle']!),
        'Caddebostan',
      );
      expect(
        extractor.extract('Harita linkini https://maps.google.com/?q=test yap', vixrexNiyetAlanByAnahtar['haritaLinki']!),
        'https://maps.google.com/?q=test',
      );
      expect(
        extractor.extract('Çalışma saatlerini 09:00-18:00 yap', vixrexNiyetAlanByAnahtar['calismaSaatleri']!),
        '09:00-18:00',
      );
      expect(
        extractor.extract('Logoyu https://a.com/logo.png yap', vixrexNiyetAlanByAnahtar['logo']!),
        'https://a.com/logo.png',
      );
    });
  });

  group('Faz 2 – validator kalite', () {
    test('heroRozet max 60', () {
      final alan = vixrexNiyetAlanByAnahtar['heroRozet']!;
      expect(VixrexFieldValidator.validate(alan, 'a' * 61).ok, false);
      expect(VixrexFieldValidator.validate(alan, 'Kısa rozet').ok, true);
    });

    test('mahalle max 60', () {
      final alan = vixrexNiyetAlanByAnahtar['mahalle']!;
      expect(VixrexFieldValidator.validate(alan, 'a' * 61).ok, false);
      expect(VixrexFieldValidator.validate(alan, 'Caddebostan').ok, true);
    });

    test('haritaLinki url', () {
      final alan = vixrexNiyetAlanByAnahtar['haritaLinki']!;
      expect(VixrexFieldValidator.validate(alan, 'https://maps.google.com').ok, true);
      expect(VixrexFieldValidator.validate(alan, 'not-a-url').ok, false);
    });

    test('logo gorsel url', () {
      final alan = vixrexNiyetAlanByAnahtar['logo']!;
      expect(VixrexFieldValidator.validate(alan, 'https://a.com/logo.png').ok, true);
      expect(VixrexFieldValidator.validate(alan, 'ftp://a.com/logo.png').ok, false);
    });

    test('hakkindaBaslik max 90, hakkindaMetin max 1200', () {
      expect(VixrexFieldValidator.validate(vixrexNiyetAlanByAnahtar['hakkindaBaslik']!, 'a' * 91).ok, false);
      expect(VixrexFieldValidator.validate(vixrexNiyetAlanByAnahtar['hakkindaMetin']!, 'a' * 1201).ok, false);
      expect(VixrexFieldValidator.validate(vixrexNiyetAlanByAnahtar['hakkindaBaslik']!, 'Biz Kimiz').ok, true);
    });
  });

  group('Faz 2 – executor kalite', () {
    test('mahalle, haritaLinki, calismaSaatleri, heroRozet, hakkindaMetin/Baslik, logo, kapakGorseli yazılır', () {
      final c = StoreEditorController(initialData: StoreData());
      const exec = VixrexExecutor();

      expect(exec.execute(controller: c, alan: vixrexNiyetAlanByAnahtar['mahalle']!, deger: 'Caddebostan'), true);
      expect(c.data.neighborhoodName, 'Caddebostan');

      expect(exec.execute(controller: c, alan: vixrexNiyetAlanByAnahtar['haritaLinki']!, deger: 'https://maps.google.com'), true);
      expect(c.data.googleBusinessLink, 'https://maps.google.com');

      expect(exec.execute(controller: c, alan: vixrexNiyetAlanByAnahtar['calismaSaatleri']!, deger: '09:00-18:00'), true);
      expect(c.data.workingHours, '09:00-18:00');

      expect(exec.execute(controller: c, alan: vixrexNiyetAlanByAnahtar['heroRozet']!, deger: 'En İyi'), true);
      expect(c.data.heroBadge, 'En İyi');

      expect(exec.execute(controller: c, alan: vixrexNiyetAlanByAnahtar['hakkindaBaslik']!, deger: 'Biz Kimiz'), true);
      expect(c.data.aboutTitle, 'Biz Kimiz');

      expect(exec.execute(controller: c, alan: vixrexNiyetAlanByAnahtar['hakkindaMetin']!, deger: 'Hikaye'), true);
      expect(c.data.corporateBio, 'Hikaye');

      expect(exec.execute(controller: c, alan: vixrexNiyetAlanByAnahtar['logo']!, deger: 'https://a.com/l.png'), true);
      expect(c.data.logoUrl, 'https://a.com/l.png');

      expect(exec.execute(controller: c, alan: vixrexNiyetAlanByAnahtar['kapakGorseli']!, deger: 'https://a.com/c.jpg'), true);
      expect(c.data.shelfImageUrl, 'https://a.com/c.jpg');
    });

    test('il/ilce özel akış – execute false', () {
      final c = StoreEditorController(initialData: StoreData());
      const exec = VixrexExecutor();
      expect(exec.execute(controller: c, alan: vixrexNiyetAlanByAnahtar['il']!, deger: 'İstanbul'), false);
      expect(exec.execute(controller: c, alan: vixrexNiyetAlanByAnahtar['ilce']!, deger: 'Kadıköy'), false);
    });
  });
}
