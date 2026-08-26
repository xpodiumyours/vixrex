import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/config/public_site_config.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/core/supabase_error_mapper.dart';
import 'package:vixrex/models/owner_bootstrap_state.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/store_local_storage_service.dart';

/// [OwnerBootstrapService.cihazaUygula] sonucu — çağıran tarafın kullanıcıya
/// ne söyleyeceğine karar verebilmesi için.
class OwnerBootstrapApplyResult {
  const OwnerBootstrapApplyResult({
    required this.veriYazildi,
    required this.korunanYerelTaslak,
    required this.tokenYazildi,
  });

  /// Sunucudaki içerik cihaza yazıldı mı.
  final bool veriYazildi;

  /// Cihazdaki taslak sunucudakinden YENİ olduğu için korundu — sunucu
  /// verisi bilerek yazılmadı.
  final bool korunanYerelTaslak;

  /// Uzaktan düzenleme anahtarı cihaza yazıldı mı.
  final bool tokenYazildi;

  static const hicbiri = OwnerBootstrapApplyResult(
    veriYazildi: false,
    korunanYerelTaslak: false,
    tokenYazildi: false,
  );
}

/// "Yeni cihazda aynı hesapla giriş → vitrini bul ve yerel durumu besle".
///
/// Bu servis iki işi ayırır ve ikisini de tek başına test edilebilir tutar:
///   1. [getir] — sunucudaki durumu okur (saf ağ çağrısı).
///   2. [cihazaUygula] — okunanı yerel depoya yazar (saf depolama).
///
/// EZME KURALI (2026-08-26, Codex'in kurduğu ilke): cihazdaki taslak
/// sunucudakinden YENİ ise üzerine yazılmaz. Kullanıcı uçakta/çevrimdışı
/// düzenleme yaptıysa, sırf başka bir cihazdan giriş yaptı diye emeği
/// sessizce silinmemeli.
class OwnerBootstrapService {
  const OwnerBootstrapService({
    this.storage = const StoreLocalStorageService(),
    SupabaseClient? client,
  }) : _client = client;

  final StoreLocalStorageService storage;
  final SupabaseClient? _client;

  SupabaseClient? get _supabase {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Sunucudaki sahip durumunu okur. Anonim oturumda `hasStore == false` ve
  /// `reason == ANONYMOUS_SESSION` döner — hata değildir.
  Future<Result<OwnerBootstrapState>> getir() async {
    final client = _supabase;
    if (client == null) {
      return const Result.success(
        OwnerBootstrapState.yok('NO_CLIENT'),
      );
    }

    try {
      final response = await client.rpc('bootstrap_owner_state');
      if (response is! Map) {
        return const Result.success(OwnerBootstrapState.yok('NO_STORE'));
      }
      return Result.success(
        OwnerBootstrapState.fromJson(Map<String, dynamic>.from(response)),
      );
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  /// [state]'i cihaza yazar. Sunucudan gelen edit token her zaman yazılır
  /// (uzaktan düzenlemenin ön koşulu); içerik ise yalnız yerel taslak daha
  /// eskiyse yazılır.
  Future<OwnerBootstrapApplyResult> cihazaUygula(
    OwnerBootstrapState state,
  ) async {
    if (!state.hasStore || state.slug.isEmpty) {
      return OwnerBootstrapApplyResult.hicbiri;
    }

    var tokenYazildi = false;
    if (state.editToken.isNotEmpty) {
      // Yayında olmayan vitrinde de token gerekir (taslağı düzenlemek için),
      // ama "yayınlanmış vitrin" işaretini yalnız gerçekten yayındaysa koy —
      // aksi halde panel yayında olmayan vitrini yayında gösterir.
      if (state.isPublished) {
        await storage.savePublishedVitrinInfo(
          slug: state.slug,
          publicLink: PublicSiteConfig.buildVitrinLink(state.slug),
          name: state.name,
          editToken: state.editToken,
        );
      } else {
        await storage.saveVitrinEditToken(state.editToken);
        await storage.saveStoreEditToken(state.editToken);
      }
      tokenYazildi = true;
    }

    final sunucuVerisi = state.tercihEdilenVeri;
    if (sunucuVerisi == null) {
      return OwnerBootstrapApplyResult(
        veriYazildi: false,
        korunanYerelTaslak: false,
        tokenYazildi: tokenYazildi,
      );
    }

    if (await _yerelTaslakDahaYeni(state)) {
      if (kDebugMode) {
        debugPrint(
          '[OwnerBootstrap] cihazdaki taslak sunucudakinden yeni — korundu',
        );
      }
      return OwnerBootstrapApplyResult(
        veriYazildi: false,
        korunanYerelTaslak: true,
        tokenYazildi: tokenYazildi,
      );
    }

    await _veriyiYaz(state, sunucuVerisi);
    return OwnerBootstrapApplyResult(
      veriYazildi: true,
      korunanYerelTaslak: false,
      tokenYazildi: tokenYazildi,
    );
  }

  Future<void> _veriyiYaz(OwnerBootstrapState state, StoreData veri) async {
    if (state.isStoreMode) {
      await storage.saveStoreData(veri);
    } else {
      await storage.saveVitrinData(veri);
    }
  }

  /// Cihazdaki taslak sunucudakinden yeni mi?
  ///
  /// Yerelde hiç veri yoksa (asıl "yeni cihaz" durumu) her zaman `false` —
  /// yazılacak bir şey ezilmiyor. Zaman damgalarından biri okunamıyorsa da
  /// `false`: bilinmeyen durumda sunucu kazanır, çünkü sunucudaki veri her
  /// zaman en az bir kez bilinçli olarak kaydedilmiştir.
  Future<bool> _yerelTaslakDahaYeni(OwnerBootstrapState state) async {
    final yerel =
        state.isStoreMode
            ? await storage.loadStoreData()
            : await storage.loadVitrinData();
    if (yerel == null) return false;

    // Farklı bir vitrin cihazda duruyorsa bu bir "taslak çakışması" değil:
    // hesabın vitrini artık başkası. Sunucu kazanır.
    final yerelSlug = yerel.slug.trim();
    if (yerelSlug.isNotEmpty && yerelSlug != state.slug) return false;

    final yerelZaman = await storage.loadVitrinDataSavedAt();
    final sunucuZaman = state.tercihEdilenZaman;
    if (yerelZaman == null || sunucuZaman == null) return false;

    return yerelZaman.isAfter(sunucuZaman);
  }
}
