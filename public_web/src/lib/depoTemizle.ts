import { getSupabaseAdmin } from "@/lib/supabaseAdmin";

/**
 * SİLİNEN VİTRİNİN GÖRSELLERİNİ DEPODAN KALDIRIR.
 *
 * NEDEN VAR (2026-08-28 ölçümü): `shelf-images` kovasındaki 328 dosyanın
 * 328'i sahipsizdi — 120 MB, deponun %77'si. Hepsi silinmiş test
 * vitrinlerinden kalmıştı. Kod tabanında vitrin/hesap silinirken depo
 * temizleyen tek satır yoktu; 100 vitrinde aynı çöp yeniden birikirdi.
 *
 * AYRICA HUKUKİ: 28 Ağustos'ta yayına alınan Veri Silme metni "hesap
 * silindiğinde galeri görselleriniz silinir" diyor. Bu dosya o taahhüdü
 * yerine getiriyor.
 *
 * Depo yazma service-role ister; bu yüzden yönetici istemcisi kullanılıyor.
 * Silme YALNIZ ilgili RPC başarılı olduktan sonra çağrılmalı — RPC sahiplik
 * kontrolünü kendisi yapıyor, burada ikinci bir yetki kontrolü yok.
 */

const KOVA = "shelf-images";
const SAYFA = 100;

/** Bir klasörün altındaki tüm dosya yollarını, alt klasörler dahil toplar. */
async function dosyalariTopla(
  admin: ReturnType<typeof getSupabaseAdmin>,
  onEk: string,
  derinlik = 0
): Promise<string[]> {
  // Yol deseni en fazla `<slug>/owner/<alan>/dosya` — dört seviye yeter.
  // Sınır, beklenmedik bir yapıda sonsuz özyinelemeyi keser.
  if (derinlik > 4) return [];

  const yollar: string[] = [];
  let offset = 0;

  for (;;) {
    const { data, error } = await admin.storage
      .from(KOVA)
      .list(onEk, { limit: SAYFA, offset });

    if (error || !data || data.length === 0) break;

    for (const oge of data) {
      const tamYol = onEk ? `${onEk}/${oge.name}` : oge.name;
      // Supabase klasörleri `id: null` ile döner — gerçek nesne değildir.
      if (oge.id === null) {
        yollar.push(...(await dosyalariTopla(admin, tamYol, derinlik + 1)));
      } else {
        yollar.push(tamYol);
      }
    }

    if (data.length < SAYFA) break;
    offset += SAYFA;
  }

  return yollar;
}

/**
 * Vitrine ait tüm görselleri siler. Kaç dosya silindiğini döner.
 *
 * Hata fırlatmaz: bu çağrı vitrin/hesap zaten silindikten SONRA yapılıyor.
 * Depo temizliği başarısız olursa kullanıcıya "silinemedi" demek yanlış
 * olur — silinmiştir. Başarısızlık loglanır, sonuç 0 döner.
 */
export async function vitrinGorsellerinisil(slug: string): Promise<number> {
  const guvenliSlug = slug.replace(/[^a-zA-Z0-9-]/g, "");
  if (!guvenliSlug) return 0;

  try {
    const admin = getSupabaseAdmin();
    const yollar = await dosyalariTopla(admin, guvenliSlug);
    if (yollar.length === 0) return 0;

    let silinen = 0;
    for (let i = 0; i < yollar.length; i += SAYFA) {
      const parca = yollar.slice(i, i + SAYFA);
      const { error } = await admin.storage.from(KOVA).remove(parca);
      if (error) {
        console.error("[depo-temizle] silme hatası:", error.message);
        break;
      }
      silinen += parca.length;
    }
    return silinen;
  } catch (hata) {
    console.error(
      "[depo-temizle] beklenmeyen hata:",
      hata instanceof Error ? hata.message : hata
    );
    return 0;
  }
}
