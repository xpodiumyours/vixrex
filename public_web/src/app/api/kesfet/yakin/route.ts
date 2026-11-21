import { NextResponse, type NextRequest } from "next/server";
import { koordinatGecerliMi, yakinVitrinleriGetir } from "@/lib/explore";

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
