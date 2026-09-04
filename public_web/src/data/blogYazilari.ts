import { supabase } from "@/lib/supabase";

/**
 * VIXREX BLOGU — merkezi public okuma katmanı.
 *
 * Katman 1'de platform yazıları artık `vixrex_blog_articles` tablosundan
 * okunur. `store_articles` yalnız esnaf vitrinlerine aittir ve bu akışta
 * kullanılmaz.
 *
 * Güvenlik sınırı iki katlıdır:
 * 1. DB RLS anon/authenticated için yalnız `status='published'` satırlarını açar.
 * 2. Public sorgular yine açıkça `status='published'` filtresi uygular.
 *
 * Sorgu hatasında taslak/public karışıklığı yaratmak yerine boş sonuç döner;
 * `/blog` mevcut davranışındaki gibi 404 olur ve sitemap yanlış URL üretmez.
 */

export type BlogYazisi = {
  slug: string;
  baslik: string;
  ozet: string;
  govde: string;
  kapakGorseli: string | null;
  yayinTarihi: string;
  guncellemeTarihi: string;
  okumaDakika: number;
};

type VixrexBlogRow = {
  slug: string;
  title: string;
  summary: string;
  content: string;
  cover_image_url: string | null;
  reading_minutes: number;
  published_at: string;
  updated_at: string;
};

const PUBLIC_SELECT =
  "slug,title,summary,content,cover_image_url,reading_minutes,published_at,updated_at";

function satiriYaziyaDonustur(row: VixrexBlogRow): BlogYazisi {
  return {
    slug: row.slug,
    baslik: row.title,
    ozet: row.summary,
    govde: row.content,
    kapakGorseli: row.cover_image_url,
    yayinTarihi: row.published_at,
    guncellemeTarihi: row.updated_at,
    okumaDakika: row.reading_minutes,
  };
}

/** Yalnız yayındaki Vixrex yazıları, yeniden eskiye sıralı. */
export async function yayindakiYazilar(): Promise<BlogYazisi[]> {
  const { data, error } = await supabase
    .from("vixrex_blog_articles")
    .select(PUBLIC_SELECT)
    .eq("status", "published")
    .order("published_at", { ascending: false });

  if (error) {
    console.error("[vixrex-blog] published list failed:", error.message);
    return [];
  }

  return ((data ?? []) as unknown as VixrexBlogRow[]).map(satiriYaziyaDonustur);
}

/** Yayındaki bir Vixrex yazısını slug ile bulur. Taslakları asla döndürmez. */
export async function yaziyiBul(slug: string): Promise<BlogYazisi | undefined> {
  const temizSlug = slug.trim();
  if (!temizSlug) return undefined;

  const { data, error } = await supabase
    .from("vixrex_blog_articles")
    .select(PUBLIC_SELECT)
    .eq("slug", temizSlug)
    .eq("status", "published")
    .maybeSingle();

  if (error) {
    console.error("[vixrex-blog] article read failed:", error.message);
    return undefined;
  }

  return data ? satiriYaziyaDonustur(data as unknown as VixrexBlogRow) : undefined;
}

/** Blog yüzeyinin görünür olup olmadığı. */
export async function blogYayindaMi(): Promise<boolean> {
  const { count, error } = await supabase
    .from("vixrex_blog_articles")
    .select("id", { count: "exact", head: true })
    .eq("status", "published");

  if (error) {
    console.error("[vixrex-blog] publish state failed:", error.message);
    return false;
  }

  return (count ?? 0) > 0;
}
