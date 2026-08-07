import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/config/public_site_config.dart';

/// 2026-08-07 — boş PUBLIC_SITE_URL nöbetçisi.
///
/// Derleme `--dart-define=PUBLIC_SITE_URL=` diye BOŞ değer geçerse Dart bunu
/// "değer var" sayar; koddaki varsayılan devreye girmez. O gün uygulama
/// vitrin linklerini kendi adresiyle kurdu, sahip önizlemesi karşılama
/// sayfasına düştü. Bu test o düşüşü engeller.
void main() {
  test('ayar boşsa link uygulamanın adresine düşmez', () {
    final link = PublicSiteConfig.buildPublicLink(
      '/api/owner-session',
      configuredOriginOverride: '',
      baseUriOverride: Uri.parse('https://vixrex-app.vercel.app/'),
    );
    expect(link, 'https://vixrex-public.vercel.app/api/owner-session');
    expect(link.contains('vixrex-app'), isFalse);
  });

  test('ayar bozuksa da vitrin adresine gider', () {
    final link = PublicSiteConfig.buildVitrinLink(
      'deneme',
      // ignore: invalid_use_of_visible_for_testing_member
    );
    expect(link.startsWith('https://vixrex-public.vercel.app/v/'), isTrue);
  });

  test('sahip oturumu girişi vitrin adresinde kurulur', () {
    final link = PublicSiteConfig.buildOwnerSessionEntryLink('deneme', 'abc123');
    expect(link.startsWith('https://vixrex-public.vercel.app/api/owner-session'), isTrue);
    expect(link.contains('slug=deneme'), isTrue);
  });
}
