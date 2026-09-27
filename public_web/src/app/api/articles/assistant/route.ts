import { NextResponse, type NextRequest } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { sahipDogrula } from "@/lib/ownerGuard";
import { blogSeoAnalizi, blogYayinEngelleri } from "@/lib/blogSeo";
import { blogSlugUret } from "@/lib/blogSlug";
import {
  blogKonulariUret,
  blogTaslagiUret,
  tazelemeGerektirenler,
  type VitrinOzeti,
} from "@/lib/blogAsistan";

export const dynamic = "force-dynamic";

const VITRIN_ALANLARI =
  "id,slug,name,kategori,business_type,province_name,district_name,address,working_hours,whatsapp";

async function vitrinOzeti(
  admin: ReturnType<typeof getSupabaseAdmin>,
  slug: string
): Promise<VitrinOzeti | null> {
  const { data, error } = await admin
    .from("stores")
    .select(VITRIN_ALANLARI)
    .eq("slug", slug)
    .maybeSingle();

  if (error) {
    console.error("[articles-assistant] store read failed:", error.message);
    return null;
  }
  if (!data) return null;

  const { data: urunler, error: urunHatasi } = await admin
    .from("products")
    .select("name")
    .eq("store_id", data.id)
    .limit(8);

  if (urunHatasi) {
    console.error("[articles-assistant] products read failed:", urunHatasi.message);
  }

  return {
    slug: data.slug ?? slug,
    ad: data.name ?? "",
    kategori: data.kategori ?? data.business_type ?? "",
    il: data.province_name ?? "",
    ilce: data.district_name ?? "",
    adres: data.address ?? "",
    calismaSaatleri: data.working_hours ?? "",
    whatsapp: data.whatsapp ?? "",
    urunler: (urunler ?? [])
      .map((urun) => urun.name ?? "")
      .filter((ad) => ad.trim().length > 0),
  };
}

export async function GET(request: NextRequest) {
  const slug = new URL(request.url).searchParams.get("slug")?.trim() ?? "";
  if (!slug) {
    return NextResponse.json({ hata: "Vitrin belirtilmedi." }, { status: 400 });
  }

  const auth = await sahipDogrula(slug);
  if (!auth.ok) {
    return NextResponse.json({ hata: auth.error }, { status: 401 });
  }

  const admin = getSupabaseAdmin();
  const vitrin = await vitrinOzeti(admin, slug);
  if (!vitrin) {
    return NextResponse.json({ hata: "Vitrin bulunamadı." }, { status: 404 });
  }

  const { data: yazilar, error } = await admin
    .from("store_articles")
    .select("slug,title,status,updated_at")
    .eq("store_slug", slug);

  if (error) {
    console.error("[articles-assistant] article list failed:", error.message);
    return NextResponse.json({ hata: "Yazılar okunamadı." }, { status: 500 });
  }

  return NextResponse.json({
    tamam: true,
    konular: blogKonulariUret(vitrin),
    tazeleme: tazelemeGerektirenler(
      (yazilar ?? []) as {
        slug: string;
        title: string;
        status: string;
        updated_at: string;
      }[]
    ),
  });
}

export async function POST(request: NextRequest) {
  let govde: Record<string, unknown>;
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  if (!slug) {
    return NextResponse.json({ hata: "Vitrin belirtilmedi." }, { status: 400 });
  }

  const auth = await sahipDogrula(slug);
  if (!auth.ok) {
    return NextResponse.json({ hata: auth.error }, { status: 401 });
  }

  const admin = getSupabaseAdmin();
  const vitrin = await vitrinOzeti(admin, slug);
  if (!vitrin) {
    return NextResponse.json({ hata: "Vitrin bulunamadı." }, { status: 404 });
  }

  const konu = typeof govde.konu === "string" ? govde.konu.trim() : "";
  const taslak = blogTaslagiUret(vitrin, konu);
  const analiz = blogSeoAnalizi({
    title: taslak.baslik,
    summary: taslak.ozet,
    content: taslak.icerik,
    topic: taslak.hedefKonu,
    city: taslak.hedefSehir,
    hasCover: false,
  });
  const engeller = blogYayinEngelleri({
    title: taslak.baslik,
    summary: taslak.ozet,
    content: taslak.icerik,
    topic: taslak.hedefKonu,
    city: taslak.hedefSehir,
    hasCover: false,
  });

  if (engeller.length) {
    console.error("[articles-assistant] taslak standardı tutmadı:", engeller.join(" "));
    return NextResponse.json(
      { hata: "Taslak yayın standardını tutmadı.", engeller },
      { status: 500 }
    );
  }

  let articleSlug = blogSlugUret(taslak.baslik);
  const { data: mevcut, error: slugHatasi } = await admin
    .from("store_articles")
    .select("id")
    .eq("store_slug", slug)
    .eq("slug", articleSlug)
    .maybeSingle();

  if (slugHatasi) {
    console.error("[articles-assistant] slug check failed:", slugHatasi.message);
    return NextResponse.json({ hata: "Taslak oluşturulamadı." }, { status: 500 });
  }
  if (mevcut) {
    articleSlug = `${articleSlug}-${Date.now().toString(36)}`;
  }

  const { error } = await admin.from("store_articles").insert({
    store_slug: slug,
    title: taslak.baslik,
    summary: taslak.ozet,
    content: taslak.icerik,
    article_type: taslak.tur,
    target_topic: taslak.hedefKonu,
    target_city: taslak.hedefSehir,
    seo_score: analiz.score,
    seo_errors: [...taslak.notlar, ...analiz.recommendations],
    status: "draft",
    slug: articleSlug,
  });

  if (error) {
    console.error("[articles-assistant] insert failed:", error.message);
    return NextResponse.json({ hata: "Taslak oluşturulamadı." }, { status: 500 });
  }

  return NextResponse.json({
    tamam: true,
    slug: articleSlug,
    baslik: taslak.baslik,
    seoScore: analiz.score,
    notlar: taslak.notlar,
  });
}
