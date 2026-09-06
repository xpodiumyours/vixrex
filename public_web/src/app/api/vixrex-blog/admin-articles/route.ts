import { revalidatePath } from "next/cache";
import { NextResponse, type NextRequest } from "next/server";
import {
  BLOG_LOCATION_SCOPES,
  BLOG_TAXONOMY_RULES,
  normalizeBlogTags,
  validBlogPurpose,
  validBlogSectorIds,
  validBlogTopic,
  type BlogLocationScope,
} from "@/lib/blogTaxonomy";
import { platformAdminDogrula } from "@/lib/platformAdminAuth";

export const dynamic = "force-dynamic";

type Govde = Record<string, unknown>;

type DistrictTarget = {
  province_code: string;
  district_name: string;
};

function govdeOku(request: NextRequest): Promise<Govde | null> {
  return request.json().catch(() => null) as Promise<Govde | null>;
}

function slugUret(value: string): string {
  return value
    .trim()
    .toLocaleLowerCase("tr-TR")
    .replace(/[çğıöşü]/g, (char) =>
      ({ ç: "c", ğ: "g", ı: "i", ö: "o", ş: "s", ü: "u" }[char] ?? char),
    )
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "")
    .slice(0, 80);
}

function metin(value: unknown, max = 10000): string {
  return typeof value === "string" ? value.trim().slice(0, max) : "";
}

function metinDizisi(value: unknown, max: number): string[] {
  if (!Array.isArray(value)) return [];
  const unique = new Set<string>();
  for (const item of value) {
    if (typeof item !== "string") continue;
    const normalized = item.trim();
    if (normalized) unique.add(normalized);
    if (unique.size >= max) break;
  }
  return [...unique];
}

function ilKodlari(value: unknown): string[] | null {
  const values = metinDizisi(value, BLOG_TAXONOMY_RULES.maxProvinceCodesPerArticle);
  if (values.some((code) => !/^\d{2}$/.test(code))) return null;
  return values;
}

function ilceHedefleri(value: unknown): DistrictTarget[] | null {
  if (!Array.isArray(value)) return [];
  const result: DistrictTarget[] = [];
  const seen = new Set<string>();
  for (const item of value) {
    if (!item || typeof item !== "object") return null;
    const raw = item as Record<string, unknown>;
    const provinceCode = metin(raw.province_code ?? raw.provinceCode, 2);
    const districtName = metin(raw.district_name ?? raw.districtName, 80);
    if (!/^\d{2}$/.test(provinceCode) || !districtName) return null;
    const key = `${provinceCode}:${districtName.toLocaleLowerCase("tr-TR")}`;
    if (!seen.has(key)) {
      seen.add(key);
      result.push({ province_code: provinceCode, district_name: districtName });
    }
    if (result.length >= 100) break;
  }
  return result;
}

function kaynakUrl(value: unknown): string[] | null {
  const values = metinDizisi(value, 20);
  for (const url of values) {
    try {
      const parsed = new URL(url);
      if (parsed.protocol !== "https:" && parsed.protocol !== "http:") return null;
    } catch {
      return null;
    }
  }
  return values;
}

function metadataOku(govde: Govde) {
  const primaryTopic = metin(govde.primaryTopic, 80);
  const purpose = metin(govde.purpose, 80);
  const sectorIds = metinDizisi(
    govde.sectorIds,
    BLOG_TAXONOMY_RULES.maxSectorIdsPerArticle,
  );
  const locationScopeRaw = metin(govde.locationScope, 20) || "national";
  const locationScope = BLOG_LOCATION_SCOPES.includes(
    locationScopeRaw as BlogLocationScope,
  )
    ? (locationScopeRaw as BlogLocationScope)
    : null;
  const provinceCodes = ilKodlari(govde.provinceCodes);
  const districtTargets = ilceHedefleri(govde.districtTargets);
  const sourceUrls = kaynakUrl(govde.sourceUrls);
  const tags = normalizeBlogTags(
    Array.isArray(govde.tags)
      ? govde.tags.filter((item): item is string => typeof item === "string")
      : [],
  );

  if (primaryTopic && !validBlogTopic(primaryTopic)) {
    return { ok: false as const, hata: "Geçersiz blog konusu." };
  }
  if (purpose && !validBlogPurpose(purpose)) {
    return { ok: false as const, hata: "Geçersiz kullanım amacı." };
  }
  if (!validBlogSectorIds(sectorIds)) {
    return { ok: false as const, hata: "Geçersiz sektör kimliği." };
  }
  if (!locationScope || !provinceCodes || !districtTargets || !sourceUrls) {
    return { ok: false as const, hata: "Geçersiz konum veya kaynak bilgisi." };
  }
  if (locationScope === "province" && provinceCodes.length === 0) {
    return { ok: false as const, hata: "İl hedefi için en az bir il kodu gerekli." };
  }
  if (locationScope === "district" && districtTargets.length === 0) {
    return { ok: false as const, hata: "İlçe hedefi için en az bir ilçe gerekli." };
  }

  return {
    ok: true as const,
    payload: {
      primary_topic: primaryTopic || null,
      purpose: purpose || null,
      sector_ids: sectorIds,
      location_scope: locationScope,
      province_codes: provinceCodes,
      district_targets: districtTargets,
      tags,
      provenance: metin(govde.provenance, 80) || "vixrex-editorial",
      source_urls: sourceUrls,
    },
  };
}

function blogOnbelleginiTemizle(slug?: string) {
  revalidatePath("/blog");
  revalidatePath("/sitemap.xml");
  if (slug) revalidatePath(`/blog/${slug}`);
}

export async function GET(request: NextRequest) {
  const kimlik = await platformAdminDogrula(request);
  if (!kimlik.ok) return kimlik.response;

  const { data, error } = await kimlik.admin
    .from("vixrex_blog_articles")
    .select(
      "id,slug,title,summary,content,cover_image_url,status,reading_minutes,published_at,created_at,updated_at,primary_topic,purpose,sector_ids,location_scope,province_codes,district_targets,tags,provenance,source_urls",
    )
    .order("updated_at", { ascending: false });

  if (error) {
    console.error("[vixrex-blog-admin] list failed:", error.message);
    return NextResponse.json({ hata: "Yazılar getirilemedi." }, { status: 500 });
  }

  return NextResponse.json({ tamam: true, yazilar: data ?? [] });
}

export async function POST(request: NextRequest) {
  const kimlik = await platformAdminDogrula(request);
  if (!kimlik.ok) return kimlik.response;

  const govde = await govdeOku(request);
  if (!govde) return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });

  const title = metin(govde.title, 160);
  if (!title) {
    return NextResponse.json({ hata: "Başlık zorunludur." }, { status: 422 });
  }

  const metadata = metadataOku(govde);
  if (!metadata.ok) {
    return NextResponse.json({ hata: metadata.hata }, { status: 422 });
  }

  const slug = slugUret(metin(govde.slug, 100) || title);
  if (!slug) {
    return NextResponse.json({ hata: "Geçerli bir slug üretilemedi." }, { status: 422 });
  }

  const payload = {
    slug,
    title,
    summary: metin(govde.summary, 500),
    content: metin(govde.content, 200000),
    cover_image_url: metin(govde.coverImageUrl, 2000) || null,
    reading_minutes:
      typeof govde.readingMinutes === "number"
        ? Math.max(1, Math.min(120, Math.round(govde.readingMinutes)))
        : 1,
    status: "draft",
    published_at: null,
    ...metadata.payload,
  };

  const { data, error } = await kimlik.admin
    .from("vixrex_blog_articles")
    .insert(payload)
    .select("id,slug")
    .single();

  if (error) {
    const status = error.code === "23505" ? 409 : 500;
    console.error("[vixrex-blog-admin] create failed:", error.message);
    return NextResponse.json(
      { hata: status === 409 ? "Bu slug zaten kullanılıyor." : "Yazı oluşturulamadı." },
      { status },
    );
  }

  blogOnbelleginiTemizle(data.slug);
  return NextResponse.json({ tamam: true, id: data.id, slug: data.slug });
}

export async function PATCH(request: NextRequest) {
  const kimlik = await platformAdminDogrula(request);
  if (!kimlik.ok) return kimlik.response;

  const govde = await govdeOku(request);
  if (!govde) return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });

  const id = metin(govde.id, 80);
  if (!id) return NextResponse.json({ hata: "Yazı ID zorunludur." }, { status: 422 });

  const { data: mevcut, error: readError } = await kimlik.admin
    .from("vixrex_blog_articles")
    .select("*")
    .eq("id", id)
    .maybeSingle();
  if (readError) {
    return NextResponse.json({ hata: "Yazı doğrulanamadı." }, { status: 500 });
  }
  if (!mevcut) return NextResponse.json({ hata: "Yazı bulunamadı." }, { status: 404 });

  const metadata = metadataOku({
    primaryTopic: govde.primaryTopic ?? mevcut.primary_topic,
    purpose: govde.purpose ?? mevcut.purpose,
    sectorIds: govde.sectorIds ?? mevcut.sector_ids,
    locationScope: govde.locationScope ?? mevcut.location_scope,
    provinceCodes: govde.provinceCodes ?? mevcut.province_codes,
    districtTargets: govde.districtTargets ?? mevcut.district_targets,
    tags: govde.tags ?? mevcut.tags,
    provenance: govde.provenance ?? mevcut.provenance,
    sourceUrls: govde.sourceUrls ?? mevcut.source_urls,
  });
  if (!metadata.ok) {
    return NextResponse.json({ hata: metadata.hata }, { status: 422 });
  }

  const title = govde.title === undefined ? mevcut.title : metin(govde.title, 160);
  const summary = govde.summary === undefined ? mevcut.summary : metin(govde.summary, 500);
  const content = govde.content === undefined ? mevcut.content : metin(govde.content, 200000);
  const status = govde.status === undefined ? mevcut.status : metin(govde.status, 20);
  if (status !== "draft" && status !== "published") {
    return NextResponse.json({ hata: "Durum yalnız draft veya published olabilir." }, { status: 422 });
  }
  if (status === "published") {
    if (!title || !summary || !content || !metadata.payload.primary_topic || !metadata.payload.purpose) {
      return NextResponse.json(
        { hata: "Yayın için başlık, özet, içerik, konu ve amaç zorunludur." },
        { status: 422 },
      );
    }
  }

  const newSlug =
    govde.slug === undefined ? mevcut.slug : slugUret(metin(govde.slug, 100));
  if (!newSlug) return NextResponse.json({ hata: "Geçersiz slug." }, { status: 422 });

  const updatePayload: Record<string, unknown> = {
    title,
    slug: newSlug,
    summary,
    content,
    cover_image_url:
      govde.coverImageUrl === undefined
        ? mevcut.cover_image_url
        : metin(govde.coverImageUrl, 2000) || null,
    reading_minutes:
      govde.readingMinutes === undefined
        ? mevcut.reading_minutes
        : typeof govde.readingMinutes === "number"
          ? Math.max(1, Math.min(120, Math.round(govde.readingMinutes)))
          : mevcut.reading_minutes,
    status,
    published_at:
      status === "published"
        ? mevcut.published_at ?? new Date().toISOString()
        : null,
    ...metadata.payload,
  };

  const { error } = await kimlik.admin
    .from("vixrex_blog_articles")
    .update(updatePayload)
    .eq("id", id);
  if (error) {
    const responseStatus = error.code === "23505" ? 409 : 500;
    console.error("[vixrex-blog-admin] update failed:", error.message);
    return NextResponse.json(
      { hata: responseStatus === 409 ? "Bu slug zaten kullanılıyor." : "Yazı güncellenemedi." },
      { status: responseStatus },
    );
  }

  blogOnbelleginiTemizle(mevcut.slug);
  if (newSlug !== mevcut.slug) blogOnbelleginiTemizle(newSlug);
  return NextResponse.json({ tamam: true, slug: newSlug });
}

export async function DELETE(request: NextRequest) {
  const kimlik = await platformAdminDogrula(request);
  if (!kimlik.ok) return kimlik.response;

  const govde = await govdeOku(request);
  const id = metin(govde?.id, 80);
  if (!id) return NextResponse.json({ hata: "Yazı ID zorunludur." }, { status: 422 });

  const { data: mevcut } = await kimlik.admin
    .from("vixrex_blog_articles")
    .select("slug")
    .eq("id", id)
    .maybeSingle();

  const { error } = await kimlik.admin
    .from("vixrex_blog_articles")
    .delete()
    .eq("id", id);
  if (error) {
    console.error("[vixrex-blog-admin] delete failed:", error.message);
    return NextResponse.json({ hata: "Yazı silinemedi." }, { status: 500 });
  }

  blogOnbelleginiTemizle(mevcut?.slug);
  return NextResponse.json({ tamam: true });
}
