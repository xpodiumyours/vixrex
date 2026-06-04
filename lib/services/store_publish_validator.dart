import 'package:vitrinx/models/store_data.dart';

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
    final missingItems = <String>[];

    if (data.name.trim().isEmpty) {
      missingItems.add('mağaza adı');
    }
    if (data.whatsapp.trim().isEmpty) {
      missingItems.add('WhatsApp numarası');
    }
    if (data.description.trim().isEmpty) {
      missingItems.add('kısa açıklama');
    }
    if (!_hasCompleteMarketplaceLink(data)) {
      missingItems.add('en az 1 pazaryeri linki');
    }
    if (data.address.trim().isEmpty) {
      missingItems.add('adres bilgisi');
    }

    if (missingItems.isEmpty) return null;

    return 'Vitrin yayınlanmadan önce şu alanları tamamlayın: ${missingItems.join(', ')}.';
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

    // Validate products if present
    for (final product in data.products) {
      if (product.name.trim().isEmpty) {
        return 'Eklenen tüm ürünlerin adı zorunludur.';
      }
    }

    return null;
  }

  bool _hasCompleteMarketplaceLink(StoreData data) {
    return data.marketplaceLinks.any(
      (link) => link.platform.trim().isNotEmpty && link.url.trim().isNotEmpty,
    );
  }
}
