import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/assistant_state.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/store_local_storage_service.dart';
import 'package:vixrex/services/vixrex_guidance_service.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';

/// Faz E (Tek Asistan planı) altın testi.
///
/// PLAN.md: "aynı snapshot verildiğinde eski `recommendationFor` ile yeni
/// `AssistantState` aynı adımı ve aynı birincil eylemi göstermeli."
///
/// `AssistantState.fromSnapshot` mevcut `VixRexGuidanceService` ve
/// `VixRexProfileSnapshot` getter'larını SARAR, kendi kararını üretmez —
/// bu test o sarmalamanın kaymadığını kilitler. Kararın kendisi
/// (`recommendationFor`'un ne önerdiği) burada değerlendirilmez; o zaten
/// `vixrex_coach_test.dart`'ın işi.
void main() {
  void expectEsdeger(
    VixRexProfileSnapshot? snapshot, {
    required bool hasShared,
  }) {
    final rec = VixRexGuidanceService.recommendationFor(
      snapshot: snapshot,
      hasShared: hasShared,
    );
    final state = AssistantState.fromSnapshot(snapshot, hasShared: hasShared);

    expect(
      state.eylemler,
      hasLength(1),
      reason: 'Bugünkü VixRexRecommendation tek eylem taşır.',
    );
    final birincil = state.eylemler.single;
    expect(birincil.primary, isTrue);
    expect(
      birincil.action,
      rec.action,
      reason: 'Birincil eylem eski recommendationFor ile aynı olmalı.',
    );
    expect(birincil.label, rec.buttonLabel);
    expect(state.mesajAnahtari, rec.id);

    expect(
      state.sonrakiAdim,
      snapshot?.nextMissingField ?? VixRexNextStep.name,
      reason: 'Sıradaki adım eski snapshot.nextMissingField ile aynı olmalı.',
    );
    expect(
      state.asama,
      snapshot?.journeyPhase(hasShared: hasShared) ?? VixRexJourneyPhase.setup,
    );
    expect(state.sonrakiEksikAlan, snapshot?.sonrakiEksikZorunluAlan);
    expect(state.doluAlan, snapshot?.completedRequiredStepCount ?? 0);
    expect(
      state.toplamAlan,
      snapshot == null ? state.toplamAlan : snapshot.totalRequiredStepCount,
    );
    expect(state.doluluk, inInclusiveRange(0, 100));
  }

  test('snapshot yok (karşılama)', () {
    expectEsdeger(null, hasShared: false);
  });

  test('boş vitrin — ad eksik', () {
    final snapshot = VixRexProfileSnapshot.from(StoreData(), null);
    expectEsdeger(snapshot, hasShared: false);
  });

  test('yalnız ad dolu — kategori eksik', () {
    final store = StoreData().copyWith(name: 'Test Store');
    final snapshot = VixRexProfileSnapshot.from(store, null);
    expectEsdeger(snapshot, hasShared: false);
  });

  test('ad + kategori dolu — whatsapp eksik', () {
    final store = StoreData().copyWith(name: 'Test Store', kategori: 'Kuaför');
    final snapshot = VixRexProfileSnapshot.from(store, null);
    expectEsdeger(snapshot, hasShared: false);
  });

  test('zorunlu alanlar tamam, yasal eksik', () {
    final store = StoreData().copyWith(
      name: 'Test Store',
      kategori: 'Kuaför',
      whatsapp: '05551234567',
      address: 'Test Adres',
      provinceName: 'Istanbul',
      districtName: 'Kadikoy',
    );
    final snapshot = VixRexProfileSnapshot.from(store, null);
    expectEsdeger(snapshot, hasShared: false);
  });

  test('yayına hazır — henüz yayınlanmamış', () {
    final store = StoreData().copyWith(
      name: 'Test Store',
      kategori: 'Kuaför',
      whatsapp: '05551234567',
      address: 'Test Adres',
      provinceName: 'Istanbul',
      districtName: 'Kadikoy',
      privacyNoticeAcknowledged: true,
      privacyNoticeVersion: '1.0',
      termsAccepted: true,
      termsVersion: '1.0',
      publicationConsentAccepted: true,
      publicationConsentVersion: '1.0',
    );
    final snapshot = VixRexProfileSnapshot.from(store, null);
    expectEsdeger(snapshot, hasShared: false);
  });

  test('yayınlı, henüz paylaşılmamış', () {
    final store = StoreData().copyWith(
      name: 'Test Store',
      kategori: 'Kuaför',
      whatsapp: '05551234567',
      address: 'Test Adres',
      provinceName: 'Istanbul',
      districtName: 'Kadikoy',
      privacyNoticeAcknowledged: true,
      privacyNoticeVersion: '1.0',
      termsAccepted: true,
      termsVersion: '1.0',
      publicationConsentAccepted: true,
      publicationConsentVersion: '1.0',
    );
    const published = PublishedVitrinInfo(
      slug: 'test',
      publicLink: 'https://vixrex-public.vercel.app/v/test',
      name: 'Test',
      editToken: 'token',
    );
    final snapshot = VixRexProfileSnapshot.from(store, published);
    expectEsdeger(snapshot, hasShared: false);
  });

  test('yayınlı, paylaşılmış, geliştirme kalemleri eksik', () {
    final store = StoreData().copyWith(
      name: 'Test Store',
      kategori: 'Kuaför',
      whatsapp: '05551234567',
      address: 'Test Adres',
      provinceName: 'Istanbul',
      districtName: 'Kadikoy',
      privacyNoticeAcknowledged: true,
      privacyNoticeVersion: '1.0',
      termsAccepted: true,
      termsVersion: '1.0',
      publicationConsentAccepted: true,
      publicationConsentVersion: '1.0',
    );
    const published = PublishedVitrinInfo(
      slug: 'test',
      publicLink: 'https://vixrex-public.vercel.app/v/test',
      name: 'Test',
      editToken: 'token',
    );
    final snapshot = VixRexProfileSnapshot.from(store, published);
    expectEsdeger(snapshot, hasShared: true);
  });
}
