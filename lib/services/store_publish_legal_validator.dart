import 'package:vixrex/models/store_data.dart';

class StorePublishLegalValidator {
  const StorePublishLegalValidator();

  String? validateLegalAcceptance(StoreData data) {
    if (!data.privacyNoticeAcknowledged ||
        data.privacyNoticeVersion.trim().isEmpty ||
        data.privacyNoticeHash.trim().isEmpty) {
      return 'Yayınlamak için Aydınlatma Metni hakkında bilgilendirildiğinizi onaylamalısınız.';
    }
    if (!data.termsAccepted ||
        data.termsVersion.trim().isEmpty ||
        data.termsHash.trim().isEmpty) {
      return 'Yayınlamak için Kullanım Şartları’nı kabul etmelisiniz.';
    }
    if (!data.publicationConsentAccepted ||
        data.publicationConsentVersion.trim().isEmpty ||
        data.publicationConsentHash.trim().isEmpty) {
      return 'Vitrininizi yayınlamak için açık rıza vermelisiniz.';
    }
    return null;
  }
}
