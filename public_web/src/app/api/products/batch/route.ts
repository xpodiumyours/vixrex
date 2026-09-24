import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { createRichCoreProduct } from "@/lib/productCoreServer";
import { urunGirdisiniHazirla } from "@/lib/productIntake";

/**
 * Toplu ürün oluşturma API'si.
 *
 * POST: Birden fazla ürünü tek seferde oluşturur.
 *
 */

export const dynamic = "force-dynamic";

interface ProductBatchItem {
  name?: string;
  description?: string;
  price_text?: string;
  priceText?: string;
  category_id?: string;
  categoryId?: string;
  image_urls?: string[];
  imageUrls?: string[];
  source_type?: string;
  sourceType?: string;
  sort_order?: number;
  sortOrder?: number;
  isVisible?: boolean;
  brand?: unknown;
  barcode?: unknown;
  stockQuantity?: unknown;
  stockStatus?: unknown;
  metadata?: unknown;
  variants?: unknown;
  externalProductId?: string;
}

interface SatirSonucu {
  sira: number;
  ad: string;
  durum: "yayinda" | "taslak" | "atlandi";
  sebep?: string;
  id?: string;
}

export async function POST(request: NextRequest) {
  let govde: { slug?: unknown; products?: unknown };
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  if (!slug) {
    return NextResponse.json({ hata: "Vitrin belirtilmedi." }, { status: 422 });
  }

  if (!Array.isArray(govde.products) || govde.products.length === 0) {
    return NextResponse.json({ hata: "En az bir ürün belirtilmeli." }, { status: 422 });
  }

  if (govde.products.length > 100) {
    return NextResponse.json({ hata: "Tek seferde en fazla 100 ürün yüklenebilir." }, { status: 422 });
  }

  const cookieStore = await cookies();
  const ownerSessionCookie = cookieStore.get(OWNER_SESSION_COOKIE)?.value;
  const ownerSession = verifyOwnerSession(ownerSessionCookie, slug);
  if (!ownerSession) {
    return NextResponse.json(
      { hata: "Oturumun geçersiz veya süresi dolmuş." },
      { status: 401 }
    );
  }

  const admin = getSupabaseAdmin();

  const { data: store } = await admin
    .from("stores")
    .select("id, edit_token, name")
    .eq("id", ownerSession.storeId)
    .single();

  if (!store?.edit_token) {
    return NextResponse.json({ hata: "Vitrin bulunamadı." }, { status: 404 });
  }

  const sonuclar: SatirSonucu[] = [];
  let yayinda = 0;
  let taslak = 0;
  let atlandi = 0;

  for (const [index, ham] of (govde.products as ProductBatchItem[]).entries()) {
    const ad = (ham.name || "").trim();
    const satirGovdesi: Record<string, unknown> = {
      name: ad,
      description: ham.description ?? "",
      priceText: ham.priceText ?? ham.price_text ?? "",
      categoryId: ham.categoryId ?? ham.category_id ?? "",
      imageUrls: ham.imageUrls ?? ham.image_urls ?? [],
      brand: ham.brand,
      barcode: ham.barcode,
      stockQuantity: ham.stockQuantity,
      stockStatus: ham.stockStatus,
      metadata: ham.metadata,
      variants: ham.variants,
    };

    const hazirlik = await urunGirdisiniHazirla({
      admin,
      storeId: store.id,
      storeName: store.name,
      govde: satirGovdesi,
      gorselPolitikasi: "toplu",
    });

    if (hazirlik.durum === "reddedildi") {
      atlandi += 1;
      sonuclar.push({ sira: index, ad, durum: "atlandi", sebep: hazirlik.sebep });
      continue;
    }

    const gorunur = hazirlik.durum === "hazir" && ham.isVisible !== false;

    try {
      const olusan = await createRichCoreProduct({
        admin,
        storeId: store.id,
        editToken: store.edit_token,
        name: hazirlik.girdi.name,
        description: hazirlik.girdi.description,
        priceText: hazirlik.girdi.priceText,
        priceAmount: hazirlik.girdi.priceAmount,
        imageUrls: hazirlik.girdi.imageUrls,
        categoryId: hazirlik.girdi.categoryId,
        sourceType: (ham.sourceType || ham.source_type || "bulk_import").trim(),
        externalProductId: ham.externalProductId || "",
        brand: hazirlik.girdi.brand,
        barcode: hazirlik.girdi.barcode,
        stockQuantity: hazirlik.girdi.stockQuantity,
        stockStatus: hazirlik.girdi.stockStatus,
        metadata: hazirlik.girdi.metadata,
        variants: hazirlik.girdi.variants,
        isVisible: gorunur,
        sortOrder: typeof ham.sortOrder === "number"
          ? ham.sortOrder
          : typeof ham.sort_order === "number"
            ? ham.sort_order
            : index,
      });

      if (gorunur) {
        yayinda += 1;
        sonuclar.push({ sira: index, ad, durum: "yayinda", id: olusan.id });
      } else {
        taslak += 1;
        sonuclar.push({
          sira: index,
          ad,
          durum: "taslak",
          id: olusan.id,
          sebep: hazirlik.durum === "taslak" ? hazirlik.eksik : "Görünürlük kapalı istendi.",
        });
      }
    } catch (err) {
      console.error("[products/batch] create failed:", err);
      atlandi += 1;
      sonuclar.push({ sira: index, ad, durum: "atlandi", sebep: "Ürün oluşturulamadı." });
    }
  }

  return NextResponse.json({
    tamam: true,
    toplam: sonuclar.length,
    eklenen: yayinda + taslak,
    yayinda,
    taslak,
    hatali: atlandi,
    satirlar: sonuclar,
    hataDetaylari: sonuclar
      .filter((satir) => satir.durum === "atlandi")
      .map((satir) => ({ index: satir.sira, error: satir.sebep })),
  });
}
