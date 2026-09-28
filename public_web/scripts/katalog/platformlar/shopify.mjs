/**
 * Shopify okuyucusu.
 *
 * Shopify ile kurulmuş siteler ürün listesini herkese açık standart bir
 * adresten yayınlar. Ölçülen gerçek (26.09.2026): denenen 3 siteden
 * istecanta.com ve goldfreshmutfak.com bu adresi açtı.
 *
 * Önemli: Shopify'da ürün kodu ve barkod ÜRÜN BAŞINA DEĞİL, VARYANT BAŞINA
 * tutulur (beden/renk her varyanttır). Bu yüzden her varyant ayrı bir ürün
 * satırı olarak yazılır; faturada gelen kod varyanta karşılık gelir.
 */

import { duzMetin, jsonIstek } from "../_ortak.mjs";

export const AD = "shopify";

const SAYFA_BOYU = 250;
const EN_COK_SAYFA = 200;

/** Bu site bu okuyucuyla okunabiliyor mu? Standart uç noktayı yoklar. */
export async function tespitEt(site) {
  try {
    const { durum, veri } = await jsonIstek(`https://${site}/products.json?limit=1`);
    return durum === 200 && Boolean(veri && Array.isArray(veri.products));
  } catch {
    return false;
  }
}

function gorselleriAl(ham) {
  return (Array.isArray(ham?.images) ? ham.images : [])
    .map((gorsel) => (typeof gorsel === "string" ? gorsel : gorsel?.src))
    .filter(Boolean);
}

/**
 * Bir Shopify ürününü varyantlarına açar. Kodu olmayan varyant üretilmez;
 * sayısı `kodsuz` olarak bildirilir.
 */
function cevir(ham, site) {
  const urunler = [];
  let kodsuz = 0;

  const ad = ham?.title ?? "";
  const marka = ham?.vendor ?? "";
  const aciklama = duzMetin(ham?.body_html ?? "");
  const gorseller = gorselleriAl(ham);
  const kaynak = ham?.handle ? `https://${site}/products/${ham.handle}` : `https://${site}`;
  const varyantlar = Array.isArray(ham?.variants) ? ham.variants : [];

  if (varyantlar.length === 0) {
    if (String(ham?.sku ?? "").trim()) {
      urunler.push({ kod: ham.sku, ad, marka, aciklama, barkod: ham.sku, gorseller, kaynak });
    } else {
      kodsuz++;
    }
    return { urunler, kodsuz };
  }

  for (const varyant of varyantlar) {
    const kod = String(varyant?.sku ?? "").trim();
    if (!kod) {
      kodsuz++;
      continue;
    }

    // Barkod alanı doluysa o kullanılır; değilse kodun kendisi denenir.
    // normalizeBarkod zaten yalnız 8-14 haneli sayıyı barkod kabul eder,
    // bu yüzden kod buraya serbestçe verilebilir.
    urunler.push({
      kod,
      ad: varyant?.title && varyant.title !== "Default Title" ? `${ad} — ${varyant.title}` : ad,
      marka,
      aciklama,
      barkod: String(varyant?.barcode ?? "").trim() || kod,
      gorseller,
      kaynak,
    });
  }

  return { urunler, kodsuz };
}

/** Sitenin tüm ürünlerini okur. */
export async function cek(site) {
  const urunler = [];
  let kodsuz = 0;
  let sayfa = 0;

  for (let s = 1; s <= EN_COK_SAYFA; s++) {
    const adres = `https://${site}/products.json?limit=${SAYFA_BOYU}&page=${s}`;
    const { durum, veri } = await jsonIstek(adres);
    const liste = veri?.products;
    if (durum !== 200 || !Array.isArray(liste) || liste.length === 0) break;

    sayfa = s;
    for (const ham of liste) {
      const sonuc = cevir(ham, site);
      urunler.push(...sonuc.urunler);
      kodsuz += sonuc.kodsuz;
    }

    if (liste.length < SAYFA_BOYU) break;
  }

  return { urunler, kodsuz, sayfa };
}
