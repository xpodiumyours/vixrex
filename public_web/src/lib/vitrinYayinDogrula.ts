import type { SupabaseClient } from "@supabase/supabase-js";
import { revalidateTag } from "next/cache";

export interface TuketiciGorunumu {
  gorunur: boolean;
  sebep?: string;
}

export async function tuketicideGorunenler(
  admin: SupabaseClient,
  storeId: string,
  urunIdleri: string[],
): Promise<Map<string, TuketiciGorunumu> | null> {
  if (urunIdleri.length === 0) return new Map();
  try {
    const { data, error } = await admin
      .from("products")
      .select("id,name,price_amount,image_urls")
      .eq("store_id", storeId)
      .eq("is_active", true)
      .eq("is_visible", true)
      .in("id", urunIdleri);
    if (error || !Array.isArray(data)) return null;

    const gorunenler = new Map<string, Record<string, unknown>>(
      data.map((kayit) => [String(kayit.id), kayit as Record<string, unknown>]),
    );
    const sonuc = new Map<string, TuketiciGorunumu>();
    for (const id of urunIdleri) {
      const kayit = gorunenler.get(id);
      if (!kayit) {
        sonuc.set(id, { gorunur: false, sebep: "Ürün vitrin sorgusunda görünmüyor." });
        continue;
      }
      const fiyat = Number(kayit.price_amount);
      const gorseller = Array.isArray(kayit.image_urls) ? kayit.image_urls : [];
      if (!String(kayit.name ?? "").trim()) {
        sonuc.set(id, { gorunur: false, sebep: "Ürün adı vitrinde boş görünüyor." });
      } else if (!(fiyat > 0)) {
        sonuc.set(id, { gorunur: false, sebep: "Vitrinde satış fiyatı görünmüyor." });
      } else if (gorseller.length === 0) {
        sonuc.set(id, { gorunur: false, sebep: "Vitrinde ürün fotoğrafı görünmüyor." });
      } else {
        sonuc.set(id, { gorunur: true });
      }
    }
    return sonuc;
  } catch (hata) {
    console.error(
      "[vitrinYayinDogrula] tuketici sorgusu dogrulanamadi:",
      hata instanceof Error ? hata.message : hata,
    );
    return null;
  }
}

export function vitrinOnbelleginiYenile(slug: string): void {
  if (!slug) return;
  for (const etiket of [`store-${slug}`, `products-${slug}`]) {
    try {
      revalidateTag(etiket, { expire: 0 });
    } catch (hata) {
      console.warn(
        "[vitrinYayinDogrula] onbellek yenilenemedi:",
        etiket,
        hata instanceof Error ? hata.message : hata,
      );
    }
  }
}
