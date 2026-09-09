import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/config/vitrin_alan_bilgisi.dart';
import 'package:vixrex/config/vitrin_alanlari.g.dart';

/// Vitrin alan etiketlerinin TEK KAYNAK kilidi.
///
/// Neden var (2026-09-09 ölçümü): SSS düzenleyicisi etiketleri ve uzunluk
/// sınırlarını elle yazıyordu; web tarafı aynı bilgileri şemadan okuyordu.
/// Eski "SSS paritesi" testi bunu göremiyordu, çünkü bir testte yalnız
/// Flutter dosyasına, başka testte yalnız web dosyasına bakıyor, ikisini hiç
/// karşılaştırmıyordu — üstelik Flutter'ın hem soru-cevap hem bölüm
/// başlıklarını düzenleyen ekranı, web'in yalnız soru-cevap düzenleyen
/// ekranıyla eşleştirilmişti. Yanlış yüzey eşlemesi yeşil yanıyordu.
///
/// Bu test farkı ÖLÇMEZ; farkın yeniden oluşmasını ENGELLER.
void main() {
  test('düzenleme ekranları alan etiketini elle yazmaz', () {
    final semaEtiketleri = {
      for (final a in vitrinAlanlari) a.etiket: a.anahtar,
    };

    final suclular = <String>[];
    final dizin = Directory('lib/widgets/editor');
    for (final dosya in dizin.listSync(recursive: true).whereType<File>()) {
      if (!dosya.path.endsWith('.dart')) continue;
      // Yorum satırlarında etiket geçmesi serbest.
      final govde = dosya
          .readAsStringSync()
          .split('\n')
          .where((satir) => !satir.trimLeft().startsWith('//'))
          .join('\n');

      for (final giris in semaEtiketleri.entries) {
        if (govde.contains("'${giris.key}'") ||
            govde.contains('"${giris.key}"')) {
          suclular.add('${dosya.path} → ${giris.key} (${giris.value})');
        }
      }
    }

    expect(
      suclular,
      isEmpty,
      reason:
          'Bu ekranlar alan etiketini elle yazıyor. '
          "vitrinAlanEtiketi('<anahtar>') kullanın; yoksa "
          'shared/vitrin_alanlari.json değiştiğinde bu ekran eski etiketi '
          'göstermeye devam eder ve web ile sessizce ayrışır.',
    );
  });

  test('SSS alanları şemadan okunuyor — etiket ve uzunluk sınırı', () {
    for (final anahtar in ['sssUstBaslik', 'sssBaslik', 'sssAciklama']) {
      expect(vitrinAlanEtiketi(anahtar), isNotEmpty);
      expect(vitrinAlanMaxUzunluk(anahtar), isNotNull);
    }

    final govde =
        File('lib/widgets/editor/faq_editor_sheet.dart').readAsStringSync();
    // Sayılar da şemadan gelmeli: eskiden 40/90/200 elle yazılıydı ve şema
    // değişse Flutter eski sınırda kalırdı.
    expect(govde.contains("maxLength: 40"), isFalse);
    expect(govde.contains("maxLength: 90"), isFalse);
    expect(govde.contains("maxLength: 200"), isFalse);
  });

  test('üretilen şema, paylaşılan kaynakla aynı alanları taşıyor', () {
    final ham =
        File('../shared/vitrin_alanlari.json').existsSync()
            ? File('../shared/vitrin_alanlari.json')
            : File('shared/vitrin_alanlari.json');
    final json = jsonDecode(ham.readAsStringSync());
    final liste = json is Map ? json['alanlar'] as List : json as List;
    expect(liste.length, vitrinAlanlari.length);
  });
}
