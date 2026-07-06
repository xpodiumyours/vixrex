import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/utils/whatsapp_link_helper.dart';
import 'package:vixrex/services/store_publish_legal_validator.dart';
import 'package:vixrex/services/store_publish_links_validator.dart';

class StorePublishValidator {
  final StorePublishLegalValidator legalValidator;
  final StorePublishLinksValidator linksValidator;

  const StorePublishValidator({
    this.legalValidator = const StorePublishLegalValidator(),
    this.linksValidator = const StorePublishLinksValidator(),
  });

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

    if (data.provinceName.trim().isEmpty || data.provinceCode.trim().isEmpty) {
      missing.add('il');
    }
    if (data.districtName.trim().isEmpty || data.districtCode.trim().isEmpty) {
      missing.add('ilçe');
    }
    if (missing.isNotEmpty) {
      return 'Lütfen şu zorunlu alanları doldurun: ${missing.join(', ')}.';
    }
    if (!WhatsAppLinkHelper.isValidTurkeyMobile(data.whatsapp)) {
      return WhatsAppLinkHelper.invalidNumberMessage;
    }

    final extraValidation = linksValidator.validateLinksAndOfferings(data);
    if (extraValidation != null) {
      return extraValidation;
    }

    final legalValidation = legalValidator.validateLegalAcceptance(data);
    if (legalValidation != null) {
      return legalValidation;
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

    if (data.provinceName.trim().isEmpty || data.provinceCode.trim().isEmpty) {
      missingItems.add('il');
    }
    if (data.districtName.trim().isEmpty || data.districtCode.trim().isEmpty) {
      missingItems.add('ilçe');
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
      if (product.category.trim().isEmpty) {
        return 'Eklenen tüm ürünlerin kategorisi zorunludur.';
      }
      if (product.displayImageUrls.length > 4) {
        return 'Bir ürüne en fazla 4 görsel eklenebilir.';
      }
    }

    final extraValidation = linksValidator.validateLinksAndOfferings(data);
    if (extraValidation != null) {
      return extraValidation;
    }

    final legalValidation = legalValidator.validateLegalAcceptance(data);
    if (legalValidation != null) {
      return legalValidation;
    }

    return null;
  }
}
