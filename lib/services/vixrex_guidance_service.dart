import 'package:vixrex/config/vixrex_mesajlar.g.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';

/// `<id>_baslik`/`_aciklama`/`_buton` anahtarlı üçlüyü kataloğdan okur.
/// Faz G3 hazırlığı (2026-08-15): önceki turda her `VixRexRecommendation`
/// metni burada satır içi yazılıydı — Next.js'in aynı öneriyi göstermesi
/// için kaynak yoktu. Artık tek kaynak `shared/vixrex_mesajlar.json`;
/// `assistantState.ts` aynı `<id>_*` anahtarlarını okuyor.
VixRexRecommendation _katalogdanOneri({
  required String id,
  required VixRexJourneyPhase phase,
  required VixRexAction action,
}) {
  return VixRexRecommendation(
    id: id,
    phase: phase,
    title: vixRexMesajlari['${id}_baslik']!,
    description: vixRexMesajlari['${id}_aciklama']!,
    buttonLabel: vixRexMesajlari['${id}_buton']!,
    action: action,
  );
}

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
  // ── Kalite Kontrol Listesi (KULLANILMIYOR — bkz. not) ────────────────────

  /// UYARI — ÖLÜ KOD: bu listenin ürettiği skor (`qualityReportFor().score`)
  /// `ChatMessage.snapshotScore` alanına yazılıp `ChatScoreBar` ile
  /// çizilecek şekilde tasarlanmış, ama `snapshotScore:` hiçbir çağrı
  /// noktasında gerçek bir değerle set edilmiyor — hep `null` kalıyor, o
  /// yüzden `ChatScoreBar` hiçbir zaman ekrana çıkmıyor (doğrulandı,
  /// 2026-08-15). Kullanıcıya gerçekten gösterilen "vitrinini güzelleştir"
  /// önerileri `improvementRecommendations()`'tan gelir — şemanın 6 kalite
  /// alanı (kapak dışındakiler) oraya eklendi, BURAYA değil.
  ///
  /// Bu liste silinmedi çünkü `AssistantState`/testler ona referans veriyor
  /// ve yeniden bağlanabilir — ama şu an ekranda görünmüyor. Buraya
  /// "kalite alanı eksik" diye yeni kalem eklemek gerçek kullanıcıya hiçbir
  /// şey göstermez; asıl kapsam `improvementRecommendations()`'ta.
  ///
  /// Flutter'a özgü 5 kalite kalemi — şemadaki `kaliteAlanlari` (7 alan)
  /// İLE BİRLEŞTİRİLMEMİŞTİR. Bu BİLİNÇLİ bir karar (ADR 0001 madde 4,
  /// 2026-08-10) — "listeyi değiştir" gibi görünen ama öyle olmayan bir iş:
  ///
  /// | Bu kalem | Şemadaki `kalite` alanı | Not |
  /// |---|---|---|
  /// | `cover` | `kapakGorseli` (shelf_image_url) | TEK gerçek örtüşme — ikisi de aynı sütuna bakıyor |
  /// | `description` | — | `descriptionCompleted` KISA `description` (hero) alanına bakar; şemanın `hakkindaMetin` (kalite, `corporate_bio`) alanı AYRI bir alandır, bakılmaz |
  /// | `gallery` | — | Şemada hiç yok — galeri öğesi var mı, Flutter'a özgü operasyonel durum |
  /// | `catalog` | — | Şemada hiç yok — ürün/hizmet sayısı, vitrin İÇERİK alanı değil |
  /// | `auto_fill` | — | Şemada hiç yok — kategori-şablon görseli uygulandı mı, Flutter'a özgü |
  static List<VixRexQualityItem> qualityItems(VixRexProfileSnapshot? snapshot) {
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
        action: VixRexAction.openCoverTemplatePicker,
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
    final rawScore = items
        .where((i) => i.completed)
        .fold(0, (s, i) => s + i.points);
    final maxScore = maxQualityScore();

    /// Normalize: raw 0-50 → 0-100 ölçek
    final normalizedScore =
        maxScore > 0 ? ((rawScore / maxScore) * 100).round().clamp(0, 100) : 0;

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
      return _katalogdanOneri(
        id: 'welcome',
        phase: VixRexJourneyPhase.setup,
        action: VixRexAction.openVitrim,
      );
    }

    // Setup phase
    final setupRec = setupRecommendation(snapshot);
    if (setupRec != null) return setupRec;

    // Yayınlanmamışsa
    if (!snapshot.isPublished) {
      return _katalogdanOneri(
        id: 'publish',
        phase: VixRexJourneyPhase.publish,
        action: VixRexAction.openVitrim,
      );
    }

    // Yayın sonrası: önce görünüm/ürün (kategori → şablon → ürün), paylaşım sonra.
    final improvements = improvementRecommendations(snapshot);
    for (final rec in improvements) {
      if (rec.id == 'improve_category' ||
          rec.id == 'improve_cover' ||
          rec.id == 'improve_catalog') {
        return rec;
      }
    }

    if (!hasShared) {
      return _katalogdanOneri(
        id: 'share',
        phase: VixRexJourneyPhase.share,
        action: VixRexAction.shareWhatsapp,
      );
    }

    if (improvements.isNotEmpty) return improvements.first;

    return _katalogdanOneri(
      id: 'all_done',
      phase: VixRexJourneyPhase.improve,
      action: VixRexAction.openVitrim,
    );
  }

  // ── Setup Rehberliği ─────────────────────────────────────────────────────

  /// Henüz yayınlanmamış vitrin için "sıradaki adım" önerisi.
  static VixRexRecommendation? setupRecommendation(
    VixRexProfileSnapshot snapshot,
  ) {
    // Yayınlanmış vitrine kurulum önerisi verilmez.
    //
    // Kategori zorunlu olunca (2026-08-06) daha önce yayınlanmış vitrinler
    // "zorunlu alan eksik" durumuna düştü ve asistan zaten yayında olana
    // "vitrinini yayınla" demeye başladı. Yayınlanmış vitrinin eksiği
    // geliştirme işidir, kurulum değil.
    if (snapshot.isPublished) return null;
    if (snapshot.areRequiredFieldsCompleted) return null;

    final next = snapshot.nextMissingField;
    return _setupRecommendationFor(next);
  }

  static VixRexRecommendation _setupRecommendationFor(VixRexNextStep next) {
    return switch (next) {
      // Kurulum CTA'ları form dump etmez → Vixrex sekmesi (gömülü onboarding).
      VixRexNextStep.name => _katalogdanOneri(
        id: 'setup_name',
        phase: VixRexJourneyPhase.setup,
        action: VixRexAction.openVitrim,
      ),
      // Faz G3 hazırlığı düzeltmesi (2026-08-15): bu case hiç yoktu —
      // kategori eksikken switch default'a (setup_publish: "tüm bilgileri
      // doldurdunuz, yayınlayın") düşüyordu. Gerçek bulgu: kategori
      // zorunlu alan olduğu hâlde eksikken asistan yanlışlıkla "hazırsın"
      // diyordu. nextMissingField zaten `.category`'yi doğru üretiyordu
      // (bkz. vixrex_profile_snapshot.dart) — burada hiç ele alınmamıştı.
      VixRexNextStep.category => _katalogdanOneri(
        id: 'setup_category',
        phase: VixRexJourneyPhase.setup,
        action: VixRexAction.openVitrim,
      ),
      VixRexNextStep.whatsapp => _katalogdanOneri(
        id: 'setup_whatsapp',
        phase: VixRexJourneyPhase.setup,
        action: VixRexAction.openVitrim,
      ),
      VixRexNextStep.address => _katalogdanOneri(
        id: 'setup_address',
        phase: VixRexJourneyPhase.setup,
        action: VixRexAction.openVitrim,
      ),
      VixRexNextStep.legal => _katalogdanOneri(
        id: 'setup_legal',
        phase: VixRexJourneyPhase.setup,
        action: VixRexAction.openVitrim,
      ),
      _ => _katalogdanOneri(
        id: 'setup_publish',
        phase: VixRexJourneyPhase.setup,
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

    if (!snapshot.categoryCompleted) {
      items.add(
        _katalogdanOneri(
          id: 'improve_category',
          phase: VixRexJourneyPhase.improve,
          action: VixRexAction.openCoverTemplatePicker,
        ),
      );
    }

    if (!snapshot.coverCompleted) {
      items.add(
        _katalogdanOneri(
          id: 'improve_cover',
          phase: VixRexJourneyPhase.improve,
          action: VixRexAction.openCoverTemplatePicker,
        ),
      );
    }

    if (!snapshot.galleryCompleted) {
      items.add(
        _katalogdanOneri(
          id: 'improve_gallery',
          phase: VixRexJourneyPhase.improve,
          action: VixRexAction.scrollToGallery,
        ),
      );
    }

    if (!snapshot.descriptionCompleted) {
      items.add(
        _katalogdanOneri(
          id: 'improve_desc',
          phase: VixRexJourneyPhase.improve,
          action: VixRexAction.scrollToDesc,
        ),
      );
    }

    if (!snapshot.catalogCompleted) {
      items.add(
        _katalogdanOneri(
          id: 'improve_catalog',
          phase: VixRexJourneyPhase.improve,
          action: VixRexAction.scrollToProducts,
        ),
      );
    }

    // ── Faz F takibi: şemadaki 7 kalite alanının, kapak dışında kalan 6'sı.
    // Önceden bu 6'sı Flutter'ın öneri motorunda hiç yoktu — yalnız
    // Next.js'in hazırlık raporu biliyordu (bkz. docs/alan-eslemesi.md).
    // Ayrı ayrı eklendi, birleştirilmedi — her biri şemada nasılsa öyle.
    if (!snapshot.heroBadgeCompleted) {
      items.add(
        _katalogdanOneri(
          id: 'improve_hero_badge',
          phase: VixRexJourneyPhase.improve,
          action: VixRexAction.openVitrim,
        ),
      );
    }

    if (!snapshot.logoCompleted) {
      items.add(
        _katalogdanOneri(
          id: 'improve_logo',
          phase: VixRexJourneyPhase.improve,
          action: VixRexAction.openVitrim,
        ),
      );
    }

    if (!snapshot.workingHoursCompleted) {
      items.add(
        _katalogdanOneri(
          id: 'improve_working_hours',
          phase: VixRexJourneyPhase.improve,
          action: VixRexAction.openVitrim,
        ),
      );
    }

    if (!snapshot.googleLinkCompleted) {
      items.add(
        _katalogdanOneri(
          id: 'improve_google_link',
          phase: VixRexJourneyPhase.improve,
          action: VixRexAction.openVitrim,
        ),
      );
    }

    if (!snapshot.aboutTitleCompleted) {
      items.add(
        _katalogdanOneri(
          id: 'improve_about_title',
          phase: VixRexJourneyPhase.improve,
          action: VixRexAction.openVitrim,
        ),
      );
    }

    if (!snapshot.aboutBioCompleted) {
      items.add(
        _katalogdanOneri(
          id: 'improve_about_bio',
          phase: VixRexJourneyPhase.improve,
          action: VixRexAction.openVitrim,
        ),
      );
    }

    // ── Randevu sistemi ──
    items.add(
      _katalogdanOneri(
        id: 'improve_booking',
        phase: VixRexJourneyPhase.improve,
        action: VixRexAction.scrollToCategory,
      ),
    );

    // ── Blog / duyuru ──
    items.add(
      _katalogdanOneri(
        id: 'improve_blog',
        phase: VixRexJourneyPhase.improve,
        action: VixRexAction.openVitrim,
      ),
    );

    // ── SEO ayarları ──
    items.add(
      _katalogdanOneri(
        id: 'improve_seo',
        phase: VixRexJourneyPhase.improve,
        action: VixRexAction.openVitrim,
      ),
    );

    // ── Hesap güvence ──
    items.add(
      _katalogdanOneri(
        id: 'improve_account',
        phase: VixRexJourneyPhase.improve,
        action: VixRexAction.openAuth,
      ),
    );

    return items;
  }
}
