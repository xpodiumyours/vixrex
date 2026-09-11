import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_conversation_context.dart';

String kararAdi(VixrexBaglamKarari karar) => switch (karar) {
  VixrexBaglamKarari.genelSor => 'genel_sor',
  VixrexBaglamKarari.ozelSor => 'ozel_sor',
  VixrexBaglamKarari.ayniKalsin => 'ayni_kalsin',
  VixrexBaglamKarari.kaldirmaOnayi => 'kaldirma_onayi',
  VixrexBaglamKarari.kaldir => 'kaldir',
  VixrexBaglamKarari.iptal => 'iptal',
  VixrexBaglamKarari.boolTrue => 'bool_true',
  VixrexBaglamKarari.boolFalse => 'bool_false',
  VixrexBaglamKarari.saatEksik => 'saat_eksik',
  VixrexBaglamKarari.adresEksik => 'adres_eksik',
  VixrexBaglamKarari.deger => 'deger',
};

void main() {
  final raw =
      jsonDecode(
            File(
              'shared/vixrex_dogal_netlestirme_senaryolari.json',
            ).readAsStringSync(),
          )
          as List<dynamic>;

  group('Vixrex doğal netleştirme bağımsız kabul kümesi', () {
    test('en az 20 konuşma senaryosu içerir', () {
      expect(raw.length, greaterThanOrEqualTo(20));
    });

    for (final item in raw.cast<Map<String, dynamic>>()) {
      test('${item['id']}: Flutter aynı bağlam kararını verir', () {
        final bekleyenJson = item['bekleyen'] as Map<String, dynamic>?;
        final bekleyen =
            bekleyenJson == null
                ? null
                : VixrexBekleyenBaglam(
                  anahtar: bekleyenJson['anahtar'] as String,
                  etiket: bekleyenJson['etiket'] as String,
                  tip: bekleyenJson['tip'] as String,
                  eylem: bekleyenJson['eylem'] as String?,
                );
        final sonuc = vixrexBaglamsalCevapKarari(
          item['girdi'] as String,
          bekleyen,
        );

        expect(kararAdi(sonuc.karar), item['karar']);
        expect(sonuc.yazma, item['yazma']);
        if (!(item['yazma'] as bool)) {
          expect(sonuc.mesaj.trim(), isNotEmpty);
        }
      });
    }

    test('bağlam yokken kullanıcıdan sistemin iç alan adını istemez', () {
      final sonuc = vixrexBaglamsalCevapKarari('bunu düzelt', null);
      expect(sonuc.mesaj, vixrexDogalGenelSoru);
      expect(sonuc.mesaj.toLowerCase(), isNot(contains('hangi alan')));
    });
  });
}
