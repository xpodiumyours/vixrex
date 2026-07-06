import 'package:vixrex/models/store_data.dart';

class StorePublishLinksValidator {
  const StorePublishLinksValidator();

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
    'diger',
  };

  String? validateLinksAndOfferings(StoreData data) {
    for (final link in data.marketplaceLinks) {
      final trimmedUrl = link.url.trim();
      final platformLower = link.platform.trim().toLowerCase();
      final isCustom =
          platformLower.isNotEmpty &&
          !_standardPlatforms.contains(platformLower);

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
      return 'En fazla 6 adet randevu hizmeti ekleyebilirsiniz.';
    }
    for (final offering in data.offerings) {
      if (offering.title.trim().isEmpty) {
        return 'Randevu hizmeti başlığı boş olamaz.';
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
}
