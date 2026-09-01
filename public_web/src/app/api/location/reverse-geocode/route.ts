import { NextResponse, type NextRequest } from "next/server";
import {
  nominatimAdresiniCoz,
  type NominatimYaniti,
} from "@/lib/konumCozumleme";

const DEFAULT_NOMINATIM_URL = "https://nominatim.openstreetmap.org";

export async function GET(request: NextRequest) {
  const latitudeParam = request.nextUrl.searchParams.get("lat");
  const longitudeParam = request.nextUrl.searchParams.get("lng");
  const latitude = Number(latitudeParam);
  const longitude = Number(longitudeParam);

  if (
    latitudeParam === null ||
    longitudeParam === null ||
    !Number.isFinite(latitude) ||
    !Number.isFinite(longitude) ||
    latitude < -90 ||
    latitude > 90 ||
    longitude < -180 ||
    longitude > 180
  ) {
    return NextResponse.json({ hata: "Geçersiz koordinat." }, { status: 400 });
  }

  const baseUrl = (process.env.NOMINATIM_BASE_URL ?? DEFAULT_NOMINATIM_URL).replace(/\/$/, "");
  const url = new URL(`${baseUrl}/reverse`);
  url.searchParams.set("format", "jsonv2");
  url.searchParams.set("lat", latitude.toFixed(6));
  url.searchParams.set("lon", longitude.toFixed(6));
  url.searchParams.set("zoom", "18");
  url.searchParams.set("addressdetails", "1");

  try {
    const response = await fetch(url, {
      headers: {
        "User-Agent": "Vixrex-Web/1.0 (+https://vixrex.com)",
        "Accept-Language": "tr-TR,tr;q=0.9",
      },
      next: { revalidate: 86_400 },
      signal: AbortSignal.timeout(6_000),
    });
    if (!response.ok) {
      return NextResponse.json({ hata: "Adres servisine ulaşılamadı." }, { status: 502 });
    }

    const konum = nominatimAdresiniCoz((await response.json()) as NominatimYaniti);
    if (!konum) {
      return NextResponse.json(
        { hata: "Koordinat alındı ancak adres çözümlenemedi. Mevcut adresiniz korundu." },
        { status: 422 },
      );
    }

    return NextResponse.json({
      konum,
      attribution: "© OpenStreetMap contributors",
    });
  } catch {
    return NextResponse.json({ hata: "Adres çözümleme zaman aşımına uğradı." }, { status: 504 });
  }
}
