import '../config/business_category_config.dart';

class WhatsAppLinkHelper {
  const WhatsAppLinkHelper._();

  static const String invalidNumberMessage =
      'Geçerli bir Türkiye cep telefonu numarası girin. Örn: 0555 123 45 67';

  static String? normalizeTurkeyMobile(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || RegExp(r'[A-Za-zÇĞİÖŞÜçğıöşü]').hasMatch(trimmed)) {
      return null;
    }

    var digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0') && digits.length == 11) {
      digits = '90${digits.substring(1)}';
    } else if (digits.startsWith('5') && digits.length == 10) {
      digits = '90$digits';
    }

    if (!RegExp(r'^905\d{9}$').hasMatch(digits)) {
      return null;
    }
    return digits;
  }

  static bool isValidTurkeyMobile(String value) {
    return normalizeTurkeyMobile(value) != null;
  }

  static String? buildGeneralUrl({
    required String number,
    required String storeName,
  }) {
    final normalized = normalizeTurkeyMobile(number);
    if (normalized == null) return null;

    final cleanName = storeName.trim();
    final message =
        cleanName.isEmpty
            ? 'Merhaba, vitrininiz hakkında bilgi almak ve sipariş vermek istiyorum.'
            : 'Merhaba, $cleanName vitrininiz hakkında bilgi almak ve sipariş vermek istiyorum.';
    return _buildUrl(normalized, message);
  }

  static String? buildCategoryGeneralUrl({
    required String number,
    required String storeName,
    required String categoryId,
  }) {
    final normalized = normalizeTurkeyMobile(number);
    if (normalized == null) return null;

    final config = BusinessCategoryConfig.categories.firstWhere(
      (c) => c.id == categoryId || c.label == categoryId,
      orElse: () => BusinessCategoryConfig.categories.firstWhere((c) => c.id == 'diger'),
    );

    final cleanName = storeName.trim().isEmpty ? 'işletmeniz' : storeName.trim();
    final message = config.whatsappTemplate.replaceAll('{storeName}', cleanName);
    return _buildUrl(normalized, message);
  }

  static String? buildInquiryUrl({
    required String number,
    required String storeName,
    required String itemTitle,
  }) {
    final normalized = normalizeTurkeyMobile(number);
    if (normalized == null) return null;

    final cleanName =
        storeName.trim().isEmpty ? 'işletmenizin' : storeName.trim();
    final cleanTitle =
        itemTitle.trim().isEmpty ? 'vitrin görseli' : itemTitle.trim();
    final message =
        "Merhaba, $cleanName vitrininizdeki '$cleanTitle' hakkında bilgi almak istiyorum.";
    return _buildUrl(normalized, message);
  }

  static String? buildCategoryOfferingUrl({
    required String number,
    required String storeName,
    required String offeringTitle,
    required String categoryId,
  }) {
    final normalized = normalizeTurkeyMobile(number);
    if (normalized == null) return null;

    final config = BusinessCategoryConfig.categories.firstWhere(
      (c) => c.id == categoryId || c.label == categoryId,
      orElse: () => BusinessCategoryConfig.categories.firstWhere((c) => c.id == 'diger'),
    );

    final cleanName = storeName.trim().isEmpty ? 'işletmeniz' : storeName.trim();
    final cleanTitle = offeringTitle.trim();

    String action = 'hakkında bilgi almak';
    if (config.ctaLabel.contains('Sipariş')) {
      action = 'siparişi vermek';
    } else if (config.ctaLabel.contains('Randevu')) {
      action = 'randevusu oluşturmak';
    } else if (config.ctaLabel.contains('Servis')) {
      action = 'servis talebi oluşturmak';
    } else if (config.ctaLabel.contains('Teklif')) {
      action = 'teklifi almak';
    }

    final message = "Merhaba, $cleanName. '$cleanTitle' $action istiyorum.";
    return _buildUrl(normalized, message);
  }

  static String _buildUrl(String normalizedNumber, String message) {
    return Uri.https('wa.me', '/$normalizedNumber', {
      'text': message,
    }).toString();
  }
}
