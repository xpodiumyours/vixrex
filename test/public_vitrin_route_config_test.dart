import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/config/public_vitrin_route_config.dart';

void main() {
  group('PublicVitrinRouteConfig', () {
    test('/v/:slug route değerinden public slug okur', () {
      final slug = PublicVitrinRouteConfig.publicSlugFromUri(
        Uri.parse('/v/test-magaza'),
      );

      expect(slug, 'test-magaza');
    });

    test('tam URL içinden public slug okur', () {
      final slug = PublicVitrinRouteConfig.publicSlugFromUri(
        Uri.parse('https://vitrinx-two.vercel.app/v/test-magaza?src=qr'),
      );

      expect(slug, 'test-magaza');
    });

    test('geçersiz route için null döner', () {
      final slug = PublicVitrinRouteConfig.publicSlugFromUri(
        Uri.parse('/blog/test-magaza'),
      );

      expect(slug, isNull);
    });
  });
}
