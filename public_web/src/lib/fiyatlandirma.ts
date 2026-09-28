import fiyatSozlesmesi from "../../../shared/fiyatlandirma.json";

/**
 * Premium üyelik bedelinin tek kaynağı: shared/fiyatlandirma.json.
 *
 * Flutter tarafı aynı dosyadan lib/config/fiyatlandirma.g.dart'ı üretir
 * (tool/fiyatlandirma_uret.dart). Fiyat değişince yalnız ortak JSON
 * düzenlenir; iki yüzey de aynı metni gösterir.
 */

export const AYLIK_PREMIUM_KURUS = fiyatSozlesmesi.aylikPremiumKurus;
export const PARA_BIRIMI = fiyatSozlesmesi.paraBirimi;

function fiyatMetni(kurus: number, simge: string): string {
  const tamKisim = Math.floor(kurus / 100);
  const kurusKisim = kurus % 100;
  if (kurusKisim === 0) return `${tamKisim} ${simge}`;
  return `${tamKisim},${String(kurusKisim).padStart(2, "0")} ${simge}`;
}

function kalipDoldur(kalip: string, fiyat: string, aylikBedel: string): string {
  return kalip.replaceAll("{aylikBedel}", aylikBedel).replaceAll("{fiyat}", fiyat);
}

const kaliplar = fiyatSozlesmesi.metinKaliplari;

/** Görüntülenen bedel, ör. "299 TL". */
export const AYLIK_PREMIUM_FIYAT = fiyatMetni(
  AYLIK_PREMIUM_KURUS,
  fiyatSozlesmesi.paraBirimiSimgesi,
);

/** Aylık bedel cümlesi, ör. "Aylık 299 TL". */
export const AYLIK_PREMIUM_BEDEL = kalipDoldur(
  kaliplar.aylikBedel,
  AYLIK_PREMIUM_FIYAT,
  "",
);

function metin(kalip: string): string {
  return kalipDoldur(kalip, AYLIK_PREMIUM_FIYAT, AYLIK_PREMIUM_BEDEL);
}

/** Premium olmayan vitrin kartı rozeti. */
export const PREMIUM_DEGIL_ROZET = metin(kaliplar.premiumDegilRozet);

/** Yayın çağrısı düğmesi. */
export const PREMIUM_ILE_YAYINLA = metin(kaliplar.premiumIleYayinla);

/** Yayın kapısı uyarısı. */
export const YAYIN_KAPISI_UYARISI = metin(kaliplar.yayinKapisiUyarisi);

/** PayTR ödeme açıklaması. */
export const ODEME_ACIKLAMASI = metin(kaliplar.odemeAciklamasi);

/** PayTR sepet satırı başlığı. */
export const ODEME_SEPET_BASLIGI = kaliplar.odemeSepetBasligi;

/** PayTR sepet tutarı, ör. "299.00". */
export const ODEME_SEPET_TUTARI = (AYLIK_PREMIUM_KURUS / 100).toFixed(2);
