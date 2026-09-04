// Sahiplik ekranında SEÇİLİ kimlik alanı varken alan bağlamı serbest metinden
// daha güçlüdür. Bu dosya yalnız dar bir gerçek kullanım durumunu çözer:
//   seçili kimlik alanı + "Çarşı teknik servis 05421702573"
// Sondaki mobil numara ayrı bir WhatsApp değeri olabilir; numaradan önceki
// etiketsiz metin de kullanıcının o anda sorulan kimlik alanına cevabıdır.
// Genel serbest-metin motorunun "işletme kimliği tahmin edilmez" kuralına
// dokunulmaz; seçili alan bağlamı olmadan ana değer otomatik kaydedilmez.

const TURKIYE_MOBIL_SONDA_REGEX =
  /(?:\+?90[\s.-]?)?0?5\d{2}[\s.-]?\d{3}[\s.-]?\d{2}[\s.-]?\d{2}\s*[.!]?\s*$/;

// Açıkça alan adı/telefon etiketi yazılmış zengin cümleler mevcut niyet
// motoruna bırakılır. Kestirme yalnız kısa, etiketsiz cevapta devreye girer;
// böylece "işletme adım X, whatsapp numaram Y" gibi çalışan akış değişmez.
const ACIK_ETIKET_REGEX =
  /\b(işletme\s+ad[ıi]m?|isletme\s+ad[iı]m?|whatsapp|watsap|telefon|numara(?:m|sı|si)?)\b/i;

export interface SeciliKimlikTelefonKestirmesi {
  anaDeger: string;
}

export function seciliKimlikTelefonKestirmesiniCikar(
  metin: string,
): SeciliKimlikTelefonKestirmesi | null {
  const ham = metin.trim();
  if (!ham || ACIK_ETIKET_REGEX.test(ham)) return null;

  const telefon = ham.match(TURKIYE_MOBIL_SONDA_REGEX);
  if (!telefon || telefon.index === undefined || telefon.index <= 0) return null;

  const anaDeger = ham
    .slice(0, telefon.index)
    .replace(/[\s,;:–—-]+$/g, "")
    .trim();

  if (anaDeger.length < 2) return null;
  return { anaDeger };
}
