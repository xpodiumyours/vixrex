import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/utils/whatsapp_link_helper.dart';

void main() {
  group('WhatsAppLinkHelper', () {
    test('desteklenen Türkiye cep telefonu biçimlerini normalize eder', () {
      for (final value in [
        '0555 123 45 67',
        '5551234567',
        '905551234567',
        '+90 (555) 123-45-67',
      ]) {
        expect(WhatsAppLinkHelper.normalizeTurkeyMobile(value), '905551234567');
      }
    });

    test('geçersiz numaraları reddeder', () {
      for (final value in [
        '',
        'abc',
        '05x',
        '0555123456',
        '055512345678',
        '02121234567',
        '+441234567890',
      ]) {
        expect(WhatsAppLinkHelper.normalizeTurkeyMobile(value), isNull);
      }
    });

    test('hazır mesajı güvenli WhatsApp URL değerine ekler', () {
      final url = WhatsAppLinkHelper.buildGeneralUrl(
        number: '0555 123 45 67',
        storeName: 'Aymira Butik',
      );

      final uri = Uri.parse(url!);
      expect(uri.host, 'wa.me');
      expect(uri.path, '/905551234567');
      expect(
        uri.queryParameters['text'],
        'Merhaba, Aymira Butik vitrininiz hakkında bilgi almak ve sipariş vermek istiyorum.',
      );
    });

    test('buildCategoryGeneralUrl doğru şablonu kullanır', () {
      final url = WhatsAppLinkHelper.buildCategoryGeneralUrl(
        number: '0555 123 45 67',
        storeName: 'Aymira Butik',
        categoryId: 'giyim_butik',
      );

      final uri = Uri.parse(url!);
      expect(
        uri.queryParameters['text'],
        'Merhaba, Aymira Butik. Ürünleriniz hakkında bilgi almak istiyorum.',
      );
    });

    test('buildCategoryOfferingUrl doğru eylemi ekler', () {
      // Sipariş Talebi eylemi test edelim (gida_firin)
      final urlGida = WhatsAppLinkHelper.buildCategoryOfferingUrl(
        number: '0555 123 45 67',
        storeName: 'Lezzet Durağı',
        offeringTitle: 'Sıcak Ekmek',
        categoryId: 'gida_firin',
      );
      expect(
        Uri.parse(urlGida!).queryParameters['text'],
        "Merhaba, Lezzet Durağı. 'Sıcak Ekmek' siparişi vermek istiyorum.",
      );

      // Randevu Talebi eylemi test edelim (kuafor)
      final urlKuafor = WhatsAppLinkHelper.buildCategoryOfferingUrl(
        number: '0555 123 45 67',
        storeName: 'Nova Kuaför',
        offeringTitle: 'Saç Kesimi',
        categoryId: 'kuafor',
      );
      expect(
        Uri.parse(urlKuafor!).queryParameters['text'],
        "Merhaba, Nova Kuaför. 'Saç Kesimi' randevusu oluşturmak istiyorum.",
      );
    });
  });
}
