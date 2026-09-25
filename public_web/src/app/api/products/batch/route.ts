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
export const maxDuration = 300;

/** Fatura fotoğrafından gelen satırların kaynak etiketi. */
export const FATURA_KAYNAGI = "invoice";

function pozitifSayi(value: unknown): number | null {
  const sayi =
    typeof value === "number"
      ? value
      : typeof value === "string"
        ? Number(value.trim().replace(",", "."))
        : NaN;
  return Number.isFinite(sayi) && sayi > 0 ? sayi : null;
}

function faturaKapisiSebebi(args: {
  hazirlik: { durum: string; eksik?: string };
  faturaKaynakli: boolean;
  satisFiyatiGirildi: boolean;
  esnafOnayladi: boolean;
}): string {
  if (args.hazirlik.durum === "taslak" && args.hazirlik.eksik) return args.hazirlik.eksik;
  if (args.faturaKaynakli && !args.satisFiyatiGirildi) {
    return "Satış fiyatı girilmedi; ürün taslak kaldı.";
  }
  if (args.faturaKaynakli && !args.esnafOnayladi) {
    return "Ürün onaylanmadı; ürün taslak kaldı.";
  }
  return "Görünürlük kapalı istendi.";
}

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
  /** Faturadan gelen satırlarda esnafın açık yayın onayı. */
  ownerApproved?: boolean;
  /** Faturadaki birim alış fiyatı. Karta yazılmaz, müşteriye gösterilmez. */
  purchasePriceAmount?: unknown;
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

  const sablonOnbellegi = new Map<string, string | null>();
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
      sablonOnbellegi,
    });

    if (hazirlik.durum === "reddedildi") {
      atlandi += 1;
      sonuclar.push({ sira: index, ad, durum: "atlandi", sebep: hazirlik.sebep });
      continue;
    }

    const kaynak = (ham.sourceType || ham.source_type || "bulk_import").trim();

    // Faturadan gelen satır, fotoğrafı ve zorunlu alanları tam olsa bile
    // kendiliğinden yayına çıkmaz: esnaf satış fiyatını girmeli ve kartı
    // açıkça onaylamalı. Fatura alış fiyatı satış fiyatı yerine geçmez.
    const faturaKaynakli = kaynak === FATURA_KAYNAGI;
    const satisFiyatiGirildi =
      typeof hazirlik.girdi.priceAmount === "number" && hazirlik.girdi.priceAmount > 0;
    const esnafOnayladi = ham.ownerApproved === true;
    const faturaKapisi = !faturaKaynakli || (satisFiyatiGirildi && esnafOnayladi);

    const gorunur =
      hazirlik.durum === "hazir" && ham.isVisible !== false && faturaKapisi;

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
        sourceType: kaynak,
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

      // Alış fiyatı ürün kartına değil, yalnız esnafın kendi kaydına yazılır.
      // Herkese açık vitrin sorgusu bu kolonu seçmez, müşteriye gösterilmez.
      const alisFiyati = pozitifSayi(ham.purchasePriceAmount);
      if (alisFiyati !== null) {
        const { error: alisHatasi } = await admin
          .from("products")
          .update({ purchase_price_amount: alisFiyati })
          .eq("id", olusan.id)
          .eq("store_id", store.id);
        if (alisHatasi) {
          console.error("[products/batch] alis fiyati yazilamadi:", alisHatasi.message);
        }
      }

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
          sebep: faturaKapisiSebebi({
            hazirlik,
            faturaKaynakli,
            satisFiyatiGirildi,
            esnafOnayladi,
          }),
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
