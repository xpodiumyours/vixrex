import { NextResponse, type NextRequest } from "next/server";
import { normalizeProductMetadata, normalizeProductVariants } from "@/lib/productRichData";
import { supabase } from "@/lib/supabase";

export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  const storeSlug = request.nextUrl.searchParams.get("store")?.trim() ?? "";
  const productSlug = request.nextUrl.searchParams.get("product")?.trim() ?? "";
  if (!storeSlug || !productSlug) {
    return NextResponse.json({ hata: "Ürün bulunamadı." }, { status: 400 });
  }

  const { data: store } = await supabase
    .from("stores")
    .select("id")
    .eq("slug", storeSlug)
    .eq("is_published", true)
    .maybeSingle<{ id: string }>();
  if (!store?.id) {
    return NextResponse.json({ hata: "Ürün bulunamadı." }, { status: 404 });
  }

  const { data: product, error } = await supabase
    .from("products")
    .select("id,slug,brand,barcode,price_amount,stock_quantity,stock_status,vat_rate,metadata,variants")
    .eq("store_id", store.id)
    .eq("slug", productSlug)
    .eq("is_active", true)
    .eq("is_visible", true)
    .maybeSingle();

  if (error || !product) {
    return NextResponse.json({ hata: "Ürün bulunamadı." }, { status: 404 });
  }

  return NextResponse.json({
    id: product.id,
    slug: product.slug,
    brand: typeof product.brand === "string" ? product.brand : null,
    barcode: typeof product.barcode === "string" ? product.barcode : null,
    priceAmount: product.price_amount == null ? null : Number(product.price_amount),
    stockQuantity: product.stock_quantity == null ? null : Number(product.stock_quantity),
    stockStatus: typeof product.stock_status === "string" ? product.stock_status : null,
    vatRate: product.vat_rate == null ? null : Number(product.vat_rate),
    metadata: normalizeProductMetadata(product.metadata),
    variants: normalizeProductVariants(product.variants),
  });
}
