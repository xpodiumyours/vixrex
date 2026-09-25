/**
 * WooCommerce okuyucusu.
 *
 * WooCommerce ile kurulmuş siteler ürün listesini herkese açık standart bir
 * adresten yayınlar. Bu okuyucu o adresi sayfa sayfa okur.
 *
 * Ölçülen gerçek (26.09.2026): denenen 16 siteden 9'u bu adresi açtı.
 *
 * Kural: ürün kodu (sku) olmayan ürün kataloğa alınmaz. Kodsuz ürün faturayla
 * eşleşemez; sayısı raporda "kodsuz" olarak açıkça gösterilir.
 */

import { duzMetin, jsonIstek } from "../_ortak.mjs";

export const AD = "woocommerce";

const YOL = "/wp-json/wc/store/v1/products";
const SAYFA_BOYU = 100;
/** Güvenlik: bozuk bir uç nokta yüzünden sonsuza gitmeyelim. */
const EN_COK_SAYFA = 500;

/** Bu site bu okuyucuyla okunabiliyor mu? Uç noktayı tek ürünle yoklar. */
export async function tespitEt(site) {
  try {
    const { durum, veri } = await jsonIstek(`https://${site}${YOL}?per_page=1&page=1`);
    return durum === 200 && Array.isArray(veri);
  } catch {
    return false;
  }
}

/**
 * Yalnız gerçek marka bilgisi alınır. Kategori adı marka yerine yazılmaz:
 * kategori "marka" diye gösterilirse ürün kartında yanlış bilgi olur.
 */
function markaBul(ham) {
  const markalar = ham?.brands;
  if (!Array.isArray(markalar) || markalar.length === 0) return "";
  return markalar.map((marka) => marka?.name).filter(Boolean).join(", ");
}

/** Ham WooCommerce ürününü standart biçime çevirir. */
function cevir(ham, site) {
  const gorseller = (Array.isArray(ham?.images) ? ham.images : [])
    .map((gorsel) => gorsel?.src)
    .filter(Boolean);

  return {
    kod: ham?.sku ?? "",
    ad: ham?.name ?? "",
    marka: markaBul(ham),
    aciklama: duzMetin(ham?.short_description || ham?.description || ""),
    barkod: ham?.sku ?? "",
    gorseller,
    kaynak: ham?.permalink || `https://${site}`,
  };
}

/**
 * Sitenin tüm ürünlerini okur.
 * Dönen: { urunler: kodlu ürünler, kodsuz: kodu olmayan ürün sayısı, sayfa }
 */
export async function cek(site) {
  const urunler = [];
  let kodsuz = 0;
  let sayfa = 0;

  for (let s = 1; s <= EN_COK_SAYFA; s++) {
    const adres = `https://${site}${YOL}?per_page=${SAYFA_BOYU}&page=${s}`;
    const { durum, veri } = await jsonIstek(adres);
    if (durum !== 200 || !Array.isArray(veri) || veri.length === 0) break;

    sayfa = s;
    for (const ham of veri) {
      const urun = cevir(ham, site);
      if (String(urun.kod).trim()) urunler.push(urun);
      else kodsuz++;
    }

    if (veri.length < SAYFA_BOYU) break;
  }

  return { urunler, kodsuz, sayfa };
}
