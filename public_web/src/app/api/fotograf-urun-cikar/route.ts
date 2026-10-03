import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { verifyStoreEditToken } from "@/lib/instagramServer";
import { fingerprintClient, getClientIp } from "@/lib/rentDemoSecurity";
import { fotografdanUrunCikar } from "@/lib/fotografUrunCikar";

export const dynamic = "force-dynamic";
export const maxDuration = 60;

const MAKS_BAYT = 5 * 1024 * 1024;
const VITRIN_BASINA_LIMIT = 20;
const PENCERE_SANIYE = 3600;

const IZINLI_TURLER = new Set(["image/jpeg", "image/png", "image/webp"]);

function gercekTur(bayt: Uint8Array): string | null {
  if (bayt.length < 12) return null;
  if (bayt[0] === 0xff && bayt[1] === 0xd8 && bayt[2] === 0xff) return "image/jpeg";
  const png = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
  if (png.every((b, i) => bayt[i] === b)) return "image/png";
  const riff = [0x52, 0x49, 0x46, 0x46];
  const webp = [0x57, 0x45, 0x42, 0x50];
  if (riff.every((b, i) => bayt[i] === b) && webp.every((b, i) => bayt[8 + i] === b)) {
    return "image/webp";
  }
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
  const dosya = form.get("dosya");
  const editTokenGovde = String(form.get("editToken") ?? "").trim();

  if (!slug) {
    return NextResponse.json({ hata: "Vitrin belirtilmedi." }, { status: 400 });
  }
  if (!(dosya instanceof File)) {
    return NextResponse.json({ hata: "Ürün fotoğrafı bulunamadı." }, { status: 400 });
  }

  const cookieStore = await cookies();
  const cerezliOturum = verifyOwnerSession(cookieStore.get(OWNER_SESSION_COOKIE)?.value, slug);

  let ownerSlug: string;
  if (cerezliOturum) {
    ownerSlug = cerezliOturum.slug;
  } else if (editTokenGovde) {
    try {
      const store = await verifyStoreEditToken(slug, editTokenGovde);
      ownerSlug = store.slug;
    } catch {
      return NextResponse.json({ hata: "Oturumun geçersiz veya süresi dolmuş." }, { status: 401 });
    }
  } else {
    return NextResponse.json({ hata: "Oturumun geçersiz veya süresi dolmuş." }, { status: 401 });
  }

  if (!process.env.OPENROUTER_API_KEY) {
    return NextResponse.json(
      { hata: "Fotoğraf çıkarma şu an hazır değil (okuyucu anahtarı tanımlı değil)." },
      { status: 503 },
    );
  }

  const admin = getSupabaseAdmin();
  const { data: limitRows } = await admin.rpc("consume_assistant_request", {
    p_client_key: `foto_urun:${ownerSlug}`,
    p_max_requests: VITRIN_BASINA_LIMIT,
    p_window_seconds: PENCERE_SANIYE,
  });
  const limit = Array.isArray(limitRows) ? limitRows[0] : limitRows;
  if (limit && !limit.allowed) {
    return NextResponse.json(
      { hata: `Çok fazla fotoğraf okudun. ${limit.retry_after_seconds} sn sonra dene.` },
      { status: 429 },
    );
  }

  const clientKey = fingerprintClient(getClientIp(request));
  const { data: ipRows } = await admin.rpc("consume_assistant_request", {
    p_client_key: `foto_urun_ip:${clientKey}`,
    p_max_requests: 40,
    p_window_seconds: 86400,
  });
  const ipLimit = Array.isArray(ipRows) ? ipRows[0] : ipRows;
  if (ipLimit && !ipLimit.allowed) {
    return NextResponse.json(
      { hata: `Çok fazla fotoğraf okudun. ${ipLimit.retry_after_seconds} sn sonra dene.` },
      { status: 429 },
    );
  }

  if (dosya.size > MAKS_BAYT) {
    return NextResponse.json({ hata: "Fotoğraf çok büyük. En fazla 5 MB." }, { status: 413 });
  }

  const bayt = new Uint8Array(await dosya.arrayBuffer());
  const tur = gercekTur(bayt);
  if (!tur || !IZINLI_TURLER.has(tur)) {
    return NextResponse.json(
      { hata: "Yalnız JPG, PNG veya WebP yükleyebilirsin." },
      { status: 415 },
    );
  }

  try {
    const oneri = await fotografdanUrunCikar(`data:${tur};base64,${Buffer.from(bayt).toString("base64")}`);
    return NextResponse.json({ tamam: true, oneri });
  } catch (cikarmaHatasi) {
    const mesaj = cikarmaHatasi instanceof Error ? cikarmaHatasi.message : "";
    if (mesaj === "OKUYUCU_HAZIR_DEGIL") {
      return NextResponse.json(
        { hata: "Fotoğraf çıkarma şu an hazır değil (okuyucu anahtarı tanımlı değil)." },
        { status: 503 },
      );
    }
    if (mesaj === "OKUYUCU_SONUC_YOK") {
      return NextResponse.json(
        { hata: "Bu fotoğraftan güvenilir bir ürün bilgisi çıkarılamadı; daha net bir fotoğraf dene." },
        { status: 422 },
      );
    }
    console.error("[fotograf-urun-cikar] okuma hatasi:", mesaj);
    return NextResponse.json({ hata: "Fotoğraf okunemedi. Tekrar dene." }, { status: 502 });
  }
}
