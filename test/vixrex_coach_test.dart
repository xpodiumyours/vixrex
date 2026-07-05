import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';

void main() {
  group('VixRexProfileSnapshot', () {
    test('Bos magaza icin name beklenmeli', () {
      final store = StoreData();
      final snapshot = VixRexProfileSnapshot.from(store, null);
      
      expect(snapshot.nameCompleted, isFalse);
      expect(snapshot.nextMissingField, VixRexNextStep.name);
    });

    test('Name dolu ise whatsapp beklenmeli', () {
      final store = StoreData().copyWith(name: 'Test Store');
      final snapshot = VixRexProfileSnapshot.from(store, null);
      
      expect(snapshot.nameCompleted, isTrue);
      expect(snapshot.whatsappCompleted, isFalse);
      expect(snapshot.nextMissingField, VixRexNextStep.whatsapp);
    });

    test('Legal eksik ise legal beklenmeli', () {
      final store = StoreData().copyWith(
        name: 'Test Store',
        whatsapp: '05551234567',
        address: 'Test Adres',
        provinceName: 'Istanbul',
        districtName: 'Kadikoy',
      );
      final snapshot = VixRexProfileSnapshot.from(store, null);
      
      expect(snapshot.nameCompleted, isTrue);
      expect(snapshot.whatsappCompleted, isTrue);
      expect(snapshot.addressCompleted, isTrue);
      expect(snapshot.legalCompleted, isFalse);
      expect(snapshot.nextMissingField, VixRexNextStep.legal);
    });

    test('IsReadyToPublish legal dahil her sey tamamsa true olmali', () {
      final store = StoreData().copyWith(
        name: 'Test Store',
        whatsapp: '05551234567',
        address: 'Test Adres',
        provinceName: 'Istanbul',
        districtName: 'Kadikoy',
        privacyNoticeAcknowledged: true,
        privacyNoticeVersion: '1.0',
        privacyNoticeHash: 'hash',
        termsAccepted: true,
        termsVersion: '1.0',
        termsHash: 'hash',
        publicationConsentAccepted: true,
        publicationConsentVersion: '1.0',
        publicationConsentHash: 'hash',
      );
      final snapshot = VixRexProfileSnapshot.from(store, null);
      
      expect(snapshot.legalCompleted, isTrue);
      expect(snapshot.isReadyToPublish, isTrue);
      expect(snapshot.isPublished, isFalse);
      expect(snapshot.nextMissingField, VixRexNextStep.publish);
    });
  });
}
