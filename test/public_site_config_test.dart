import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/config/public_site_config.dart';

void main() {
  group('PublicSiteConfig', () {
    test('PUBLIC_SITE_URL varsa public linki bu origin ile üretir', () {
      final link = PublicSiteConfig.buildPublicLink(
        '/v/test-magaza',
        configuredOriginOverride: 'https://public.example.com/silinecek',
        baseUriOverride: Uri.parse('http://localhost:7357'),
      );

      expect(link, 'https://public.example.com/v/test-magaza');
    });

    // 2026-08-07 DAVRANIŞ DEĞİŞİKLİĞİ.
    //
    // Bu iki test eskiden şunu kilitliyordu: ayar boşsa link MEVCUT WEB
    // ORIGIN'İ ile kurulsun. Canlıda tam olarak bu oldu — derleme betiği
    // boş bir değer geçirdi, uygulama vitrin linklerini KENDİ adresiyle
    // kurdu ve sahip önizlemesi karşılama sayfasına düştü. Testler yeşildi
    // çünkü yanlış davranışı doğru sayıyorlardı.
    //
    // Artık ayar boş veya bozuksa sabit vitrin adresine düşülür.
    test('ayar boşsa uygulamanın kendi adresine DÜŞMEZ', () {
      final link = PublicSiteConfig.buildPublicLink(
        'v/test-magaza',
        configuredOriginOverride: '',
        baseUriOverride: Uri.parse('https://vixrex-app.vercel.app/editor'),
      );

      expect(link, 'https://vixrex-public.vercel.app/v/test-magaza');
      expect(link.contains('vixrex-app'), isFalse);
    });

    test('ayar bozuksa da vitrin adresine düşer', () {
      final link = PublicSiteConfig.buildPublicLink(
        '/v/test-magaza',
        configuredOriginOverride: 'public.example.com',
        baseUriOverride: Uri.parse('about:blank'),
      );

      expect(link, 'https://vixrex-public.vercel.app/v/test-magaza');
    });

    test('bare slug linkini /v/ slug olarak onarır', () {
      final repaired = PublicSiteConfig.repairPublicLink(
        'https://vixrex-public.vercel.app/nova-kuafor',
      );
      expect(repaired, 'https://vixrex-public.vercel.app/v/nova-kuafor');
    });

    test('hash /v/slug ve localhost linklerini canonical üretir', () {
      expect(
        PublicSiteConfig.repairPublicLink(
          'http://localhost:49692/#/v/nova-kuafor',
        ),
        'https://vixrex-public.vercel.app/v/nova-kuafor',
      );
      expect(
        PublicSiteConfig.repairPublicLink(
          'https://vixrex-public.vercel.app/#/v/nova-kuafor',
        ),
        'https://vixrex-public.vercel.app/v/nova-kuafor',
      );
      expect(
        PublicSiteConfig.repairPublicLink(
          'http://localhost:49692/v/nova-kuafor',
        ),
        'https://vixrex-public.vercel.app/v/nova-kuafor',
      );
    });

    test('randevu path ve tracker linkleri Next.js ile aynı sözleşmede', () {
      expect(
        PublicSiteConfig.buildBookingPath('nova-kuafor'),
        '/v/nova-kuafor/randevu',
      );
      expect(
        PublicSiteConfig.buildBookingTrackerPath('nova-kuafor', 'tok123'),
        '/v/nova-kuafor/randevu/tok123',
      );
      expect(
        PublicSiteConfig.buildBookingTrackerLink('nova-kuafor', 'tok123'),
        'https://vixrex-public.vercel.app/v/nova-kuafor/randevu/tok123',
      );
    });

    test('path resolve: /v/slug ve bare slug', () {
      expect(
        PublicSiteConfig.resolveVitrinSlugFromPath('/v/nova-kuafor'),
        'nova-kuafor',
      );
      expect(
        PublicSiteConfig.resolveVitrinSlugFromPath('/v/nova-kuafor/'),
        'nova-kuafor',
      );
      expect(
        PublicSiteConfig.resolveVitrinSlugFromPath('/nova-kuafor'),
        'nova-kuafor',
      );
      expect(PublicSiteConfig.resolveVitrinSlugFromPath('/auth'), isNull);
      expect(PublicSiteConfig.resolveVitrinSlugFromPath('/'), isNull);
    });
  });
}
