import { NextResponse, type NextRequest } from "next/server";
import {
  GorselSikistirmaHatasi,
  ONBELLEK_SANIYE,
  gorseliSikistir,
} from "@/lib/gorselSikistir";
import { platformAdminDogrula } from "@/lib/platformAdminAuth";

export const dynamic = "force-dynamic";

const MAX_BAYT = 5 * 1024 * 1024;
const SAATLIK_LIMIT = 100;
const SAAT = 3600;

function gercekTur(bayt: Uint8Array): string | null {
  if (bayt.length < 12) return null;

  if (bayt[0] === 0xff && bayt[1] === 0xd8 && bayt[2] === 0xff) {
    return "image/jpeg";
  }

  const png = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
  if (png.every((value, index) => bayt[index] === value)) {
    return "image/png";
  }

  const riff = [0x52, 0x49, 0x46, 0x46];
  const webp = [0x57, 0x45, 0x42, 0x50];
  if (
    riff.every((value, index) => bayt[index] === value) &&
    webp.every((value, index) => bayt[index + 8] === value)
  ) {
    return "image/webp";
  }

  return null;
}

/**
 * Vixrex merkezi blog kapak yüklemesi.
 * Owner upload'tan bilinçli olarak ayrıdır: owner-session veya vitrin alan
 * şeması kabul etmez; yalnız platform admin Bearer oturumu kullanır.
 */
export async function POST(request: NextRequest) {
  const kimlik = await platformAdminDogrula(request);
  if (!kimlik.ok) return kimlik.response;

  let form: FormData;
  try {
    form = await request.formData();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const dosya = form.get("dosya");
  if (!(dosya instanceof File)) {
    return NextResponse.json({ hata: "Kapak görseli bulunamadı." }, { status: 400 });
  }
  if (dosya.size <= 0 || dosya.size > MAX_BAYT) {
    return NextResponse.json({ hata: "Kapak görseli en fazla 5 MB olabilir." }, { status: 413 });
  }

  const { data: limitRows, error: limitError } = await kimlik.admin.rpc(
    "consume_assistant_request",
    {
      p_client_key: `vixrex_blog_upload:${kimlik.userId}`,
      p_max_requests: SAATLIK_LIMIT,
      p_window_seconds: SAAT,
    },
  );
  const limit = Array.isArray(limitRows) ? limitRows[0] : limitRows;
  if (limitError) {
    console.error("[vixrex-blog-upload] rate limit failed:", limitError.message);
    return NextResponse.json({ hata: "Görsel yüklenemedi. Tekrar dene." }, { status: 500 });
  }
  if (limit && !limit.allowed) {
    return NextResponse.json(
      { hata: `Yükleme sınırına ulaşıldı. ${limit.retry_after_seconds} saniye sonra tekrar dene.` },
      { status: 429 },
    );
  }

  const bayt = new Uint8Array(await dosya.arrayBuffer());
  if (bayt.length <= 0 || bayt.length > MAX_BAYT) {
    return NextResponse.json({ hata: "Kapak görseli en fazla 5 MB olabilir." }, { status: 413 });
  }

  const tur = gercekTur(bayt);
  if (!tur) {
    return NextResponse.json({ hata: "Yalnız JPG, PNG veya WebP yüklenebilir." }, { status: 415 });
  }

  let cikti;
  try {
    cikti = await gorseliSikistir(bayt, tur);
  } catch (error) {
    const mesaj =
      error instanceof GorselSikistirmaHatasi
        ? error.message
        : "Görsel işlenemedi. Tekrar dene.";
    return NextResponse.json({ hata: mesaj }, { status: 422 });
  }

  const dosyaAdi = `${Date.now()}-${Math.random().toString(36).slice(2, 10)}.${cikti.uzanti}`;
  const yol = `vixrex-blog/covers/${dosyaAdi}`;

  const { error: uploadError } = await kimlik.admin.storage
    .from("shelf-images")
    .upload(yol, cikti.bayt, {
      contentType: cikti.tur,
      cacheControl: ONBELLEK_SANIYE,
      upsert: false,
    });

  if (uploadError) {
    console.error("[vixrex-blog-upload] storage failed:", uploadError.message);
    return NextResponse.json({ hata: "Görsel yüklenemedi. Tekrar dene." }, { status: 500 });
  }

  const { data } = kimlik.admin.storage.from("shelf-images").getPublicUrl(yol);
  return NextResponse.json({ tamam: true, url: data.publicUrl });
}
