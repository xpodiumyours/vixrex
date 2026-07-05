import 'package:vitrinx/models/chat_message.dart';
import 'package:vitrinx/services/xrex_profile_snapshot.dart';

/// X-rex ekranı ve sohbeti tarafından ortak kullanılan tek öneri modeli.
class XrexRecommendation {
  final String id;
  final XrexJourneyPhase phase;
  final String title;
  final String description;
  final String buttonLabel;
  final XrexAction action;

  const XrexRecommendation({
    required this.id,
    required this.phase,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.action,
  });
}

// ─── Kalite Kontrol Öğeleri ─────────────────────────────────────────────────

class XrexQualityItem {
  final String id;
  final String label;
  final int points;
  final bool completed;
  final XrexAction action;

  const XrexQualityItem({
    required this.id,
    required this.label,
    required this.points,
    required this.completed,
    required this.action,
  });
}

// ─── Kalite Raporu ───────────────────────────────────────────────────────────

class XrexQualityReport {
  /// 0-100 arası normalize edilmiş kalite puanı
  final int score;
  final XrexQualityItem? nextImprovement;
  final List<XrexQualityItem> items;

  const XrexQualityReport({
    required this.score,
    this.nextImprovement,
    required this.items,
  });
}

// ─── Rehberlik Servisi ──────────────────────────────────────────────────────

class XrexGuidanceService {
  // ── Kalite Kontrol Listesi ───────────────────────────────────────────────

  static List<XrexQualityItem> qualityItems(
    XrexProfileSnapshot? snapshot,
  ) {
    return [
      XrexQualityItem(
        id: 'cover',
        label: 'Kapak fotoğrafı',
        points: 10,
        completed: snapshot?.coverCompleted ?? false,
        action: XrexAction.scrollToCover,
      ),
      XrexQualityItem(
        id: 'description',
        label: 'İşletme açıklaması',
        points: 10,
        completed: snapshot?.descriptionCompleted ?? false,
        action: XrexAction.scrollToDesc,
      ),
      XrexQualityItem(
        id: 'gallery',
        label: 'Galeri görselleri',
        points: 10,
        completed: snapshot?.galleryCompleted ?? false,
        action: XrexAction.scrollToGallery,
      ),
      XrexQualityItem(
        id: 'catalog',
        label: 'Ürün veya hizmetler',
        points: 10,
        completed: snapshot?.catalogCompleted ?? false,
        action: XrexAction.scrollToProducts,
      ),
      XrexQualityItem(
        id: 'auto_fill',
        label: 'Kategoriye özel görseller',
        points: 10,
        completed: snapshot?.autoFillCompleted ?? false,
        action: XrexAction.scrollToCategory,
      ),
    ];
  }

  static int maxQualityScore() {
    return qualityItems(null).fold(0, (s, i) => s + i.points);
  }

  // ── Kalite Raporu ────────────────────────────────────────────────────────

  static XrexQualityReport qualityReportFor({
    XrexProfileSnapshot? snapshot,
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

    return XrexQualityReport(
      score: normalizedScore,
      nextImprovement: next.completed ? null : next,
      items: items,
    );
  }

  // ── Öneri ────────────────────────────────────────────────────────────────

  static XrexRecommendation recommendationFor({
    XrexProfileSnapshot? snapshot,
    required bool hasShared,
  }) {
    if (snapshot == null) {
      return const XrexRecommendation(
        id: 'welcome',
        phase: XrexJourneyPhase.setup,
        title: 'Vitrininizi Oluşturun',
        description: 'VitrinX ile dijital vitrininizi oluşturmak için ilk adımı atın.',
        buttonLabel: 'Başla',
        action: XrexAction.openVitrim,
      );
    }

    // Setup phase
    final setupRec = setupRecommendation(snapshot);
    if (setupRec != null) return setupRec;

    // Yayınlanmamışsa
    if (!snapshot.isPublished) {
      return const XrexRecommendation(
        id: 'publish',
        phase: XrexJourneyPhase.publish,
        title: 'Vitrininizi Yayınlayın',
        description: 'Tüm gerekli bilgileri doldurdunuz. Şimdi vitrininizi yayınlayabilirsiniz.',
        buttonLabel: 'Yayınla',
        action: XrexAction.openVitrim,
      );
    }

    // Paylaşılmamışsa
    if (!hasShared) {
      return const XrexRecommendation(
        id: 'share',
        phase: XrexJourneyPhase.share,
        title: 'Vitrininizi Paylaşın',
        description: 'Vitrininiz yayında! Müşterilerinize ulaşmak için paylaşın.',
        buttonLabel: 'Paylaş',
        action: XrexAction.shareWhatsapp,
      );
    }

    // Improvement recommendations
    final improvements = improvementRecommendations(snapshot);
    if (improvements.isNotEmpty) return improvements.first;

    // Default: all done
    return const XrexRecommendation(
      id: 'all_done',
      phase: XrexJourneyPhase.improve,
      title: 'Tebrikler!',
      description: 'Vitrininiz harika görünüyor. Daha fazla özellik için bize ulaşabilirsiniz.',
      buttonLabel: 'Vitrinime Git',
      action: XrexAction.openVitrim,
    );
  }

  // ── Setup Rehberliği ─────────────────────────────────────────────────────

  /// Henüz yayınlanmamış vitrin için "sıradaki adım" önerisi.
  static XrexRecommendation? setupRecommendation(
    XrexProfileSnapshot snapshot,
  ) {
    if (snapshot.areRequiredFieldsCompleted) return null;

    final next = snapshot.nextMissingField;
    return _setupRecommendationFor(next);
  }

  static XrexRecommendation _setupRecommendationFor(
    XrexNextStep next,
  ) {
    return switch (next) {
      XrexNextStep.name => const XrexRecommendation(
        id: 'setup_name',
        phase: XrexJourneyPhase.setup,
        title: 'İşletme adınızı girin',
        description:
            'Vitrininizde görünecek işletme adınızı ekleyerek başlayın.',
        buttonLabel: 'İşletme Adı Ekle',
        action: XrexAction.scrollToName,
      ),
      XrexNextStep.whatsapp => const XrexRecommendation(
        id: 'setup_whatsapp',
        phase: XrexJourneyPhase.setup,
        title: 'WhatsApp numaranızı ekleyin',
        description:
            'Müşterilerinizin sizi hızlıca ulaşabilmesi için WhatsApp numaranızı girin.',
        buttonLabel: 'WhatsApp Ekle',
        action: XrexAction.scrollToWhatsapp,
      ),
      XrexNextStep.address => const XrexRecommendation(
        id: 'setup_address',
        phase: XrexJourneyPhase.setup,
        title: 'Adres ve konum bilgisi ekleyin',
        description:
            'Müşterilerin sizi bulabilmesi için adres ve konum bilgisi ekleyin.',
        buttonLabel: 'Adres Ekle',
        action: XrexAction.scrollToAddress,
      ),
      XrexNextStep.legal => const XrexRecommendation(
        id: 'setup_legal',
        phase: XrexJourneyPhase.setup,
        title: 'Yasal onayları tamamlayın',
        description:
            'Vitrininizi yayınlayabilmeniz için gerekli yasal onayları vermeniz gerekiyor.',
        buttonLabel: 'Onayları İncele',
        action: XrexAction.scrollToLegal,
      ),
      _ => const XrexRecommendation(
        id: 'setup_publish',
        phase: XrexJourneyPhase.setup,
        title: 'Vitrininizi yayınlayın',
        description:
            'Tüm gerekli bilgileri doldurdunuz. Şimdi vitrininizi yayınlayabilirsiniz.',
        buttonLabel: 'Vitrinimi Aç',
        action: XrexAction.openVitrim,
      ),
    };
  }

  // ── Publish Sonrası Öneriler ─────────────────────────────────────────────

  /// Yayınlandıktan sonraki iyileştirme önerileri.
  static List<XrexRecommendation> improvementRecommendations(
    XrexProfileSnapshot snapshot,
  ) {
    final items = <XrexRecommendation>[];

    if (!snapshot.coverCompleted) {
      items.add(
        const XrexRecommendation(
          id: 'improve_cover',
          phase: XrexJourneyPhase.improve,
          title: 'Kapak fotoğrafı ekleyin',
          description:
              'Vitrininize kapak fotoğrafı ekleyerek daha profesyonel görünmesini sağlayın.',
          buttonLabel: 'Kapak Fotoğrafına Git',
          action: XrexAction.scrollToCover,
        ),
      );
    }

    if (!snapshot.galleryCompleted) {
      items.add(
        const XrexRecommendation(
          id: 'improve_gallery',
          phase: XrexJourneyPhase.improve,
          title: 'Galeri görselleri ekleyin',
          description:
              'Ürün veya hizmet fotoğraflarınızı galeriye ekleyin.',
          buttonLabel: 'Galeriye Git',
          action: XrexAction.scrollToGallery,
        ),
      );
    }

    if (!snapshot.descriptionCompleted) {
      items.add(
        const XrexRecommendation(
          id: 'improve_desc',
          phase: XrexJourneyPhase.improve,
          title: 'İşletme açıklaması ekleyin',
          description:
              'İşletmenizi tanıtan kısa bir açıklama ekleyin.',
          buttonLabel: 'Açıklamaya Git',
          action: XrexAction.scrollToDesc,
        ),
      );
    }

    if (!snapshot.catalogCompleted) {
      items.add(
        const XrexRecommendation(
          id: 'improve_catalog',
          phase: XrexJourneyPhase.improve,
          title: 'Ürün veya hizmet ekleyin',
          description:
              'Müşterilerinize sunduğunuz ürün ve hizmetleri ekleyin.',
          buttonLabel: 'Ürün/Hizmet Alanına Git',
          action: XrexAction.scrollToProducts,
        ),
      );
    }

    return items;
  }

  // ── Selamlama Mesajı ─────────────────────────────────────────────────────

  static String greetingMessage(XrexProfileSnapshot? snapshot) {
    if (snapshot == null || snapshot.storeName.isEmpty) {
      return 'Merhaba! Vitrininizi oluşturmak ve geliştirmek için size yardımcı olabilirim. Nasıl başlamak istersiniz?';
    }

    final score = _calculateScore(snapshot);
    final maxScore = maxQualityScore();

    if (score >= maxScore * 0.8) {
      return '${snapshot.storeName} vitrini harika görünüyor! Kalite puanınız $score/$maxScore. Paylaşım veya ek özellikler hakkında yardımcı olabilirim.';
    } else if (score >= maxScore * 0.5) {
      return '${snapshot.storeName} vitrini iyi gidiyor! Kalite puanınız $score/$maxScore. Bazı iyileştirmelerle daha da profesyonel görünebilir.';
    } else {
      return '${snapshot.storeName} vitrininizi geliştirelim! Mevcut kalite puanınız $score/$maxScore. Size adım adım yardımcı olabilirim.';
    }
  }

  static int _calculateScore(XrexProfileSnapshot snapshot) {
    return qualityItems(snapshot)
        .where((item) => item.completed)
        .fold(0, (sum, item) => sum + item.points);
  }
}
