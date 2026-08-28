import 'package:vixrex/config/vitrin_alanlari.g.dart';
import 'package:vixrex/config/vixrex_mesajlar.g.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/auto_fill_service.dart';
import 'package:vixrex/services/store_local_storage_service.dart';
import 'package:vixrex/utils/whatsapp_link_helper.dart';

// ─── Eksik alan enum'u ────────────────────────────────────────────────────────
/// Kurulum akışındaki duraklar.
///
/// Alan durakları (name, category, whatsapp, address) ŞEMADAN gelir —
/// hangisinin zorunlu olduğu ve hangi sırayla sorulacağı
/// lib/config/vitrin_alanlari.g.dart içinde tanımlıdır.
/// legal / publish / share alan değil, akış aşamasıdır.
enum VixRexNextStep { name, category, whatsapp, address, legal, publish, share }

/// VixRex'in kullanıcıya göstereceği rehberlik aşaması.
enum VixRexJourneyPhase { setup, publish, share, improve }

extension VixRexNextStepLabel on VixRexNextStep {
  String get label {
    switch (this) {
      case VixRexNextStep.name:
        return 'İşletme adı';
      case VixRexNextStep.category:
        return 'İşletme kategorisi';
      case VixRexNextStep.whatsapp:
        return 'WhatsApp numarası';
      case VixRexNextStep.address:
        return 'Adres / konum';
      case VixRexNextStep.legal:
        return 'Yasal yayınlama onayları';
      case VixRexNextStep.publish:
        return 'Yayınla';
      case VixRexNextStep.share:
        return 'Paylaşım';
    }
  }
}

// ─── Snapshot ─────────────────────────────────────────────────────────────────
/// Vitrin durumunun kullanıcı dostu özeti.
/// Güvenlik: editToken, userId, session bilgisi içermez.
class VixRexProfileSnapshot {
  final bool nameCompleted;
  final bool whatsappCompleted;
  final bool addressCompleted;
  final bool legalCompleted;
  final bool coverCompleted;
  final bool galleryCompleted;
  final bool descriptionCompleted;
  final bool catalogCompleted;
  final bool autoFillCompleted;
  // Faz F takibi (Tek Asistan planı): şemadaki 7 `kalite` alanının geri
  // kalanı — heroRozet/logo/çalışma saatleri/harita linki/hakkımızda
  // başlığı/hakkımızda metni. Önceden Flutter'ın aktif öneri motoru
  // (improvementRecommendations) bunları hiç sormuyordu; yalnız Next.js'in
  // genel hazırlık raporu biliyordu. Esnaf yalnız telefonu kullanıyorsa bu
  // 6 alan hiç dürtülmüyordu — iki yüzey farklı "vitrinini güzelleştir"
  // listesi gösteriyordu. Altısı da şemadaki 6 AYRI alana karşılık gelir —
  // hakkındaBaşlık ve hakkındaMetin birleştirilmedi, şemada nasılsa öyle.
  final bool heroBadgeCompleted;
  final bool logoCompleted;
  final bool workingHoursCompleted;
  final bool googleLinkCompleted;
  final bool aboutTitleCompleted;
  final bool aboutBioCompleted;
  final bool isPublished;
  final String storeName;
  final String category;
  final String address;
  final String province;
  final String district;
  final String publicLink;

  const VixRexProfileSnapshot({
    required this.nameCompleted,
    required this.whatsappCompleted,
    required this.addressCompleted,
    required this.legalCompleted,
    required this.coverCompleted,
    required this.galleryCompleted,
    required this.descriptionCompleted,
    required this.catalogCompleted,
    this.autoFillCompleted = false,
    this.heroBadgeCompleted = false,
    this.logoCompleted = false,
    this.workingHoursCompleted = false,
    this.googleLinkCompleted = false,
    this.aboutTitleCompleted = false,
    this.aboutBioCompleted = false,
    required this.isPublished,
    required this.storeName,
    required this.category,
    this.address = '',
    this.province = '',
    required this.district,
    required this.publicLink,
  });

  // ── Factory ───────────────────────────────────────────────────────────────

  factory VixRexProfileSnapshot.from(
    StoreData data,
    PublishedVitrinInfo? publishedInfo, {
    bool autoFillCompleted = false,
  }) {
    final nameOk = data.name.trim().isNotEmpty;
    final whatsappOk =
        data.whatsapp.trim().isNotEmpty &&
        WhatsAppLinkHelper.isValidTurkeyMobile(data.whatsapp);
    final addressOk =
        data.address.trim().isNotEmpty &&
        data.provinceName.trim().isNotEmpty &&
        data.districtName.trim().isNotEmpty;

    // Not: hash DB'de boş olabilir (bkz. StoreEditorController._stampAcceptedLegalDocuments).
    // Yayın kapısı (isLegalPublishReady) da hash'i şart koşmaz; burada da koşmuyoruz.
    final legalOk =
        data.privacyNoticeAcknowledged &&
        data.privacyNoticeVersion.trim().isNotEmpty &&
        data.termsAccepted &&
        data.termsVersion.trim().isNotEmpty &&
        data.publicationConsentAccepted &&
        data.publicationConsentVersion.trim().isNotEmpty;

    final isPublished = publishedInfo != null && publishedInfo.isComplete;
    final coverCompleted = data.shelfImageUrl.trim().isNotEmpty;
    final galleryCompleted = data.galleryItems.isNotEmpty;
    final descriptionCompleted = data.description.trim().isNotEmpty;
    final catalogCompleted =
        data.products.isNotEmpty || data.offerings.isNotEmpty;
    // autoFillCompleted veri kaynagindan gelmez - ayri kontrol edilir
    final heroBadgeCompleted = data.heroBadge.trim().isNotEmpty;
    final logoCompleted = (data.logoUrl ?? '').trim().isNotEmpty;
    final workingHoursCompleted = data.workingHours.trim().isNotEmpty;
    final googleLinkCompleted = data.googleBusinessLink.trim().isNotEmpty;
    // Şemada iki AYRI kalite alanı (hakkindaBaslik, hakkindaMetin) —
    // birleştirilmedi, ikisi de kendi başına kontrol edilir.
    final aboutTitleCompleted = data.aboutTitle.trim().isNotEmpty;
    final aboutBioCompleted = data.corporateBio.trim().isNotEmpty;

    return VixRexProfileSnapshot(
      nameCompleted: nameOk,
      whatsappCompleted: whatsappOk,
      addressCompleted: addressOk,
      legalCompleted: legalOk,
      coverCompleted: coverCompleted,
      galleryCompleted: galleryCompleted,
      descriptionCompleted: descriptionCompleted,
      catalogCompleted: catalogCompleted,
      autoFillCompleted: autoFillCompleted, // SnapshotLoader'dan ayarlanacak
      heroBadgeCompleted: heroBadgeCompleted,
      logoCompleted: logoCompleted,
      workingHoursCompleted: workingHoursCompleted,
      googleLinkCompleted: googleLinkCompleted,
      aboutTitleCompleted: aboutTitleCompleted,
      aboutBioCompleted: aboutBioCompleted,
      isPublished: isPublished,
      storeName: data.name.trim(),
      category: data.kategori.trim(),
      address: data.address.trim(),
      province: data.provinceName.trim(),
      district: data.districtName.trim(),
      publicLink: publishedInfo?.publicLink.trim() ?? '',
    );
  }

  // ── Sıradaki Zorunlu Adım ─────────────────────────────────────────────────

  /// Yalnızca ilk eksik alanı döndürür.
  /// Sıradaki eksik ZORUNLU alan — sıra ve küme ŞEMADAN gelir.
  ///
  /// Buraya kadar zorunlu alanlar elle sayılıyordu (ad → WhatsApp → adres).
  /// Next.js tarafı ise kendi listesini tutuyordu ve kategoriyi de zorunlu
  /// sayıyordu. İki farklı tanım yüzünden sohbetle açılan her vitrin
  /// kategorisiz ("Diğer") kalıyordu.
  ///
  /// Artık tek kaynak var: şemadaki `zorunlu` işareti. Yeni bir alanı
  /// zorunlu yapmak için şemaya tek satır yeter; burası kendiliğinden
  /// öğrenir.
  VitrinAlani? get sonrakiEksikZorunluAlan {
    for (final alan in zorunluAlanlar) {
      if (!_alanDolu(alan.anahtar)) return alan;
    }
    return null;
  }

  bool _alanDolu(String anahtar) {
    switch (anahtar) {
      case 'isletmeAdi':
        return nameCompleted;
      case 'whatsapp':
        return whatsappCompleted;
      // Faz F (Tek Asistan planı): il/ilçe artık şemada AYRI zorunlu alan
      // (Next.js tarafı bunları hiç bilmiyordu — bkz. docs/alan-eslemesi.md).
      // 'adres' burada BİLEREK yalnız ham adres metnine bakar —
      // addressCompleted (public getter, geriye dönük uyum için hâlâ
      // üçünü birlikte sayıyor) DEĞİL. Aksi hâlde zorunluAlanlar sırasında
      // 'adres' 'il'/'ilce'den önce geldiği için, il veya ilçe boşken
      // addressCompleted da false olur, sonrakiEksikZorunluAlan hep
      // 'adres' der ve 'il'/'ilce' case'lerine hiç sıra gelmez — tam da
      // zorunlu_alan_baglanti_test.dart'ın yakaladığı sapma buydu.
      case 'adres':
        return address.trim().isNotEmpty;
      case 'kategori':
        return categoryCompleted;
      case 'il':
        return province.trim().isNotEmpty;
      case 'ilce':
        return district.trim().isNotEmpty;
      default:
        // Şemaya yeni zorunlu alan eklenmiş ama buraya bağlanmamış.
        // Akışı tıkamamak için dolu sayılır; sözleşme testi bu boşluğu
        // yakalar ve bağlanmasını zorunlu kılar.
        return true;
    }
  }

  VixRexNextStep get nextMissingField {
    final eksik = sonrakiEksikZorunluAlan;
    if (eksik != null) {
      final akisAdimi = vixRexAsistanAdimiForAlan(eksik.anahtar);
      switch (akisAdimi?.id) {
        case 'name':
          return VixRexNextStep.name;
        case 'category':
          return VixRexNextStep.category;
        case 'whatsapp':
          return VixRexNextStep.whatsapp;
        case 'location':
          return VixRexNextStep.address;
        default:
          throw StateError(
            'Zorunlu ${eksik.anahtar} alanı Vixrex Asistan akışına bağlı değil.',
          );
      }
    }
    if (!legalCompleted) return VixRexNextStep.legal;
    if (!isPublished) return VixRexNextStep.publish;
    return VixRexNextStep.share;
  }

  // ── Yardımcılar ───────────────────────────────────────────────────────────

  bool get categoryCompleted =>
      category.trim().isNotEmpty &&
      category.trim().toLowerCase() != 'diger' &&
      category.trim().toLowerCase() != 'diğer';

  bool get isReadyToPublish => areRequiredFieldsCompleted && !isPublished;

  /// Zorunlu alanların HEPSİ dolu mu — küme şemadan gelir.
  ///
  /// Yasal onay şema alanı değil, akış aşamasıdır: onu veritabanı
  /// tetikleyicisi zorunlu tutuyor (PUBLICATION_CONSENT_REQUIRED).
  /// Bu yüzden ayrıca eklenir.
  bool get areRequiredFieldsCompleted =>
      zorunluAlanlar.every((a) => _alanDolu(a.anahtar)) && legalCompleted;

  /// Tamamlanan zorunlu adım sayısı — şemadaki alanlar + yasal onay.
  /// Elle sayı tutulmaz; şemaya zorunlu alan eklenince kendiliğinden artar.
  int get completedRequiredStepCount =>
      zorunluAlanlar.where((a) => _alanDolu(a.anahtar)).length +
      (legalCompleted ? 1 : 0);

  /// Toplam zorunlu adım sayısı — şemadan + yasal onay.
  int get totalRequiredStepCount => zorunluAlanlar.length + 1;

  VixRexJourneyPhase journeyPhase({required bool hasShared}) {
    // YAYIN ÖNCE SORULUR.
    //
    // Eskiden önce "zorunlu alanlar tamam mı" bakılıyordu. Kategori zorunlu
    // olunca (2026-08-06) daha önce yayınlanmış vitrinler "kurulum"
    // aşamasına düştü ve asistan zaten yayında olana "yayınla" demeye
    // başladı.
    //
    // Yayınlanmış bir vitrin kurulumu geçmiştir. Eksik alanı varsa bu
    // geliştirme işidir, kurulum değil.
    if (isPublished) {
      return hasShared ? VixRexJourneyPhase.improve : VixRexJourneyPhase.share;
    }
    if (!areRequiredFieldsCompleted) return VixRexJourneyPhase.setup;
    return VixRexJourneyPhase.publish;
  }
}

// ─── Snapshot Servis ─────────────────────────────────────────────────────────
/// HomeShellScreen'in lazy yükleme için kullandığı yardımcı.
class VixRexSnapshotLoader {
  final StoreLocalStorageService _storage;

  const VixRexSnapshotLoader({StoreLocalStorageService? storage})
    : _storage = storage ?? const StoreLocalStorageService();

  Future<VixRexProfileSnapshot> load() async {
    final vitrinData = await _storage.loadVitrinData();
    final publishedInfo = await _storage.loadPublishedVitrinInfo();
    if (vitrinData == null) {
      return const VixRexProfileSnapshot(
        nameCompleted: false,
        whatsappCompleted: false,
        addressCompleted: false,
        legalCompleted: false,
        coverCompleted: false,
        galleryCompleted: false,
        descriptionCompleted: false,
        catalogCompleted: false,
        autoFillCompleted: false,
        isPublished: false,
        storeName: '',
        category: '',
        district: '',
        publicLink: '',
      );
    }
    bool autoFillApplied = false;
    final storeId = vitrinData.id;
    if (storeId != null && storeId.trim().isNotEmpty) {
      try {
        autoFillApplied = await AutoFillService.wasAutoFillApplied(storeId);
      } catch (_) {
        autoFillApplied = false;
      }
    }
    return VixRexProfileSnapshot.from(
      vitrinData,
      publishedInfo,
      autoFillCompleted: autoFillApplied,
    );
  }
}
