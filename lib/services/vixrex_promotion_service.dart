import 'package:vixrex/config/public_site_config.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';
import 'package:vixrex/services/category_image_service.dart';

enum VixRexPromotionTone {
  short,
  friendly,
  professional,
}

class VixRexPromotionDraft {
  final VixRexPromotionTone tone;
  final String label;
  final String text;

  const VixRexPromotionDraft({
    required this.tone,
    required this.label,
    required this.text,
  });
}

/// Yayındaki vitrin için tamamen yerel, düzenlenebilir tanıtım metinleri üretir.
abstract final class VixRexPromotionService {
  static List<VixRexPromotionDraft> draftsFor(VixRexProfileSnapshot? snapshot) {
    final name = _valueOrFallback(snapshot?.storeName, 'İşletmemiz');
    final category = _valueOrFallback(snapshot?.category, 'ürün ve hizmetler');
    final district = snapshot?.district.trim() ?? '';
    final rawLink = snapshot?.publicLink.trim() ?? '';
    final link = rawLink.isEmpty
        ? ''
        : PublicSiteConfig.repairPublicLink(rawLink);
    final locationText = district.isEmpty ? '' : ' $district’te';
    final linkText = link.isEmpty ? '' : '\n$link';

    return [
      VixRexPromotionDraft(
        tone: VixRexPromotionTone.short,
        label: 'Kısa',
        text: '$name dijital vitrini yayında. Hemen inceleyin.$linkText',
      ),
      VixRexPromotionDraft(
        tone: VixRexPromotionTone.friendly,
        label: 'Samimi',
        text:
            'Merhaba!$locationText hizmet veren $name artık Vixrex’te. Ürünlerimize ve iletişim bilgilerimize tek bağlantıdan ulaşabilirsiniz.$linkText',
      ),
      VixRexPromotionDraft(
        tone: VixRexPromotionTone.professional,
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

  /// vixrex'in "Hazır görseller kullan" önerisi için mesaj listesi
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

  /// vixrex'te gösterilecek tek bir auto-fill öneri mesajı seç
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
