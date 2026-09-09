import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/config/vixrex_niyet_sozlugu.g.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_field_validator.dart';

void main() {
  group('Vixrex 46 alan doğrulama parity kabul kümesi — Flutter', () {
    final senaryolar = (jsonDecode(
      File('shared/vixrex_dogrulama_senaryolari.json').readAsStringSync(),
    ) as List<dynamic>)
        .cast<Map<String, dynamic>>();

    test('ortak senaryoların tamamında aynı kabul/red ve normalize sonucu', () {
      final hatalar = <String>[];

      for (final senaryo in senaryolar) {
        final anahtar = senaryo['anahtar'] as String;
        final alan = vixrexNiyetAlanByAnahtar[anahtar];
        if (alan == null) {
          hatalar.add('${senaryo['id']}: sözlükte alan yok: $anahtar');
          continue;
        }

        final sonuc = VixrexFieldValidator.validate(
          alan,
          senaryo['girdi'] as String,
        );
        final beklenenOk = senaryo['ok'] as bool;
        if (sonuc.ok != beklenenOk) {
          hatalar.add(
            '${senaryo['id']}: ok=${sonuc.ok}, beklenen=$beklenenOk',
          );
          continue;
        }

        if (sonuc.ok) {
          final beklenen = senaryo.containsKey('deger') ? senaryo['deger'] : null;
          if (sonuc.normalizedDeger != beklenen) {
            hatalar.add(
              '${senaryo['id']}: deger=${sonuc.normalizedDeger}, beklenen=$beklenen',
            );
          }
        } else {
          final beklenenHata = senaryo['hata'] as String?;
          if (sonuc.hata != beklenenHata) {
            hatalar.add(
              '${senaryo['id']}: hata=${sonuc.hata}, beklenen=$beklenenHata',
            );
          }
        }
      }

      expect(hatalar, isEmpty, reason: hatalar.join('\n'));
    });
  });
}
