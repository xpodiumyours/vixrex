import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Public vitrin route ownership', () {
    final config =
        jsonDecode(File('vercel.json').readAsStringSync())
            as Map<String, dynamic>;
    final redirects =
        (config['redirects'] as List<dynamic>).cast<Map<String, dynamic>>();
    final rewrites =
        (config['rewrites'] as List<dynamic>).cast<Map<String, dynamic>>();

    test('Flutter app host redirects every public web route to Next.js', () {
      expect(redirects, contains(containsPair('source', '/v/:path*')));
      expect(
        redirects,
        contains(
          containsPair(
            'destination',
            'https://vixrex-public.vercel.app/v/:path*',
          ),
        ),
      );
      expect(
        redirects,
        contains(
          allOf(
            containsPair('source', '/sitemap.xml'),
            containsPair(
              'destination',
              'https://vixrex-public.vercel.app/sitemap.xml',
            ),
          ),
        ),
      );
      expect(
        redirects,
        contains(
          allOf(
            containsPair('source', '/robots.txt'),
            containsPair(
              'destination',
              'https://vixrex-public.vercel.app/robots.txt',
            ),
          ),
        ),
      );
    });

    test('Flutter app has no public vitrin rewrite or legacy SEO handlers', () {
      expect(
        rewrites.any((route) => route['source'].toString().startsWith('/v/')),
        isFalse,
      );
      expect(File(r'api/v/[slug].js').existsSync(), isFalse);
      expect(File('api/sitemap.js').existsSync(), isFalse);
      expect(File('api/robots.js').existsSync(), isFalse);
    });

    test(
      'App router inside lib/config/app_router.dart routes all /v/* paths strictly to PublicSiteRedirectScreen',
      () {
        final source = File('lib/config/app_router.dart').readAsStringSync();

        expect(source, isNot(contains('public_product_screen.dart')));
        expect(source, isNot(contains('PublicProductScreen')));
        expect(
          File('lib/screens/public_product_screen.dart').existsSync(),
          isFalse,
        );
        expect(File('lib/widgets/vitrin_cart_dock.dart').existsSync(), isFalse);
        expect(
          File('lib/widgets/vitrin_product_card.dart').existsSync(),
          isFalse,
        );
        expect(
          File('lib/services/vitrin_cart_service.dart').existsSync(),
          isFalse,
        );
        expect(
          File('test/vitrin_cart_service_test.dart').existsSync(),
          isFalse,
        );

        final vRoutes =
            RegExp(
              r"path:\s*'(/v/[^']*)'",
            ).allMatches(source).map((match) => match.group(1)!).toList();
        expect(
          vRoutes,
          containsAll([
            '/v/:slug/randevu/:token',
            '/v/:slug/randevu',
            '/v/:slug/urun/:productSlug',
            '/v/:slug',
          ]),
        );

        final vRouteBlocks =
            source
                .split('GoRoute(')
                .where((block) => RegExp(r"path:\s*'/v/").hasMatch(block))
                .toList();
        expect(vRouteBlocks, isNotEmpty);
        for (final block in vRouteBlocks) {
          expect(
            block,
            contains('PublicSiteRedirectScreen.fromPath'),
            reason: '/v/* route must use PublicSiteRedirectScreen: $block',
          );
          expect(
            block,
            isNot(contains('PublicProductScreen')),
            reason: '/v/* route must not use PublicProductScreen: $block',
          );
        }
      },
    );

    test(
      'Next.js fallback origins point to canonical public and active app hosts',
      () {
        final siteUrl =
            File('public_web/src/lib/siteUrl.ts').readAsStringSync();

        expect(siteUrl, contains('https://vixrex.com'));
        expect(siteUrl, contains('https://vixrex-app.vercel.app'));
        expect(siteUrl, isNot(contains('vixrex-two.vercel.app')));
      },
    );
  });
}
