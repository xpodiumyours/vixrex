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
  });
}
