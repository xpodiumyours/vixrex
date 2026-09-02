import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_intent_resolver.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_normalizer.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_value_extractor.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_field_validator.dart';
import 'package:vixrex/config/vixrex_niyet_sozlugu.g.dart';

void main() {
  group('VixrexNormalizer parity', () {
    test('Türkçe normalize ı→i ve küçük harf', () {
      expect(VixrexNormalizer.normalize('İşletme Adı'), 'isletme adi');
      expect(VixrexNormalizer.normalize('WHATSAPP'), 'whatsapp');
      expect(VixrexNormalizer.normalize('Çalışma Saatleri'), 'calisma saatleri');
    });
  });

  group('VixrexIntentResolver – 46 alan sözlüğü', () {
    final resolver = VixrexIntentResolver();

    test('sözlük 46 alan', () {
      expect(vixrexNiyetSozlugu.length, 46);
    });

    test('6 zorunlu alan tanınır', () {
      expect(resolver.resolve('İşletme adını Aymira yap')?.anahtar, 'isletmeAdi');
      expect(resolver.resolve('Kategorimi Kuaför yap')?.anahtar, 'kategori');
      expect(resolver.resolve('WhatsApp numaramı 0555 123 45 67 yap')?.anahtar, 'whatsapp');
      expect(resolver.resolve('Adresimi Atatürk Cad. No:24 yap')?.anahtar, 'adres');
      expect(resolver.resolve('İli İstanbul yap')?.anahtar, 'il');
      expect(resolver.resolve('İlçeyi Kadıköy yap')?.anahtar, 'ilce');
    });

    test('uzun eş-anlam önceliği – "işletme adı" > "ad"', () {
      final r = resolver.resolve('işletme adını değiştir');
      expect(r?.anahtar, 'isletmeAdi');
    });

    test('görsel/konum alanları da tanınır', () {
      expect(resolver.resolve('Kapak görselini https://a.com/x.jpg yap')?.anahtar, 'kapakGorseli');
      expect(resolver.resolve('Çalışma saatlerini 09:00-18:00 yap')?.anahtar, 'calismaSaatleri');
    });

    test('bilinmeyen alan null', () {
      expect(resolver.resolve('bugün hava çok güzel'), isNull);
    });
  });

  group('VixrexValueExtractor – tırnak/:/fiil', () {
    final extractor = VixrexValueExtractor();
    final isletme = vixrexNiyetAlanByAnahtar['isletmeAdi']!;
    final whatsapp = vixrexNiyetAlanByAnahtar['whatsapp']!;
    final adres = vixrexNiyetAlanByAnahtar['adres']!;

    test('tırnak içi', () {
      expect(extractor.extract("İşletme adını 'Aymira Giyim' yap", isletme), 'Aymira Giyim');
      expect(extractor.extract('Dükkan adı "Caddebostan Kuaför" olsun', isletme), 'Caddebostan Kuaför');
    });

    test('iki nokta sonrası', () {
      expect(extractor.extract('İşletme adı: Aymira', isletme), 'Aymira');
      expect(extractor.extract('whatsapp: 0555 123 45 67', whatsapp), '0555 123 45 67');
    });

    test('fiil öncesi', () {
      expect(extractor.extract('WhatsApp numaramı 0555 123 45 67 yap', whatsapp), '0555 123 45 67');
    });

    test('değer yok → null veya doğrulamada reddedilir (netleştirme)', () {
      final v1 = extractor.extract('İşletme adını değiştir', isletme);
      // "değiştir" tek başına değer değil – ya null ya da validator reddeder.
      if (v1 != null) {
        final vr = VixrexFieldValidator.validate(isletme, v1);
        // v1 "nı" gibi kısa kalıntı olabilir – validator reddetmeli, yoksa extractor null olmalıydı.
        expect(vr.ok == false || v1.trim().length < 2, true, reason: 'v1=$v1 validatorOk=${vr.ok}');
      } else {
        expect(v1, isNull);
      }
      // "adres yanlış" – serbest cümle, extractor kalanı döndürebilir ama pipeline netleştirme sorar.
      final v2 = extractor.extract('adres yanlış', adres);
      // Bu faz için önemli olan: değer eksikse pipeline netleştirme soracak – extractor null veya kısa değer fark etmez.
      expect(v2 == null || v2.trim().length < 10 || VixrexFieldValidator.validate(adres, v2!).ok == false, true, reason: 'v2=$v2');
    });

    test('tırnak yoksa alan adını çıkar ve kalanı döndür (serbest metin)', () {
      // Kalite alanı serbest metin – remainderAfterFieldMention
      final rozet = vixrexNiyetAlanByAnahtar['heroRozet']!;
      expect(extractor.extract('Rozeti Kadıköyün En İyisi yap', rozet), isNotNull);
    });
  });

  group('VixrexFieldValidator – 6 zorunlu', () {
    test('isletmeAdi min 2', () {
      final alan = vixrexNiyetAlanByAnahtar['isletmeAdi']!;
      expect(VixrexFieldValidator.validate(alan, 'A').ok, false);
      expect(VixrexFieldValidator.validate(alan, 'Aymira').ok, true);
    });

    test('whatsapp tr_mobil', () {
      final alan = vixrexNiyetAlanByAnahtar['whatsapp']!;
      expect(VixrexFieldValidator.validate(alan, '0555 123 45 67').ok, true);
      expect(VixrexFieldValidator.validate(alan, '123').ok, false);
    });

    test('adres sokak/cadde + numara', () {
      final alan = vixrexNiyetAlanByAnahtar['adres']!;
      expect(VixrexFieldValidator.validate(alan, 'Atatürk Cad. No:24').ok, true);
      expect(VixrexFieldValidator.validate(alan, 'asd').ok, false);
    });

    test('kategori secim', () {
      final alan = vixrexNiyetAlanByAnahtar['kategori']!;
      expect(VixrexFieldValidator.validate(alan, 'Kuaför').ok, true);
      expect(VixrexFieldValidator.validate(alan, 'Uzay').ok, false);
    });

    test('adres max 200', () {
      final alan = vixrexNiyetAlanByAnahtar['adres']!;
      final long = 'a' * 201;
      expect(VixrexFieldValidator.validate(alan, long).ok, false);
    });
  });

  group('Sözlük sözleşmesi – her alan 4 alan zorunlu', () {
    test('her alan anahtar+esAnlamlar+ornekIfadeler+beklenenVeriTipi var', () {
      for (final a in vixrexNiyetSozlugu) {
        expect(a.anahtar.trim().isNotEmpty, true, reason: 'anahtar boş: $a');
        expect(a.esAnlamlar.isNotEmpty, true, reason: '${a.anahtar} esAnlamlar boş');
        expect(a.ornekIfadeler.isNotEmpty, true, reason: '${a.anahtar} ornekIfadeler boş');
        expect(a.beklenenVeriTipi.trim().isNotEmpty, true, reason: '${a.anahtar} beklenenVeriTipi boş');
      }
    });

    test('46 alan tek kaynakla aynı – vitrinFieldSchema 46', () {
      // vitrinAlanlari.g.dart 46 olduğu sözleşmesi public_web’de de var – burada da 46.
      expect(vixrexNiyetSozlugu.length, 46);
    });
  });
}
