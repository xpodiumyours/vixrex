import 'package:vixrex/models/store_data.dart';

/// `bootstrap_owner_state` RPC'sinin dönüşü — kalıcı hesapla giriş yapan
/// sahibin sunucudaki tam durumu.
///
/// NEDEN TEK MODEL (2026-08-26): önceden "yeni cihazda vitrinimi bul" akışı
/// üç ayrı parçadan toplanıyordu — slug `get_own_published_store`'dan,
/// edit_token YALNIZ cihaz belleğinden, çalışma taslağı ise hiç. Yeni
/// cihazda bellek boş olduğu için token da boş kalıyor, uygulama vitrini
/// düzenleyemiyor ve taslak dalına düşüp YENİ bir vitrin satırı açıyordu.
/// Üçü artık tek çağrıdan, tek parça halinde gelir.
class OwnerBootstrapState {
  const OwnerBootstrapState({
    required this.hasStore,
    required this.reason,
    this.slug = '',
    this.name = '',
    this.editToken = '',
    this.isPublished = false,
    this.isStoreMode = false,
    this.liveVersion = 0,
    this.liveData,
    this.hasDraft = false,
    this.draftData,
    this.draftStale = false,
    this.liveUpdatedAt,
    this.draftUpdatedAt,
  });

  /// Kalıcı hesabı olmayan (anonim oturum) veya vitrini olmayan durum.
  const OwnerBootstrapState.yok(this.reason)
    : hasStore = false,
      slug = '',
      name = '',
      editToken = '',
      isPublished = false,
      isStoreMode = false,
      liveVersion = 0,
      liveData = null,
      hasDraft = false,
      draftData = null,
      draftStale = false,
      liveUpdatedAt = null,
      draftUpdatedAt = null;

  final bool hasStore;

  /// Sunucunun verdiği sebep kodu: `OK`, `NO_STORE`, `ANONYMOUS_SESSION`.
  final String reason;

  final String slug;
  final String name;

  /// Vitrinin kendi edit token'ı. Sunucu bunu YALNIZ vitrinin sahibine
  /// döner (auth.uid() eşleşmesi) — yeni cihazda uzaktan düzenlemenin tek
  /// yolu bu.
  final String editToken;

  final bool isPublished;

  /// `stores.is_store` — mağaza modu mu, vitrin modu mu.
  final bool isStoreMode;

  final int liveVersion;

  /// Yayındaki (canlı) satırın verisi.
  final StoreData? liveData;

  /// Web'de bırakılmış, henüz yayınlanmamış çalışma taslağı var mı.
  final bool hasDraft;
  final StoreData? draftData;

  /// Taslak üretildikten sonra canlı kayıt ilerlemiş — sessiz ezme riski.
  final bool draftStale;

  final DateTime? liveUpdatedAt;
  final DateTime? draftUpdatedAt;

  bool get anonimOturum => reason == 'ANONYMOUS_SESSION';

  /// Sunucudaki en güncel içerik: çalışma taslağı varsa o, yoksa canlı veri.
  /// Codex'in kurduğu ilke (2026-08-26): "working draft varsa onu, yoksa
  /// yayındaki veriyi".
  StoreData? get tercihEdilenVeri =>
      (hasDraft && draftData != null) ? draftData : liveData;

  /// [tercihEdilenVeri]'nin sunucudaki yazılma zamanı.
  DateTime? get tercihEdilenZaman =>
      (hasDraft && draftData != null) ? draftUpdatedAt : liveUpdatedAt;

  factory OwnerBootstrapState.fromJson(Map<String, dynamic> json) {
    final reason = (json['reason'] ?? '').toString();
    if (json['has_store'] != true) {
      return OwnerBootstrapState.yok(reason.isEmpty ? 'NO_STORE' : reason);
    }

    return OwnerBootstrapState(
      hasStore: true,
      reason: reason.isEmpty ? 'OK' : reason,
      slug: (json['slug'] ?? '').toString().trim(),
      name: (json['name'] ?? '').toString(),
      editToken: (json['edit_token'] ?? '').toString().trim(),
      isPublished: json['is_published'] == true,
      isStoreMode: json['is_store'] == true,
      liveVersion: _tamsayi(json['live_version']),
      liveData: _vitrinVerisi(json['store_data']),
      hasDraft: json['has_draft'] == true,
      draftData: _vitrinVerisi(json['draft_data']),
      draftStale: json['draft_stale'] == true,
      liveUpdatedAt: _zaman(json['live_updated_at']),
      draftUpdatedAt: _zaman(json['draft_updated_at']),
    );
  }

  /// Taslak/canlı jsonb'si bozuksa TÜM açılışı düşürmek yerine o parçayı
  /// yok sayarız — kullanıcı en azından vitrinine erişebilsin.
  static StoreData? _vitrinVerisi(Object? raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    if (map.isEmpty) return null;
    try {
      return StoreData.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static int _tamsayi(Object? raw) {
    if (raw is int) return raw;
    return int.tryParse((raw ?? '').toString()) ?? 0;
  }

  static DateTime? _zaman(Object? raw) {
    final metin = (raw ?? '').toString().trim();
    if (metin.isEmpty) return null;
    return DateTime.tryParse(metin)?.toUtc();
  }
}

/// `claim_store_for_user` RPC'sinin dönüşü.
class StoreClaimResult {
  const StoreClaimResult({
    required this.ok,
    required this.reason,
    this.slug = '',
  });

  const StoreClaimResult.basarisiz(this.reason) : ok = false, slug = '';

  final bool ok;

  /// `CLAIMED`, `ALREADY_MINE`, `ALREADY_OWNS_STORE`, `ANONYMOUS_SESSION`,
  /// `INVALID_TOKEN`, `NOT_CLAIMABLE`.
  final String reason;

  final String slug;

  /// Vitrin bu çağrıda gerçekten hesaba bağlandı (zaten bağlı değildi).
  bool get yeniBaglandi => ok && reason == 'CLAIMED';

  bool get zatenBaskaVitrinVar => reason == 'ALREADY_OWNS_STORE';

  /// Kullanıcıya gösterilecek mesaj. `null` ise sessiz geçilir — her sonucu
  /// ekrana basmak akışı gürültüye boğar.
  String? get kullaniciMesaji {
    if (yeniBaglandi) {
      return 'Vitrininiz hesabınıza bağlandı. Artık her cihazdan açabilirsiniz.';
    }
    if (zatenBaskaVitrinVar) {
      return 'Bu hesabın zaten bir vitrini var. Bir hesap yalnızca bir vitrin '
          'yönetebilir.';
    }
    return null;
  }

  factory StoreClaimResult.fromJson(Map<String, dynamic> json) =>
      StoreClaimResult(
        ok: json['ok'] == true,
        reason: (json['reason'] ?? '').toString(),
        slug: (json['slug'] ?? '').toString().trim(),
      );
}
