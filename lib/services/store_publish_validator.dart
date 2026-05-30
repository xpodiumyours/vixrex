import 'package:vitrinx/models/store_data.dart';

class StorePublishValidator {
  const StorePublishValidator();

  String? validate(StoreData data) {
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

  bool _hasCompleteMarketplaceLink(StoreData data) {
    return data.marketplaceLinks.any(
      (link) => link.platform.trim().isNotEmpty && link.url.trim().isNotEmpty,
    );
  }
}
