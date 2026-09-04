/**
 * "Esnaf tek paragraf yazsın, asistan anlasın" — serbest metinden alan
 * çıkarımı. Ücretsiz, deterministik (regex + coğrafi/kategori sözlük
 * eşleştirme) — LLM/API YOK. Var olan doğrulayıcı/eşleştirici
 * fonksiyonları TEKRAR KULLANIR, yeniden icat etmez:
 *   - kategori → resolveBusinessCategory (businessCategories.ts) doğrudan
 *   - çalışma saatleri → findTimeRange (workingHours.ts) doğrudan
 *   - adres → isAddressValid (addressValidator.ts) doğrudan, yalnız hangi
 *     cümlenin adres olduğunu seçen tarama kısmı yeni
 *   - il/ilçe → ilIlceCikar (turkeyPlaceMatcher.ts)
 *   - WhatsApp → vitrinFieldValidation.ts'teki normalizeTurkeyMobile'ın
 *     rakam-şekli mantığı burada tekrarlanır (fonksiyonun kendisi
 *     çağrılamaz: ilk satırı paragrafta HERHANGİ bir harf varsa reddeder,
 *     bu her paragraf için doğru olur)
 *
 * KASITLI OLARAK YOK: işletme adı — otomatikVitrinIcerik.ts'nin başındaki
 * kuralla aynı ilke, gerçek kimlik asla tahmin edilmez. Bu, dönüş tipinde
 * YAPISAL bir garanti (bkz. serbest-metin-cikarim.test.ts).
 */
import { resolveBusinessCategory } from "./businessCategories";
import { findTimeRange, TIME_RANGE_REGEX } from "./workingHours";
import { isAddressValid } from "./addressValidator";
import { ilIlceCikar } from "./turkeyPlaceMatcher";
import { seciliKimlikTelefonKestirmesiniCikar } from "./ownerSelectedInput";

export interface SerbestMetinSonuc {
  whatsapp?: string; // "90XXXXXXXXXX"
  kategoriEtiketi?: string;
  calismaSaatleriMetni?: string; // "09:00 - 20:00"
  ilAdi?: string;
  ilceAdi?: string;
  adres?: string;
}

const TELEFON_ADAYI_REGEX =
  /(?:\+?90[\s.-]?)?0?5\d{2}[\s.-]?\d{3}[\s.-]?\d{2}[\s.-]?\d{2}/;

/** vitrinFieldValidation.ts'teki normalizeTurkeyMobile'ın rakam-şekli
 * dallarıyla AYNI mantık — kaynak orada, sürüklenirse ikisi birden
 * güncellenmeli (bkz. dosya başı yorumu). */
function telefonuNormallestir(eslesenAltDizge: string): string | null {
  const digits = eslesenAltDizge.replace(/\D/g, "");
  if (/^05\d{9}$/.test(digits)) return `90${digits.slice(1)}`;
  if (/^5\d{9}$/.test(digits)) return `90${digits}`;
  if (/^905\d{9}$/.test(digits)) return digits;
  return null;
}

// Adres cümlelerine bölerken "Cad." / "Sok." / "Mah." / "No." gibi
// kısaltmaların noktası cümle sonu SAYILMAMALI — yoksa "Atatürk Cad.
// No:24" yanlışlıkla "Atatürk Cad" (kapı no'suz, ama yine de
// isAddressValid'i geçebilir) ve "No:24" diye ikiye bölünür. Bölmeden
// önce noktayı düz metinle koruyup bölündükten sonra geri koyarız — sıra
// önemli bir işaret kullanılır (metinde geçmesi neredeyse imkansız),
// gerçek boşluklarla karışmasın diye BİR boşluk değil.
const ADRES_KISALTMALARI = ["cad", "sok", "mah", "bulv", "blv", "apt", "blok", "sit", "no"];
const NOKTA_KORUMA_ISARETI = "§§NOKTA§§";

function adresCumlelerineBol(metin: string): string[] {
  let korunanNoktali = metin;
  for (const kisaltma of ADRES_KISALTMALARI) {
    korunanNoktali = korunanNoktali.replace(
      new RegExp(`\\b(${kisaltma})\\.`, "gi"),
      (_, k: string) => `${k}${NOKTA_KORUMA_ISARETI}`,
    );
  }
  return korunanNoktali
    .split(/[.,;\n]|\bve\b/i)
    .map((parca) => parca.replaceAll(NOKTA_KORUMA_ISARETI, ".").trim())
    .filter(Boolean);
}

function adresCikar(paragraf: string, cikarilacakAltDizgeler: string[]): string | null {
  let temizlenmis = paragraf;
  for (const parca of cikarilacakAltDizgeler) {
    if (parca) temizlenmis = temizlenmis.replace(parca, " ");
  }
  for (const cumle of adresCumlelerineBol(temizlenmis)) {
    if (isAddressValid(cumle)) return cumle;
  }
  return null;
}

export function serbestMetindenAlanlariCikar(paragraf: string): SerbestMetinSonuc {
  const sonuc: SerbestMetinSonuc = {};

  const telefonAdayi = paragraf.match(TELEFON_ADAYI_REGEX)?.[0] ?? "";
  const whatsapp = telefonAdayi ? telefonuNormallestir(telefonAdayi) : null;
  if (whatsapp) sonuc.whatsapp = whatsapp;

  // Gerçek testte "Çarşı teknik servis 0542..." seçili kimlik sorusuna
  // verilen kısa cevaptı. Genel çıkarıcı, telefon dışındaki "çarşı" ve
  // "teknik servis" parçalarını sırasıyla adres/kategori sanıp yanlış
  // alanlara yazıyordu. Etiketsiz kısa metin + sonda mobil numara deseni
  // kimlik cevabı OLABİLİR; genel motor kimliği tahmin etmediği için burada
  // en güvenli davranış yalnız kesin olan telefonu döndürmek ve kalan metni
  // kategori/adrese dağıtmamaktır. Seçili alan kendi değerini ayrı bağlamda
  // ownerSelectedInput üzerinden alır.
  if (whatsapp && seciliKimlikTelefonKestirmesiniCikar(paragraf)) {
    return sonuc;
  }

  const kategori = resolveBusinessCategory(paragraf);
  if (kategori) sonuc.kategoriEtiketi = kategori.label;

  const saatler = findTimeRange(paragraf);
  if (saatler) sonuc.calismaSaatleriMetni = saatler.raw;

  const yer = ilIlceCikar(paragraf);
  if (yer) {
    sonuc.ilAdi = yer.il;
    if (yer.ilce) sonuc.ilceAdi = yer.ilce;
  }

  // Adres taraması, zaten bulunan telefon/saat alt-dizgelerini temizden
  // sonra yapılır — yoksa "0532 123 45 67" gibi salt rakamlı bir "cümle"
  // isAddressValid'in rakam koşulunu yanlışlıkla geçebilir. Ham eşleşen
  // alt-dizgeler kullanılır (saatler.raw değil — o normalize/dolgulu bir
  // biçim, paragrafta harfiyen geçmeyebilir).
  const saatAdayi = paragraf.match(TIME_RANGE_REGEX)?.[0] ?? "";
  const cikarilacaklar = [telefonAdayi, saatAdayi].filter(Boolean);
  const adres = adresCikar(paragraf, cikarilacaklar);
  if (adres) sonuc.adres = adres;

  return sonuc;
}