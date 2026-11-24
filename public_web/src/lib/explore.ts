import { revalidateTag, unstable_cache } from "next/cache";
import { supabase } from "./supabase";
import { EXPLORE_STORE_SELECT } from "./publicStoreSelect";
import { resolveBusinessCategory } from "./businessCategories";
import { isTestOrDenemeStore } from "./denemeVitrinFiltresi";

/**
 * Keşfet dizininin veri katmanı.
 *
 * Flutter'daki karşılığı `lib/repositories/explore_repository.dart:21-76`.
 * Sorgu bilerek birebir aynı tutuldu (yayında + en son güncellenen 100):
 * iki istemci aynı listeyi göstermezse "uygulamada gördüğüm vitrin sitede
 * yok" şikâyeti kaçınılmaz olur.
 *
 * Kiralık/örnek ayrımı: YALNIZ `is_demo`. Dart tarafındaki
 * `storefront_kind` kolonu hiçbir migration'da yok — `isRentalTemplate`
 * pratikte `is_demo`'ya iniyor (2026-08-26 doğrulaması).
 */

export const KESFET_LIMIT = 100;

export type KesfetVitrini = {
  slug: string;
  ad: string;
  aciklama: string;
  kategoriEtiketi: string;
  kategoriKimligi: string | null;
  kapakUrl: string | null;
  konum: string;
  kiralikMi: boolean;
  acikMi: boolean;
  urunSayisi: number;
  urunAdlari: string[];
  whatsapp: string | null;
  guncellemeZamani: string | null;
  puan: number | null;
  mesafeMetre?: number | null;
};

type StoreSatiri = {
  id: string;
  slug: string | null;
  name: string | null;
  description: string | null;
  address: string | null;
  kategori: string | null;
  business_type: string | null;
  shelf_image_url: string | null;
  logo_url: string | null;
  province_name: string | null;
  district_name: string | null;
  status: string | null;
  is_demo: boolean | null;
  whatsapp: string | null;
  updated_at: string | null;
  rating_score: number | null;
  show_storefront_rating: boolean | null;
  distance_meters?: number | null;
};

export function vitrinPuani(satir: { rating_score: number | null; show_storefront_rating: boolean | null }): number | null {
  if (satir.show_storefront_rating !== true) return null;
  return typeof satir.rating_score === "number" ? satir.rating_score : null;
}

function konumMetni(satir: StoreSatiri): string {
  const ilce = satir.district_name?.trim() ?? "";
  const il = satir.province_name?.trim() ?? "";
  if (ilce && il) return `${ilce}, ${il}`;
  return ilce || il || satir.address?.trim() || "Konum belirtilmedi";
}

function kategoriEtiketi(satir: StoreSatiri): {
  etiket: string;
  kimlik: string | null;
} {
  const ham = satir.kategori?.trim() || satir.business_type?.trim() || "";
  if (!ham) return { etiket: "Dijital Vitrin", kimlik: null };
  const cozulen = resolveBusinessCategory(ham);
  return { etiket: cozulen?.label ?? ham, kimlik: cozulen?.id ?? null };
}

export function koordinatGecerliMi(lat: number, lng: number): boolean {
  return (
    Number.isFinite(lat) &&
    Number.isFinite(lng) &&
    lat >= -90 &&
    lat <= 90 &&
    lng >= -180 &&
    lng <= 180
  );
}

async function vitrinleriUrunlerleDoldur(hamSatirlar: StoreSatiri[]): Promise<KesfetVitrini[]> {
  const satirlar = hamSatirlar.filter(
    (satir) =>
      (satir.slug ?? "").trim().length > 0 && !isTestOrDenemeStore(satir)
  );
  if (satirlar.length === 0) return [];

  const sayaclar = new Map<string, number>();
  const urunAdlari = new Map<string, string[]>();
  const { data: urunler, error: urunHatasi } = await supabase
    .from("products")
    .select("store_id,name")
    .in(
      "store_id",
      satirlar.map((satir) => satir.id)
    )
    .eq("is_active", true)
    .eq("is_visible", true);

  if (urunHatasi) {
    console.error("[kesfet] ürün sayısı okunamadı:", urunHatasi.message);
    throw new Error("Vitrin ürünleri okunamadı");
  }

  for (const urun of (urunler ?? []) as { store_id: string; name: string | null }[]) {
    sayaclar.set(urun.store_id, (sayaclar.get(urun.store_id) ?? 0) + 1);
    const ad = urun.name?.trim();
    if (ad) {
      const adlar = urunAdlari.get(urun.store_id) ?? [];
      adlar.push(ad);
      urunAdlari.set(urun.store_id, adlar);
    }
  }

  return satirlar.map((satir) => {
    const { etiket, kimlik } = kategoriEtiketi(satir);
    const durum = (satir.status ?? "").trim().toLocaleLowerCase("tr-TR");
    const mesafe =
      typeof satir.distance_meters === "number" && Number.isFinite(satir.distance_meters)
        ? satir.distance_meters
        : undefined;
    return {
      slug: (satir.slug ?? "").trim(),
      ad: satir.name?.trim() || "İsimsiz vitrin",
      aciklama: satir.description?.trim() || "",
      kategoriEtiketi: etiket,
      kategoriKimligi: kimlik,
      kapakUrl: satir.shelf_image_url?.trim() || satir.logo_url?.trim() || null,
      konum: konumMetni(satir),
      kiralikMi: satir.is_demo === true,
      acikMi: durum === "" || durum.startsWith("açık") || durum.startsWith("acik"),
      urunSayisi: sayaclar.get(satir.id) ?? 0,
      urunAdlari: urunAdlari.get(satir.id) ?? [],
      whatsapp: satir.whatsapp?.trim() || null,
      guncellemeZamani: satir.updated_at,
      puan: vitrinPuani(satir),
      ...(mesafe !== undefined ? { mesafeMetre: mesafe } : {}),
    };
  });
}

async function _kesfetGetir(): Promise<KesfetVitrini[]> {
  const { data, error } = await supabase
    .from("stores")
    .select(EXPLORE_STORE_SELECT)
    .eq("is_published", true)
    .order("updated_at", { ascending: false })
    .limit(KESFET_LIMIT);

  if (error) {
    console.error("[kesfet] vitrin sorgusu başarısız:", error.message);
    throw new Error("Vitrinler okunamadı");
  }
  if (!data) return [];

  return vitrinleriUrunlerleDoldur(data as unknown as StoreSatiri[]);
}

export async function yakinVitrinleriGetir({
  lat,
  lng,
  radiusMeters = 5000,
}: {
  lat: number;
  lng: number;
  radiusMeters?: number;
}): Promise<KesfetVitrini[]> {
  if (!koordinatGecerliMi(lat, lng)) {
    throw new Error("Geçersiz konum koordinatı");
  }

  const yaricap =
    typeof radiusMeters === "number" && Number.isFinite(radiusMeters)
      ? Math.min(Math.max(Math.round(radiusMeters), 100), 100000)
      : 5000;

  const { data, error } = await supabase.rpc("search_nearby_stores", {
    p_lat: lat,
    p_lng: lng,
    p_radius_m: yaricap,
    p_limit: 50,
  });

  if (error) {
    console.error("[kesfet] yakın vitrin sorgusu başarısız:", error.message);
    throw new Error("Yakındaki vitrinler okunamadı");
  }
  if (!data) return [];

  return vitrinleriUrunlerleDoldur(data as unknown as StoreSatiri[]);
}

/** Yayındaki vitrinler, en son güncellenen önce. */
const kesfetVitrinleriniOnbellektenGetir = unstable_cache(
  _kesfetGetir,
  ["kesfet"],
  {
    tags: ["kesfet"],
    revalidate: 300,
  }
);

export const kesfetVitrinleriniGetir = kesfetVitrinleriniOnbellektenGetir;

/**
 * Yayın/pasifleştirme anında Keşfet listesinin önbelleğini düşürür.
 *
 * Yukarıdaki liste 5 dakika saklanıyor. Düşürülmezse esnaf "yayınladım"
 * der ama kendi vitrinini Keşfet'te en fazla 5 dakika sonra görür —
 * akış orada "çalışmıyor" gibi durur (2026-10-03). Yayınlama uçları
 * (create-store, owner-publish, ürün yayını) bunu çağırır.
 */
export function kesfetOnbelleginiYenile(): void {
  try {
    revalidateTag("kesfet", { expire: 0 });
  } catch (hata) {
    console.warn(
      "[kesfet] onbellek yenilenemedi:",
      hata instanceof Error ? hata.message : hata
    );
  }
}

/** Tek kategorinin yayındaki vitrinleri — ek sorgu atmaz, listeyi süzer. */
export async function kategoriVitrinleriniGetir(
  kategoriKimligi: string,
  listeyiGetir: () => Promise<KesfetVitrini[]> = kesfetVitrinleriniGetir
): Promise<KesfetVitrini[]> {
  try {
    const hepsi = await listeyiGetir();
    return hepsi.filter((vitrin) => vitrin.kategoriKimligi === kategoriKimligi);
  } catch {
    // Bu fonksiyon statik kategori sayfalarının build aşamasında da çalışır.
    // Geçici veri kesintisi bütün web yayınını durdurmamalı; ana Keşfet
    // çağrısı hatayı taşımaya ve kendi error boundary'sini göstermeye devam eder.
    return [];
  }
}
