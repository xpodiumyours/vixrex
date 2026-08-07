import 'package:vixrex/config/vitrin_alanlari.g.dart';
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
  static const int requiredStepCount = 4;

  final bool nameCompleted;
  final bool whatsappCompleted;
  final bool addressCompleted;
  final bool legalCompleted;
  final bool coverCompleted;
  final bool galleryCompleted;
  final bool descriptionCompleted;
  final bool catalogCompleted;
  final bool autoFillCompleted;
  final bool isPublished;
  final String storeName;
  final String category;
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
    required this.isPublished,
    required this.storeName,
    required this.category,
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
      isPublished: isPublished,
      storeName: data.name.trim(),
      category: data.kategori.trim(),
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
      case 'adres':
        return addressCompleted;
      case 'kategori':
        return categoryCompleted;
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
      switch (eksik.anahtar) {
        case 'isletmeAdi':
          return VixRexNextStep.name;
        case 'kategori':
          return VixRexNextStep.category;
        case 'whatsapp':
          return VixRexNextStep.whatsapp;
        case 'adres':
          return VixRexNextStep.address;
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
