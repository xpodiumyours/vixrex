import { isLunaInvoiceProduct } from "./products";
import type { RichProductItem } from "./richProductItem";

const TELIF_ANAHTARI = "_telif_onayi_bekliyor";

export interface ResmiMarkaRafiSonucu {
  resmiMarkaAdi: string | null;
  resmiUrunler: RichProductItem[];
  digerUrunler: RichProductItem[];
}

function telifBekliyorMu(product: RichProductItem): boolean {
  return Boolean((product as unknown as Record<string, unknown>)[TELIF_ANAHTARI]);
}

function urunMarkasiniAl(product: RichProductItem): string {
  const meta =
    product.metadata && typeof product.metadata === "object"
      ? (product.metadata as Record<string, unknown>)
      : null;
  const aday = typeof meta?.brand === "string" ? meta.brand : "";
  return aday.trim();
}

export function resmiMarkaRafiniAyir(
  products: readonly RichProductItem[],
): ResmiMarkaRafiSonucu {
  const markaSayaci = new Map<string, { ad: string; sayi: number }>();

  for (const product of products) {
    if (!isLunaInvoiceProduct(product)) continue;
    if (telifBekliyorMu(product)) continue;
    const marka = urunMarkasiniAl(product);
    if (!marka) continue;
    const anahtar = marka.toLocaleLowerCase("tr-TR");
    const mevcut = markaSayaci.get(anahtar);
    if (mevcut) {
      mevcut.sayi += 1;
    } else {
      markaSayaci.set(anahtar, { ad: marka, sayi: 1 });
    }
  }

  let baskinAnahtar: string | null = null;
  let baskinAd: string | null = null;
  let enYuksek = 0;

  for (const [anahtar, veri] of markaSayaci.entries()) {
    if (veri.sayi > enYuksek) {
      enYuksek = veri.sayi;
      baskinAnahtar = anahtar;
      baskinAd = veri.ad;
    }
  }

  if (!baskinAnahtar || !baskinAd) {
    return {
      resmiMarkaAdi: null,
      resmiUrunler: [],
      digerUrunler: [...products],
    };
  }

  const resmiUrunler: RichProductItem[] = [];
  const digerUrunler: RichProductItem[] = [];

  for (const product of products) {
    const marka = urunMarkasiniAl(product).toLocaleLowerCase("tr-TR");
    if (
      isLunaInvoiceProduct(product) &&
      !telifBekliyorMu(product) &&
      marka === baskinAnahtar
    ) {
      resmiUrunler.push(product);
    } else {
      digerUrunler.push(product);
    }
  }

  return {
    resmiMarkaAdi: baskinAd,
    resmiUrunler,
    digerUrunler,
  };
}
