import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/config/vixrex_niyet_sozlugu.g.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_field_validator.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_intent_resolver.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_value_extractor.dart';

String gecerliHamDeger(String anahtar, String tip) {
  if (anahtar == 'whatsapp') return '0555 123 45 67';
  if (tip == 'telefon') return '0212 555 44 33';
  if (tip == 'eposta') return 'info@aymira.com';
  if (anahtar == 'adres') return 'Atatürk Cad. No:24';
  if (anahtar == 'kategori') return 'Teknik Servis';
  if (anahtar == 'enlem') return '41.025';
  if (anahtar == 'boylam') return '29.05';
  if (anahtar == 'galeriAksiyonLinki') return '#galeri';
  if (tip == 'url' || tip == 'gorsel') return 'https://example.com/deger';
  if (anahtar == 'calismaSaatleri') return '09:00-18:00';
  if (anahtar == 'instagram') return 'aymiragiyim';
  return 'Örnek Değer';
}

const sabitBeklenen = <String, String>{
  "İşletme adını 'Aymira Giyim' yap": 'Aymira Giyim',
  "Rozeti 'Kadıköy'ün En İyisi' yap": "Kadıköy'ün En İyisi",
  "Konum metnini 'Kadıköy, İstanbul' yap": 'Kadıköy, İstanbul',
  'Kategorimi Kuaför yap': 'Kuaför',
  "İşletme türünü 'Erkek Kuaförü' yap": 'Erkek Kuaförü',
  'WhatsApp numaramı 0555 123 45 67 yap': '0555 123 45 67',
  "Adresimi 'Atatürk Cad. No:24' yap": 'Atatürk Cad. No:24',
  'İli İstanbul yap': 'İstanbul',
  'İlçeyi Kadıköy yap': 'Kadıköy',
  'Mahalleyi Caddebostan yap': 'Caddebostan',
  "Harita etiketini 'Çarşı içi, otopark var' yap": 'Çarşı içi, otopark var',
  "Çalışma saatlerini '09:00-18:00' yap": '09:00-18:00',
  'Instagramı aymiragiyim yap': 'aymiragiyim',
  'Web sitemi https://aymira.com yap': 'https://aymira.com',
  'Enlemi 41.025 yap': '41.025',
  'Boylamı 29.05 yap': '29.05',
  "Kampanya etiketini 'Bu haftaya özel' yap": 'Bu haftaya özel',
  "Kampanya fiyatını '499 TL' yap": '499 TL',
};

void main() {
  const resolver = VixrexIntentResolver();
  const extractor = VixrexValueExtractor();

  group('Vixrex mevcut 127 cümle — Flutter niyet + değer + doğrulama', () {
    test('sözlükteki kayıtlı cümle sayısı 127', () {
      final toplam = vixrexNiyetSozlugu.fold<int>(
        0,
        (n, alan) => n + alan.ornekIfadeler.length,
      );
      expect(toplam, 127);
    });

    test('{deger} içeren her kalıp değeri eksiksiz ayırır ve doğrular', () {
      final hatalar = <String>[];
      for (final alan in vixrexNiyetSozlugu) {
        for (final ornek in alan.ornekIfadeler) {
          if (!ornek.contains('{deger}')) continue;
          final beklenen = gecerliHamDeger(alan.anahtar, alan.tip);
          final input = ornek.replaceAll('{deger}', beklenen);
          final bulunan = resolver.resolve(input);
          final ham =
              bulunan == null ? null : extractor.extract(input, bulunan);
          final dogrulama =
              ham == null ? null : VixrexFieldValidator.validate(alan, ham);
          if (bulunan?.anahtar != alan.anahtar ||
              ham != beklenen ||
              dogrulama?.ok != true) {
            hatalar.add(
              '${alan.anahtar}: "$input" -> intent=${bulunan?.anahtar}, deger="$ham", valid=${dogrulama?.ok}',
            );
          }
        }
      }
      expect(hatalar, isEmpty, reason: hatalar.join('\n'));
    });

    test('sabit kritik doğal örnekleri de eksiksiz ayırır', () {
      final hatalar = <String>[];
      for (final entry in sabitBeklenen.entries) {
        final alan = resolver.resolve(entry.key);
        final ham = alan == null ? null : extractor.extract(entry.key, alan);
        if (alan == null || ham != entry.value) {
          hatalar.add(
            '"${entry.key}" -> ${alan?.anahtar} / "$ham"; beklenen="${entry.value}"',
          );
        }
      }
      expect(hatalar, isEmpty, reason: hatalar.join('\n'));
    });
  });
}
