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
  calismaSaatleriMetni?: string;
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

// Çok günlü saat anlatımı tek bir HH:MM-HH:MM aralığına indirgenemez.
// Özellikle "hafta içi 09-18, cumartesi 10-16, pazar kapalı" girdisinde
// eski çıkarıcı yalnız ilk aralığı kaydediyor; ikinci aralıktaki rakamlar da
// adres tarayıcısına kalıp "cumartesi 10:00-16:00" gibi sahte adres
// üretebiliyordu. Vitrin alanı bugün metin olduğu için veri modelini
// değiştirmeden, yalnız gün/saat bölümünü kayıpsız koruyoruz.
const CALISMA_GUN_IPUCU_REGEX =
  /\b(her\s+gün|her\s+gun|hafta\s+içi|hafta\s+ici|hafta\s+sonu|pazartesi|salı|sali|çarşamba|carsamba|perşembe|persembe|cuma|cumartesi|pazar|pzt|sal|çar|car|per|cum|cmt|paz)\b/gi;
// JavaScript `\b` yalnız ASCII "word" karakterleriyle güvenilir çalışır;
// Türkçe `ı` kelime karakteri sayılmadığı için `/kapalı\b/` eşleşmez.
// Son sınırı açıkça boşluk/noktalama/metin sonu olarak tanımlarız.
const KAPALI_IPUCU_REGEX = /\bkapal[ıi](?=$|[\s.,;:!?])/gi;

function tumSaatAraliklari(metin: string): string[] {
  return Array.from(metin.matchAll(new RegExp(TIME_RANGE_REGEX.source, "g"))).map(
    (eslesme) => eslesme[0],
  );
}

function zenginCalismaSaatleriMetniCikar(paragraf: string): string | null {
  const saatler = Array.from(
    paragraf.matchAll(new RegExp(TIME_RANGE_REGEX.source, "g")),
  );
  if (saatler.length === 0) return null;

  const gunler = Array.from(paragraf.matchAll(CALISMA_GUN_IPUCU_REGEX));
  if (gunler.length === 0) return null;

  const ilkSaatIndex = saatler[0].index ?? 0;
  const baslangicEslesmesi =
    [...gunler]
      .reverse()
      .find((eslesme) => (eslesme.index ?? Number.MAX_SAFE_INTEGER) <= ilkSaatIndex) ??
    gunler[0];
  const baslangic = baslangicEslesmesi.index ?? 0;

  const kapalilar = Array.from(paragraf.matchAll(KAPALI_IPUCU_REGEX)).filter(
    (eslesme) => (eslesme.index ?? -1) >= baslangic,
  );

  // Tek aralık + "hafta içi" gibi basit kullanım mevcut davranışta kalır:
  // geriye yine normalize "09:00 - 19:00" döner. Kayıpsız metin yalnız
  // gerçekten birden fazla zaman bilgisi olduğunda devreye girer.
  if (saatler.length === 1 && kapalilar.length === 0) return null;

  let bitis = baslangic;
  for (const eslesme of saatler) {
    const index = eslesme.index ?? 0;
    if (index < baslangic) continue;
    bitis = Math.max(bitis, index + eslesme[0].length);
  }
  for (const eslesme of kapalilar) {
    const index = eslesme.index ?? 0;
    bitis = Math.max(bitis, index + eslesme[0].length);
  }
  if (bitis <= baslangic) return null;

  return paragraf
    .slice(baslangic, bitis)
    .replace(/\s+/g, " ")
    .trim()
    .replace(/[.,;:]+$/g, "")
    .trim();
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

  const zenginSaatler = zenginCalismaSaatleriMetniCikar(paragraf);
  const saatler = findTimeRange(paragraf);
  if (zenginSaatler) sonuc.calismaSaatleriMetni = zenginSaatler;
  else if (saatler) sonuc.calismaSaatleriMetni = saatler.raw;

  const yer = ilIlceCikar(paragraf);
  if (yer) {
    sonuc.ilAdi = yer.il;
    if (yer.ilce) sonuc.ilceAdi = yer.ilce;
  }

  // Adres taraması, zaten bulunan telefon/saat alt-dizgelerini temizden
  // sonra yapılır — yoksa saat aralıklarının rakamları AddressValidator'ın
  // "rakam var" koşulunu geçip sahte adres olabilir. Tek aralık değil,
  // paragraftaki TÜM aralıklar çıkarılır; zengin çok-günlü saat metni de
  // bütünüyle temizlenir.
  const saatAdaylari = tumSaatAraliklari(paragraf);
  const cikarilacaklar = [telefonAdayi, zenginSaatler ?? "", ...saatAdaylari].filter(Boolean);
  const adres = adresCikar(paragraf, cikarilacaklar);
  if (adres) sonuc.adres = adres;

  return sonuc;
}
