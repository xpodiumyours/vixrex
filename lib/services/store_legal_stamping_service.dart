import 'package:flutter/foundation.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/legal_document_service.dart';

/// [StoreLegalStampingService.stamp] sonucu. [data] her zaman (başarı ya da
/// hata fark etmeksizin) yerinde damgalanmış olarak döner; [errorMessage]
/// yalnız çağıranın kullanıcıya göstermeyi SEÇTİĞİ durumlarda anlamlıdır —
/// göstermek/susmak kararı controller'a (`reportError`) aittir.
class LegalStampResult {
  const LegalStampResult({required this.isSuccess, this.errorMessage});

  final bool isSuccess;
  final String? errorMessage;
}

/// `StoreEditorController`'ın onaylı yasal kutular (gizlilik/şartlar/yayın
/// izni) için sürüm+hash damgalama mantığını sahiplenir.
///
/// Önce sunucudaki AKTİF belgeleri yüklemeyi dener; yükleme başarılıysa
/// onaylanmış her kutu gerçek sürüm/hash ile damgalanır (üzerine yazılır).
/// Yükleme başarısız olsa veya beklenmeyen bir hata fırlatsa bile akış
/// kilitlenmez: [_ensureFallbackStamps] bilinen aktif sürümlerle
/// (2026-07-05) boşluğu doldurur — yalnız sürüm hâlâ boşsa (doluysa üzerine
/// yazmaz).
///
/// 2026-08-13: `store_editor_controller.dart`'tan (Faz 2, controller
/// parçalama) birebir taşındı. Davranış kasıtlı olarak değiştirilmedi.
/// [StoreData] burada YERİNDE mutasyona uğrar — controller'ın kendi `_data`
/// referansıyla aynı nesne; `notifyListeners` ve hata state'ini göstermek
/// çağıranın (controller'ın) sorumluluğunda kalır (bkz.
/// `ProductCatalogSyncService` — controller-state callback'i yok, aynı
/// desen).
class StoreLegalStampingService {
  const StoreLegalStampingService({
    required LegalDocumentService legalDocumentService,
  }) : _legalDocumentService = legalDocumentService;

  final LegalDocumentService _legalDocumentService;

  /// [data]'yı yerinde damgalar, gösterilip gösterilmeyeceğine çağıranın
  /// karar vereceği sonucu döner.
  Future<LegalStampResult> stamp(StoreData data) async {
    LegalStampResult result;
    try {
      final loaded = await _legalDocumentService.loadPublishingDocuments();
      result = loaded.when(
        success: (docs) {
          if (data.privacyNoticeAcknowledged) {
            data.privacyNoticeVersion = docs.privacy.version;
            data.privacyNoticeHash = docs.privacy.contentHash;
            data.privacyNoticeAcknowledgedAt ??= DateTime.now();
          }
          if (data.termsAccepted) {
            data.termsVersion = docs.terms.version;
            data.termsHash = docs.terms.contentHash;
            data.termsAcceptedAt ??= DateTime.now();
          }
          if (data.publicationConsentAccepted) {
            data.publicationConsentVersion = docs.consent.version;
            data.publicationConsentHash = docs.consent.contentHash;
            data.publicationConsentAcceptedAt ??= DateTime.now();
          }
          return const LegalStampResult(isSuccess: true);
        },
        failure: (f) {
          if (kDebugMode) {
            debugPrint('StoreLegalStampingService.stamp: ${f.message}');
          }
          return const LegalStampResult(
            isSuccess: false,
            errorMessage:
                'Belgeler yüklenemedi. İnternet bağlantınızı kontrol edin',
          );
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('StoreLegalStampingService.stamp failed: $e');
      }
      result = const LegalStampResult(
        isSuccess: false,
        errorMessage: 'Belgeler yüklenemedi. Lütfen tekrar deneyin',
      );
    }
    _ensureFallbackStamps(data);
    return result;
  }

  /// Supabase'teki aktif `legal_documents` sürümleri (2026-07-05). API
  /// başarısız olsa bile bilinen aktif sürümlerle boşluk doldurulur.
  void _ensureFallbackStamps(StoreData data) {
    if (data.privacyNoticeAcknowledged &&
        data.privacyNoticeVersion.trim().isEmpty) {
      data.privacyNoticeVersion = 'privacy-2026-07-05';
      data.privacyNoticeHash = '';
      data.privacyNoticeAcknowledgedAt ??= DateTime.now();
    }
    if (data.termsAccepted && data.termsVersion.trim().isEmpty) {
      data.termsVersion = 'terms-2026-07-05';
      data.termsHash = '';
      data.termsAcceptedAt ??= DateTime.now();
    }
    if (data.publicationConsentAccepted &&
        data.publicationConsentVersion.trim().isEmpty) {
      data.publicationConsentVersion = 'consent-2026-07-05';
      data.publicationConsentHash = '';
      data.publicationConsentAcceptedAt ??= DateTime.now();
    }
  }
}
