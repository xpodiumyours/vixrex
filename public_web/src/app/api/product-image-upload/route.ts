import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { fingerprintClient, getClientIp } from "@/lib/rentDemoSecurity";
import { MIN_PRODUCT_IMAGE_SOURCE_SHORT_EDGE } from "@/lib/productImagePolicy";
import {
  GorselSikistirmaHatasi,
  gorseliSikistir,
  ONBELLEK_SANIYE,
  type SikistirilmisGorsel,
} from "@/lib/gorselSikistir";

// Ürün görseli yükleme — Flutter'daki StoreShelfUploadService.uploadProductImage
// karşılığı (maks 5 MB, JPG/PNG/WebP, bayttan tür doğrulama, sharp ile 1600px).

export const dynamic = "force-dynamic";

const MAX_BAYT = 5 * 1024 * 1024;
const LIMIT_PER_STORE = 30;
const WINDOW_SECONDS = 3600;

const IZINLI_TURLER = new Map([
  ["image/jpeg", "jpg"],
  ["image/png", "png"],
  ["image/webp", "webp"],
]);

function gercekTur(bayt: Uint8Array): string | null {
  if (bayt.length < 12) return null;
  if (bayt[0] === 0xff && bayt[1] === 0xd8 && bayt[2] === 0xff) return "image/jpeg";
  const png = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
  if (png.every((b, i) => bayt[i] === b)) return "image/png";
  const riff = [0x52, 0x49, 0x46, 0x46];
  const webp = [0x57, 0x45, 0x42, 0x50];
  if (riff.every((b, i) => bayt[i] === b) && webp.every((b, i) => bayt[8 + i] === b)) return "image/webp";
  return null;
}

export async function POST(request: NextRequest) {
  let form: FormData;
  try {
    form = await request.formData();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = String(form.get("slug") ?? "").trim();
  const productId = String(form.get("productId") ?? form.get("product_id") ?? "").trim();
  const dosya = form.get("dosya");

  if (!slug) return NextResponse.json({ hata: "Vitrin belirtilmedi." }, { status: 400 });
  if (!(dosya instanceof File)) return NextResponse.json({ hata: "Dosya bulunamadı." }, { status: 400 });

  const cookieStore = await cookies();
  const ownerSessionCookie = cookieStore.get(OWNER_SESSION_COOKIE)?.value;
  const ownerSession = verifyOwnerSession(ownerSessionCookie, slug);
  if (!ownerSession) {
    return NextResponse.json({ hata: "Oturumun geçersiz veya süresi dolmuş." }, { status: 401 });
  }

  const admin = getSupabaseAdmin();
  const { data: limitRows } = await admin.rpc("consume_assistant_request", {
    p_client_key: `product_image:${ownerSession.slug}`,
    p_max_requests: LIMIT_PER_STORE,
    p_window_seconds: WINDOW_SECONDS,
  });
  const limit = Array.isArray(limitRows) ? limitRows[0] : limitRows;
  if (limit && !limit.allowed) {
    return NextResponse.json({ hata: `Çok fazla yükleme. ${limit.retry_after_seconds} sn sonra dene.` }, { status: 429 });
  }

  // IP bazlı günlük limit (owner-upload ile aynı desen, ikinci tablo yok)
  const clientIp = getClientIp(request);
  const clientKey = fingerprintClient(clientIp);
  const { data: ipRows } = await admin.rpc("consume_assistant_request", {
    p_client_key: `product_image_ip:${clientKey}`,
    p_max_requests: 50,
    p_window_seconds: 86400,
  });
  const ipLimit = Array.isArray(ipRows) ? ipRows[0] : ipRows;
  if (ipLimit && !ipLimit.allowed) {
    return NextResponse.json({ hata: `Çok fazla yükleme. ${ipLimit.retry_after_seconds} sn sonra dene.` }, { status: 429 });
  }

  if (dosya.size > MAX_BAYT) {
    return NextResponse.json({ hata: "Dosya çok büyük. En fazla 5 MB." }, { status: 413 });
  }
  const bayt = new Uint8Array(await dosya.arrayBuffer());
  if (bayt.length > MAX_BAYT) {
    return NextResponse.json({ hata: "Dosya çok büyük. En fazla 5 MB." }, { status: 413 });
  }
  const tur = gercekTur(bayt);
  const uzanti = tur ? IZINLI_TURLER.get(tur) : null;
  if (!tur || !uzanti) {
    return NextResponse.json({ hata: "Yalnız JPG, PNG veya WebP yükleyebilirsin." }, { status: 415 });
  }

  let sikistirilmis: SikistirilmisGorsel;
  try {
    sikistirilmis = await gorseliSikistir(bayt, tur, { minShortEdge: MIN_PRODUCT_IMAGE_SOURCE_SHORT_EDGE });
  } catch (hata) {
    const mesaj = hata instanceof GorselSikistirmaHatasi ? hata.message : "Görsel işlenemedi.";
    return NextResponse.json({ hata: mesaj }, { status: 422 });
  }

  const guvenliSlug = ownerSession.slug.replace(/[^a-zA-Z0-9-]/g, "");
  const guvenliProduct = (productId || "new").replace(/[^a-zA-Z0-9-]/g, "").slice(0, 32) || "new";
  const dosyaAdi = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}.${sikistirilmis.uzanti}`;
  const yol = `${guvenliSlug}/products/${guvenliProduct}/${dosyaAdi}`;

  try {
    const { error } = await admin.storage.from("shelf-images").upload(yol, sikistirilmis.bayt, {
      contentType: sikistirilmis.tur,
      cacheControl: ONBELLEK_SANIYE,
      upsert: false,
    });
    if (error) {
      console.error("[product-image-upload] storage:", error.message);
      return NextResponse.json({ hata: "Görsel yüklenemedi." }, { status: 500 });
    }
    const { data } = admin.storage.from("shelf-images").getPublicUrl(yol);
    return NextResponse.json({ tamam: true, url: data.publicUrl });
  } catch (err) {
    console.error("[product-image-upload] failed:", err instanceof Error ? err.message : "unknown");
    return NextResponse.json({ hata: "Görsel yüklenemedi." }, { status: 500 });
  }
}
