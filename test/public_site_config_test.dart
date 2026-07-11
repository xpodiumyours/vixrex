import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/config/public_site_config.dart';

void main() {
  group('PublicSiteConfig', () {
    test('PUBLIC_SITE_URL varsa public linki bu origin ile üretir', () {
      final link = PublicSiteConfig.buildPublicLink(
        '/v/test-magaza',
        configuredOriginOverride: 'https://vixrex-two.vercel.app/silinecek',
        baseUriOverride: Uri.parse('http://localhost:7357'),
      );

      expect(link, 'https://vixrex-two.vercel.app/v/test-magaza');
    });

    test('PUBLIC_SITE_URL yoksa mevcut web origin değerine düşer', () {
      final link = PublicSiteConfig.buildPublicLink(
        'v/test-magaza',
        configuredOriginOverride: '',
        baseUriOverride: Uri.parse('http://localhost:7357/editor'),
      );

      expect(link, 'http://localhost:7357/v/test-magaza');
    });

    test('geçersiz origin varsa sadece path döner', () {
      final link = PublicSiteConfig.buildPublicLink(
        '/v/test-magaza',
        configuredOriginOverride: 'vixrex-two.vercel.app',
        baseUriOverride: Uri.parse('about:blank'),
      );

      expect(link, '/v/test-magaza');
    });

    test('bare slug linkini /v/ slug olarak onarır', () {
      final repaired = PublicSiteConfig.repairPublicLink(
        'https://vixrex.app/nova-kuafor',
      );
      expect(repaired, 'https://vixrex.app/v/nova-kuafor');
    });

    test('hash /v/slug ve localhost linklerini canonical üretir', () {
      expect(
        PublicSiteConfig.repairPublicLink(
          'http://localhost:49692/#/v/nova-kuafor',
        ),
        'https://vixrex.app/v/nova-kuafor',
      );
      expect(
        PublicSiteConfig.repairPublicLink(
          'https://vixrex.app/#/v/nova-kuafor',
        ),
        'https://vixrex.app/v/nova-kuafor',
      );
      expect(
        PublicSiteConfig.repairPublicLink(
          'http://localhost:49692/v/nova-kuafor',
        ),
        'https://vixrex.app/v/nova-kuafor',
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
