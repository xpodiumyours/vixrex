/// Form validasyon yardımcıları.
class Validators {
  const Validators._();

  /// TR WhatsApp numarası: 0 5XX XXX XX XX veya +90 5XX XXX XX XX
  static final RegExp _whatsappTr = RegExp(
    r'^(?:\+?90|0)?5[0-9]{2}\s?[0-9]{3}\s?[0-9]{2}\s?[0-9]{2}$',
  );

  /// Genel telefon numarası (uluslararası).
  static final RegExp _phone = RegExp(
    r'^\+?[0-9]{7,15}$',
  );

  /// URL doğrulama.
  static final RegExp _url = RegExp(
    r'^https?://[^\s/$.?#].[^\s]*$',
  );

  /// Instagram kullanıcı adı veya URL'i.
  static final RegExp _instagram = RegExp(
    r'^(?:https?://(?:www\.)?instagram\.com/)?@?[a-zA-Z0-9_.]{1,30}$',
  );

  /// WhatsApp numarası doğrula (TR).
  static String? validateWhatsApp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'WhatsApp numarası zorunludur.';
    }
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!_whatsappTr.hasMatch(cleaned) && !_phone.hasMatch(cleaned)) {
      return 'Geçerli bir telefon numarası girin (05XX XXX XX XX).';
    }
    return null;
  }

  /// URL doğrula.
  static String? validateUrl(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) return null;
    if (!_url.hasMatch(value.trim())) {
      return '${fieldName ?? "URL"} geçerli değil. http:// veya https:// ile başlamalı.';
    }
    return null;
  }

  /// Instagram doğrula.
  static String? validateInstagram(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!_instagram.hasMatch(value.trim())) {
      return 'Geçerli bir Instagram kullanıcı adı veya linki girin.';
    }
    return null;
  }

  /// Zorunlu alan doğrula.
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName zorunludur.';
    }
    return null;
  }

  /// Telefon numarasını formatla: 05XX XXX XX XX
  static String formatPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return raw;
    final body = digits.length > 10 ? digits.substring(digits.length - 10) : digits;
    if (body.length != 10) return raw;
    return '${body.substring(0, 4)} ${body.substring(4, 7)} ${body.substring(7, 9)} ${body.substring(9)}';
  }
}
