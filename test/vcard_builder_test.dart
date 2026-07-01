import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/utils/vcard_builder.dart';

void main() {
  // ---------------------------------------------------------------------------
  // hasVCardData
  // ---------------------------------------------------------------------------
  group('VCardBuilder.hasVCardData', () {
    test('returns false when name is empty', () {
      expect(VCardBuilder.hasVCardData(StoreData(name: '')), false);
    });

    test('returns false when name present but all contact fields empty', () {
      expect(VCardBuilder.hasVCardData(StoreData(name: 'Mağaza')), false);
    });

    test('returns true when name and whatsapp present', () {
      expect(
        VCardBuilder.hasVCardData(
          StoreData(name: 'Mağaza', whatsapp: '05551234567'),
        ),
        true,
      );
    });

    test('returns true when name and website present', () {
      expect(
        VCardBuilder.hasVCardData(
          StoreData(name: 'Mağaza', website: 'https://test.com'),
        ),
        true,
      );
    });

    test('returns true when name and instagram present', () {
      expect(
        VCardBuilder.hasVCardData(
          StoreData(name: 'Mağaza', instagram: '@test'),
        ),
        true,
      );
    });

    test('returns true when name and address present', () {
      expect(
        VCardBuilder.hasVCardData(
          StoreData(name: 'Mağaza', address: 'İstanbul'),
        ),
        true,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // buildContactText
  // ---------------------------------------------------------------------------
  group('VCardBuilder.buildContactText', () {
    test('includes store name always', () {
      final text = VCardBuilder.buildContactText(StoreData(name: 'Test Store'));
      expect(text, contains('Mağaza: Test Store'));
    });

    test('includes WhatsApp when valid', () {
      final text = VCardBuilder.buildContactText(
        StoreData(name: 'Store', whatsapp: '05551234567'),
      );
      expect(text, contains('WhatsApp:'));
    });

    test('omits WhatsApp when invalid', () {
      final text = VCardBuilder.buildContactText(
        StoreData(name: 'Store', whatsapp: '123'),
      );
      expect(text, isNot(contains('WhatsApp:')));
    });

    test('includes website when provided', () {
      final text = VCardBuilder.buildContactText(
        StoreData(name: 'Store', website: 'https://test.com'),
      );
      expect(text, contains('Web: https://test.com'));
    });

    test('includes address when provided', () {
      final text = VCardBuilder.buildContactText(
        StoreData(name: 'Store', address: 'İstanbul, Türkiye'),
      );
      expect(text, contains('Adres: İstanbul, Türkiye'));
    });

    test('omits blank optional fields', () {
      final text = VCardBuilder.buildContactText(
        StoreData(name: 'Store'),
      );
      expect(text, isNot(contains('WhatsApp:')));
      expect(text, isNot(contains('Instagram:')));
      expect(text, isNot(contains('Web:')));
      expect(text, isNot(contains('Adres:')));
    });
  });

  // ---------------------------------------------------------------------------
  // buildFileContent
  // ---------------------------------------------------------------------------
  group('VCardBuilder.buildFileContent', () {
    test('starts with BEGIN:VCARD and ends with END:VCARD', () {
      final content = VCardBuilder.buildFileContent(StoreData(name: 'Store'));
      expect(content.trimRight(), startsWith('BEGIN:VCARD'));
      expect(content.trimRight(), endsWith('END:VCARD'));
    });

    test('contains FN and ORG set to store name', () {
      final content = VCardBuilder.buildFileContent(StoreData(name: 'Mağazam'));
      expect(content, contains('FN:Mağazam'));
      expect(content, contains('ORG:Mağazam'));
    });

    test('includes TEL for a valid phone number', () {
      final content = VCardBuilder.buildFileContent(
        StoreData(name: 'Store', whatsapp: '05551234567'),
      );
      expect(content, contains('TEL;TYPE=CELL,VOICE:+'));
    });

    test('omits TEL when phone is invalid', () {
      final content = VCardBuilder.buildFileContent(
        StoreData(name: 'Store', whatsapp: '123'),
      );
      expect(content, isNot(contains('TEL;')));
    });

    test('includes URL when website provided', () {
      final content = VCardBuilder.buildFileContent(
        StoreData(name: 'Store', website: 'https://magaza.com'),
      );
      expect(content, contains('URL;TYPE=WORK:https://magaza.com'));
    });

    test('includes ADR and escapes commas in address', () {
      final content = VCardBuilder.buildFileContent(
        StoreData(name: 'Store', address: 'Bağcılar, İstanbul'),
      );
      expect(content, contains('ADR;TYPE=WORK::;'));
      expect(content, contains('\\,'));
    });

    test('includes NOTE from corporateBio when available', () {
      final content = VCardBuilder.buildFileContent(
        StoreData(name: 'Store', corporateBio: 'Biyografi'),
      );
      expect(content, contains('NOTE:Biyografi'));
    });

    test('falls back to description for NOTE when corporateBio empty', () {
      final content = VCardBuilder.buildFileContent(
        StoreData(name: 'Store', description: 'Açıklama'),
      );
      expect(content, contains('NOTE:Açıklama'));
    });

    test('omits NOTE when both bio and description are empty', () {
      final content = VCardBuilder.buildFileContent(StoreData(name: 'Store'));
      expect(content, isNot(contains('NOTE:')));
    });
  });
}
