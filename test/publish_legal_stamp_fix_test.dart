import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/legal_document.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/store_local_storage_service.dart';
import 'package:vixrex/services/store_publish_legal_validator.dart';

void main() {
  test('boş content_hash ile legal document usable', () {
    const doc = LegalDocument(
      type: 'privacy',
      version: 'privacy-2026-07-05',
      title: 'Gizlilik',
      subtitle: '',
      contentHash: '',
      sections: [],
    );
    expect(doc.isUsable, isTrue);
  });

  test('yayın kartı editToken olmadan gösterilebilir', () {
    const info = PublishedVitrinInfo(
      slug: 'deneme-7',
      publicLink: 'https://vixrex-public.vercel.app/v/deneme-7',
      name: 'deneme 7',
      editToken: '',
    );
    expect(info.isComplete, isTrue);
  });

  test('validator yalnızca onay kutularını ister', () {
    final data = StoreData(
      name: 'deneme 7',
      kategori: 'Diğer',
      status: 'Açık',
      privacyNoticeAcknowledged: true,
      privacyNoticeVersion: '',
      privacyNoticeHash: '',
      termsAccepted: true,
      termsVersion: '',
      termsHash: '',
      publicationConsentAccepted: true,
      publicationConsentVersion: '',
      publicationConsentHash: '',
    );
    expect(
      const StorePublishLegalValidator().validateLegalAcceptance(data),
      isNull,
    );
  });
}
