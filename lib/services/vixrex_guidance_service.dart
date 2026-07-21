import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';

/// Vixrex ekranı ve sohbeti tarafından ortak kullanılan tek öneri modeli.
class VixRexRecommendation {
  final String id;
  final VixRexJourneyPhase phase;
  final String title;
  final String description;
  final String buttonLabel;
  final VixRexAction action;

  const VixRexRecommendation({
    required this.id,
    required this.phase,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.action,
  });
}

// ─── Kalite Kontrol Öğeleri ─────────────────────────────────────────────────

class VixRexQualityItem {
  final String id;
  final String label;
  final int points;
  final bool completed;
  final VixRexAction action;

  const VixRexQualityItem({
    required this.id,
    required this.label,
    required this.points,
    required this.completed,
    required this.action,
  });
}

// ─── Kalite Raporu ───────────────────────────────────────────────────────────

class VixRexQualityReport {
  /// 0-100 arası normalize edilmiş kalite puanı
  final int score;
  final VixRexQualityItem? nextImprovement;
  final List<VixRexQualityItem> items;

  const VixRexQualityReport({
    required this.score,
    this.nextImprovement,
    required this.items,
  });
}

// ─── Rehberlik Servisi ──────────────────────────────────────────────────────

class VixRexGuidanceService {
  // ── Kalite Kontrol Listesi ───────────────────────────────────────────────

  static List<VixRexQualityItem> qualityItems(
    VixRexProfileSnapshot? snapshot,
  ) {
    return [
      VixRexQualityItem(
        id: 'cover',
        label: 'Kapak fotoğrafı',
        points: 10,
        completed: snapshot?.coverCompleted ?? false,
        action: VixRexAction.openCoverTemplatePicker,
      ),
      VixRexQualityItem(
        id: 'description',
        label: 'İşletme açıklaması',
        points: 10,
        completed: snapshot?.descriptionCompleted ?? false,
        action: VixRexAction.scrollToDesc,
      ),
      VixRexQualityItem(
        id: 'gallery',
        label: 'Galeri görselleri',
        points: 10,
        completed: snapshot?.galleryCompleted ?? false,
        action: VixRexAction.scrollToGallery,
      ),
      VixRexQualityItem(
        id: 'catalog',
        label: 'Ürün veya hizmetler',
        points: 10,
        completed: snapshot?.catalogCompleted ?? false,
        action: VixRexAction.scrollToProducts,
      ),
      VixRexQualityItem(
        id: 'auto_fill',
        label: 'Kategoriye özel görseller',
        points: 10,
        completed: snapshot?.autoFillCompleted ?? false,
        action: VixRexAction.scrollToCategory,
      ),
    ];
  }

  static int maxQualityScore() {
    return qualityItems(null).fold(0, (s, i) => s + i.points);
  }

  // ── Kalite Raporu ────────────────────────────────────────────────────────

  static VixRexQualityReport qualityReportFor({
    VixRexProfileSnapshot? snapshot,
    required bool hasShared,
  }) {
    final items = qualityItems(snapshot);
    final rawScore = items.where((i) => i.completed).fold(0, (s, i) => s + i.points);
    final maxScore = maxQualityScore();

    /// Normalize: raw 0-50 → 0-100 ölçek
    final normalizedScore = maxScore > 0
        ? ((rawScore / maxScore) * 100).round().clamp(0, 100)
        : 0;

    final next = items.firstWhere(
      (i) => !i.completed,
      orElse: () => items.last,
    );

    return VixRexQualityReport(
      score: normalizedScore,
      nextImprovement: next.completed ? null : next,
      items: items,
    );
  }

  // ── Öneri ────────────────────────────────────────────────────────────────

  static VixRexRecommendation recommendationFor({
    VixRexProfileSnapshot? snapshot,
    required bool hasShared,
  }) {
    if (snapshot == null) {
      return const VixRexRecommendation(
        id: 'welcome',
        phase: VixRexJourneyPhase.setup,
        title: 'Vitrininizi Oluşturun',
        description: 'Vixrex ile dijital vitrininizi oluşturmak için ilk adımı atın.',
        buttonLabel: 'Başla',
        action: VixRexAction.openVitrim,
      );
    }

    // Setup phase
    final setupRec = setupRecommendation(snapshot);
    if (setupRec != null) return setupRec;

    // Yayınlanmamışsa
    if (!snapshot.isPublished) {
      return const VixRexRecommendation(
        id: 'publish',
        phase: VixRexJourneyPhase.publish,
        title: 'Vitrininizi Yayınlayın',
        description: 'Tüm gerekli bilgileri doldurdunuz. Şimdi vitrininizi yayınlayabilirsiniz.',
        buttonLabel: 'Yayınla',
        action: VixRexAction.openVitrim,
      );
    }

    // Yayın sonrası: önce görünüm/ürün (şablon → ürün), paylaşım sonra.
    final improvements = improvementRecommendations(snapshot);
    for (final rec in improvements) {
      if (rec.id == 'improve_cover' || rec.id == 'improve_catalog') {
        return rec;
      }
    }

    if (!hasShared) {
      return const VixRexRecommendation(
        id: 'share',
        phase: VixRexJourneyPhase.share,
        title: 'Vitrininizi Paylaşın',
        description:
            'Vitrinin hazır. Müşterilerine ulaştırmak için paylaşalım.',
        buttonLabel: 'Paylaş',
        action: VixRexAction.shareWhatsapp,
      );
    }

    if (improvements.isNotEmpty) return improvements.first;

    return const VixRexRecommendation(
      id: 'all_done',
      phase: VixRexJourneyPhase.improve,
      title: 'Tebrikler!',
      description: 'Vitrininiz harika görünüyor. Daha fazla özellik için bize ulaşabilirsiniz.',
      buttonLabel: 'Vitrinime Git',
      action: VixRexAction.openVitrim,
    );
  }

  // ── Setup Rehberliği ─────────────────────────────────────────────────────

  /// Henüz yayınlanmamış vitrin için "sıradaki adım" önerisi.
  static VixRexRecommendation? setupRecommendation(
    VixRexProfileSnapshot snapshot,
  ) {
    if (snapshot.areRequiredFieldsCompleted) return null;

    final next = snapshot.nextMissingField;
    return _setupRecommendationFor(next);
  }

  static VixRexRecommendation _setupRecommendationFor(
    VixRexNextStep next,
  ) {
    return switch (next) {
      VixRexNextStep.name => const VixRexRecommendation(
        id: 'setup_name',
        phase: VixRexJourneyPhase.setup,
        title: 'İşletme adınızı girin',
        description:
            'Vitrininizde görünecek işletme adınızı ekleyerek başlayın.',
        buttonLabel: 'İşletme Adı Ekle',
        action: VixRexAction.scrollToName,
      ),
      VixRexNextStep.whatsapp => const VixRexRecommendation(
        id: 'setup_whatsapp',
        phase: VixRexJourneyPhase.setup,
        title: 'WhatsApp numaranızı ekleyin',
        description:
            'Müşterilerinizin sizi hızlıca ulaşabilmesi için WhatsApp numaranızı girin.',
        buttonLabel: 'WhatsApp Ekle',
        action: VixRexAction.scrollToWhatsapp,
      ),
      VixRexNextStep.address => const VixRexRecommendation(
        id: 'setup_address',
        phase: VixRexJourneyPhase.setup,
        title: 'Adres ve konum bilgisi ekleyin',
        description:
            'Müşterilerin sizi bulabilmesi için adres ve konum bilgisi ekleyin.',
        buttonLabel: 'Adres Ekle',
        action: VixRexAction.scrollToAddress,
      ),
      VixRexNextStep.legal => const VixRexRecommendation(
        id: 'setup_legal',
        phase: VixRexJourneyPhase.setup,
        title: 'Yasal onayları tamamlayın',
        description:
            'Vitrininizi yayınlayabilmeniz için gerekli yasal onayları vermeniz gerekiyor.',
        buttonLabel: 'Onayları İncele',
        action: VixRexAction.scrollToLegal,
      ),
      _ => const VixRexRecommendation(
        id: 'setup_publish',
        phase: VixRexJourneyPhase.setup,
        title: 'Vitrininizi yayınlayın',
        description:
            'Tüm gerekli bilgileri doldurdunuz. Şimdi vitrininizi yayınlayabilirsiniz.',
        buttonLabel: 'Vitrinimi Aç',
        action: VixRexAction.openVitrim,
      ),
    };
  }

  // ── Publish Sonrası Öneriler ─────────────────────────────────────────────

  /// Yayınlandıktan sonraki iyileştirme önerileri.
  static List<VixRexRecommendation> improvementRecommendations(
    VixRexProfileSnapshot snapshot,
  ) {
    final items = <VixRexRecommendation>[];

    if (!snapshot.coverCompleted) {
      items.add(
        const VixRexRecommendation(
          id: 'improve_cover',
          phase: VixRexJourneyPhase.improve,
          title: 'Şablonla güzelleştir',
          description:
              'Güzel. Şimdi kategorine göre hazır şablonlardan birini seçelim — '
              'dijital vitrini hızlıca daha güzel yapalım.',
          buttonLabel: 'Hazır şablonları aç',
          action: VixRexAction.openCoverTemplatePicker,
        ),
      );
    }

    if (!snapshot.galleryCompleted) {
      items.add(
        const VixRexRecommendation(
          id: 'improve_gallery',
          phase: VixRexJourneyPhase.improve,
          title: 'Galeri görselleri ekleyin',
          description:
              'Ürün veya hizmet fotoğraflarınızı galeriye ekleyin.',
          buttonLabel: 'Galeriye Git',
          action: VixRexAction.scrollToGallery,
        ),
      );
    }

    if (!snapshot.descriptionCompleted) {
      items.add(
        const VixRexRecommendation(
          id: 'improve_desc',
          phase: VixRexJourneyPhase.improve,
          title: 'İşletme açıklaması ekleyin',
          description:
              'İşletmenizi tanıtan kısa bir açıklama ekleyin.',
          buttonLabel: 'Açıklamaya Git',
          action: VixRexAction.scrollToDesc,
        ),
      );
    }

    if (!snapshot.catalogCompleted) {
      items.add(
        const VixRexRecommendation(
          id: 'improve_catalog',
          phase: VixRexJourneyPhase.improve,
          title: 'Ürünleri yükle',
          description:
              'Müşterilerine gösterebilmen için ürünleri nasıl yükleyeceğimize '
              'karar verelim — tarayıcı veya elle ekleme.',
          buttonLabel: 'Ürün yükleme yolunu seç',
          action: VixRexAction.scrollToProducts,
        ),
      );
    }

    // ── Randevu sistemi ──
    items.add(
      const VixRexRecommendation(
        id: 'improve_booking',
        phase: VixRexJourneyPhase.improve,
        title: 'Randevu sistemi kurun',
        description:
            'Müşterileriniz online randevu alsın — 7/24 açık kalın.',
        buttonLabel: 'Randevu ayarları',
        action: VixRexAction.scrollToCategory,
      ),
    );

    // ── Blog / duyuru ──
    items.add(
      const VixRexRecommendation(
        id: 'improve_blog',
        phase: VixRexJourneyPhase.improve,
        title: 'Duyuru veya yazı paylaşın',
        description:
            'Kampanya, indirim veya haberlerinizi yazarak Google\'da üst sıralara çıkın.',
        buttonLabel: 'Vitrinime git',
        action: VixRexAction.openVitrim,
      ),
    );

    // ── SEO ayarları ──
    items.add(
      const VixRexRecommendation(
        id: 'improve_seo',
        phase: VixRexJourneyPhase.improve,
        title: 'Google görünürlüğünü güçlendirin',
        description:
            'Meta başlık, açıklama ve anahtar kelimelerinizi girerek arama sonuçlarında öne çıkın.',
        buttonLabel: 'Vitrinime git',
        action: VixRexAction.openVitrim,
      ),
    );

    // ── Hesap güvence ──
    items.add(
      const VixRexRecommendation(
        id: 'improve_account',
        phase: VixRexJourneyPhase.improve,
        title: 'Hesabınızı güvenceye alın',
        description:
            'Giriş yaparak vitrininizi hesabınıza bağlayın — verileriniz güvende kalsın.',
        buttonLabel: 'Hesap',
        action: VixRexAction.openAuth,
      ),
    );

    return items;
  }
}
