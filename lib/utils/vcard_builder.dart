import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/utils/whatsapp_link_helper.dart';

/// Helpers for building vCard contact data from a [StoreData] instance.
///
/// All methods are pure functions keyed on [StoreData], with no dependency on
/// any widget or build context.
class VCardBuilder {
  VCardBuilder._();

  /// Returns `true` when [storeData] has enough contact fields to produce a
  /// meaningful vCard.
  static bool hasVCardData(StoreData storeData) {
    if (storeData.name.trim().isEmpty) return false;
    return WhatsAppLinkHelper.isValidTurkeyMobile(storeData.whatsapp) ||
        storeData.instagram.trim().isNotEmpty ||
        storeData.website.trim().isNotEmpty ||
        storeData.address.trim().isNotEmpty;
  }

  /// Returns a plain-text contact summary suitable for clipboard sharing.
  static String buildContactText(StoreData storeData) {
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

  /// Builds a standard vCard 3.0 file content string.
  static String buildFileContent(StoreData storeData) {
    final name = storeData.name.trim();
    final phone = WhatsAppLinkHelper.normalizeTurkeyMobile(storeData.whatsapp);
    final address = storeData.address.trim();
    final website = storeData.website.trim();
    final bio =
        storeData.corporateBio.trim().isNotEmpty
            ? storeData.corporateBio.trim()
            : storeData.description.trim();

    final card = StringBuffer();
    card.writeln('BEGIN:VCARD');
    card.writeln('VERSION:3.0');
    card.writeln('FN:$name');
    card.writeln('ORG:$name');
    if (phone != null) {
      card.writeln('TEL;TYPE=CELL,VOICE:+$phone');
    }
    if (website.isNotEmpty) {
      card.writeln('URL;TYPE=WORK:$website');
    }
    if (address.isNotEmpty) {
      final escapedAddress =
          address.replaceAll(',', '\\,').replaceAll('\n', ' ');
      card.writeln('ADR;TYPE=WORK:;;$escapedAddress;;;;');
    }
    if (bio.isNotEmpty) {
      card.writeln('NOTE:$bio');
    }
    card.writeln('END:VCARD');
    return card.toString();
  }
}
