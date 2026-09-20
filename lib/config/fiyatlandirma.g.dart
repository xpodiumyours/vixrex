// shared/fiyatlandirma.json dosyasından üretildi.
// ELLE DÜZENLENMEZ — dart run tool/fiyatlandirma_uret.dart

/// Aylık premium bedeli, kuruş.
const int aylikPremiumKurus = 29900;

/// Para birimi kodu (PayTR ve yapısal veri için).
const String paraBirimi = 'TRY';

/// Görüntülenen bedel, ör. 299 TL.
const String aylikPremiumFiyat = '299 TL';

/// Aylık bedel cümlesi, ör. Aylık 299 TL.
const String aylikPremiumBedel = 'Aylık 299 TL';

/// Premium olmayan vitrin kartı rozeti.
const String premiumDegilRozet = 'Premium değil · Aylık 299 TL ile yayınla';

/// Yayın çağrısı düğmesi.
const String premiumIleYayinla = 'Premium ile yayınla — aylık 299 TL';

/// Yayın kapısı uyarısı.
const String yayinKapisiUyarisi =
    'Bu hazır vitrin yalnız premium üyelikle yayınlanır. Aylık 299 TL ile devam et.';
