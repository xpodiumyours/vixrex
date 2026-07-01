import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/utils/vitrin_url_helper.dart';

void main() {
  // ---------------------------------------------------------------------------
  // normalizeExternalUrl
  // ---------------------------------------------------------------------------
  group('VitrinUrlHelper.normalizeExternalUrl', () {
    test('returns empty string for blank input', () {
      expect(VitrinUrlHelper.normalizeExternalUrl(''), '');
      expect(VitrinUrlHelper.normalizeExternalUrl('   '), '');
    });

    test('preserves valid https URLs', () {
      expect(
        VitrinUrlHelper.normalizeExternalUrl('https://example.com'),
        'https://example.com',
      );
    });

    test('preserves valid http URLs', () {
      expect(
        VitrinUrlHelper.normalizeExternalUrl('http://example.com/path'),
        'http://example.com/path',
      );
    });

    test('prepends https:// when scheme is missing but a dot is present', () {
      expect(
        VitrinUrlHelper.normalizeExternalUrl('example.com'),
        'https://example.com',
      );
      expect(
        VitrinUrlHelper.normalizeExternalUrl('sub.example.com/page'),
        'https://sub.example.com/page',
      );
    });

    test('returns empty string for bare words with no dot', () {
      expect(VitrinUrlHelper.normalizeExternalUrl('localhost'), '');
      expect(VitrinUrlHelper.normalizeExternalUrl('magaza'), '');
    });

    test('returns empty string for non-http schemes', () {
      expect(VitrinUrlHelper.normalizeExternalUrl('ftp://example.com'), '');
      expect(VitrinUrlHelper.normalizeExternalUrl('mailto:a@b.com'), '');
    });
  });

  // ---------------------------------------------------------------------------
  // buildInstagramUrl
  // ---------------------------------------------------------------------------
  group('VitrinUrlHelper.buildInstagramUrl', () {
    test('builds URL from bare username', () {
      expect(
        VitrinUrlHelper.buildInstagramUrl('kullanici'),
        'https://instagram.com/kullanici',
      );
    });

    test('strips leading @ from handle', () {
      expect(
        VitrinUrlHelper.buildInstagramUrl('@kullanici'),
        'https://instagram.com/kullanici',
      );
    });

    test('passes through existing instagram.com URL', () {
      expect(
        VitrinUrlHelper.buildInstagramUrl('https://instagram.com/kullanici'),
        'https://instagram.com/kullanici',
      );
    });

    test('normalises bare instagram.com domain', () {
      expect(
        VitrinUrlHelper.buildInstagramUrl('instagram.com/kullanici'),
        'https://instagram.com/kullanici',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // buildMapsUrl
  // ---------------------------------------------------------------------------
  group('VitrinUrlHelper.buildMapsUrl', () {
    test('builds directions URL when coordinates provided', () {
      final url = VitrinUrlHelper.buildMapsUrl(
        'Adres',
        latitude: 41.01,
        longitude: 28.97,
      );
      expect(url, contains('maps/dir'));
      expect(url, contains('41.01'));
      expect(url, contains('28.97'));
    });

    test('builds search URL when no coordinates provided', () {
      final url = VitrinUrlHelper.buildMapsUrl('Bağcılar, İstanbul');
      expect(url, contains('maps/search'));
      expect(url, contains(Uri.encodeQueryComponent('Bağcılar, İstanbul')));
    });

    test('ignores address when coordinates are given', () {
      final url = VitrinUrlHelper.buildMapsUrl(
        'ignored',
        latitude: 39.9,
        longitude: 32.8,
      );
      expect(url, contains('maps/dir'));
      expect(url, isNot(contains('ignored')));
    });
  });

  // ---------------------------------------------------------------------------
  // publicWebsiteActionUrl
  // ---------------------------------------------------------------------------
  group('VitrinUrlHelper.publicWebsiteActionUrl', () {
    test('returns publicLink in public mode when it is valid', () {
      final url = VitrinUrlHelper.publicWebsiteActionUrl(
        publicLink: 'https://vitrinx.app/v/test',
        publicMode: true,
        websiteUrl: 'https://magaza.com',
      );
      expect(url, 'https://vitrinx.app/v/test');
    });

    test('falls back to websiteUrl in public mode when publicLink is empty', () {
      final url = VitrinUrlHelper.publicWebsiteActionUrl(
        publicLink: '',
        publicMode: true,
        websiteUrl: 'https://magaza.com',
      );
      expect(url, 'https://magaza.com');
    });

    test('returns websiteUrl when not in public mode', () {
      final url = VitrinUrlHelper.publicWebsiteActionUrl(
        publicLink: 'https://vitrinx.app/v/test',
        publicMode: false,
        websiteUrl: 'https://magaza.com',
      );
      expect(url, 'https://magaza.com');
    });

    test('returns empty when both publicLink and websiteUrl are empty', () {
      final url = VitrinUrlHelper.publicWebsiteActionUrl(
        publicLink: null,
        publicMode: true,
        websiteUrl: '',
      );
      expect(url, '');
    });
  });
}
