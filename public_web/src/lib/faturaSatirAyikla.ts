import type { HamFaturaSatiri } from "@/lib/faturaEslestir";

// Görüntü okuyucunun (vixrex-fatura-goru) döndürdüğü HAM METNİ satırlara
// ayırır. Model yalnız "gördüğünü yaz" der — hangi kelimenin kod, hangisinin
// beden olduğuna model KARAR VERMEZ; bu dosya deterministik kodla yapar.
// Böylece aynı satır her zaman aynı sonucu üretir, model her seferinde
// "yorumlamaz".
//
// Bilinen sınır: bu bir sezgisel (heuristic) ayrıştırıcıdır, gerçek bir
// fatura fotoğrafıyla doğruluğu henüz ÖLÇÜLMEDİ — yalnız bilinen gerçek
// satır biçimleriyle test edildi (bkz. faturaSatirAyikla.test.ts).

const BEDEN_KELIMELERI = new Set([
  "XS", "S", "M", "L", "XL", "XXL", "XXXL", "2XL", "3XL", "4XL",
]);

function turkceBuyuk(deger: string): string {
  return deger
    .replace(/i/g, "İ")
    .replace(/ı/g, "I")
    .toLocaleUpperCase("tr-TR");
}

// Türkçe büyük harfe çevirirken i/İ, ı/I karışmasın diye kelimeler küçük
// harften türetilir — elle "SİYAH" yazıp yanlışlıkla "SIYAH" yazma riski
// olmasın.
const RENK_KELIMELERI = new Set(
  [
    "siyah", "beyaz", "lacivert", "bej", "gri", "kırmızı", "mavi", "yeşil",
    "sarı", "pembe", "mor", "turuncu", "kahverengi", "ekru", "haki", "bordo",
    "turkuaz", "antrasit", "krem",
  ].map(turkceBuyuk),
);

const BIRIM_KELIMELERI = new Set(["AD", "ADET", "AD.", "ADET."]);

/** "137,00" veya "1.234,50" biçimindeki fiyat belirtecini sayıya çevirir. */
function fiyatMi(token: string): number | null {
  const temiz = token.replace(/^[₺$]/, "").replace(/TL\.?$/i, "");
  if (!/^\d{1,3}(\.\d{3})*,\d{2}$/.test(temiz)) return null;
  const sayi = Number(temiz.replace(/\./g, "").replace(",", "."));
  return Number.isFinite(sayi) ? sayi : null;
}

function kodMu(token: string): boolean {
  // Harf+rakam karışık kod (ELT1302) ya da kısa yalın rakam kod (0282, KP1
  // gibi — barkoddan ayırt etmek için 8 haneden kısa tutulur).
  if (/^[A-Za-zÇĞİÖŞÜçğıöşü]{2,6}\d{1,6}$/.test(token)) return true;
  if (/^\d{1,6}$/.test(token) && token.length < 8) return true;
  return false;
}

function barkodMu(token: string): boolean {
  return /^\d{8,14}$/.test(token);
}

function bedenMi(token: string): boolean {
  const b = turkceBuyuk(token);
  if (BEDEN_KELIMELERI.has(b)) return true;
  // Sayısal beden: 34-56 arası (giysi) veya tek haneli çocuk numarası.
  if (/^\d{1,2}$/.test(token)) {
    const n = Number(token);
    return n >= 1 && n <= 60;
  }
  return false;
}

/**
 * "8–10 Yaş" / "8-10 yaş" gibi yaş aralığını tek beden değeri olarak yakalar.
 * Satır içinde ARA BİR YERDE geçtiği için ^/$ ile tüm satıra ÇAPALANMAZ —
 * yalnız bu alt diziyi bulur.
 */
// NOT: sonda \b (kelime sınırı) KULLANILMAZ — JS regex "ş" gibi Türkçe
// harfleri "kelime karakteri" saymadığı için \b, "Yaş" sonrası hiç
// eşleşmiyordu (iki tarafı da "kelime dışı" sayılıp sınır oluşmuyordu).
const YAS_DESENI = /\d{1,2}\s*[–-]\s*\d{1,2}\s*Yaş/gi;
// `g` bayraklı deseni `.test()` ile tekrar tekrar çağırmak `lastIndex`
// durumu yüzünden atlamalı sonuç verir — token kontrolü için ayrı,
// bayraksız bir kopya kullanılır.
const YAS_DESENI_TEK = /^\d{1,2}\s*[–-]\s*\d{1,2}\s*Yaş$/i;

/**
 * Tek bir fatura satırını (zaten satıra bölünmüş, boşlukla ayrılmış token
 * dizisi olarak) yapılandırılmış alanlara çevirir. Kod veya ad yoksa null
 * döner — o satır ürün sayılmaz.
 */
export function faturaSatiriniAyikla(ham: string): HamFaturaSatiri | null {
  const satir = ham.trim().replace(/\s+/g, " ");
  if (!satir) return null;

  // Yaş aralığını ("8–10 Yaş") tek token'a indir ki döngü onu bedene
  // ayırabilsin.
  const birlesikSatir = satir.replace(YAS_DESENI, (tam) => tam.replace(/\s+/g, "_"));
  const tokenlar = birlesikSatir.split(" ").filter(Boolean);
  if (tokenlar.length === 0) return null;

  let kod = "";
  let barkod = "";
  let beden = "";
  let varyant = "";
  let adet: number | null = null;
  const fiyatlar: number[] = [];
  const adTokenlari: string[] = [];

  for (let i = 0; i < tokenlar.length; i++) {
    const ham = tokenlar[i];
    const token = ham.replace(/_/g, " ");
    const buyuk = turkceBuyuk(ham);

    if (!kod && kodMu(ham) && i === 0) {
      kod = ham.toUpperCase();
      continue;
    }
    if (!barkod && barkodMu(ham)) {
      barkod = ham;
      continue;
    }
    if (YAS_DESENI_TEK.test(token)) {
      beden = token.replace(/\s+/g, " ").replace(/^(\d+)\s*-\s*(\d+)/, "$1–$2");
      continue;
    }
    if (!beden && bedenMi(ham)) {
      beden = ham.toUpperCase();
      continue;
    }
    if (!varyant && RENK_KELIMELERI.has(buyuk)) {
      varyant = ham[0].toLocaleUpperCase("tr-TR") + ham.slice(1).toLocaleLowerCase("tr-TR");
      continue;
    }
    if (adet === null && BIRIM_KELIMELERI.has(buyuk) && i > 0) {
      const onceki = tokenlar[i - 1];
      const sayi = Number(onceki);
      if (Number.isFinite(sayi) && sayi > 0 && adTokenlari[adTokenlari.length - 1] === onceki) {
        adTokenlari.pop(); // adet sayısı yanlışlıkla ada eklenmişti, geri al
      }
      if (Number.isFinite(sayi) && sayi > 0) adet = sayi;
      continue;
    }
    const fiyat = fiyatMi(ham);
    if (fiyat !== null) {
      fiyatlar.push(fiyat);
      continue;
    }
    if (buyuk === "TL" || buyuk === "TRY" || buyuk === "₺") continue;

    adTokenlari.push(token);
  }

  const ad = adTokenlari.join(" ").trim();
  if (!kod && !ad) return null;

  const guvenPuanlari = [kod, barkod, ad, beden, adet !== null].filter(Boolean).length;

  return {
    model: kod,
    ad,
    barkod,
    varyant,
    beden,
    adet,
    alisBirimFiyat: fiyatlar[0] ?? null,
    satirToplam: fiyatlar.length > 1 ? fiyatlar[fiyatlar.length - 1] : null,
    guven: Math.min(1, guvenPuanlari / 5),
  };
}

/** Fatura/dış hat/toplam gibi ürün OLMAYAN satırları eler. */
const ATLA_DESENLERI = [
  /^toplam\b/i,
  /^ara toplam\b/i,
  /^kdv\b/i,
  /^tarih\b/i,
  /^fiş no\b/i,
  /^fatura no\b/i,
  /^sayfa\b/i,
  /^i̇mza\b/i,
  /^imza\b/i,
  /^kaşe\b/i,
];

/**
 * Görüntü okuyucudan gelen ham çok satırlı metni ürün satırlarına çevirir.
 *
 * Bilinerek yapılmayan şey: toplam tutar/adet ile satırların toplamını
 * karşılaştırıp otomatik düzeltme — bu tahmin olur. Karşılaştırma yalnız
 * `tool/fatura_olcum.py` ile ayrı bir ölçüm adımında yapılır.
 */
export function hamMetniSatirlaraAyir(metin: string): HamFaturaSatiri[] {
  const satirlar = metin
    .split(/\r?\n/)
    .map((s) => s.trim())
    .filter(Boolean)
    .filter((s) => !ATLA_DESENLERI.some((desen) => desen.test(s)));

  const sonuc: HamFaturaSatiri[] = [];
  for (const satir of satirlar) {
    const ayiklanan = faturaSatiriniAyikla(satir);
    // Kod da barkod da yoksa (yalnız ad+fiyat) bu satır faturanın ürün
    // tablosu dışı bir açıklaması olabilir — eşleştirmeye giremeyeceği için
    // yine de döndürülür (taslak kapısı zaten kodu olmayanı reddeder).
    if (ayiklanan) sonuc.push(ayiklanan);
  }
  return sonuc;
}
