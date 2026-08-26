import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/config/public_site_config.dart';
import 'package:vixrex/services/owner_bootstrap_service.dart';
import 'package:vixrex/services/store_local_storage_service.dart';

/// [DemoRentalService.hesabaKirala] sonucu.
class DemoRentalResult {
  const DemoRentalResult({
    required this.ok,
    required this.reason,
    this.slug = '',
    this.duzenleyiciUrl = '',
  });

  const DemoRentalResult.basarisiz(this.reason)
    : ok = false,
      slug = '',
      duzenleyiciUrl = '';

  final bool ok;

  /// `RENTED`, `ALREADY_OWNS_STORE`, `ANONYMOUS_SESSION`, `RATE_LIMITED`,
  /// `SOURCE_NOT_FOUND`, `SLUG_GENERATION_FAILED`, `NO_SESSION`, `ERROR`.
  final String reason;

  final String slug;

  /// Sahip oturumu kurulmuş düzenleyici linki.
  final String duzenleyiciUrl;

  /// Hesaplı yol denenmemeli/başarısız — çağıran misafir yoluna düşsün.
  bool get misafirYolunaDus =>
      reason == 'ANONYMOUS_SESSION' ||
      reason == 'NO_SESSION' ||
      reason == 'ERROR';

  /// Kullanıcıya gösterilecek mesaj. `null` ise sessiz geçilir.
  String? get kullaniciMesaji {
    switch (reason) {
      case 'ALREADY_OWNS_STORE':
        return 'Bu hesabın zaten bir vitrini var. Bir hesap yalnızca bir '
            'vitrin yönetebilir.';
      case 'RATE_LIMITED':
        return 'Çok fazla deneme yapıldı. Lütfen biraz sonra tekrar dene.';
      case 'SOURCE_NOT_FOUND':
        return 'Bu vitrin artık kiralık örnek olarak mevcut değil.';
      case 'SLUG_GENERATION_FAILED':
        return 'Vitrin şu anda kiralanamıyor. Lütfen tekrar dene.';
      default:
        return null;
    }
  }
}

/// "Bu vitrini kirala" — kalıcı hesapla giriş yapmış kullanıcı için.
///
/// NEDEN (2026-08-26): kiralama bugüne kadar yalnız misafir yoluyla
/// çalışıyordu. Uygulama sadece tarayıcıda `/rent-demo` linkini açıyor,
/// üretilen vitrinin slug'ını da edit token'ını da hiç öğrenmiyordu
/// (AppRouter.navigateToRentDemo). Vitrin sahipsiz doğduğu ve token'ı 24
/// saatlik olduğu için (V-15) ertesi gün kimse o vitrine ulaşamıyordu.
///
/// Hesaplı yolda klon SAHİPLİ doğar (`rent_demo_for_account`): kiralama
/// anında hesaba bağlanır, token bir yıllık olur, tek-vitrin kuralı
/// uygulanır. Misafir yolu olduğu gibi durur — giriş yapmamış kullanıcı
/// eskisi gibi tarayıcıya gider.
class DemoRentalService {
  const DemoRentalService({
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

  /// Kalıcı (anonim olmayan) bir hesapla giriş yapılmış mı?
  bool get kaliciHesapVar {
    final user = _supabase?.auth.currentUser;
    return user != null && !user.isAnonymous;
  }

  Future<DemoRentalResult> hesabaKirala(String demoSlug) async {
    final client = _supabase;
    if (client == null || !kaliciHesapVar) {
      return const DemoRentalResult.basarisiz('NO_SESSION');
    }

    final slug = demoSlug.trim();
    if (slug.isEmpty) return const DemoRentalResult.basarisiz('INVALID_SLUG');

    try {
      final response = await client.rpc(
        'rent_demo_for_account',
        params: {'p_source_slug': slug},
      );
      if (response is! Map) {
        return const DemoRentalResult.basarisiz('ERROR');
      }

      final sonuc = Map<String, dynamic>.from(response);
      if (sonuc['ok'] != true) {
        return DemoRentalResult(
          ok: false,
          reason: (sonuc['reason'] ?? 'ERROR').toString(),
          slug: (sonuc['slug'] ?? '').toString(),
        );
      }

      final yeniSlug = (sonuc['slug'] ?? '').toString().trim();
      final editToken = (sonuc['edit_token'] ?? '').toString().trim();
      if (yeniSlug.isEmpty || editToken.isEmpty) {
        return const DemoRentalResult.basarisiz('ERROR');
      }

      // Vitrin artık hesabın: cihazı sunucudaki gerçek durumla besle.
      // Böylece kiralayan kişi uygulamada da vitrinini görür, tarayıcıyı
      // kapatsa bile kaybolmaz.
      final durum =
          await OwnerBootstrapService(storage: storage, client: client).getir();
      await durum.when(
        success:
            (state) => OwnerBootstrapService(
              storage: storage,
              client: client,
            ).cihazaUygula(state),
        failure: (_) async => null,
      );

      final url = await _duzenleyiciLinki(client, yeniSlug, editToken);
      return DemoRentalResult(
        ok: true,
        reason: 'RENTED',
        slug: yeniSlug,
        duzenleyiciUrl: url,
      );
    } catch (_) {
      return const DemoRentalResult.basarisiz('ERROR');
    }
  }

  /// Kısa ömürlü sahip oturumu kurup düzenleyici linkini üretir.
  /// Oturum kurulamazsa vitrin yine de hesapta durur — kullanıcı vitrinini
  /// kaybetmez, yalnız bu sefer tarayıcı açılmaz.
  Future<String> _duzenleyiciLinki(
    SupabaseClient client,
    String slug,
    String editToken,
  ) async {
    try {
      final response = await client.rpc(
        'create_owner_session',
        params: {'p_slug': slug, 'p_edit_token': editToken},
      );
      final code =
          (response is Map ? response['code'] : null)?.toString().trim() ?? '';
      if (code.isEmpty) return '';
      return PublicSiteConfig.buildOwnerSessionEntryLink(slug, code);
    } catch (_) {
      return '';
    }
  }
}
