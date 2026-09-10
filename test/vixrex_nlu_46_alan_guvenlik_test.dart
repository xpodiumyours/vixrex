import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/config/vixrex_niyet_sozlugu.g.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_field_validator.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_intent_resolver.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_nlu_pipeline.dart';

void main() {
  group('Vixrex Assistant 46 alan güvenlik kapısı', () {
    const resolver = VixrexIntentResolver();

    Future<({bool ok, String? hata, Object? normalizedDeger})> validate(
      VixrexNiyetAlan alan,
      String ham,
    ) async {
      final v = VixrexFieldValidator.validate(alan, ham);
      return (ok: v.ok, hata: v.hata, normalizedDeger: v.normalizedDeger);
    }

    test('46 alanın her sözlük örneği kendi alanına çözülür', () {
      expect(vixrexNiyetSozlugu.length, 46);
      final hatalar = <String>[];

      for (final alan in vixrexNiyetSozlugu) {
        for (final ornek in alan.ornekIfadeler) {
          final input = ornek.replaceAll('{deger}', 'Örnek Değer');
          final bulunan = resolver.resolve(input);
          if (bulunan?.anahtar != alan.anahtar) {
            hatalar.add(
              '${alan.anahtar}: "$input" -> ${bulunan?.anahtar ?? 'null'}',
            );
          }
        }
      }

      expect(hatalar, isEmpty, reason: hatalar.join('\n'));
    });

    test(
      'her tek-alan sözlük örneği resolveAll içinde yalnız kendi alanını üretir',
      () {
        final hatalar = <String>[];

        for (final alan in vixrexNiyetSozlugu) {
          for (final ornek in alan.ornekIfadeler) {
            final input = ornek.replaceAll('{deger}', 'Örnek Değer');
            final bulunan = resolver
                .resolveAll(input)
                .map((a) => a.anahtar)
                .toList();
            final dogruTekAlan =
                bulunan.length == 1 && bulunan.first == alan.anahtar;
            if (!dogruTekAlan) {
              hatalar.add(
                '${alan.anahtar}: "$input" -> [${bulunan.join(', ')}]',
              );
            }
          }
        }

        expect(hatalar, isEmpty, reason: hatalar.join('\n'));
      },
    );

    test('ayrı metin aralıklarındaki gerçek iki alan korunur', () {
      final alanlar = resolver
          .resolveAll(
            'Telefonu 0212 555 44 33 yap, e-postayı info@denizteknik.com yap',
          )
          .map((a) => a.anahtar)
          .toList();

      expect(alanlar.length, 2);
      expect(alanlar.toSet(), {'telefon', 'eposta'});
    });

    test('kısa il aliası sıradan kelimenin içinden niyet üretmez', () {
      final alanlar = resolver.resolveAll(
        'Ailece müşterilerimize hizmet veriyoruz.',
      );
      expect(alanlar.map((a) => a.anahtar), isNot(contains('il')));
    });

    test(
      'aç/kapat doğal komutları gerçek pipeline sonucunda bool üretir',
      () async {
        SharedPreferences.setMockInitialValues({});
        final pipeline = VixrexNluPipeline();

        final ac = await pipeline.handle(
          input: 'Puanı göster',
          controller: null,
          onValidate: validate,
        );
        expect(ac.outcome, VixrexNluPipelineOutcome.handled);
        expect(ac.appliedAnahtar, 'puanGoster');
        expect(ac.appliedDeger, true);

        final kapat = await pipeline.handle(
          input: 'Yol tarifi butonunu gizle',
          controller: null,
          onValidate: validate,
        );
        expect(kapat.outcome, VixrexNluPipelineOutcome.handled);
        expect(kapat.appliedAnahtar, 'yolTarifiGoster');
        expect(kapat.appliedDeger, false);
      },
    );

    test(
      'çoklu niyette bir alan özel akış isterse diğer alan da kısmi yazılmaz',
      () async {
        SharedPreferences.setMockInitialValues({});
        final pipeline = VixrexNluPipeline();
        final controller = StoreEditorController(initialData: StoreData());
        final oncekiTelefon = controller.data.phone;

        final result = await pipeline.handle(
          input: 'Telefonu 0212 123 45 67 yap, ili İstanbul yap',
          controller: controller,
          onValidate: validate,
          needsSpecialFlow: (alan) => alan.anahtar == 'il',
        );

        expect(result.outcome, VixrexNluPipelineOutcome.needsClarification);
        expect(controller.data.phone, oncekiTelefon);
      },
    );
  });
}
