import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/services/store_local_storage_service.dart';
import 'package:vitrinx/utils/whatsapp_link_helper.dart';

// ─── Eksik alan enum'u ────────────────────────────────────────────────────────
enum XrexNextStep {
  name,
  whatsapp,
  address,
  legal,
  publish,
  share,
}

extension XrexNextStepLabel on XrexNextStep {
  String get label {
    switch (this) {
      case XrexNextStep.name:     return 'İşletme adı';
      case XrexNextStep.whatsapp: return 'WhatsApp numarası';
      case XrexNextStep.address:  return 'Adres / konum';
      case XrexNextStep.legal:    return 'Yasal yayınlama onayları';
      case XrexNextStep.publish:  return 'Yayınla';
      case XrexNextStep.share:    return 'Paylaşım';
    }
  }
}

// ─── Snapshot ─────────────────────────────────────────────────────────────────
/// Vitrin durumunun kullanıcı dostu özeti.
/// Güvenlik: editToken, userId, session bilgisi içermez.
class XrexProfileSnapshot {
  final bool nameCompleted;
  final bool whatsappCompleted;
  final bool addressCompleted;
  final bool legalCompleted;
  final bool isPublished;

  const XrexProfileSnapshot({
    required this.nameCompleted,
    required this.whatsappCompleted,
    required this.addressCompleted,
    required this.legalCompleted,
    required this.isPublished,
  });

  // ── Factory ───────────────────────────────────────────────────────────────

  factory XrexProfileSnapshot.from(
    StoreData data,
    PublishedVitrinInfo? publishedInfo,
  ) {
    final nameOk     = data.name.trim().isNotEmpty;
    final whatsappOk = data.whatsapp.trim().isNotEmpty &&
                       WhatsAppLinkHelper.isValidTurkeyMobile(data.whatsapp);
    final addressOk  = data.address.trim().isNotEmpty &&
                       data.provinceName.trim().isNotEmpty &&
                       data.districtName.trim().isNotEmpty;
    
    final legalOk = data.privacyNoticeAcknowledged &&
                    data.privacyNoticeVersion.trim().isNotEmpty &&
                    data.privacyNoticeHash.trim().isNotEmpty &&
                    data.termsAccepted &&
                    data.termsVersion.trim().isNotEmpty &&
                    data.termsHash.trim().isNotEmpty &&
                    data.publicationConsentAccepted &&
                    data.publicationConsentVersion.trim().isNotEmpty &&
                    data.publicationConsentHash.trim().isNotEmpty;

    final isPublished = publishedInfo != null && publishedInfo.isComplete;

    return XrexProfileSnapshot(
      nameCompleted:     nameOk,
      whatsappCompleted: whatsappOk,
      addressCompleted:  addressOk,
      legalCompleted:    legalOk,
      isPublished:       isPublished,
    );
  }

  // ── Sıradaki Zorunlu Adım ─────────────────────────────────────────────────

  /// Yalnızca ilk eksik alanı döndürür.
  XrexNextStep get nextMissingField {
    if (!nameCompleted)     return XrexNextStep.name;
    if (!whatsappCompleted) return XrexNextStep.whatsapp;
    if (!addressCompleted)  return XrexNextStep.address;
    if (!legalCompleted)    return XrexNextStep.legal;
    if (!isPublished)       return XrexNextStep.publish;
    return XrexNextStep.share;
  }

  // ── Yardımcılar ───────────────────────────────────────────────────────────

  bool get isReadyToPublish => nameCompleted && whatsappCompleted && addressCompleted && legalCompleted && !isPublished;
}

// ─── Snapshot Servis ─────────────────────────────────────────────────────────
/// HomeShellScreen'in lazy yükleme için kullandığı yardımcı.
class XrexSnapshotLoader {
  final StoreLocalStorageService _storage;

  const XrexSnapshotLoader({
    StoreLocalStorageService? storage,
  }) : _storage = storage ?? const StoreLocalStorageService();

  Future<XrexProfileSnapshot?> load() async {
    final vitrinData = await _storage.loadVitrinData();
    if (vitrinData == null) return null;
    final publishedInfo = await _storage.loadPublishedVitrinInfo();
    return XrexProfileSnapshot.from(vitrinData, publishedInfo);
  }
}
