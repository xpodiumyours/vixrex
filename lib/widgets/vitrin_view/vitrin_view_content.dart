import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/utils/whatsapp_link_helper.dart';

class VitrinViewContent {
  static String aboutText(StoreData storeData) {
    final corporateBio = storeData.corporateBio.trim();
    if (corporateBio.isNotEmpty) return corporateBio;
    return storeData.description.trim();
  }

  static String professionalBioText(StoreData storeData) {
    if (storeData.corporateBio.trim().isNotEmpty) {
      return storeData.corporateBio.trim();
    }
    if (storeData.description.trim().isNotEmpty) {
      return storeData.description.trim();
    }
    return 'Tüm bilgileriniz, linkleriniz ve iletişim kanallarınız tek yerde.';
  }

  static String storeInitials(StoreData storeData) {
    final words =
        storeData.name
            .trim()
            .split(RegExp(r'\s+'))
            .where((word) => word.isNotEmpty)
            .toList();

    if (words.isEmpty) return 'VX';
    if (words.length == 1) {
      return words.first.runes
          .take(2)
          .map(String.fromCharCode)
          .join()
          .toUpperCase();
    }

    return words
        .take(2)
        .map((word) => String.fromCharCode(word.runes.first))
        .join()
        .toUpperCase();
  }

  static String publicHeroDescription(StoreData storeData) {
    final description = storeData.description.trim();
    if (description.isNotEmpty) return description;

    final bio = storeData.corporateBio.trim();
    if (bio.isNotEmpty) return bio;

    if (storeData.products.isNotEmpty) {
      return 'Ürünleri, iletişim kanalları ve konumu tek dijital vitrinde.';
    }
    return '';
  }

  static String buildVCardContactText(StoreData storeData) {
    final lines = <String>[
      'Mağaza: ${storeData.name.trim()}',
      if (WhatsAppLinkHelper.isValidTurkeyMobile(storeData.whatsapp))
        'WhatsApp: ${storeData.whatsapp.trim()}',
      if (storeData.instagram.trim().isNotEmpty)
        'Instagram: ${storeData.instagram.trim()}',
      if (storeData.website.trim().isNotEmpty)
        'Web: ${storeData.website.trim()}',
      if (storeData.address.trim().isNotEmpty)
        'Adres: ${storeData.address.trim()}',
    ];
    return lines.join('\n');
  }

  static String buildVCardFileContent(StoreData storeData) {
    final name = storeData.name.trim();
    final phone = WhatsAppLinkHelper.normalizeTurkeyMobile(storeData.whatsapp);
    final address = storeData.address.trim();
    final website = storeData.website.trim();
    final bio = aboutText(storeData);

    final card =
        StringBuffer()
          ..writeln('BEGIN:VCARD')
          ..writeln('VERSION:3.0')
          ..writeln('FN:$name')
          ..writeln('ORG:$name');

    if (phone != null) {
      card.writeln('TEL;TYPE=CELL,VOICE:+$phone');
    }
    if (website.isNotEmpty) {
      card.writeln('URL;TYPE=WORK:$website');
    }
    if (address.isNotEmpty) {
      final escapedAddress = address
          .replaceAll(',', '\\,')
          .replaceAll('\n', ' ');
      card.writeln('ADR;TYPE=WORK:;;$escapedAddress;;;;');
    }
    if (bio.isNotEmpty) {
      card.writeln('NOTE:$bio');
    }

    card.writeln('END:VCARD');
    return card.toString();
  }

  static String buildShareUrl(StoreData storeData, String? publicLink) {
    final slug = storeData.name.toLowerCase().replaceAll(
      RegExp(r'[^a-zA-Z0-9]'),
      '-',
    );
    return publicLink ?? 'https://vixrex.app/v/$slug';
  }
}
