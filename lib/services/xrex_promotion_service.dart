import 'package:vitrinx/services/xrex_profile_snapshot.dart';

enum XrexPromotionTone {
  short,
  friendly,
  professional,
}

class XrexPromotionDraft {
  final XrexPromotionTone tone;
  final String label;
  final String text;

  const XrexPromotionDraft({
    required this.tone,
    required this.label,
    required this.text,
  });
}

/// Yayındaki vitrin için tamamen yerel, düzenlenebilir tanıtım metinleri üretir.
abstract final class XrexPromotionService {
  static List<XrexPromotionDraft> draftsFor(XrexProfileSnapshot? snapshot) {
    final name = _valueOrFallback(snapshot?.storeName, 'İşletmemiz');
    final category = _valueOrFallback(snapshot?.category, 'ürün ve hizmetler');
    final district = snapshot?.district.trim() ?? '';
    final link = snapshot?.publicLink.trim() ?? '';
    final locationText = district.isEmpty ? '' : ' $district’te';
    final linkText = link.isEmpty ? '' : '\n$link';

    return [
      XrexPromotionDraft(
        tone: XrexPromotionTone.short,
        label: 'Kısa',
        text: '$name dijital vitrini yayında. Hemen inceleyin.$linkText',
      ),
      XrexPromotionDraft(
        tone: XrexPromotionTone.friendly,
        label: 'Samimi',
        text:
            'Merhaba!$locationText hizmet veren $name artık VitrinX’te. Ürünlerimize ve iletişim bilgilerimize tek bağlantıdan ulaşabilirsiniz.$linkText',
      ),
      XrexPromotionDraft(
        tone: XrexPromotionTone.professional,
        label: 'Profesyonel',
        text:
            '$name dijital vitrini yayına açıldı. $category, konum ve iletişim bilgilerimizi incelemek için bağlantıyı ziyaret edebilirsiniz.$linkText',
      ),
    ];
  }

  static String _valueOrFallback(String? value, String fallback) {
    final normalized = value?.trim() ?? '';
    return normalized.isEmpty ? fallback : normalized;
  }
}
