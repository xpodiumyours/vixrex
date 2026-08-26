import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/models/owner_bootstrap_state.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/demo_rental_service.dart';
import 'package:vixrex/services/owner_bootstrap_service.dart';
import 'package:vixrex/services/store_local_storage_service.dart';

/// VIXREX CORE — kalıcı hesap sahipliği sözleşmesinin nöbetçisi
/// (migration: 20260826000000_vixrex_core_kalici_hesap_sahipligi.sql).
///
/// Sözleşmenin kendisi Postgres'te; buradaki testler istemci tarafının o
/// sözleşmeyi doğru okuduğunu ve sözleşmenin kurallarının migration'dan
/// sessizce düşmediğini korur. Sessiz düşme teorik değil: 20260824050000
/// (V-15) ürün kopyalamayı tam olarak böyle kaybetti.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    StoreLocalStorageService.resetCache();
  });

  StoreData vitrin(String ad, {String slug = 'kiralik-kafe-1'}) =>
      StoreData(name: ad, kategori: 'Diğer', status: 'Açık', slug: slug);

  Map<String, dynamic> sunucuDurumu({
    bool hasDraft = false,
    String canliAd = 'Canlı Vitrin',
    String taslakAd = 'Taslak Vitrin',
    String? draftUpdatedAt,
    String? liveUpdatedAt,
    bool isPublished = true,
  }) => {
    'has_store': true,
    'reason': 'OK',
    'slug': 'kiralik-kafe-1',
    'name': canliAd,
    'edit_token': 'a' * 32,
    'is_published': isPublished,
    'is_store': false,
    'live_version': 5,
    'store_data': vitrin(canliAd).toJson(),
    'has_draft': hasDraft,
    'draft_data': hasDraft ? vitrin(taslakAd).toJson() : <String, dynamic>{},
    'draft_version': hasDraft ? 2 : null,
    'base_live_version': hasDraft ? 5 : null,
    'draft_stale': false,
    'live_updated_at': liveUpdatedAt,
    'draft_updated_at': draftUpdatedAt,
  };

  group('OwnerBootstrapState', () {
    test('vitrini olmayan hesap: has_store false, sebep taşınır', () {
      final state = OwnerBootstrapState.fromJson({
        'has_store': false,
        'reason': 'NO_STORE',
      });
      expect(state.hasStore, isFalse);
      expect(state.reason, 'NO_STORE');
      expect(state.tercihEdilenVeri, isNull);
    });

    test('anonim oturum ayırt edilir', () {
      final state = OwnerBootstrapState.fromJson({
        'has_store': false,
        'reason': 'ANONYMOUS_SESSION',
      });
      expect(state.anonimOturum, isTrue);
    });

    test('çalışma taslağı varsa canlı veriye TERCİH edilir', () {
      final state = OwnerBootstrapState.fromJson(sunucuDurumu(hasDraft: true));
      expect(state.tercihEdilenVeri?.name, 'Taslak Vitrin');
    });

    test('taslak yoksa canlı veri kullanılır', () {
      final state = OwnerBootstrapState.fromJson(sunucuDurumu());
      expect(state.tercihEdilenVeri?.name, 'Canlı Vitrin');
    });

    test('bozuk taslak jsonb tüm açılışı düşürmez', () {
      final json = sunucuDurumu(hasDraft: true);
      json['draft_data'] = 'bozuk';
      final state = OwnerBootstrapState.fromJson(json);
      expect(state.hasStore, isTrue);
      expect(state.tercihEdilenVeri?.name, 'Canlı Vitrin');
    });
  });

  group('StoreClaimResult', () {
    test('yeni bağlanma kullanıcıya bildirilir', () {
      final sonuc = StoreClaimResult.fromJson({
        'ok': true,
        'reason': 'CLAIMED',
        'slug': 'x',
      });
      expect(sonuc.yeniBaglandi, isTrue);
      expect(sonuc.kullaniciMesaji, isNotNull);
    });

    test('zaten bağlıysa sessiz geçilir', () {
      final sonuc = StoreClaimResult.fromJson({
        'ok': true,
        'reason': 'ALREADY_MINE',
      });
      expect(sonuc.yeniBaglandi, isFalse);
      expect(sonuc.kullaniciMesaji, isNull);
    });

    test('tek-vitrin kuralı kullanıcıya açıklanır', () {
      final sonuc = StoreClaimResult.fromJson({
        'ok': false,
        'reason': 'ALREADY_OWNS_STORE',
        'slug': 'baska-vitrin',
      });
      expect(sonuc.zatenBaskaVitrinVar, isTrue);
      expect(sonuc.kullaniciMesaji, contains('yalnızca bir vitrin'));
    });
  });

  group('OwnerBootstrapService.cihazaUygula', () {
    const storage = StoreLocalStorageService();
    const service = OwnerBootstrapService(storage: storage);

    test('yeni cihaz: veri de token da yazılır', () async {
      final state = OwnerBootstrapState.fromJson(sunucuDurumu());
      final sonuc = await service.cihazaUygula(state);

      expect(sonuc.veriYazildi, isTrue);
      expect(sonuc.tokenYazildi, isTrue);
      expect(sonuc.korunanYerelTaslak, isFalse);
      expect((await storage.loadVitrinData())?.name, 'Canlı Vitrin');
      // Yeni cihazda uzaktan düzenlemenin ön koşulu: token cihaza indi.
      expect(await storage.loadVitrinEditToken(), 'a' * 32);
    });

    test('cihazdaki taslak DAHA YENİ ise üzerine yazılmaz', () async {
      await storage.saveVitrinData(vitrin('Cihazdaki Taslak'));

      final state = OwnerBootstrapState.fromJson(
        sunucuDurumu(
          hasDraft: true,
          draftUpdatedAt:
              DateTime.now()
                  .toUtc()
                  .subtract(const Duration(hours: 2))
                  .toIso8601String(),
        ),
      );
      final sonuc = await service.cihazaUygula(state);

      expect(sonuc.korunanYerelTaslak, isTrue);
      expect(sonuc.veriYazildi, isFalse);
      expect((await storage.loadVitrinData())?.name, 'Cihazdaki Taslak');
      // Veri korunsa da token yine de yazılır — yoksa düzenleme yapılamaz.
      expect(sonuc.tokenYazildi, isTrue);
    });

    test('cihazdaki taslak DAHA ESKİ ise sunucu kazanır', () async {
      await storage.saveVitrinData(vitrin('Eski Yerel'));

      final state = OwnerBootstrapState.fromJson(
        sunucuDurumu(
          hasDraft: true,
          draftUpdatedAt:
              DateTime.now()
                  .toUtc()
                  .add(const Duration(hours: 2))
                  .toIso8601String(),
        ),
      );
      final sonuc = await service.cihazaUygula(state);

      expect(sonuc.veriYazildi, isTrue);
      expect((await storage.loadVitrinData())?.name, 'Taslak Vitrin');
    });

    test('cihazda BAŞKA vitrin varsa taslak çakışması sayılmaz', () async {
      await storage.saveVitrinData(vitrin('Başka Vitrin', slug: 'baska-slug'));

      final state = OwnerBootstrapState.fromJson(
        sunucuDurumu(
          hasDraft: true,
          draftUpdatedAt:
              DateTime.now()
                  .toUtc()
                  .subtract(const Duration(days: 5))
                  .toIso8601String(),
        ),
      );
      final sonuc = await service.cihazaUygula(state);

      expect(sonuc.korunanYerelTaslak, isFalse);
      expect(sonuc.veriYazildi, isTrue);
    });

    test('vitrini olmayan durumda hiçbir şey yazılmaz', () async {
      final sonuc = await service.cihazaUygula(
        const OwnerBootstrapState.yok('NO_STORE'),
      );
      expect(sonuc.veriYazildi, isFalse);
      expect(sonuc.tokenYazildi, isFalse);
      expect(await storage.loadVitrinData(), isNull);
    });

    test('yayında olmayan vitrin "yayınlandı" diye işaretlenmez', () async {
      final state = OwnerBootstrapState.fromJson(
        sunucuDurumu(isPublished: false),
      );
      await service.cihazaUygula(state);

      expect(await storage.loadPublishedVitrinInfo(), isNull);
      expect(await storage.loadVitrinEditToken(), 'a' * 32);
    });
  });

  group('DemoRentalResult', () {
    test('oturum yoksa misafir yoluna düşülür', () {
      const sonuc = DemoRentalResult.basarisiz('NO_SESSION');
      expect(sonuc.misafirYolunaDus, isTrue);
    });

    test('tek-vitrin kuralında misafir yoluna DÜŞÜLMEZ', () {
      // Düşülseydi kullanıcı ikinci bir sahipsiz vitrin üretirdi — tam da
      // kuralın engellediği şey.
      const sonuc = DemoRentalResult(ok: false, reason: 'ALREADY_OWNS_STORE');
      expect(sonuc.misafirYolunaDus, isFalse);
      expect(sonuc.kullaniciMesaji, isNotNull);
    });
  });

  group('CORE migration nöbetçisi', () {
    final migration =
        File(
          '${Directory.current.path}/supabase/migrations/'
          '20260826000000_vixrex_core_kalici_hesap_sahipligi.sql',
        ).readAsStringSync();

    test('tek-vitrin kuralı veritabanı garantisiyle duruyor', () {
      expect(migration, contains('CREATE UNIQUE INDEX'));
      expect(migration, contains('stores_tek_vitrin_per_user'));
      expect(migration, contains('WHERE "user_id" IS NOT NULL'));
    });

    test('anonim oturum vitrin sahiplenemez', () {
      expect(migration, contains('is_permanent_user'));
      expect(migration, contains('ANONYMOUS_SESSION'));
    });

    test('sahiplenince token süresi kalıcıya çekilir', () {
      expect(
        migration,
        contains("edit_token_expires_at = now() + interval '1 year'"),
      );
    });

    test('klonlama ürünleri ve kategorileri KOPYALAR', () {
      // 20260824050000 bunu sessizce düşürmüştü; kiralanan vitrinler
      // 24 Ağustos'tan beri boş doğuyordu.
      expect(migration, contains('_kategori_esleme'));
      expect(migration, contains('insert into public.products'));
      expect(migration, contains('insert into public.product_categories'));
    });

    test('sırlar taslak/canlı veride sızmaz', () {
      expect(migration, contains('strip_draft_secrets'));
    });
  });
}
