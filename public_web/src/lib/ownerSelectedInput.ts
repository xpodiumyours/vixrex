// Sahiplik ekranında SEÇİLİ alan varken, alan bağlamı serbest metinden daha güçlüdür.
// Bu dosya yalnız dar bir gerçek kullanım durumunu çözer:
//   İşletme Adı seçili + "Çarşı teknik servis 05421702573"
// Burada sondaki mobil numara WhatsApp olarak ayrılabilir; numaradan önceki
// metin ise kullanıcının zaten "İşletme Adı" sorusuna verdiği cevaptır.
// Genel serbest-metin motorunun "işletme kimliği tahmin edilmez" kuralına
// dokunulmaz; seçili alan yokken bu kestirme hiçbir zaman çalışmaz.

const TURKIYE_MOBIL_SONDA_REGEX =
  /(?:\+?90[\s.-]?)?0?5\d{2}[\s.-]?\d{3}[\s.-]?\d{2}[\s.-]?\d{2}\s*[.!]?\s*$/;

// Açıkça alan adı/telefon etiketi yazılmış zengin cümleler mevcut niyet
// motoruna bırakılır. Kestirme yalnız kullanıcının kısa, etiketsiz cevabında
// devreye girer; böylece "işletme adım X, whatsapp numaram Y" gibi çalışan
// akışların davranışı değişmez.
const ACIK_ETIKET_REGEX =
  /\b(işletme\s+ad[ıi]m?|isletme\s+ad[iı]m?|whatsapp|watsap|telefon|numara(?:m|sı|si)?)\b/i;

export interface IsletmeAdiTelefonKestirmesi {
  isletmeAdi: string;
}

export function isletmeAdiTelefonKestirmesiniCikar(
  metin: string,
): IsletmeAdiTelefonKestirmesi | null {
  const ham = metin.trim();
  if (!ham || ACIK_ETIKET_REGEX.test(ham)) return null;

  const telefon = ham.match(TURKIYE_MOBIL_SONDA_REGEX);
  if (!telefon || telefon.index === undefined || telefon.index <= 0) return null;

  const isletmeAdi = ham
    .slice(0, telefon.index)
    .replace(/[\s,;:–—-]+$/g, "")
    .trim();

  if (isletmeAdi.length < 2) return null;
  return { isletmeAdi };
}

/**
 * Yukarıdaki kestirme kullanıldıysa aynı etiketsiz isim parçası "teknik
 * servis" diye kategoriye veya "çarşı" diye adrese tekrar dağıtılmamalı.
 * Bu dar durumda güvenle ayrılan tek bonus veri mobil numaradır.
 */
export function businessNameShortcutBonusAllowed(
  bonusAnahtar: string,
  shortcutUsed: boolean,
): boolean {
  return !shortcutUsed || bonusAnahtar === "whatsapp";
}
