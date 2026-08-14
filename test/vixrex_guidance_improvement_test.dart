import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/vixrex_guidance_service.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';

/// `improvementRecommendations` gerçekten esnafa gösterilen "vitrinini
/// güzelleştir" listesi — `qualityItems`'ın aksine ölü kod değil
/// (bkz. vixrex_guidance_service.dart'taki uyarı). Bu dosya kilitlenene
/// kadar hiç testi yoktu.
///
/// Faz F takibi (Tek Asistan planı, 2026-08-15): şemadaki 7 kalite
/// alanının kapak dışındaki 6'sı (heroRozet, logo, calismaSaatleri,
/// haritaLinki, hakkindaBaslik, hakkindaMetin) buraya eklendi — önceden
/// hiç önerilmiyorlardı, yalnız Next.js'in hazırlık raporu biliyordu.
void main() {
  StoreData tamDoluStore() => StoreData().copyWith(
    name: 'Test Store',
    kategori: 'Kuaför',
    shelfImageUrl: 'https://example.com/kapak.jpg',
    galleryItems: [
      StoreGalleryItem(id: '1', imageUrl: 'https://example.com/g1.jpg'),
    ],
    description: 'Kısa açıklama',
    products: [Product(id: 'p1', name: 'Ürün')],
    heroBadge: 'Profesyonel Teknik Servis',
    logoUrl: 'https://example.com/logo.png',
    workingHours: 'Pzt-Cmt 09:00-20:00',
    googleBusinessLink: 'https://g.page/test',
    aboutTitle: 'Hikayemiz',
    corporateBio: '2010 yılından beri hizmetinizdeyiz.',
  );

  VixRexProfileSnapshot snapshotOf(StoreData data) =>
      VixRexProfileSnapshot.from(data, null);

  group('improvementRecommendations — yeni 6 kalite kalemi (Faz F)', () {
    final vakalar = <String, (StoreData Function(StoreData), String)>{
      'improve_hero_badge': ((d) => d.copyWith(heroBadge: ''), 'heroBadge'),
      'improve_logo': ((d) => d.copyWith(logoUrl: ''), 'logoUrl'),
      'improve_working_hours': (
        (d) => d.copyWith(workingHours: ''),
        'workingHours',
      ),
      'improve_google_link': (
        (d) => d.copyWith(googleBusinessLink: ''),
        'googleBusinessLink',
      ),
      'improve_about_title': ((d) => d.copyWith(aboutTitle: ''), 'aboutTitle'),
      'improve_about_bio': (
        (d) => d.copyWith(corporateBio: ''),
        'corporateBio',
      ),
    };

    for (final entry in vakalar.entries) {
      final id = entry.key;
      final bosalt = entry.value.$1;
      final alanAdi = entry.value.$2;

      test('$alanAdi boşken "$id" önerilir, doluyken önerilmez', () {
        final bosSnapshot = snapshotOf(bosalt(tamDoluStore()));
        final doluSnapshot = snapshotOf(tamDoluStore());

        final bosOneriler = VixRexGuidanceService.improvementRecommendations(
          bosSnapshot,
        ).map((r) => r.id);
        final doluOneriler = VixRexGuidanceService.improvementRecommendations(
          doluSnapshot,
        ).map((r) => r.id);

        expect(bosOneriler, contains(id));
        expect(doluOneriler, isNot(contains(id)));
      });
    }

    test('her şey doluyken 6 yeni kalemin hiçbiri önerilmez', () {
      final snapshot = snapshotOf(tamDoluStore());
      final oneriler =
          VixRexGuidanceService.improvementRecommendations(
            snapshot,
          ).map((r) => r.id).toSet();

      for (final id in vakalar.keys) {
        expect(oneriler, isNot(contains(id)));
      }
    });
  });

  test('öneri id\'leri benzersizdir (kazara çift eklenme yok)', () {
    final snapshot = snapshotOf(StoreData());
    final idler =
        VixRexGuidanceService.improvementRecommendations(
          snapshot,
        ).map((r) => r.id).toList();

    expect(idler.toSet().length, idler.length);
  });
}
