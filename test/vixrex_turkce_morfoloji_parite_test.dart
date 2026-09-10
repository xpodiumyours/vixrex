import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_intent_resolver.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_value_extractor.dart';

void main() {
  const resolver = VixrexIntentResolver();
  const extractor = VixrexValueExtractor();

  final cases = <({String input, String anahtar, String deger})>[
    (input: 'Dükkanın adı Aymira Giyim', anahtar: 'isletmeAdi', deger: 'Aymira Giyim'),
    (input: 'Dükkanımın adı Aymira Giyim', anahtar: 'isletmeAdi', deger: 'Aymira Giyim'),
    (input: 'Ürünlerin başlığı Ürünlerimiz', anahtar: 'urunBolumBaslik', deger: 'Ürünlerimiz'),
    (input: 'Galerinin başlığı Yaptığımız İşler', anahtar: 'galeriBaslik', deger: 'Yaptığımız İşler'),
  ];

  group('Türkçe iyelik/genitif — Flutter', () {
    for (final c in cases) {
      test('${c.input} -> ${c.anahtar}', () {
        final alan = resolver.resolve(c.input);
        expect(alan?.anahtar, c.anahtar);
        expect(alan == null ? null : extractor.extract(c.input, alan), c.deger);
      });
    }

    test("kısa 'il' aliası normal kelime içinden doğmaz", () {
      for (final input in [
        'Ailece müşterilerimize hizmet veriyoruz',
        'İlgili bilgiyi sonra ekleriz',
        'Kaliteli hizmet veriyoruz',
      ]) {
        expect(
          resolver.resolveAll(input).map((a) => a.anahtar),
          isNot(contains('il')),
        );
      }
    });
  });
}
