import { unstable_cache } from "next/cache";
import { supabase } from "./supabase";
import { BUSINESS_CATEGORIES } from "./businessCategories";

/**
 * Kategori şablon görselleri — ana sayfadaki katalog ve `/kesfet/[kategori]`
 * sayfaları için tek kaynak.
 *
 * Flutter tarafı bu veriyi kategori BAŞINA bir sorguyla çekiyor
 * (`landing_template_catalog.dart` 20 kategori için 20 tur atıyor). Sunucu
 * tarafında tek sorgu yeter; sonuç zaten 5 dakika önbellekleniyor.
 *
 * Yetki: `category_image_templates` üzerinde `category_templates_select_public`
 * politikası anon rolüne `is_active = true` satırları açıyor ve görseller
 * herkese açık `category-templates` kovasında. Bu yüzden anon istemci doğru
 * seçim — `getSupabaseAdmin()` burada kullanılmaz.
 *
 * ÖLÇÜM (2026-08-26): 19 kanonik kategorinin HEPSİNDE en az 3 kapak görseli
 * var (toplam 326 aktif satır). Yani gerçek veri her kategori için mevcut;
 * Flutter'daki Unsplash yedek haritası web'e taşınmadı. Sorgunun tamamen
 * başarısız olduğu durumda kartlar görselsiz ama biçimli görünür.
 */

export type SablonGorseli = {
  id: string;
  url: string;
  kucukUrl: string | null;
  baslik: string | null;
  tur: "cover" | "gallery" | "product" | "logo_placeholder";
};

export type KategoriSablonu = {
  kategoriKimligi: string;
  etiket: string;
  kapaklar: SablonGorseli[];
  galeri: SablonGorseli[];
  urunler: SablonGorseli[];
  toplam: number;
};

type SatirTipi = {
  id: string;
  category_key: string;
  category_label: string | null;
  image_type: string;
  image_url: string;
  thumbnail_url: string | null;
  title: string | null;
};

// DİKKAT: `unstable_cache` dönüşü JSON'a çevirip saklıyor. Buradan `Map`
// dönmek derlemede "a.get is not a function" ile patlar — önbellekten geri
// gelen şey düz bir nesnedir. Bu yüzden önbelleklenen değer DİZİ; harita
// önbelleğin dışında kuruluyor.
async function _sablonlariGetir(): Promise<KategoriSablonu[]> {
  const { data, error } = await supabase
    .from("category_image_templates")
    .select(
      "id,category_key,category_label,image_type,image_url,thumbnail_url,title"
    )
    .eq("is_active", true)
    .order("display_order", { ascending: true });

  const sonuc = new Map<string, KategoriSablonu>();
  for (const kategori of BUSINESS_CATEGORIES) {
    sonuc.set(kategori.id, {
      kategoriKimligi: kategori.id,
      etiket: kategori.label,
      kapaklar: [],
      galeri: [],
      urunler: [],
      toplam: 0,
    });
  }

  if (error || !data) {
    if (error) {
      console.error("[categoryTemplates] sorgu başarısız:", error.message);
    }
    return [...sonuc.values()];
  }

  for (const satir of data as SatirTipi[]) {
    const kayit = sonuc.get(satir.category_key);
    if (!kayit) continue; // kanonik olmayan anahtar — yok sayılır

    const gorsel: SablonGorseli = {
      id: satir.id,
      url: satir.image_url,
      kucukUrl: satir.thumbnail_url,
      baslik: satir.title,
      tur: satir.image_type as SablonGorseli["tur"],
    };

    if (satir.image_type === "cover") kayit.kapaklar.push(gorsel);
    else if (satir.image_type === "gallery") kayit.galeri.push(gorsel);
    else if (satir.image_type === "product") kayit.urunler.push(gorsel);
    else continue;

    kayit.toplam += 1;
  }

  return [...sonuc.values()];
}

/** Tüm kanonik kategoriler, şablon görselleriyle. Boş kategori de döner. */
export const kategoriSablonlariniGetir = () =>
  unstable_cache(_sablonlariGetir, ["category-templates"], {
    tags: ["category-templates"],
    revalidate: 300,
  })();

/** Kimliğe göre aramak için harita. Önbelleğin DIŞINDA kurulur (yukarıdaki not). */
export async function kategoriSablonHaritasi(): Promise<
  Map<string, KategoriSablonu>
> {
  const liste = await kategoriSablonlariniGetir();
  return new Map(liste.map((kayit) => [kayit.kategoriKimligi, kayit]));
}

/** Tek kategori. Bilinmeyen kimlik için `null`. */
export async function kategoriSablonuGetir(
  kategoriKimligi: string
): Promise<KategoriSablonu | null> {
  const harita = await kategoriSablonHaritasi();
  return harita.get(kategoriKimligi) ?? null;
}
