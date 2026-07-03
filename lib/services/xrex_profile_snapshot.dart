import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/services/auto_fill_service.dart';
import 'package:vitrinx/services/store_local_storage_service.dart';
import 'package:vitrinx/utils/whatsapp_link_helper.dart';

// ─── Eksik alan enum'u ────────────────────────────────────────────────────────
enum XrexNextStep { name, whatsapp, address, legal, publish, share }

/// X-rex'in kullanıcıya göstereceği rehberlik aşaması.
enum XrexJourneyPhase { setup, publish, share, improve }

extension XrexNextStepLabel on XrexNextStep {
  String get label {
    switch (this) {
      case XrexNextStep.name:
        return 'İşletme adı';
      case XrexNextStep.whatsapp:
        return 'WhatsApp numarası';
      case XrexNextStep.address:
        return 'Adres / konum';
      case XrexNextStep.legal:
        return 'Yasal yayınlama onayları';
      case XrexNextStep.publish:
        return 'Yayınla';
      case XrexNextStep.share:
        return 'Paylaşım';
    }
  }
}

// ─── Snapshot ─────────────────────────────────────────────────────────────────
/// Vitrin durumunun kullanıcı dostu özeti.
/// Güvenlik: editToken, userId, session bilgisi içermez.
class XrexProfileSnapshot {
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

  const XrexProfileSnapshot({
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

  factory XrexProfileSnapshot.from(
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

    final legalOk =
        data.privacyNoticeAcknowledged &&
        data.privacyNoticeVersion.trim().isNotEmpty &&
        data.privacyNoticeHash.trim().isNotEmpty &&
        data.termsAccepted &&
        data.termsVersion.trim().isNotEmpty &&
        data.termsHash.trim().isNotEmpty &&
        data.publicationConsentAccepted &&
        data.publicationConsentVersion.trim().isNotEmpty &&
        data.publicationConsentHash.trim().isNotEmpty;

    final isPublished = publishedInfo != null && publishedInfo.isComplete;
    final coverCompleted = data.shelfImageUrl.trim().isNotEmpty;
    final galleryCompleted = data.galleryItems.isNotEmpty;
    final descriptionCompleted = data.description.trim().isNotEmpty;
    final catalogCompleted =
        data.products.isNotEmpty || data.offerings.isNotEmpty;
    // autoFillCompleted veri kaynagindan gelmez - ayri kontrol edilir

    return XrexProfileSnapshot(
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
      category:
          data.kategori.trim().isNotEmpty
              ? data.kategori.trim()
              : data.businessType.trim(),
      district: data.districtName.trim(),
      publicLink: publishedInfo?.publicLink.trim() ?? '',
    );
  }

  // ── Sıradaki Zorunlu Adım ─────────────────────────────────────────────────

  /// Yalnızca ilk eksik alanı döndürür.
  XrexNextStep get nextMissingField {
    if (!nameCompleted) return XrexNextStep.name;
    if (!whatsappCompleted) return XrexNextStep.whatsapp;
    if (!addressCompleted) return XrexNextStep.address;
    if (!legalCompleted) return XrexNextStep.legal;
    if (!isPublished) return XrexNextStep.publish;
    return XrexNextStep.share;
  }

  // ── Yardımcılar ───────────────────────────────────────────────────────────

  bool get isReadyToPublish =>
      nameCompleted &&
      whatsappCompleted &&
      addressCompleted &&
      legalCompleted &&
      !isPublished;

  bool get areRequiredFieldsCompleted =>
      nameCompleted && whatsappCompleted && addressCompleted && legalCompleted;

  int get completedRequiredStepCount =>
      [
        nameCompleted,
        whatsappCompleted,
        addressCompleted,
        legalCompleted,
      ].where((completed) => completed).length;

  XrexJourneyPhase journeyPhase({required bool hasShared}) {
    if (!areRequiredFieldsCompleted) return XrexJourneyPhase.setup;
    if (!isPublished) return XrexJourneyPhase.publish;
    if (!hasShared) return XrexJourneyPhase.share;
    return XrexJourneyPhase.improve;
  }
}

// ─── Snapshot Servis ─────────────────────────────────────────────────────────
/// HomeShellScreen'in lazy yükleme için kullandığı yardımcı.
class XrexSnapshotLoader {
  final StoreLocalStorageService _storage;

  const XrexSnapshotLoader({StoreLocalStorageService? storage})
    : _storage = storage ?? const StoreLocalStorageService();

  Future<XrexProfileSnapshot> load() async {
    final vitrinData = await _storage.loadVitrinData();
    final publishedInfo = await _storage.loadPublishedVitrinInfo();
    if (vitrinData == null) {
      return const XrexProfileSnapshot(
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
    return XrexProfileSnapshot.from(
      vitrinData,
      publishedInfo,
      autoFillCompleted: autoFillApplied,
    );
  }
}
