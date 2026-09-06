import { supabase } from "@/lib/supabase";
import type { BlogLocationScope } from "@/lib/blogTaxonomy";

/**
 * VIXREX BLOGU — merkezi public okuma katmanı.
 *
 * `store_articles` yalnız esnaf vitrinlerine aittir ve bu akışta kullanılmaz.
 * Public okuma iki kat fail-closed korunur:
 * 1. DB RLS yalnız status='published' satırlarını açar.
 * 2. Bu sorgular da status='published' filtresini açıkça uygular.
 */

export type BlogIlceHedefi = {
  province_code: string;
  district_name: string;
};

export type BlogYazisi = {
  slug: string;
  baslik: string;
  ozet: string;
  govde: string;
  kapakGorseli: string | null;
  yayinTarihi: string;
  guncellemeTarihi: string;
  okumaDakika: number;
  konu: string | null;
  amac: string | null;
  sektorler: string[];
  konumKapsami: BlogLocationScope;
  ilKodlari: string[];
  ilceHedefleri: BlogIlceHedefi[];
  etiketler: string[];
  provenance: string;
  kaynakUrl: string[];
};

export type BlogYaziFiltreleri = {
  konu?: string;
  sektor?: string;
  ilKodu?: string;
  etiket?: string;
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
  primary_topic: string | null;
  purpose: string | null;
  sector_ids: string[] | null;
  location_scope: BlogLocationScope | null;
  province_codes: string[] | null;
  district_targets: BlogIlceHedefi[] | null;
  tags: string[] | null;
  provenance: string | null;
  source_urls: string[] | null;
};

const PUBLIC_SELECT =
  "slug,title,summary,content,cover_image_url,reading_minutes,published_at,updated_at,primary_topic,purpose,sector_ids,location_scope,province_codes,district_targets,tags,provenance,source_urls";

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
    konu: row.primary_topic,
    amac: row.purpose,
    sektorler: row.sector_ids ?? [],
    konumKapsami: row.location_scope ?? "national",
    ilKodlari: row.province_codes ?? [],
    ilceHedefleri: Array.isArray(row.district_targets) ? row.district_targets : [],
    etiketler: row.tags ?? [],
    provenance: row.provenance ?? "vixrex-editorial",
    kaynakUrl: row.source_urls ?? [],
  };
}

function hataMesaji(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

/** Yalnız yayındaki Vixrex yazıları, yeniden eskiye sıralı ve isteğe bağlı filtreli. */
export async function yayindakiYazilar(
  filtreler: BlogYaziFiltreleri = {},
): Promise<BlogYazisi[]> {
  try {
    let sorgu = supabase
      .from("vixrex_blog_articles")
      .select(PUBLIC_SELECT)
      .eq("status", "published");

    if (filtreler.konu) sorgu = sorgu.eq("primary_topic", filtreler.konu);
    if (filtreler.sektor) sorgu = sorgu.contains("sector_ids", [filtreler.sektor]);
    if (filtreler.ilKodu) sorgu = sorgu.contains("province_codes", [filtreler.ilKodu]);
    if (filtreler.etiket) sorgu = sorgu.contains("tags", [filtreler.etiket]);

    const { data, error } = await sorgu.order("published_at", { ascending: false });

    if (error) {
      console.error("[vixrex-blog] published list failed:", error.message);
      return [];
    }

    return ((data ?? []) as unknown as VixrexBlogRow[]).map(satiriYaziyaDonustur);
  } catch (error) {
    console.error("[vixrex-blog] published list unavailable:", hataMesaji(error));
    return [];
  }
}

/** Yayındaki bir Vixrex yazısını slug ile bulur. Taslakları asla döndürmez. */
export async function yaziyiBul(slug: string): Promise<BlogYazisi | undefined> {
  const temizSlug = slug.trim();
  if (!temizSlug) return undefined;

  try {
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
  } catch (error) {
    console.error("[vixrex-blog] article unavailable:", hataMesaji(error));
    return undefined;
  }
}

/** Yalnız iki ucu da yayında olan ilişkili merkezi yazıları döndürür. */
export async function ilgiliYazilar(slug: string): Promise<BlogYazisi[]> {
  const temizSlug = slug.trim();
  if (!temizSlug) return [];

  try {
    const { data: article, error: articleError } = await supabase
      .from("vixrex_blog_articles")
      .select("id")
      .eq("slug", temizSlug)
      .eq("status", "published")
      .maybeSingle();
    if (articleError || !article) return [];

    const { data: relations, error: relationError } = await supabase
      .from("vixrex_blog_article_relations")
      .select("related_article_id")
      .eq("article_id", article.id);
    if (relationError || !relations?.length) return [];

    const ids = relations.map((relation) => relation.related_article_id);
    const { data, error } = await supabase
      .from("vixrex_blog_articles")
      .select(PUBLIC_SELECT)
      .in("id", ids)
      .eq("status", "published")
      .order("published_at", { ascending: false });
    if (error) return [];

    return ((data ?? []) as unknown as VixrexBlogRow[]).map(satiriYaziyaDonustur);
  } catch (error) {
    console.error("[vixrex-blog] related articles unavailable:", hataMesaji(error));
    return [];
  }
}

/** Blog yüzeyinin görünür olup olmadığı. */
export async function blogYayindaMi(): Promise<boolean> {
  try {
    const { count, error } = await supabase
      .from("vixrex_blog_articles")
      .select("id", { count: "exact", head: true })
      .eq("status", "published");

    if (error) {
      console.error("[vixrex-blog] publish state failed:", error.message);
      return false;
    }

    return (count ?? 0) > 0;
  } catch (error) {
    console.error("[vixrex-blog] publish state unavailable:", hataMesaji(error));
    return false;
  }
}
