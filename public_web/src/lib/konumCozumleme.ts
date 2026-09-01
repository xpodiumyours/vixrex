import { getDistrictsForProvince, turkeyProvinces } from "@/lib/turkeyCities";

export interface NominatimYaniti {
  display_name?: unknown;
  address?: Record<string, unknown> | null;
}

export interface CozulenKonum {
  provinceName: string;
  districtName: string;
  address: string;
}

function metin(deger: unknown): string {
  return typeof deger === "string" ? deger.trim() : "";
}

function normalize(deger: string): string {
  return deger
    .toLocaleLowerCase("tr-TR")
    .replaceAll("ı", "i")
    .replaceAll("ş", "s")
    .replaceAll("ğ", "g")
    .replaceAll("ü", "u")
    .replaceAll("ö", "o")
    .replaceAll("ç", "c")
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "");
}

function mahalleEtiketi(deger: string): string {
  const kucuk = deger.toLocaleLowerCase("tr-TR");
  if (
    kucuk.endsWith("mahallesi") ||
    kucuk.endsWith("mahalle") ||
    kucuk.endsWith("mah.") ||
    kucuk.endsWith("mah")
  ) {
    return deger;
  }
  return `${deger} Mah.`;
}

/** Flutter LocationService.getAddressFromCoordinates ile aynı sunum sözleşmesi. */
export function nominatimAdresiniCoz(yanit: NominatimYaniti): CozulenKonum | null {
  const hamAdres = yanit.address ?? {};
  const road = metin(hamAdres.road) || metin(hamAdres.street) || metin(hamAdres.pedestrian);
  const suburb =
    metin(hamAdres.suburb) ||
    metin(hamAdres.neighbourhood) ||
    metin(hamAdres.quarter);
  const town =
    metin(hamAdres.town) ||
    metin(hamAdres.city_district) ||
    metin(hamAdres.district) ||
    metin(hamAdres.county);
  const city = metin(hamAdres.city) || metin(hamAdres.province) || metin(hamAdres.state);
  const displayName = metin(yanit.display_name);

  const aramaMetni = normalize(
    Object.values(hamAdres).map(metin).filter(Boolean).concat(displayName).join(" "),
  );
  const province = turkeyProvinces.find((aday) =>
    aramaMetni.includes(normalize(aday.name)),
  );
  if (!province) return null;

  const district = [...getDistrictsForProvince(province.name)]
    .sort((a, b) => b.length - a.length)
    .find((aday) => aramaMetni.includes(normalize(aday)));
  if (!district) return null;

  const parcalar: string[] = [];
  if (suburb) parcalar.push(mahalleEtiketi(suburb));
  if (road) parcalar.push(road);
  if (town) parcalar.push(town);
  if (city && normalize(city) !== normalize(town)) parcalar.push(city);

  const address = parcalar.join(", ") || displayName;
  if (!address) return null;

  return {
    provinceName: province.name,
    districtName: district,
    address,
  };
}

/** Landing ve sahip asistanının kullandığı tek GPS → adres istemcisi. */
export async function gpsAdresiniCoz(
  latitude: number,
  longitude: number,
): Promise<CozulenKonum> {
  const params = new URLSearchParams({
    lat: latitude.toFixed(6),
    lng: longitude.toFixed(6),
  });
  const response = await fetch(`/api/location/reverse-geocode?${params.toString()}`);
  const body = (await response.json().catch(() => null)) as
    | { konum?: CozulenKonum; hata?: string }
    | null;

  if (!response.ok || !body?.konum) {
    throw new Error(body?.hata ?? "Adres çözümlenemedi.");
  }
  return body.konum;
}
