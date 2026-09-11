import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/config/vixrex_niyet_sozlugu.g.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_executor.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_field_validator.dart';

String _gecerliGirdi(VixrexNiyetAlan alan) {
  switch (alan.anahtar) {
    case 'isletmeAdi':
      return 'Deniz Teknik';
    case 'kategori':
      return 'telefon servis';
    case 'whatsapp':
      return '0532 555 44 33';
    case 'telefon':
      return '0212 555 44 33';
    case 'eposta':
      return 'info@denizteknik.com';
    case 'adres':
      return 'Atatürk Cad. No:24';
    case 'enlem':
      return '41';
    case 'boylam':
      return '29';
  }

  switch (alan.tip) {
    case 'acikKapali':
      return 'göster';
    case 'url':
    case 'gorsel':
      return 'https://example.com/vixrex.jpg';
    case 'telefon':
      return '02125554433';
    case 'eposta':
      return 'info@example.com';
    case 'sayi':
      return '1';
    case 'secim':
      return 'Diğer';
    case 'metin':
    case 'uzunMetin':
      return 'Örnek Değer';
    default:
      return 'Örnek Değer';
  }
}

void main() {
  group('Vixrex Assistant 46 alan executor kapsamı', () {
    test('46 alanın 44ü doğrudan yürütülür, il ve ilçe özel akışta kalır', () {
      expect(vixrexNiyetSozlugu.length, 46);

      const ozelAkis = {'il', 'ilce'};
      final hatalar = <String>[];
      var dogrudan = 0;
      var ozel = 0;

      for (final alan in vixrexNiyetSozlugu) {
        final dogrulama = VixrexFieldValidator.validate(
          alan,
          _gecerliGirdi(alan),
        );
        if (!dogrulama.ok) {
          hatalar.add('${alan.anahtar}: doğrulama reddetti: ${dogrulama.hata}');
          continue;
        }

        final controller = StoreEditorController(initialData: StoreData());
        final uygulandi = const VixrexExecutor().execute(
          controller: controller,
          alan: alan,
          deger: dogrulama.normalizedDeger,
        );

        if (ozelAkis.contains(alan.anahtar)) {
          ozel += 1;
          if (uygulandi) {
            hatalar.add(
              '${alan.anahtar}: özel akış olması gerekirken doğrudan yazıldı',
            );
          }
        } else {
          dogrudan += 1;
          if (!uygulandi) {
            hatalar.add('${alan.anahtar}: doğrulandı ama executor uygulamadı');
          }
        }
      }

      expect(dogrudan, 44);
      expect(ozel, 2);
      expect(hatalar, isEmpty, reason: hatalar.join('\n'));
    });
  });
}
