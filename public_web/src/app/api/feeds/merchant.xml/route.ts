import { NextResponse } from "next/server";
import { supabase } from "@/lib/supabase";
import { gorselIzinBekliyorMu } from "@/lib/faturaGorselHakDenetimi";
import { MAX_PRODUCT_IMAGES } from "@/lib/productImagePolicy";
import { getProductImages, isLikelyUiScreenshotUrl } from "@/lib/products";
import { normalizeProductMetadata } from "@/lib/productRichData";
import {
  normalizeGoogleGtin,
  productIsInStock,
} from "@/lib/productStructuredData";
import { buildSiteUrl, getSiteUrl } from "@/lib/siteUrl";
import { isTestOrDenemeStore } from "@/lib/testStoreFilter";

export const revalidate = 3600;

const PAGE_SIZE = 1000;

const PRODUCT_SELECT_WITH_GPC =
  "id,store_id,name,slug,description,price_amount,currency,stock_status,stock_quantity,brand,barcode,image_urls,google_product_category,is_active,is_visible,source_type,fatura_kanit,metadata";

const PRODUCT_SELECT_FALLBACK =
  "id,store_id,name,slug,description,price_amount,currency,stock_status,stock_quantity,brand,barcode,image_urls,is_active,is_visible,source_type,fatura_kanit,metadata";

type StoreRow = {
  id: string;
  slug: string;
  name: string;
  description: string | null;
  is_demo: boolean | null;
  is_published?: boolean;
};

type ProductRow = {
  id: string;
  store_id: string;
  name: string;
  slug: string;
  description: string | null;
  price_amount: number | string | null;
  currency: string | null;
  stock_status: string | null;
  stock_quantity: number | null;
  brand: string | null;
  barcode: string | null;
  image_urls: unknown;
  google_product_category?: string | null;
  is_active?: boolean;
  is_visible?: boolean;
  source_type: string | null;
  fatura_kanit: unknown;
  metadata?: unknown;
};

type PostgrestErrorLike = {
  code?: string;
  message?: string;
} | null;

type PostgrestResultLike<T> = {
  data: T[] | null;
  error: PostgrestErrorLike;
};

type RangeCapableQuery<T> = PromiseLike<PostgrestResultLike<T>> & {
  range?: (from: number, to: number) => PromiseLike<PostgrestResultLike<T>>;
};

function xmlEscape(value: unknown): string {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}

function eksikGoogleKategoriSutunuHatasiMi(error: PostgrestErrorLike): boolean {
  if (!error) return false;
  if (error.code === "42703") return true;
  return String(error.message || "").includes("google_product_category");
}

function gecerliMerchantGorseliMi(url: string): boolean {
  if (!url.startsWith("https://")) return false;
  if (isLikelyUiScreenshotUrl(url)) return false;
  if (url.toLowerCase().includes("/images/vixrex_v_crystal_mascot.webp")) {
    return false;
  }
  try {
    const parsed = new URL(url);
    return parsed.protocol === "https:" && Boolean(parsed.hostname);
  } catch {
    return false;
  }
}

async function sayfaliSorgula<T>(
  sorguUret: () => RangeCapableQuery<T>,
): Promise<PostgrestResultLike<T>> {
  const ilkSorgu = sorguUret();
  if (typeof ilkSorgu.range !== "function") {
    const sonuc = await ilkSorgu;
    return { data: sonuc.data ?? [], error: sonuc.error ?? null };
  }

  const tumSatirlar: T[] = [];
  let baslangic = 0;
  while (true) {
    const sorgu = baslangic === 0 ? ilkSorgu : sorguUret();
    const sonuc = await sorgu.range!(baslangic, baslangic + PAGE_SIZE - 1);
    if (sonuc.error) {
      return { data: null, error: sonuc.error };
    }
    const sayfa = Array.isArray(sonuc.data) ? sonuc.data : [];
    tumSatirlar.push(...sayfa);
    if (sayfa.length < PAGE_SIZE) {
      break;
    }
    baslangic += PAGE_SIZE;
  }

  return { data: tumSatirlar, error: null };
}

function merchantItemXmlUret(p: ProductRow, store: StoreRow): string | null {
  if (p.is_active === false || p.is_visible === false) return null;

  const id = String(p.id || "").trim();
  const name = String(p.name || "").trim();
  const slug = String(p.slug || "").trim();
  if (!id || !name || !slug) return null;

  const metadata = normalizeProductMetadata(p.metadata);
  if (metadata.itemKind === "service") return null;

  const izinDurumu = gorselIzinBekliyorMu(p.fatura_kanit);
  const telifEngelli =
    izinDurumu === true ||
    (p.source_type === "invoice" && izinDurumu !== false);
  if (telifEngelli) return null;

  if (
    p.price_amount == null ||
    (typeof p.price_amount === "string" && p.price_amount.trim() === "")
  ) {
    return null;
  }
  const tutar = Number(p.price_amount);
  if (!Number.isFinite(tutar) || tutar <= 0) return null;

  const gecerliGorseller = getProductImages({
    name,
    imageUrls: Array.isArray(p.image_urls)
      ? p.image_urls.filter((u): u is string => typeof u === "string")
      : [],
    source: p.source_type || undefined,
    metadata: p.metadata,
  })
    .filter(gecerliMerchantGorseliMi)
    .slice(0, MAX_PRODUCT_IMAGES);

  if (gecerliGorseller.length === 0) return null;

  const anaGorsel = gecerliGorseller[0];
  const ekGorseller = gecerliGorseller.slice(1);
  const rawCurrency = String(p.currency || "").trim();
  const currency = /^[A-Z]{3}$/.test(rawCurrency) ? rawCurrency : "TRY";
  const price = `${tutar.toFixed(2)} ${currency}`;

  const normStockStatus =
    typeof p.stock_status === "string"
      ? p.stock_status.replaceAll("_", " ")
      : p.stock_status;
  const avail =
    productIsInStock(normStockStatus, p.stock_quantity) &&
    productIsInStock(normStockStatus, null)
      ? "in_stock"
      : "out_of_stock";

  const gtin = normalizeGoogleGtin(p.barcode);
  const explicitBrand = String(p.brand || "").trim();
  const mpn = metadata.identifiers?.mpn?.trim() || "";

  const hamCondition = metadata.attributes?.find(
    (attr) => attr.key === "condition",
  )?.value;
  const conditionDegeri =
    typeof hamCondition === "string" ? hamCondition.trim().toLowerCase() : "";
  const condition =
    conditionDegeri === "used" || conditionDegeri === "refurbished"
      ? conditionDegeri
      : "new";

  const link = buildSiteUrl(`/v/${store.slug}/urun/${slug}`);
  const description = (p.description && p.description.trim()) || name;
  const gpc = String(p.google_product_category || "").trim();

  const satirlar: string[] = [
    `      <g:id>${xmlEscape(id)}</g:id>`,
    `      <title>${xmlEscape(name)}</title>`,
    `      <description>${xmlEscape(description)}</description>`,
    `      <link>${xmlEscape(link)}</link>`,
    `      <g:image_link>${xmlEscape(anaGorsel)}</g:image_link>`,
    ...ekGorseller.map(
      (ekUrl) =>
        `      <g:additional_image_link>${xmlEscape(ekUrl)}</g:additional_image_link>`,
    ),
    `      <g:availability>${avail}</g:availability>`,
    `      <g:price>${xmlEscape(price)}</g:price>`,
  ];

  if (gtin) {
    satirlar.push(
      `      <g:brand>${xmlEscape(explicitBrand || store.name)}</g:brand>`,
    );
    satirlar.push(`      <g:gtin>${xmlEscape(gtin)}</g:gtin>`);
  } else if (explicitBrand && mpn) {
    satirlar.push(`      <g:brand>${xmlEscape(explicitBrand)}</g:brand>`);
    satirlar.push(`      <g:mpn>${xmlEscape(mpn)}</g:mpn>`);
  } else {
    if (explicitBrand) {
      satirlar.push(`      <g:brand>${xmlEscape(explicitBrand)}</g:brand>`);
    }
    satirlar.push("      <g:identifier_exists>no</g:identifier_exists>");
  }

  satirlar.push(`      <g:condition>${condition}</g:condition>`);
  if (gpc) {
    satirlar.push(
      `      <g:google_product_category>${xmlEscape(gpc)}</g:google_product_category>`,
    );
  }

  return `    <item>\n${satirlar.join("\n")}\n    </item>`;
}

export async function GET() {
  try {
    const siteUrl = getSiteUrl();

    const storeSonuc = await sayfaliSorgula<StoreRow>(() => {
      const q = supabase
        .from("stores")
        .select("id,slug,name,description,is_demo,is_published")
        .eq("is_published", true)
        .eq("is_demo", false);
      return (
        typeof (q as { order?: unknown }).order === "function"
          ? (
              q as {
                order: (col: string, opts: { ascending: boolean }) => unknown;
              }
            ).order("id", { ascending: true })
          : q
      ) as RangeCapableQuery<StoreRow>;
    });

    if (storeSonuc.error) {
      return new NextResponse("Feed generation failed", { status: 500 });
    }

    const yayinliStores = (storeSonuc.data || []).filter(
      (s) => s.is_published !== false && !s.is_demo && !isTestOrDenemeStore(s),
    );

    const storeIds = yayinliStores.map((s) => s.id);
    const storeById = new Map(yayinliStores.map((s) => [s.id, s]));

    let products: ProductRow[] = [];
    if (storeIds.length > 0) {
      const urunSorgusuKur = (selectCols: string) => () => {
        const q = supabase
          .from("products")
          .select(selectCols)
          .in("store_id", storeIds)
          .eq("is_active", true)
          .eq("is_visible", true);
        return (
          typeof (q as { order?: unknown }).order === "function"
            ? (
                q as {
                  order: (col: string, opts: { ascending: boolean }) => unknown;
                }
              ).order("id", { ascending: true })
            : q
        ) as RangeCapableQuery<ProductRow>;
      };

      let prodSonuc = await sayfaliSorgula<ProductRow>(
        urunSorgusuKur(PRODUCT_SELECT_WITH_GPC),
      );
      if (prodSonuc.error && eksikGoogleKategoriSutunuHatasiMi(prodSonuc.error)) {
        prodSonuc = await sayfaliSorgula<ProductRow>(
          urunSorgusuKur(PRODUCT_SELECT_FALLBACK),
        );
      }
      if (prodSonuc.error) {
        return new NextResponse("Feed generation failed", { status: 500 });
      }
      products = prodSonuc.data ?? [];
    }

    const itemsXml = products
      .map((p) => {
        const store = storeById.get(p.store_id);
        if (!store) return null;
        return merchantItemXmlUret(p, store);
      })
      .filter((satir): satir is string => Boolean(satir))
      .join("\n");

    const xml = `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:g="http://base.google.com/ns/1.0">
  <channel>
    <title>Vixrex Merchant Feed</title>
    <link>${xmlEscape(siteUrl)}</link>
    <description>Vixrex vitrinlerindeki aktif ürünler</description>${itemsXml ? `\n${itemsXml}` : ""}
  </channel>
</rss>`;

    return new NextResponse(xml, {
      status: 200,
      headers: {
        "Content-Type": "application/xml; charset=utf-8",
        "Cache-Control": "public, s-maxage=3600, stale-while-revalidate=86400",
      },
    });
  } catch {
    return new NextResponse("Feed generation failed", { status: 500 });
  }
}
