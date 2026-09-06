import 'package:supabase_flutter/supabase_flutter.dart';

/// VIXREX CORE sahiplik akışının tek Supabase erişim sınırı.
///
/// NEDEN VAR (2026-08-26)
/// `owner_bootstrap_service` ve `demo_rental_service` Supabase istemcisini
/// kendileri `Supabase.instance` üzerinden alıp doğrudan `rpc()` çağırıyordu.
/// `.github/scripts/verify_supabase_erisim_ratchet.py` bunu yakaladı:
/// repository dışındaki doğrudan erişim 22'den 24'e çıkmıştı.
///
/// Bekçiyi susturmanın kolay yolu istemciyi buraya taşıyıp `rpc()` çağrılarını
/// serviste bırakmaktı — o kuralı kandırmak olurdu. Onun yerine **çağrıların
/// kendisi** buraya taşındı; servisler artık ne istemciyi tanıyor ne RPC adını.
///
/// HATA YÖNETİMİ: metotlar hatayı YUTMAZ, olduğu gibi fırlatır. Servisler
/// hatayı kendi sözleşmelerine çeviriyor (`SupabaseErrorMapper`, `Result`,
/// `DemoRentalResult`) — bu davranış refactor'da bilerek korundu.
///
/// `const` yapılabilir olması şart: `OwnerBootstrapService` ve
/// `DemoRentalService` const constructor'a sahip ve depoda `const` olarak
/// kuruluyorlar (`app_router.dart`, `auth_service.dart`).
class VitrinSahiplikRepository {
  const VitrinSahiplikRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  /// Supabase henüz kurulmamışsa (test, çevrimdışı açılış) `null` döner —
  /// fırlatmaz. Servislerin "NO_CLIENT" dalı buna dayanıyor.
  SupabaseClient? get istemci {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Kalıcı (anonim olmayan) bir hesapla giriş yapılmış mı?
  bool get kaliciHesapVar {
    final user = istemci?.auth.currentUser;
    return user != null && !user.isAnonymous;
  }

  /// `bootstrap_owner_state` — yeni cihazda açılışın tek kaynağı.
  /// Ham yanıtı döndürür; yorumlamak servisin işi.
  Future<dynamic> bootstrapOwnerState(SupabaseClient client) {
    return client.rpc('bootstrap_owner_state');
  }

  /// Mevcut güvenli working-draft bootstrap RPC'si. Yeni endpoint değildir;
  /// 5.8 Flutter assistant yalnız çalışma taslağı henüz yoksa bunu kullanır.
  Future<dynamic> getOrCreateWorkingDraft(
    SupabaseClient client, {
    required String slug,
    required String editToken,
  }) {
    return client.rpc(
      'get_or_create_working_draft',
      params: {'p_slug': slug, 'p_edit_token': editToken},
    );
  }

  /// `rent_demo_canonical` — Flutter ve Next.js için tek kiralama zinciri.
  Future<dynamic> rentDemoForAccount(SupabaseClient client, String sourceSlug) {
    return client.rpc(
      'rent_demo_canonical',
      params: {'p_source_slug': sourceSlug, 'p_flow_type': 'kiralama'},
    );
  }

  /// `create_owner_session` — kısa ömürlü sahip oturumu kodu üretir.
  Future<dynamic> createOwnerSession(
    SupabaseClient client, {
    required String slug,
    required String editToken,
  }) {
    return client.rpc(
      'create_owner_session',
      params: {'p_slug': slug, 'p_edit_token': editToken},
    );
  }
}
