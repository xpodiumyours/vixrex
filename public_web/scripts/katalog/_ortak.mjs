/**
 * Ürün havuzu toplayıcısı — ortak altyapı.
 *
 * Bu dosya hiçbir siteye özel değildir. Yaptığı iş:
 *   - adres okuma (zaman aşımı, geri çekilerek tekrar deneme)
 *   - nezaket: aynı siteye istekleri aralıklı gönderme, robots.txt'e uyma
 *   - gelen ham veriyi tek standart biçime çevirme
 *   - dosyaya yazma ve sayı raporu üretme
 *
 * Bağımlılık yok. Yalnız Node.js yerleşikleri kullanılır (Node 18+).
 */

import { mkdir, readFile, writeFile } from "node:fs/promises";
import { readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const BURASI = path.dirname(fileURLToPath(import.meta.url));

/**
 * Katalogların yazıldığı klasör.
 *
 * `src/` DIŞINDADIR: bu dosyalar Next.js paketine gömülmez. Toplam hacim
 * megabaytlara çıktığı için (tek firma 9 MB olabiliyor) paketlemek yanlış
 * olur; uygulama bunları yalnız gerektiğinde okur.
 */
export const VERI_KLASORU = path.resolve(BURASI, "..", "..", "data", "katalog");

// Ürün fotoğrafı sınırları TEK KAYNAKTAN gelir: shared/product_image_policy.json.
// Sayı başka dosyada elle yazılmaz.
const POLITIKA = JSON.parse(
  readFileSync(path.resolve(BURASI, "..", "..", "..", "shared", "product_image_policy.json"), "utf8"),
);

/** Ürün kartının kabul ettiği en fazla fotoğraf sayısı. */
export const EN_COK_GORSEL = Number(POLITIKA.maxImages) || 11;

/**
 * Açıklama kırpma sınırı. Kartta gösterilecek metin için fazlasıyla yeterli;
 * kırpılmasa tek firmanın kataloğu tek başına megabaytlara çıkıyor.
 */
export const EN_COK_ACIKLAMA = 600;

/** Kendini tanıtan kullanıcı adı — site sahibi kimin okuduğunu görebilsin. */
export const KULLANICI_ARACI = "VixrexKatalog/1.0 (+https://vixrex.com; urun havuzu toplama)";

const ZAMAN_ASIMI_MS = 15000;
/** Aynı siteye iki istek arasında en az bu kadar beklenir (nezaket). */
const NEZAKET_MS = 900;
const EN_COK_DENEME = 3;

const sonIstek = new Map();

function bekle(ms) {
  return new Promise((coz) => setTimeout(coz, ms));
}

async function nezaketBekle(host) {
  const onceki = sonIstek.get(host) ?? 0;
  const gecen = Date.now() - onceki;
  if (gecen < NEZAKET_MS) await bekle(NEZAKET_MS - gecen);
  sonIstek.set(host, Date.now());
}

/**
 * Tek bir adresi okur.
 *
 * 5xx ve ağ hatasında geri çekilerek tekrar dener. 4xx dönerse tekrar
 * denemez: site kapalı ya da engelli demektir, zorlanmaz.
 */
export async function istek(url, { zamanAsimiMs = ZAMAN_ASIMI_MS } = {}) {
  const host = new URL(url).host;
  let sonHata = null;

  for (let deneme = 1; deneme <= EN_COK_DENEME; deneme++) {
    await nezaketBekle(host);
    const kontrol = new AbortController();
    const zamanlayici = setTimeout(() => kontrol.abort(), zamanAsimiMs);

    try {
      const yanit = await fetch(url, {
        headers: { "user-agent": KULLANICI_ARACI, accept: "application/json, text/html;q=0.9, */*;q=0.8" },
        signal: kontrol.signal,
        redirect: "follow",
      });
      clearTimeout(zamanlayici);
      const govde = await yanit.text();

      if (yanit.ok) return { durum: yanit.status, govde, basliklar: yanit.headers };
      if (yanit.status < 500) return { durum: yanit.status, govde, basliklar: yanit.headers };
      sonHata = new Error(`HTTP ${yanit.status}`);
    } catch (hata) {
      clearTimeout(zamanlayici);
      sonHata = hata;
    }

    if (deneme < EN_COK_DENEME) await bekle(deneme * 1500);
  }

  throw sonHata ?? new Error(`İstek başarısız: ${url}`);
}

/**
 * JSON dönen adresler için kısa yol.
 * Dönen gövde JSON değilse `veri` null olur; hata fırlatılmaz.
 */
export async function jsonIstek(url, secenekler) {
  const yanit = await istek(url, secenekler);
  if (yanit.durum !== 200) return { durum: yanit.durum, veri: null, basliklar: yanit.basliklar };

  const kirpilmis = yanit.govde.trim();
  if (!kirpilmis.startsWith("[") && !kirpilmis.startsWith("{")) {
    return { durum: yanit.durum, veri: null, basliklar: yanit.basliklar };
  }

  try {
    return { durum: yanit.durum, veri: JSON.parse(kirpilmis), basliklar: yanit.basliklar };
  } catch {
    return { durum: yanit.durum, veri: null, basliklar: yanit.basliklar };
  }
}

const robotsOnbellek = new Map();

/** robots.txt kaydını bir kez indirir. Ağ hatası ayrıca bildirilir. */
async function robotsKaydi(url) {
  const hedef = new URL(url);
  const anahtar = hedef.host;
  if (robotsOnbellek.has(anahtar)) return robotsOnbellek.get(anahtar);

  let kayit = { metin: "", ulasildi: false };
  try {
    const yanit = await istek(`${hedef.protocol}//${hedef.host}/robots.txt`, { zamanAsimiMs: 8000 });
    kayit = { metin: yanit.durum === 200 ? yanit.govde : "", ulasildi: true };
  } catch {
    kayit = { metin: "", ulasildi: false };
  }

  robotsOnbellek.set(anahtar, kayit);
  return kayit;
}

/**
 * Sitenin durumu: erişilebiliyor mu, robots bizi engelliyor mu.
 * "Ulaşılamadı" ile "burada ürün yok" ayrı şeylerdir; karıştırılmaz.
 */
export async function siteDurumu(url) {
  const hedef = new URL(url);
  const kayit = await robotsKaydi(url);
  if (!kayit.ulasildi) return { ulasildi: false, engelli: false };
  if (!kayit.metin) return { ulasildi: true, engelli: false };

  let bizimIcin = false;
  for (const ham of kayit.metin.split(/\r?\n/)) {
    const satir = ham.split("#")[0].trim();
    if (!satir || !satir.includes(":")) continue;

    const ikiNokta = satir.indexOf(":");
    const alan = satir.slice(0, ikiNokta).trim().toLowerCase();
    const deger = satir.slice(ikiNokta + 1).trim();

    if (alan === "user-agent") {
      bizimIcin = deger === "*" || deger.toLowerCase().includes("vixrex");
    } else if (bizimIcin && alan === "disallow" && deger && hedef.pathname.startsWith(deger)) {
      return { ulasildi: true, engelli: true };
    }
  }

  return { ulasildi: true, engelli: false };
}

/** robots.txt bizi engelliyorsa true döner. */
export async function robotsEngelliMi(url) {
  return (await siteDurumu(url)).engelli;
}

/** HTML varlıklarını gerçek karaktere çevirir (ürün adlarında sık görülür). */
export function htmlCoz(metin) {
  return String(metin ?? "")
    .replace(/&#x([0-9a-f]+);/gi, (_, kod) => String.fromCharCode(parseInt(kod, 16)))
    .replace(/&#(\d+);/g, (_, kod) => String.fromCharCode(Number(kod)))
    .replace(/&quot;/g, '"')
    .replace(/&#0?39;|&apos;/g, "'")
    .replace(/&nbsp;/g, " ")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&amp;/g, "&");
}

/** HTML etiketlerini atıp düz metne indirger. */
export function duzMetin(html) {
  return htmlCoz(
    String(html ?? "")
      .replace(/<(script|style)[^>]*>[\s\S]*?<\/\1>/gi, " ")
      .replace(/<br\s*\/?>/gi, " ")
      .replace(/<[^>]+>/g, " "),
  )
    .replace(/\s+/g, " ")
    .trim();
}

/** Ürün/stok kodunu karşılaştırılabilir hale getirir. ELT-1302 → ELT1302 */
export function normalizeKod(deger) {
  return String(deger ?? "")
    .trim()
    .toUpperCase()
    .replace(/[\s._\-/]/g, "");
}

/** Barkodu yalnız 8-14 haneli sayıysa kabul eder; değilse boş döner. */
export function normalizeBarkod(deger) {
  const rakam = String(deger ?? "").replace(/\D/g, "");
  return rakam.length >= 8 && rakam.length <= 14 ? rakam : "";
}

/**
 * Ham ürünü tek standart biçime çevirir.
 * Kod yoksa ürün alınmaz — kodsuz ürün faturayla eşleşemez.
 */
export function urunuNormalle(ham, kaynak) {
  const kod = normalizeKod(ham?.kod);
  if (!kod) return null;

  const gorseller = Array.from(
    new Set(
      (Array.isArray(ham?.gorseller) ? ham.gorseller : [])
        .filter((adres) => typeof adres === "string" && /^https?:\/\//i.test(adres))
        .map((adres) => adres.trim()),
    ),
  );

  return {
    kod,
    ad: htmlCoz(ham?.ad).replace(/\s+/g, " ").trim(),
    marka: htmlCoz(ham?.marka).replace(/\s+/g, " ").trim(),
    aciklama: htmlCoz(ham?.aciklama).replace(/\s+/g, " ").trim().slice(0, EN_COK_ACIKLAMA),
    barkod: normalizeBarkod(ham?.barkod),
    gorseller: gorseller.slice(0, EN_COK_GORSEL),
    kaynak: String(kaynak ?? "").trim(),
  };
}

/** Listeyi normalize eder, aynı kodu iki kez yazmaz, koda göre sıralar. */
export function urunleriNormalle(hamlar, kaynak) {
  const harita = new Map();
  for (const ham of hamlar ?? []) {
    const urun = urunuNormalle(ham, kaynak);
    if (urun && !harita.has(urun.kod)) harita.set(urun.kod, urun);
  }
  return [...harita.values()].sort((a, b) => a.kod.localeCompare(b.kod, "tr"));
}

/** Bir katalog için sayı raporu. Ölçülmeyen şey rapor edilmez. */
export function ozet(urunler) {
  return {
    urun: urunler.length,
    barkodlu: urunler.filter((u) => u.barkod).length,
    adli: urunler.filter((u) => u.ad).length,
    aciklamali: urunler.filter((u) => u.aciklama).length,
    fotografli: urunler.filter((u) => u.gorseller.length > 0).length,
    fotograf: urunler.reduce((toplam, u) => toplam + u.gorseller.length, 0),
  };
}

/** Kataloğu tek standart dosyaya yazar. */
export async function katalogYaz(anahtar, urunler) {
  await mkdir(VERI_KLASORU, { recursive: true });
  const dosya = path.join(VERI_KLASORU, `uretici-katalog-${anahtar}.json`);
  await writeFile(dosya, `${JSON.stringify(urunler)}\n`, "utf8");
  return dosya;
}

/** firma listesini okur (firmalar.json). */
export async function firmalariOku() {
  const dosya = path.resolve(BURASI, "firmalar.json");
  const ham = await readFile(dosya, "utf8");
  return JSON.parse(ham);
}

/** Sonuç tablosunu ekrana basar. */
export function raporYazdir(satirlar) {
  const basliklar = ["firma", "platform", "durum", "urun", "kodsuz", "barkod", "foto"];
  const icerik = (anahtar) => satirlar.map((s) => String(s[anahtar] ?? ""));
  const genislik = basliklar.map((baslik, i) => {
    const anahtar = ["firma", "platform", "durum", "urun", "kodsuz", "barkod", "foto"][i];
    return Math.max(baslik.length, ...icerik(anahtar).map((d) => d.length), 4);
  });

  const bicimle = (hucreler) =>
    hucreler.map((hucre, i) => String(hucre ?? "").padEnd(genislik[i])).join("  ");

  const alanlar = ["firma", "platform", "durum", "urun", "kodsuz", "barkod", "foto"];
  console.log(bicimle(basliklar));
  console.log(genislik.map((w) => "-".repeat(w)).join("  "));
  for (const satir of satirlar) {
    console.log(bicimle(alanlar.map((alan) => satir[alan])));
  }
}
