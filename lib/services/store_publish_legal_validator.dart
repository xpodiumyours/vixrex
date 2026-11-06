import 'package:vixrex/models/store_data.dart';

class StorePublishLegalValidator {
  const StorePublishLegalValidator();

  String? validateLegalAcceptance(StoreData data) {
    if (!data.privacyNoticeAcknowledged) {
      return 'Yayınlamak için Aydınlatma Metni hakkında bilgilendirildiğinizi onaylamalısınız.';
    }
    if (!data.termsAccepted) {
      return 'Yayınlamak için Kullanım Şartları’nı kabul etmelisiniz.';
    }
    // Version damgası publish() içinde doldurulur; burada sadece onay kutusu.
    return null;
  }
}
