/**
 * Site haritası + sayfa içi yapılandırılmış veri okuyucusu.
 *
 * Standart bir ürün adresi yayınlamayan platformlar için tek genel yol:
 *   1. Site haritasını (sitemap) oku, ürün sayfalarının adreslerini topla
 *   2. Her ürün sayfasını oku
 *   3. Sayfadaki yapılandırılmış ürün verisini (JSON-LD `Product`) al;
 *      yoksa microdata (itemprop) alanlarını oku
 *
 * Ölçülen gerçek (26.09.2026):
 *   - Ticimax (erdemicgiyim.com)  → JSON-LD Product var
 *   - İkas   (kinzitoptan.com)   → JSON-LD Product var
 *   - T-Soft (berrakicgiyim.com.tr, /xml/sitemap/product.xml) → JSON-LD var
 *   - İdeasoft (kozaicgiyim.com) → JSON-LD yok, microdata itemprop var
 *
 * Bu okuyucu OTOMATİK ÇALIŞMAZ: her ürün için ayrı sayfa okur, yani diğer
 * okuyuculardan çok daha yavaştır. Yalnız açıkça istendiğinde çalıştırılır:
 *   node scripts/katalog/tara.mjs --platform=jsonld --firma=<anahtar>
 *
 * Kural: kodu olmayan ürün kataloğa alınmaz.
 */

import { duzMetin, istek, jsonIstek } from "../_ortak.mjs";

export const AD = "jsonld";
/** Otomatik platform taramasında denenmez. */
export const otomatik = false;

/** Bir firmada en çok kaç ürün sayfası okunur (güvenlik sınırı). */
const VARSAYILAN_SINIR = 250;
/** Site haritası zincirinde en çok kaç alt harita izlenir. */
const EN_COK_ALT_HARITA = 40;

const locAdresleri = (xml) =>
  [...String(xml ?? "").matchAll(/<loc>\s*([^<\s]+)\s*<\/loc>/gi)].map((eslesme) => eslesme[1]);

function sayfaHaritasiMi(xml) {
  return /<sitemapindex/i.test(String(xml ?? ""));
}

/**
 * Ürün sayfalarının adreslerini toplar.
 * Ürün sayfası haritası varsa (ör. /xml/sitemap/product.xml) yalnız o izlenir.
 */
async function urunAdresleri(site) {
  const kok = await istek(`https://${site}/sitemap.xml`).catch(() => null);
  if (!kok || kok.durum !== 200) return [];

  const birinci = locAdresleri(kok.govde);
  if (!sayfaHaritasiMi(kok.govde)) return birinci;

  // Ürün sayfalarına işaret eden alt haritalar önce gelir.
  const sirali = [...birinci].sort((a, b) => {
    const puan = (adres) => (/product|urun/i.test(adres) && !/image|resim|brand|marka|category|kategori|page|sayfa/i.test(adres) ? -1 : 0);
    return puan(a) - puan(b);
  });

  const adresler = [];
  for (const alt of sirali.slice(0, EN_COK_ALT_HARITA)) {
    if (/image|resim/i.test(alt)) continue;
    const yanit = await istek(alt).catch(() => null);
    if (yanit && yanit.durum === 200) adresler.push(...locAdresleri(yanit.govde));
    if (adresler.length > 0 && /product|urun/i.test(alt)) break;
  }

  return adresler;
}

/** JSON-LD blokları içinde `@type: Product` olan kaydı bulur. */
function jsonldUrunu(html) {
  const bloklar = [
    ...String(html ?? "").matchAll(/<script[^>]+application\/ld\+json[^>]*>([\s\S]*?)<\/script>/gi),
  ];

  for (const blok of bloklar) {
    let veri;
    try {
      veri = JSON.parse(blok[1]);
    } catch {
      continue;
    }

    const liste = Array.isArray(veri) ? veri : (veri?.["@graph"] ?? [veri]);
    for (const kayit of liste) {
      const turler = [].concat(kayit?.["@type"] ?? []).map((tur) => String(tur).toLowerCase());
      if (turler.includes("product")) return kayit;
    }
  }

  return null;
}

function jsonldGorselleri(kayit, site) {
  const ham = kayit?.image;
  const liste = Array.isArray(ham) ? ham : ham ? [ham] : [];

  const adresler = liste
    .map((gorsel) => (typeof gorsel === "string" ? gorsel : gorsel?.url))
    .filter((adres) => typeof adres === "string" && adres.trim() !== "")
    .map((adres) => {
      const temiz = adres.trim();
      if (temiz.startsWith("//")) return `https:${temiz}`;
      if (temiz.startsWith("/")) return `https://${site}${temiz}`;
      return temiz;
    })
    .filter((adres) => /^https?:\/\//i.test(adres));

  return [...new Set(adresler)];
}

/** Microdata: itemprop="ad" taşıyan etiketin değerini okur. */
function ozellikDegeri(html, ad) {
  const meta = new RegExp(`<meta[^>]*itemprop=["']${ad}["'][^>]*content=["']([^"']*)["'][^>]*>`, "i");
  const metaEslesme = String(html).match(meta);
  if (metaEslesme) return duzMetin(metaEslesme[1]);

  const etiket = new RegExp(`<[^>]*itemprop=["']${ad}["'][^>]*>([\\s\\S]{0,400}?)<`, "i");
  const etiketEslesme = String(html).match(etiket);
  return etiketEslesme ? duzMetin(etiketEslesme[1]) : "";
}

/** Microdata: itemprop="image" taşıyan tüm adresleri okur. */
function ozellikGorselleri(html) {
  const adresler = [];
  const duzenli = /<[^>]*itemprop=["']image["'][^>]*>/gi;
  for (const etiket of String(html).matchAll(duzenli)) {
    const icerik = etiket[0].match(/content=["']([^"']+)["']/i) ?? etiket[0].match(/src=["']([^"']+)["']/i);
    if (icerik && /^https?:\/\//i.test(icerik[1])) adresler.push(icerik[1]);
  }
  return [...new Set(adresler)];
}

/** Sayfadan ürün bilgisini çıkarır: önce JSON-LD, sonra microdata. */
function sayfadanUrun(html, site, adres) {
  const kayit = jsonldUrunu(html);

  if (kayit) {
    const marka =
      typeof kayit.brand === "string" ? kayit.brand : (kayit.brand?.name ?? "");
    return {
      kod: String(kayit.sku ?? kayit.mpn ?? "").trim(),
      ad: String(kayit.name ?? "").trim(),
      marka: String(marka).trim(),
      aciklama: duzMetin(kayit.description ?? ""),
      barkod: String(kayit.gtin13 ?? kayit.gtin ?? kayit.gtin12 ?? kayit.sku ?? "").trim(),
      gorseller: jsonldGorselleri(kayit, site),
      kaynak: adres,
    };
  }

  const kod = ozellikDegeri(html, "sku") || ozellikDegeri(html, "productID");
  if (!kod) return null;

  return {
    kod,
    ad: ozellikDegeri(html, "name"),
    marka: ozellikDegeri(html, "brand"),
    aciklama: ozellikDegeri(html, "description"),
    barkod: ozellikDegeri(html, "gtin13") || kod,
    gorseller: ozellikGorselleri(html),
    kaynak: adres,
  };
}

export async function tespitEt() {
  // Otomatik taranmaz; yalnız açıkça istendiğinde çalışır.
  return false;
}

export async function cek(site, { sinir = VARSAYILAN_SINIR, ilerleme } = {}) {
  const adresler = await urunAdresleri(site);
  const urunler = [];
  let kodsuz = 0;
  let okunan = 0;

  for (const adres of adresler) {
    if (okunan >= sinir) break;
    okunan++;

    const yanit = await istek(adres).catch(() => null);
    if (!yanit || yanit.durum !== 200) {
      kodsuz++;
      continue;
    }

    const urun = sayfadanUrun(yanit.govde, site, adres);
    if (!urun) {
      kodsuz++;
      continue;
    }

    if (String(urun.kod).trim()) urunler.push(urun);
    else kodsuz++;

    if (ilerleme && okunan % 25 === 0) ilerleme(okunan, urunler.length);
  }

  // Sınıra takıldıysa bu katalog EKSİKTİR. Sessiz kalmak yanlış olur:
  // "hepsi bu kadar" sanılır.
  return { urunler, kodsuz, sayfa: okunan, kesildi: adresler.length > okunan };
}
