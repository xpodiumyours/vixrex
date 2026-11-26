import { NextResponse } from "next/server";
import { supabase } from "@/lib/supabase";
import { gorselIzinBekliyorMu } from "@/lib/faturaGorselHakDenetimi";
import { getSiteUrl, buildSiteUrl } from "@/lib/siteUrl";

export const revalidate = 3600;

type StoreRow = {
  id: string;
  slug: string;
  name: string;
  description: string | null;
  is_demo: boolean | null;
  is_published: boolean;
  google_store_code: string | null;
  google_place_id: string | null;
};

type ProductRow = {
  id: string;
  store_id: string;
  name: string;
  slug: string;
  description: string | null;
  price_amount: number | null;
  currency: string | null;
  stock_status: string | null;
  stock_quantity: number | null;
  brand: string | null;
  barcode: string | null;
  image_urls: unknown;
  google_product_category: string | null;
  is_active: boolean;
  is_visible: boolean;
  source_type: string | null;
  fatura_kanit: unknown;
};

function xmlEscape(value: unknown): string {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}

function gs1Gtin(barcode: string | null): string | null {
  const temiz = String(barcode || "").trim().replace(/\s+/g, "");
  if (!temiz) return null;
  // GS1 geçerli GTIN: 8/12/13/14 haneli sayısal.
  if (!/^\d{8}$|^\d{12}$|^\d{13}$|^\d{14}$/.test(temiz)) return null;
  return temiz;
}

function availability(stockStatus: string | null, qty: number | null): string {
  const durum = String(stockStatus || "").toLowerCase();
  if (durum === "out_of_stock" || durum === "out of stock") return "out_of_stock";
  if (typeof qty === "number" && qty <= 0) return "out_of_stock";
  return "in_stock";
}

export async function GET() {
  const siteUrl = getSiteUrl();

  const { data: stores, error: storeError } = await supabase
    .from("stores")
    .select("id,slug,name,description,is_demo,is_published,google_store_code,google_place_id")
    .eq("is_published", true);

  if (storeError) {
    return new NextResponse("<!-- feed error -->", { status: 500 });
  }

  const yayinliStores = (stores || []).filter(
    (s: StoreRow) => !s.is_demo,
  ) as StoreRow[];

  const storeIds = yayinliStores.map((s) => s.id);
  const storeById = new Map(yayinliStores.map((s) => [s.id, s]));

  let products: ProductRow[] = [];
  if (storeIds.length > 0) {
    const { data: prods, error: prodError } = await supabase
      .from("products")
      .select(
        "id,store_id,name,slug,description,price_amount,currency,stock_status,stock_quantity,brand,barcode,image_urls,google_product_category,is_active,is_visible,source_type,fatura_kanit",
      )
      .in("store_id", storeIds)
      .eq("is_active", true)
      .eq("is_visible", true);

    if (!prodError && Array.isArray(prods)) {
      products = prods as ProductRow[];
    }
  }

  // Görsel onayı tamamlanmamış (fatura kaynaklı, hak bekleyen) ürünleri eler.
  const onayliUrunler = products.filter((p) => {
    if (p.source_type !== "invoice") return true;
    const bekliyor = gorselIzinBekliyorMu(p.fatura_kanit);
    return bekliyor !== true;
  });

  const itemsXml = onayliUrunler
    .map((p) => {
      const store = storeById.get(p.store_id);
      if (!store) return "";
      const imageLink =
        Array.isArray(p.image_urls) && p.image_urls.length > 0
          ? String(p.image_urls[0])
          : "";
      const link = buildSiteUrl(`/v/${store.slug}/urun/${p.slug}`);
      const price =
        p.price_amount != null
          ? `${Number(p.price_amount).toFixed(2)} ${p.currency || "TRY"}`
          : "";
      const gtin = gs1Gtin(p.barcode);
      const avail = availability(p.stock_status, p.stock_quantity);
      const brand = p.brand || store.name;
      const gpc = p.google_product_category || "";

      return `    <item>
      <g:id>${xmlEscape(p.id)}</g:id>
      <title>${xmlEscape(p.name)}</title>
      <description>${xmlEscape(p.description || p.name)}</description>
      <link>${xmlEscape(link)}</link>
      ${imageLink ? `<g:image_link>${xmlEscape(imageLink)}</g:image_link>` : ""}
      <g:availability>${avail}</g:availability>
      ${price ? `<g:price>${xmlEscape(price)}</g:price>` : ""}
      <g:brand>${xmlEscape(brand)}</g:brand>
      ${gtin ? `<g:gtin>${xmlEscape(gtin)}</g:gtin>` : ""}
      <g:condition>new</g:condition>
      ${gpc ? `<g:google_product_category>${xmlEscape(gpc)}</g:google_product_category>` : ""}
    </item>`;
    })
    .filter(Boolean)
    .join("\n");

  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:g="http://base.google.com/ns/1.0">
  <channel>
    <title>Vixrex Merchant Feed</title>
    <link>${xmlEscape(siteUrl)}</link>
    <description>Vixrex vitrinlerindeki aktif ürünler</description>
${itemsXml}
  </channel>
</rss>`;

  return new NextResponse(xml, {
    status: 200,
    headers: {
      "Content-Type": "application/xml; charset=utf-8",
      "Cache-Control": "public, s-maxage=3600, stale-while-revalidate=86400",
    },
  });
}
