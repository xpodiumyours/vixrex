// shared/fiyatlandirma.json dosyasından üretildi.
// ELLE DÜZENLENMEZ — dart run tool/fiyatlandirma_uret.dart

/// Aylık premium bedeli, kuruş.
const int aylikPremiumKurus = 29900;

/// Para birimi kodu (PayTR ve yapısal veri için).
const String paraBirimi = 'TRY';

/// Görüntülenen bedel, ör. 299 TL.
const String aylikPremiumFiyat = '299 TL';

/// Aylık bedel cümlesi, ör. Aylık 299 TL.
const String aylikPremiumBedel = 'Pilot dönemde ücretsiz';

/// Premium olmayan vitrin kartı rozeti.
const String premiumDegilRozet =
    'Premium değil · pilot dönemde ücretsiz yayınla';

/// Yayın çağrısı düğmesi.
const String premiumIleYayinla = 'Yayınla — pilot dönemde ücretsiz';

/// Yayın kapısı uyarısı.
const String yayinKapisiUyarisi =
    'Bu hazır vitrin yalnız premium üyelikle yayınlanır. Pilot dönemde ücretsiz.';
