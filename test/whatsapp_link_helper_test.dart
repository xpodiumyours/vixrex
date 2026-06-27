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

    test(
      'randevu onay, ret ve tarih güncelleme şablonlarını doğru şekilde doldurur ve URL üretir',
      () {
        final confirmUrl = WhatsAppLinkHelper.buildAppointmentMessageUrl(
          number: '0555 123 45 67',
          template: WhatsAppLinkHelper.appointmentConfirmTemplate,
          customerName: 'Ahmet Ozan',
          dateStr: '22.06.2026',
          timeStr: '14:30',
          serviceTitle: 'Saç Kesimi',
          link: 'https://vitrinx.com/v/nova-kuafor',
        );
        expect(
          Uri.parse(confirmUrl!).queryParameters['text'],
          'Merhaba Ahmet Ozan, 22.06.2026 saat 14:30 için Saç Kesimi randevunuz onaylanmıştır. Teşekkür ederiz. Vitrinimiz: https://vitrinx.com/v/nova-kuafor',
        );

        final rejectUrl = WhatsAppLinkHelper.buildAppointmentMessageUrl(
          number: '0555 123 45 67',
          template: WhatsAppLinkHelper.appointmentRejectTemplate,
          customerName: 'Ahmet Ozan',
          dateStr: '22.06.2026',
          timeStr: '14:30',
          serviceTitle: 'Saç Kesimi',
          link: 'https://vitrinx.com/v/nova-kuafor',
        );
        expect(
          Uri.parse(rejectUrl!).queryParameters['text'],
          'Merhaba Ahmet Ozan, 22.06.2026 saat 14:30 için talep ettiğiniz Saç Kesimi randevunuz maalesef uygun olmadığımız için onaylanamamıştır.',
        );

        final rescheduleUrl = WhatsAppLinkHelper.buildAppointmentMessageUrl(
          number: '0555 123 45 67',
          template: WhatsAppLinkHelper.appointmentRescheduleTemplate,
          customerName: 'Ahmet Ozan',
          dateStr: '22.06.2026',
          timeStr: '14:30',
          serviceTitle: 'Saç Kesimi',
          link: 'https://vitrinx.com/v/nova-kuafor',
        );
        expect(
          Uri.parse(rescheduleUrl!).queryParameters['text'],
          'Merhaba Ahmet Ozan, talep ettiğiniz Saç Kesimi randevu saati uygun olmadığı için yeni bir tarih belirlemek üzere bizimle iletişime geçebilirsiniz.',
        );
      },
    );
  });
}
