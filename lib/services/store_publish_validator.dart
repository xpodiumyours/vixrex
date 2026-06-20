import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/utils/whatsapp_link_helper.dart';

class StorePublishValidator {
  const StorePublishValidator();

  // Legacy validate method for compatibility/tests
  String? validate(StoreData data) {
    if (data.isStore) {
      return validateStore(data);
    } else {
      return validateVitrin(data);
    }
  }

  String? validateVitrin(StoreData data) {
    final missing = <String>[];

    if (data.name.trim().isEmpty) {
      missing.add('işletme adı');
    }
    if (data.whatsapp.trim().isEmpty) {
      missing.add('WhatsApp numarası');
    }
    if (data.address.trim().isEmpty) {
      missing.add('konum / adres');
    }

    if (missing.isNotEmpty) {
      return 'Lütfen şu zorunlu alanları doldurun: ${missing.join(', ')}.';
    }
    if (!WhatsAppLinkHelper.isValidTurkeyMobile(data.whatsapp)) {
      return WhatsAppLinkHelper.invalidNumberMessage;
    }
    return null;
  }

  String? validateStore(StoreData data) {
    final missingItems = <String>[];

    if (data.name.trim().isEmpty) {
      missingItems.add('mağaza adı');
    }
    if (data.whatsapp.trim().isEmpty) {
      missingItems.add('telefon / WhatsApp numarası');
    }
    if (data.description.trim().isEmpty) {
      missingItems.add('kısa açıklama');
    }
    if (data.address.trim().isEmpty) {
      missingItems.add('adres bilgisi');
    }
    if (data.kategori.trim().isEmpty) {
      missingItems.add('işletme kategorisi');
    }

    if (missingItems.isNotEmpty) {
      return 'Mağaza yayınlanmadan önce şu alanları tamamlayın: ${missingItems.join(', ')}.';
    }
    if (!WhatsAppLinkHelper.isValidTurkeyMobile(data.whatsapp)) {
      return WhatsAppLinkHelper.invalidNumberMessage;
    }

    // Validate products if present
    for (final product in data.products) {
      if (product.name.trim().isEmpty) {
        return 'Eklenen tüm ürünlerin adı zorunludur.';
      }
    }

    return null;
  }
}
