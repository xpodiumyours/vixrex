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

    test('Next.js fallback origins point to active Vercel projects', () {
      final nextConfig = File('public_web/next.config.ts').readAsStringSync();
      final siteUrl = File('public_web/src/lib/siteUrl.ts').readAsStringSync();

      expect(nextConfig, contains('https://vixrex-app.vercel.app'));
      expect(nextConfig, isNot(contains('vixrex-two.vercel.app')));
      expect(siteUrl, contains('https://vixrex-public.vercel.app'));
    });
  });
}
