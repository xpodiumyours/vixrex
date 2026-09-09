import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_general_intent_resolver.dart';

void main() {
  group('Vixrex genel intent Flutter ↔ Next parity', () {
    const resolver = VixrexGeneralIntentResolver();
    final senaryolar = (jsonDecode(
      File('shared/vixrex_genel_intent_senaryolari.json').readAsStringSync(),
    ) as List<dynamic>)
        .cast<Map<String, dynamic>>();

    test('ortak genel-intent kabul kümesinin tamamını doğru çözer', () {
      final hatalar = <String>[];

      for (final senaryo in senaryolar) {
        final bulunan = resolver.resolve(senaryo['girdi'] as String);
        final beklenen = senaryo['payload'] as String;
        if (bulunan != beklenen) {
          hatalar.add(
            '${senaryo['id']}: ${senaryo['girdi']} -> ${bulunan ?? 'null'}',
          );
        }
      }

      expect(hatalar, isEmpty, reason: hatalar.join('\n'));
    });

    test('XML/toplu ürün daha kısa fotoğraf yükle niyetine yenilmez', () {
      expect(
        resolver.resolve('XML ile toplu ürün yüklemek istiyorum'),
        'xml_upload',
      );
    });

    test('kapak foto ifadesinde daha özgül kapak niyeti kazanır', () {
      expect(resolver.resolve('Kapak foto seçelim'), 'kapak');
    });
  });
}
