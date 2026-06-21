import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/utils/whatsapp_link_helper.dart';

class StorePublishValidator {
  const StorePublishValidator();

  static const _standardPlatforms = {
    'trendyol',
    'hepsiburada',
    'n11',
    'amazon',
    'çiçeksepeti',
    'ciceksepeti',
    'shopier',
    'google işletme',
    'google isletme',
    'instagram',
    'whatsapp',
    'diğer',
    'diger'
  };

  // Legacy validate method for compatibility/tests
  String? validate(StoreData data) {
    if (data.isStore) {
      return validateStore(data);
    } else {
      return validateVitrin(data);
    }
  }

  String? _validateLinksAndOfferings(StoreData data) {
    for (final link in data.marketplaceLinks) {
      final trimmedUrl = link.url.trim();
      final platformLower = link.platform.trim().toLowerCase();
      final isCustom = platformLower.isNotEmpty && !_standardPlatforms.contains(platformLower);

      if (isCustom && trimmedUrl.isEmpty) {
        return 'Geçersiz web adresi formatı. Lütfen geçerli bir web sitesi veya sosyal medya linki girin.';
      }

      if (trimmedUrl.isNotEmpty) {
        final urlLower = trimmedUrl.toLowerCase();
        if (urlLower.startsWith('javascript:') ||
            urlLower.startsWith('data:') ||
            urlLower.startsWith('file:') ||
            urlLower.startsWith('tel:') ||
            urlLower.startsWith('mailto:')) {
          return 'Geçersiz web adresi formatı. Lütfen geçerli bir web sitesi veya sosyal medya linki girin.';
        }
        final uri = Uri.tryParse(trimmedUrl);
        if (uri == null || !trimmedUrl.contains('.')) {
          return 'Geçersiz web adresi formatı. Lütfen geçerli bir web sitesi veya sosyal medya linki girin.';
        }
      }
    }

    if (data.offerings.length > 6) {
      return 'En fazla 6 adet hizmet veya öne çıkan ekleyebilirsiniz.';
    }
    for (final offering in data.offerings) {
      if (offering.title.trim().isEmpty) {
        return 'Hizmet veya öne çıkan başlığı boş olamaz.';
      }
      if (offering.title.trim().length > 60) {
        return 'Hizmet başlığı en fazla 60 karakter olabilir.';
      }
      if (offering.description.trim().length > 120) {
        return 'Hizmet açıklaması en fazla 120 karakter olabilir.';
      }
      if (offering.price.trim().length > 30) {
        return 'Hizmet fiyatı en fazla 30 karakter olabilir.';
      }
    }
    return null;
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

    final extraValidation = _validateLinksAndOfferings(data);
    if (extraValidation != null) {
      return extraValidation;
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

    final extraValidation = _validateLinksAndOfferings(data);
    if (extraValidation != null) {
      return extraValidation;
    }

    return null;
  }
}
