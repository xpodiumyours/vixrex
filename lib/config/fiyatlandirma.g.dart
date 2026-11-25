// shared/fiyatlandirma.json dosyasından üretildi.
// ELLE DÜZENLENMEZ — dart run tool/fiyatlandirma_uret.dart

/// Aylık premium bedeli, kuruş.
const int aylikPremiumKurus = 129500;

/// Para birimi kodu (yapısal veri için).
const String paraBirimi = 'TRY';

/// Görüntülenen bedel, ör. 1295 TL.
const String aylikPremiumFiyat = '1295 TL';

/// Aylık bedel cümlesi, ör. Aylık 1295 TL.
const String aylikPremiumBedel = 'Aylık 1295 TL';

/// Premium olmayan vitrin kartı rozeti.
const String premiumDegilRozet = 'Premium değil · Aylık 1295 TL ile yayınla';

/// Yayın çağrısı düğmesi.
const String premiumIleYayinla = 'Premium ile yayınla — aylık 1295 TL';

/// Yayın kapısı uyarısı.
const String yayinKapisiUyarisi =
    'Bu hazır vitrin yalnız premium üyelikle yayınlanır. Aylık 1295 TL ile devam et.';
