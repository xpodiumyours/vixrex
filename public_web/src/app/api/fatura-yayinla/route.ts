import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { verifyStoreEditToken } from "@/lib/instagramServer";
import { publishInvoiceProduct } from "@/lib/productCoreServer";
import { tuketicideGorunenler, vitrinOnbelleginiYenile } from "@/lib/vitrinYayinDogrula";

// Fatura taslaklarının AYRI Yayınla ucu (P5 + P6).
//
// "Bilgileri onayla" (/api/products/batch, yayinIstegi yok) yalnız taslak
// kaydeder; bu uç taslağı sunucuda tekrar okuyup görünür yapar. İki giriş
// yolu var: tarayıcı çerezle (verifyOwnerSession), Flutter store
// edit_token ile (verifyStoreEditToken) — /api/fatura-oku ile aynı desen,
// böylece web ve telefon aynı kapıdan yayınlar.
//
// Kapılar publish_invoice_product RPC'sinde veritabanı düzeyinde de yeniden
// okunur; bu uçtaki kontroller erken, anlaşılır hata içindir.

export const dynamic = "force-dynamic";

interface YayinSonucu {
  id: string;
  durum: "yayinda" | "taslak";
  sebep?: string;
}

export async function POST(request: NextRequest) {
  let govde: { slug?: unknown; productIds?: unknown; editToken?: unknown };
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  const productIds = Array.isArray(govde.productIds)
    ? govde.productIds.filter((id): id is string => typeof id === "string" && id.trim().length > 0)
    : [];
  const editTokenGovde = typeof govde.editToken === "string" ? govde.editToken.trim() : "";

  if (!slug) {
    return NextResponse.json({ hata: "Vitrin belirtilmedi." }, { status: 422 });
  }
  if (productIds.length === 0) {
    return NextResponse.json({ hata: "Yayınlanacak ürün belirtilmedi." }, { status: 422 });
  }
  if (productIds.length > 100) {
    return NextResponse.json({ hata: "Tek seferde en fazla 100 ürün yayınlanabilir." }, { status: 422 });
  }

  const cookieStore = await cookies();
  const cerezliOturum = verifyOwnerSession(cookieStore.get(OWNER_SESSION_COOKIE)?.value, slug);

  const admin = getSupabaseAdmin();
  let storeId = cerezliOturum?.storeId ?? "";
  let editToken = "";

  if (cerezliOturum) {
    const { data: store } = await admin
      .from("stores")
      .select("id, edit_token")
      .eq("id", cerezliOturum.storeId)
      .single();
    if (!store?.edit_token) {
      return NextResponse.json({ hata: "Vitrin bulunamadı." }, { status: 404 });
    }
    editToken = store.edit_token as string;
  } else if (editTokenGovde) {
    try {
      const store = await verifyStoreEditToken(slug, editTokenGovde);
      storeId = store.id;
      editToken = editTokenGovde;
    } catch {
      return NextResponse.json({ hata: "Oturumun geçersiz veya süresi dolmuş." }, { status: 401 });
    }
    if (!storeId) {
      return NextResponse.json({ hata: "Vitrin bulunamadı." }, { status: 404 });
    }
  } else {
    return NextResponse.json({ hata: "Oturumun geçersiz veya süresi dolmuş." }, { status: 401 });
  }

  const sonuclar: YayinSonucu[] = [];
  let yayinda = 0;
  let taslak = 0;

  for (const id of productIds) {
    const { data: urun } = await admin
      .from("products")
      .select("id,source_type,is_visible,price_amount,image_urls,stock_quantity,fatura_kanit")
      .eq("id", id)
      .eq("store_id", storeId)
      .maybeSingle();

    if (!urun) {
      taslak += 1;
      sonuclar.push({ id, durum: "taslak", sebep: "Ürün bu vitrine ait değil." });
      continue;
    }

    const satir = urun as {
      source_type?: string;
      is_visible?: boolean;
    };

    if (satir.source_type !== "invoice") {
      taslak += 1;
      sonuclar.push({ id, durum: "taslak", sebep: "Bu ürün fatura akışından gelmedi." });
      continue;
    }
    if (satir.is_visible === true) {
      yayinda += 1;
      sonuclar.push({ id, durum: "yayinda" });
      continue;
    }

    // Kilitli kapsam: üretici fotoğrafı yayını durdurmaz; kullanım izni
    // sonra, çalışan sistemle istenir (kayıtlar invoice_image_rights'ta).
    try {
      const yayin = await publishInvoiceProduct({ admin, productId: id, editToken });
      if (yayin.success) {
        yayinda += 1;
        sonuclar.push({ id, durum: "yayinda" });
      } else {
        taslak += 1;
        sonuclar.push({ id, durum: "taslak", sebep: yayin.hata ?? "Ürün yayınlanamadı." });
      }
    } catch (err) {
      console.error("[fatura-yayinla] publish failed:", err);
      taslak += 1;
      sonuclar.push({ id, durum: "taslak", sebep: "Ürün yayınlanamadı." });
    }
  }

  const yayindakiler = sonuclar.filter((sonuc) => sonuc.durum === "yayinda").map((sonuc) => sonuc.id);
  const gorunum = await tuketicideGorunenler(admin, storeId, yayindakiler);
  let dogrulanamayan = 0;
  if (gorunum) {
    for (const sonuc of sonuclar) {
      if (sonuc.durum !== "yayinda") continue;
      const durum = gorunum.get(sonuc.id);
      if (durum && !durum.gorunur) {
        sonuc.durum = "taslak";
        sonuc.sebep = durum.sebep;
        yayinda -= 1;
        taslak += 1;
      }
    }
  } else {
    dogrulanamayan = yayindakiler.length;
  }
  if (yayinda > 0) vitrinOnbelleginiYenile(slug);

  return NextResponse.json({
    tamam: true,
    yayinda,
    taslak,
    satirlar: sonuclar,
    ...(dogrulanamayan > 0 ? { tuketiciDogrulamasi: "yapilamadi" } : { tuketiciDogrulamasi: "tamam" }),
  });
}
