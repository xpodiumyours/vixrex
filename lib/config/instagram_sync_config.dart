/// Instagram senkronizasyonu yapılandırması.
///
/// Bu özellik henüz aktif değildir.
/// Aktifleştirmek için:
/// 1. Vercel'de INSTAGRAM_SYNC_ENABLED=true env var'ı ayarla
/// 2. public_web projesinde Instagram API ayarlarını kontrol et
/// 3. Token yönetiminin çalıştığını doğrula
///
/// Not: Bu compile-time bir flag'dir. Değiştirmek için yeniden build gerekir.
abstract final class InstagramSyncConfig {
  static const bool enabled = bool.fromEnvironment(
    'INSTAGRAM_SYNC_ENABLED',
    defaultValue: false,
  );
}
