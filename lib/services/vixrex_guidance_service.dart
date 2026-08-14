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
      return const VixRexRecommendation(
        id: 'welcome',
        phase: VixRexJourneyPhase.setup,
        title: 'Vitrininizi Oluşturun',
        description:
            'Vixrex ile dijital vitrininizi oluşturmak için ilk adımı atın.',
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
        description:
            'Tüm gerekli bilgileri doldurdunuz. Şimdi vitrininizi yayınlayabilirsiniz.',
        buttonLabel: 'Yayınla',
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
      description:
          'Vitrininiz harika görünüyor. Daha fazla özellik için bize ulaşabilirsiniz.',
      buttonLabel: 'Vitrinime Git',
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
      VixRexNextStep.name => const VixRexRecommendation(
        id: 'setup_name',
        phase: VixRexJourneyPhase.setup,
        title: 'İşletme adınızı girin',
        description:
            'Vitrininizde görünecek işletme adınızı ekleyerek başlayın.',
        buttonLabel: 'İşletme Adı Ekle',
        action: VixRexAction.openVitrim,
      ),
      VixRexNextStep.whatsapp => const VixRexRecommendation(
        id: 'setup_whatsapp',
        phase: VixRexJourneyPhase.setup,
        title: 'WhatsApp numaranızı ekleyin',
        description:
            'Müşterilerinizin sizi hızlıca ulaşabilmesi için WhatsApp numaranızı girin.',
        buttonLabel: 'WhatsApp Ekle',
        action: VixRexAction.openVitrim,
      ),
      VixRexNextStep.address => const VixRexRecommendation(
        id: 'setup_address',
        phase: VixRexJourneyPhase.setup,
        title: 'Adres ve konum bilgisi ekleyin',
        description:
            'Müşterilerin sizi bulabilmesi için adres ve konum bilgisi ekleyin.',
        buttonLabel: 'Adres Ekle',
        action: VixRexAction.openVitrim,
      ),
      VixRexNextStep.legal => const VixRexRecommendation(
        id: 'setup_legal',
        phase: VixRexJourneyPhase.setup,
        title: 'Yasal onayları tamamlayın',
        description:
            'Vitrininizi yayınlayabilmeniz için gerekli yasal onayları vermeniz gerekiyor.',
        buttonLabel: 'Onayları İncele',
        action: VixRexAction.openVitrim,
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

    if (!snapshot.categoryCompleted) {
      items.add(
        const VixRexRecommendation(
          id: 'improve_category',
          phase: VixRexJourneyPhase.improve,
          title: 'Şablonla güzelleştir',
          description:
              'Vitrinin yayında! Şimdi hazır şablonlardan birini seçelim ki '
              'işletmene özel tasarım ve görselleri ekleyelim.',
          buttonLabel: 'Hazır şablonları aç',
          action: VixRexAction.openCoverTemplatePicker,
        ),
      );
    }

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
          description: 'Ürün veya hizmet fotoğraflarınızı galeriye ekleyin.',
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
          description: 'İşletmenizi tanıtan kısa bir açıklama ekleyin.',
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

    // ── Faz F takibi: şemadaki 7 kalite alanının, kapak dışında kalan 6'sı.
    // Önceden bu 6'sı Flutter'ın öneri motorunda hiç yoktu — yalnız
    // Next.js'in hazırlık raporu biliyordu (bkz. docs/alan-eslemesi.md).
    // Ayrı ayrı eklendi, birleştirilmedi — her biri şemada nasılsa öyle.
    if (!snapshot.heroBadgeCompleted) {
      items.add(
        const VixRexRecommendation(
          id: 'improve_hero_badge',
          phase: VixRexJourneyPhase.improve,
          title: 'Kapak rozeti ekle',
          description:
              'Kapak fotoğrafının üstüne kısa bir rozet metni ekle — '
              'işletmeni bir bakışta anlatır. Örn: "Profesyonel Teknik '
              'Servis / Kadıköy".',
          buttonLabel: 'Rozet ekle',
          action: VixRexAction.openVitrim,
        ),
      );
    }

    if (!snapshot.logoCompleted) {
      items.add(
        const VixRexRecommendation(
          id: 'improve_logo',
          phase: VixRexJourneyPhase.improve,
          title: 'Logonu ekle',
          description:
              'İşletme logon vitrinin üst köşesinde görünür — kurumsal bir '
              'ilk izlenim bırakır.',
          buttonLabel: 'Logo ekle',
          action: VixRexAction.openVitrim,
        ),
      );
    }

    if (!snapshot.workingHoursCompleted) {
      items.add(
        const VixRexRecommendation(
          id: 'improve_working_hours',
          phase: VixRexJourneyPhase.improve,
          title: 'Çalışma saatlerini ekle',
          description:
              'Müşterin ne zaman açık olduğunu görsün, boşuna gelip seni '
              'kapalı bulmasın.',
          buttonLabel: 'Saatleri ekle',
          action: VixRexAction.openVitrim,
        ),
      );
    }

    if (!snapshot.googleLinkCompleted) {
      items.add(
        const VixRexRecommendation(
          id: 'improve_google_link',
          phase: VixRexJourneyPhase.improve,
          title: 'Google İşletme / harita bağlantını ekle',
          description:
              'Müşterin tek tıkla yol tarifi alsın veya Google\'daki '
              'işletme sayfana ulaşsın.',
          buttonLabel: 'Bağlantı ekle',
          action: VixRexAction.openVitrim,
        ),
      );
    }

    if (!snapshot.aboutTitleCompleted) {
      items.add(
        const VixRexRecommendation(
          id: 'improve_about_title',
          phase: VixRexJourneyPhase.improve,
          title: 'Hakkımızda başlığı ekle',
          description:
              'Hakkımızda bölümüne kısa, dikkat çekici bir başlık yaz.',
          buttonLabel: 'Başlık ekle',
          action: VixRexAction.openVitrim,
        ),
      );
    }

    if (!snapshot.aboutBioCompleted) {
      items.add(
        const VixRexRecommendation(
          id: 'improve_about_bio',
          phase: VixRexJourneyPhase.improve,
          title: 'İşletmenin hikayesini anlat',
          description:
              'Hakkımızda metnine işletmenin hikayesini, neyi farklı '
              'yaptığını yaz — müşteri seni tanısın.',
          buttonLabel: 'Hikayeni yaz',
          action: VixRexAction.openVitrim,
        ),
      );
    }

    // ── Randevu sistemi ──
    items.add(
      const VixRexRecommendation(
        id: 'improve_booking',
        phase: VixRexJourneyPhase.improve,
        title: 'Randevu sistemi kurun',
        description: 'Müşterileriniz online randevu alsın — 7/24 açık kalın.',
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
