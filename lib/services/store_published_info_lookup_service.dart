import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/config/public_site_config.dart';
import 'package:vixrex/services/owner_bootstrap_service.dart';
import 'package:vixrex/services/store_local_storage_service.dart';

/// Kullanıcının Supabase'te yayınlanmış mağazasını arar.
///
/// Controller cephe parçalama, Faz 9 (2026-08-13): `initialize()`'ın
/// çağırdığı `_fetchPublishedInfoFromSupabase`'in sorgu mantığı birebir
/// buraya taşındı. Bu, `initialize()`'ın kendisinden farklı — saf bir
/// arama: girdi (client, yerel slug) → çıktı (`PublishedVitrinInfo?`),
/// `this`'e (controller state, `saveLocally`, `notifyListeners`) bağlı
/// değil. `initialize()`'ın geri kalanı controller'da kalıyor (Faz 7'deki
/// `publish()` gibi, birçok controller/mixin metodunu koordine ediyor).
class StorePublishedInfoLookupService {
  const StorePublishedInfoLookupService({required this.storage});
  final StoreLocalStorageService storage;

  /// Önce oturum açmış kullanıcının kendi yayınlanmış vitrinini arar;
  /// bulamazsa [localSlugFallback] (boşsa cihazda son bilinen yayınlanmış
  /// slug) ile dener. Bulursa `PublishedVitrinInfo` döner. `saveLocally`
  /// ÇAĞIRMAZ — bu, çağıran tarafın sorumluluğu (galeri senkronu editör
  /// medya state'ine bağlı, bu servise ait değil).
  ///
  /// Not (2026-08-20): ilk arama artık `stores.user_id`'yi doğrudan
  /// filtrelemiyor — o sütunun SELECT'i authenticated'ten kapalı (V-09),
  /// doğrudan filtre tüm sorguyu 42501 ile düşürüyordu. Bunun yerine
  /// `get_own_published_store` RPC'si kullanılır (SECURITY DEFINER,
  /// `is_store_owner_by_id/_by_slug` ile aynı desen) — user_id'yi asla
  /// client'a döndürmez.
  Future<PublishedVitrinInfo?> lookup({
    required SupabaseClient client,
    required String localSlugFallback,
  }) async {
    try {
      Map<String, dynamic>? response;
      var sunucuTokeni = '';
      final userId = client.auth.currentUser?.id;
      if (userId != null) {
        // 2026-08-26: önce bootstrap_owner_state — slug/ad İLE BİRLİKTE
        // vitrinin kendi edit_token'ını da döndürür. Bu olmadan yeni bir
        // cihazda token boş kalıyor, canEditRemote false oluyor ve
        // OwnerPreviewService taslak dalına düşüp YENİ bir vitrin satırı
        // açıyordu.
        final bootstrap = await OwnerBootstrapService(
          storage: storage,
          client: client,
        ).getir();
        final state = bootstrap.when(
          success: (value) => value,
          failure: (_) => null,
        );
        if (state != null && state.hasStore && state.isPublished) {
          response = {'slug': state.slug, 'name': state.name};
          sunucuTokeni = state.editToken;
        }

        // Eski yol: hesapla eşleşen yayınlanmış vitrin (token döndürmez).
        // bootstrap bir şey bulamadıysa (ör. anonim oturum) hâlâ geçerli.
        if (response == null) {
          final rpcResult = await client.rpc('get_own_published_store');
          if (rpcResult is Map) {
            response = Map<String, dynamic>.from(rpcResult);
          }
        }
      }

      if (response == null) {
        final localSlug =
            localSlugFallback.trim().isNotEmpty
                ? localSlugFallback.trim()
                : (await storage.loadLastPublishedSlug() ?? '').trim();
        if (localSlug.isNotEmpty) {
          response =
              await client
                  .from('stores')
                  .select('slug, name')
                  .eq('slug', localSlug)
                  .eq('is_published', true)
                  .maybeSingle();
        }
      }

      if (response == null) return null;

      final slug = (response['slug'] ?? '').toString().trim();
      if (slug.isEmpty) return null;

      // Sunucudan gelen token her zaman kazanır: cihazdaki kopya eski
      // (ör. süresi dolmuş kiralık token) olabilir, sunucudaki tazedir.
      var editToken = sunucuTokeni;
      if (editToken.isEmpty) {
        editToken =
            (await storage.loadVitrinEditToken())?.trim() ??
            (await storage.loadStoreEditToken())?.trim() ??
            '';
      }

      return PublishedVitrinInfo(
        publicLink: PublicSiteConfig.buildVitrinLink(slug),
        slug: slug,
        name: (response['name'] ?? '').toString(),
        editToken: editToken,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('StorePublishedInfoLookupService.lookup: $e');
      return null;
    }
  }
}
