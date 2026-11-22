import { NextResponse, type NextRequest } from "next/server";
import { koordinatGecerliMi, yakinVitrinleriGetir } from "@/lib/explore";
import { fingerprintClient, getClientIp } from "@/lib/rentDemoSecurity";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";

const YAKIN_ISTEK_LIMITI = 60;
const YAKIN_PENCERE_SANIYE = 60;

async function yakinKotaAsildiMi(request: NextRequest): Promise<NextResponse | null> {
  let clientKey: string;
  try {
    clientKey = fingerprintClient(getClientIp(request));
  } catch (error) {
    if (process.env.VERCEL_ENV !== "production") return null;
    console.error("[kesfet/yakin] istemci parmak izi alınamadı:", error);
    return NextResponse.json(
      { hata: "Yakındaki vitrinler geçici olarak kullanılamıyor." },
      { status: 503 }
    );
  }

  let admin: ReturnType<typeof getSupabaseAdmin>;
  try {
    admin = getSupabaseAdmin();
  } catch (error) {
    if (process.env.VERCEL_ENV !== "production") return null;
    console.error("[kesfet/yakin] kota sayacı kullanılamıyor:", error);
    return NextResponse.json(
      { hata: "Yakındaki vitrinler geçici olarak kullanılamıyor." },
      { status: 503 }
    );
  }

  const { data, error } = await admin.rpc("consume_assistant_request", {
    p_client_key: `kesfet_yakin:ip:${clientKey}`,
    p_max_requests: YAKIN_ISTEK_LIMITI,
    p_window_seconds: YAKIN_PENCERE_SANIYE,
  });

  if (error) {
    if (process.env.VERCEL_ENV !== "production") return null;
    console.error("[kesfet/yakin] kota sayacı yanıt vermedi:", error.message);
    return NextResponse.json(
      { hata: "Yakındaki vitrinler geçici olarak kullanılamıyor." },
      { status: 503 }
    );
  }

  const limit = Array.isArray(data) ? data[0] : data;
  if (limit && limit.allowed === false) {
    const retryAfter = Number(limit.retry_after_seconds);
    return NextResponse.json(
      { hata: "Çok fazla yakın konum isteği yaptın. Lütfen biraz sonra tekrar dene." },
      {
        status: 429,
        headers: {
          "Retry-After": String(
            Number.isFinite(retryAfter) ? retryAfter : YAKIN_PENCERE_SANIYE
          ),
        },
      }
    );
  }

  return null;
}

export async function GET(request: NextRequest) {
  const { searchParams } = request.nextUrl;
  const latParam = searchParams.get("lat");
  const lngParam = searchParams.get("lng");
  const radiusParam = searchParams.get("radius");

  if (
    latParam === null ||
    lngParam === null ||
    latParam.trim() === "" ||
    lngParam.trim() === ""
  ) {
    return NextResponse.json({ hata: "Geçersiz koordinat." }, { status: 400 });
  }

  const lat = Number(latParam);
  const lng = Number(lngParam);

  if (!koordinatGecerliMi(lat, lng)) {
    return NextResponse.json({ hata: "Geçersiz koordinat." }, { status: 400 });
  }

  let radiusMeters: number | undefined;
  if (radiusParam !== null && radiusParam.trim() !== "") {
    const parsedRadius = Number(radiusParam);
    if (!Number.isFinite(parsedRadius) || parsedRadius <= 0) {
      return NextResponse.json({ hata: "Geçersiz yarıçap." }, { status: 400 });
    }
    radiusMeters = parsedRadius;
  }

  const kotaYaniti = await yakinKotaAsildiMi(request);
  if (kotaYaniti) return kotaYaniti;

  try {
    const vitrinler = await yakinVitrinleriGetir({
      lat,
      lng,
      ...(radiusMeters !== undefined ? { radiusMeters } : {}),
    });
    return NextResponse.json({ vitrinler });
  } catch {
    return NextResponse.json(
      { hata: "Yakındaki vitrinler yüklenemedi." },
      { status: 500 }
    );
  }
}
