import { normalizeProductMetadata } from "@/lib/productRichData";
import { isLunaInvoiceProduct, isPublicCatalogProduct } from "@/lib/products";
import type { RichProductItem } from "@/lib/richProductItem";
import { sanitizePermissionText } from "@/lib/supplierPermissionRequest";

export interface ResmiMarkaRafGrubu<T extends RichProductItem = RichProductItem> {
  marka: string;
  markaAnahtari: string;
  resmiAlanAdi: string;
  urunler: T[];
  urunSayisi: number;
}

const YASAKLI_ARACI_ALANLAR = new Set([
  "trendyol.com",
  "hepsiburada.com",
  "n11.com",
  "amazon.com",
  "amazon.com.tr",
  "amazon.de",
  "ciceksepeti.com",
  "pttavm.com",
  "gittigidiyor.com",
  "morhipo.com",
  "pazarama.com",
  "idefix.com",
  "kitapyurdu.com",
  "dr.com.tr",
  "akakce.com",
  "cimri.com",
  "epey.com",
  "fiyat.com",
  "sahibinden.com",
  "letgo.com",
  "dolap.com",
  "gardrops.com",
  "zebramo.com",
  "ebay.com",
  "ebay.co.uk",
  "aliexpress.com",
  "alibaba.com",
  "temu.com",
  "shein.com",
  "etsy.com",
  "walmart.com",
  "dsmcdn.com",
  "hepsiburada.net",
  "n11cdn.com",
  "media-amazon.com",
  "ssl-images-amazon.com",
  "bit.ly",
  "tinyurl.com",
  "ty.gl",
  "amzn.to",
  "t.co",
  "goo.gl",
  "ow.ly",
  "facebook.com",
  "instagram.com",
  "youtube.com",
  "youtu.be",
  "tiktok.com",
  "x.com",
  "twitter.com",
  "pinterest.com",
  "linkedin.com",
  "wikipedia.org",
  "vikipedi.org",
  "sikayetvar.com",
  "eksisozluk.com",
  "openfoodfacts.org",
  "barcodelookup.com",
  "upcitemdb.com",
  "ean-search.org",
  "gtinsearch.org",
  "vertexaisearch.cloud.google.com",
]);

const DOGRULANMIS_DURUMLAR = new Set([
  "doğrulandı",
  "dogrulandi",
  "doğrulanmış",
  "dogrulanmis",
  "verified",
  "onaylandi",
  "onaylandı",
  "kanitli",
  "kanıtlı",
]);

function temizMarkaAdi(deger: unknown): string {
  if (typeof deger !== "string") return "";
  const onceki = deger
    .replace(/[\r\n\t\u0000-\u001F\u007F-\u009F\u2028\u2029]+/g, " ")
    .replace(/\bTR\d{2}(?:\s?[0-9A-Z]{4}){5}\s?[0-9A-Z]{2}\b/gi, "")
    .replace(/\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b/gi, "");
  return sanitizePermissionText(onceki)
    .replace(/^[\s,.;:\/\-–—]+|[\s,.;:\/\-–—]+$/g, "")
    .replace(/\s+/g, " ")
    .trim();
}

function resmiAlanAdiniDogrula(hamUrl: unknown): string | null {
  if (typeof hamUrl !== "string") return null;
  const temiz = hamUrl.trim();
  if (!temiz || /\s/.test(temiz)) return null;
  let url: URL;
  try {
    url = new URL(temiz);
  } catch {
    return null;
  }
  if (url.protocol !== "https:" || url.username || url.password) return null;
  const host = url.hostname.toLocaleLowerCase("tr-TR").replace(/^www\./, "").replace(/\.$/, "");
  if (!host || !host.includes(".") || host === "localhost" || host.endsWith(".local")) return null;
  if (/^\d{1,3}(?:\.\d{1,3}){3}$/.test(host) || host.includes(":")) return null;
  for (const yasakli of YASAKLI_ARACI_ALANLAR) {
    if (host === yasakli || host.endsWith(`.${yasakli}`)) return null;
  }
  return host;
}

function dogrulamaDurumuGecerliMi(status?: string): boolean {
  const etiket = String(status || "")
    .replace(/^[✓?✗⚠\s]+/, "")
    .trim()
    .toLocaleLowerCase("tr-TR");
  return DOGRULANMIS_DURUMLAR.has(etiket);
}

export function resmiMarkaRaflariniDerle<T extends RichProductItem>(
  products: readonly T[],
  secenekler?: { isOwner?: boolean },
): ResmiMarkaRafGrubu<T>[] {
  const isOwner = Boolean(secenekler?.isOwner);
  const gruplar = new Map<string, ResmiMarkaRafGrubu<T>>();

  for (const product of products) {
    if (!isOwner && !isPublicCatalogProduct(product)) continue;
    if (isOwner && !String(product.name || "").trim()) continue;

    const marka = temizMarkaAdi(product.brand);
    if (!marka) continue;

    const metadata = normalizeProductMetadata(product.metadata);
    if (metadata.itemKind === "service") continue;

    const resmiAlanAdi = resmiAlanAdiniDogrula(metadata.manufacturerSource?.url);
    if (!resmiAlanAdi) continue;

    const dogrulanmis =
      isLunaInvoiceProduct(product) ||
      dogrulamaDurumuGecerliMi(metadata.manufacturerSource?.verificationStatus);
    if (!dogrulanmis) continue;

    const markaAnahtari = marka.toLocaleLowerCase("tr-TR");
    const mevcut = gruplar.get(markaAnahtari);
    if (mevcut) {
      mevcut.urunler.push(product);
      mevcut.urunSayisi = mevcut.urunler.length;
    } else {
      gruplar.set(markaAnahtari, {
        marka,
        markaAnahtari,
        resmiAlanAdi,
        urunler: [product],
        urunSayisi: 1,
      });
    }
  }

  return Array.from(gruplar.values()).sort(
    (a, b) => b.urunSayisi - a.urunSayisi || a.marka.localeCompare(b.marka, "tr"),
  );
}
