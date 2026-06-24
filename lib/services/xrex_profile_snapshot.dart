import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/services/store_local_storage_service.dart';

// ─── Eksik alan enum'u ────────────────────────────────────────────────────────
enum XrexMissingField {
  whatsapp,     // +20 puan — en kritik
  address,      // +15 puan
  cover,        // +15 puan (logoUrl)
  gallery,      // +10 puan
  description,  // +10 puan
  products,     // +10 puan
}

extension XrexMissingFieldLabel on XrexMissingField {
  String get label {
    switch (this) {
      case XrexMissingField.whatsapp:     return 'WhatsApp numarası';
      case XrexMissingField.address:      return 'Adres / konum';
      case XrexMissingField.cover:        return 'Kapak fotoğrafı';
      case XrexMissingField.gallery:      return 'Galeri fotoğrafı';
      case XrexMissingField.description:  return 'İşletme açıklaması';
      case XrexMissingField.products:     return 'Ürün veya hizmet';
    }
  }

  int get scoreValue {
    switch (this) {
      case XrexMissingField.whatsapp:     return 20;
      case XrexMissingField.address:      return 15;
      case XrexMissingField.cover:        return 15;
      case XrexMissingField.gallery:      return 10;
      case XrexMissingField.description:  return 10;
      case XrexMissingField.products:     return 10;
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
  final bool coverPhotoCompleted;
  final int galleryCount;
  final bool descriptionCompleted;
  final bool hasProducts;
  final bool isPublished;
  final String? publicLink;

  /// 0–100 arası sağlık skoru.
  /// İşletme adı (20) + WhatsApp (20) + Adres (15) + Kapak (15) +
  /// Galeri≥1 (10) + Açıklama (10) + Ürün/hizmet (10) = 100
  final int healthScore;

  const XrexProfileSnapshot({
    required this.nameCompleted,
    required this.whatsappCompleted,
    required this.addressCompleted,
    required this.coverPhotoCompleted,
    required this.galleryCount,
    required this.descriptionCompleted,
    required this.hasProducts,
    required this.isPublished,
    required this.publicLink,
    required this.healthScore,
  });

  // ── Factory ───────────────────────────────────────────────────────────────

  factory XrexProfileSnapshot.from(
    StoreData data,
    PublishedVitrinInfo? publishedInfo,
  ) {
    final nameOk        = data.name.trim().isNotEmpty;
    final whatsappOk    = data.whatsapp.trim().isNotEmpty;
    final addressOk     = data.address.trim().isNotEmpty ||
                          data.provinceName.trim().isNotEmpty;
    final coverOk       = (data.logoUrl?.trim().isNotEmpty ?? false) ||
                          data.shelfImageUrl.trim().isNotEmpty;
    final galleryCount  = data.galleryItems.length;
    final descOk        = data.description.trim().isNotEmpty;
    final hasProducts   = data.offerings.isNotEmpty || data.products.isNotEmpty;

    final isPublished   = publishedInfo != null && publishedInfo.isComplete;
    final publicLink    = isPublished ? publishedInfo.publicLink : null;

    var score = 0;
    if (nameOk)           score += 20;
    if (whatsappOk)       score += 20;
    if (addressOk)        score += 15;
    if (coverOk)          score += 15;
    if (galleryCount > 0) score += 10;
    if (descOk)           score += 10;
    if (hasProducts)      score += 10;

    return XrexProfileSnapshot(
      nameCompleted:        nameOk,
      whatsappCompleted:    whatsappOk,
      addressCompleted:     addressOk,
      coverPhotoCompleted:  coverOk,
      galleryCount:         galleryCount,
      descriptionCompleted: descOk,
      hasProducts:          hasProducts,
      isPublished:          isPublished,
      publicLink:           publicLink,
      healthScore:          score,
    );
  }

  // ── İyileştirme #2: Önceliklendirilmiş eksik alan listesi ─────────────────

  /// Eksik alanları etki puanına göre sıralı döner (en kritik önce).
  /// İşletme adı zaten 20 puan ama temel gereklilik olduğundan
  /// ayrı kontrol edilmez; snapshot adı olmadan yüklendiğinde
  /// nameCompleted false olur ve aşağıdaki listeye girmez (isim alanı
  /// ayrı mesaj olarak ele alınır).
  List<XrexMissingField> get prioritizedMissing {
    return [
      if (!whatsappCompleted)    XrexMissingField.whatsapp,
      if (!addressCompleted)     XrexMissingField.address,
      if (!coverPhotoCompleted)  XrexMissingField.cover,
      if (galleryCount == 0)     XrexMissingField.gallery,
      if (!descriptionCompleted) XrexMissingField.description,
      if (!hasProducts)          XrexMissingField.products,
    ];
  }

  // ── Yardımcılar ───────────────────────────────────────────────────────────

  bool get isFullyComplete => healthScore == 100;
  bool get isReadyToPublish => healthScore >= 80 && !isPublished;
  bool get needsWork => healthScore < 80 && !isPublished;

  /// Skor rengini belirler: kırmızı / turuncu / sarı / yeşil
  XrexScoreLevel get scoreLevel {
    if (isPublished && healthScore >= 80) return XrexScoreLevel.published;
    if (healthScore >= 80)  return XrexScoreLevel.good;
    if (healthScore >= 50)  return XrexScoreLevel.medium;
    return XrexScoreLevel.low;
  }
}

enum XrexScoreLevel { low, medium, good, published }

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
