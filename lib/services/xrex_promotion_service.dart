import 'package:vitrinx/services/xrex_profile_snapshot.dart';
import 'package:vitrinx/services/category_image_service.dart';

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

  // ─── Hazır Görsel Sablon Mesajları ──────────────────────────────────────────

  /// xrex'in "Hazır görseller kullan" önerisi için mesaj listesi
  static List<String> getAutoFillPrompts({
    required String category,
    int? availableCount,
  }) {
    final countText = availableCount != null ? '$availableCount adet' : 'onlarca';
    final categoryLabel = category.trim().isEmpty ? 'bu kategori' : category;

    return [
      '$categoryLabel vitrinin için hazır görseller eklemek ister misin? Tek tıkla kapak, galeri ve ürün görselleri otomatik dolsun.',
      'Vitrin kalite puanını +40 artır! $categoryLabel kategorisine özel $countText hazır görsel seni bekliyor.',
      'Görsel ekleme derdine son! $categoryLabel şablonlarımızla vitrinini dakikalar içinde tamamla.',
      'Profesyonel vitrin için profesyonel görseller. $categoryLabel kategorisinde $countText hazır şablon var.',
      'Hala boş vitrin mi? $categoryLabel için özenle seçilmiş $countText görselle vitrinini şimdi tamamla!',
    ];
  }

  /// xrex'te gösterilecek tek bir auto-fill öneri mesajı seç
  static String pickAutoFillPrompt({
    required String category,
    int? availableCount,
  }) {
    final prompts = getAutoFillPrompts(
      category: category,
      availableCount: availableCount,
    );
    // Kategori key'ine göre deterministik seç (her seferinde aynı mesaj)
    final key = mapKategoriToKey(category) ?? category;
    final index = key.hashCode.abs() % prompts.length;
    return prompts[index];
  }
}
