import { Metadata } from "next";
import { Suspense } from "react";
import { notFound } from "next/navigation";
import Link from "next/link";
import Image from "next/image";
import { unstable_cache } from "next/cache";
import { supabase } from "@/lib/supabase";
import {
  deriveCollections,
  getProductUrlSlug,
  normalizeExternalUrl,
  normalizeWhatsappDigits,
  safeParseJson,
  type ProductItem,
} from "@/lib/products";
import { buildSiteUrl, getSiteUrl } from "@/lib/siteUrl";
import ProductCatalog from "./ProductCatalog";

export const revalidate = 60;

interface PageProps {
  params: Promise<{ slug: string }>;
}

interface GalleryItem {
  id?: string;
  imageUrl: string;
  title?: string;
}

interface MarketplaceLinkItem {
  id?: string;
  platform: string;
  url: string;
  subtitle?: string;
}

interface PublicStoreRow {
  id: string;
  slug: string;
  name: string;
  business_type: string | null;
  description: string | null;
  corporate_bio: string | null;
  whatsapp: string | null;
  instagram: string | null;
  website: string | null;
  address: string | null;
  status: string | null;
  marketplace_links: unknown;
  gallery_items: unknown;
  products: unknown;
  references_link: string | null;
  shelf_image_url: string | null;
  logo_url: string | null;
  working_hours: unknown;
  is_published: boolean;
  kategori: string | null;
  latitude: number | null;
  longitude: number | null;
  google_business_link: string | null;
  product_storage_version: number | null;
}

interface ProductRow {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  price_text: string | null;
  price_amount: number | null;
  currency: string;
  stock_status: string | null;
  image_urls: string[];
  category_id: string | null;
  is_visible: boolean;
  is_active: boolean;
  source_type: string;
  sort_order: number;
}

interface CategoryRow {
  id: string;
  name: string;
}

const PUBLIC_STORE_SELECT =
  "id,slug,name,business_type,description,corporate_bio,whatsapp,instagram," +
  "website,address,status,marketplace_links,gallery_items,products," +
  "references_link,shelf_image_url,logo_url,working_hours,is_published," +
  "kategori,latitude,longitude,google_business_link,product_storage_version";

async function _getStoreData(slug: string) {
  try {
    const { data: storeData, error: storeError } = await supabase
      .from("stores")
      .select(PUBLIC_STORE_SELECT)
      .eq("slug", slug)
      .eq("is_published", true)
      .maybeSingle();

    if (storeError) {
      console.error(`Public store query failed for slug=${slug}:`, storeError);
      throw storeError;
    }
    if (!storeData) return null;
    const store = storeData as unknown as PublicStoreRow;

    const storeId = store.id;

    const [bookingResult, articlesResult, categoryResult, productResult] = await Promise.all([
      supabase
        .from("booking_settings")
        .select("*")
        .eq("store_slug", slug)
        .maybeSingle(),
      supabase
        .from("store_articles")
        .select("*")
        .eq("store_slug", slug)
        .eq("status", "published")
        .order("published_at", { ascending: false, nullsFirst: false })
        .order("created_at", { ascending: false })
        .limit(3),
      supabase
        .from("product_categories")
        .select("id,name")
        .eq("store_id", storeId)
        .eq("is_active", true)
        .order("sort_order"),
      supabase
        .from("products")
        .select(
          "id,name,slug,description,price_text,price_amount,currency,stock_status,image_urls,category_id,is_visible,is_active,source_type,sort_order"
        )
        .eq("store_id", storeId)
        .eq("is_active", true)
        .eq("is_visible", true)
        .order("sort_order", { ascending: true })
        .order("id", { ascending: true }),
    ]);

    const categories = (categoryResult.data || []) as CategoryRow[];

    const categoryMap = new Map<string, string>();
    categories.forEach((cat) => {
      categoryMap.set(cat.id, cat.name);
    });

    const visibleProducts = (productResult.data || [])
      .filter((p: Record<string, unknown>) => (p.name as string)?.trim())
      .map((p: Record<string, unknown>) => ({
        id: p.id as string,
        slug: p.slug as string,
        name: p.name as string,
        description: (p.description as string) || undefined,
        price:
          (p.price_text as string) ||
          (p.price_amount != null
            ? `${p.price_amount} ${p.currency}`
            : undefined),
        imageUrls: Array.isArray(p.image_urls) ? (p.image_urls as string[]) : [],
        categoryId: (p.category_id as string) || undefined,
        category:
          (p.category_id ? categoryMap.get(p.category_id as string) : undefined) ||
          undefined,
        stockStatus: (p.stock_status as string) || undefined,
        isVisible: p.is_visible as boolean,
        source: p.source_type as string,
      }));

    return {
      store,
      bookingSettings: bookingResult.data,
      articles: articlesResult.data || [],
      visibleProducts,
      categories,
    };
  } catch (err) {
    console.error(`Store data fetch error for slug=${slug}:`, err);
    throw err;
  }
}

const getStoreData = (slug: string) =>
  unstable_cache(
    () => _getStoreData(slug),
    [`store-${slug}`],
    { tags: [`store-${slug}`, `products-${slug}`], revalidate: 60 }
  )();

export async function generateMetadata(props: PageProps): Promise<Metadata> {
  const params = await props.params;
  const data = await getStoreData(params.slug);
  if (!data) return { robots: { index: false, follow: false } };

  const { store } = data;
  const title = `${store.name} - Vixrex`;
  const description =
    store.description || store.corporate_bio || `${store.name} Dijital Vitrini`;
  const image = store.shelf_image_url || store.logo_url || "";
  const canonicalPath = `/v/${store.slug}`;
  const canonicalUrl = buildSiteUrl(canonicalPath);
  const ogImages = image
    ? [{ url: image.startsWith("http") ? image : buildSiteUrl(image) }]
    : [];

  return {
    title,
    description,
    robots: { index: true, follow: true },
    alternates: {
      canonical: canonicalPath,
    },
    openGraph: {
      title,
      description,
      url: canonicalUrl,
      siteName: "Vixrex",
      locale: "tr_TR",
      images: ogImages,
      type: "profile",
    },
    twitter: {
      card: "summary_large_image",
      title,
      description,
      images: ogImages.map((item) => item.url),
    },
  };
}

export default async function StorePage(props: PageProps) {
  const params = await props.params;
  const data = await getStoreData(params.slug);
  if (!data) {
    notFound();
  }

  const { store, bookingSettings, articles, visibleProducts, categories } = data;

  const galleryItems = safeParseJson<GalleryItem>(store.gallery_items);
  const marketplaceLinks = safeParseJson<MarketplaceLinkItem>(store.marketplace_links);

  const siteUrl = getSiteUrl();
  const publicUrl = buildSiteUrl(`/v/${store.slug}`);
  const heroImage =
    store.shelf_image_url || store.logo_url || "";
  const hasPhysicalLocation =
    store.address && store.latitude != null && store.longitude != null;
  const isBookingEnabled = bookingSettings?.is_enabled ?? false;
  const phoneDigits = normalizeWhatsappDigits(store.whatsapp);
  const waBaseUrl = phoneDigits ? `https://wa.me/${phoneDigits}` : null;
  const whatsappActionUrl = waBaseUrl
    ? `${waBaseUrl}?text=${encodeURIComponent(`Merhaba, ${store.name} vitrininiz hakkında bilgi almak istiyorum.`)}`
    : null;
  const instagramValue = String(store.instagram || "").trim();
  const instagramUrl = (() => {
    if (!instagramValue) return null;
    if (/instagram\.com/i.test(instagramValue)) {
      return normalizeExternalUrl(instagramValue);
    }
    const username = instagramValue.replace(/^@/, "").replace(/\//g, "").trim();
    return username ? `https://instagram.com/${username}` : null;
  })();
  const websiteUrl = normalizeExternalUrl(store.website);
  const referencesUrl = normalizeExternalUrl(store.references_link);
  const mapsUrl = hasPhysicalLocation
    ? `https://www.google.com/maps/search/?api=1&query=${store.latitude},${store.longitude}`
    : store.address
      ? `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(store.address)}`
      : null;
  const displayDescription =
    store.description ||
    store.corporate_bio ||
    "Ürünleri, iletişim bilgileri ve konumu tek dijital vitrinde inceleyin.";
  const collections = deriveCollections(visibleProducts);

  const categoryLower = (store.kategori || "").toLowerCase();
  let businessType = "LocalBusiness";
  if (categoryLower.includes("kuaför") || categoryLower.includes("hair")) {
    businessType = "HairSalon";
  } else if (
    categoryLower.includes("güzellik") ||
    categoryLower.includes("beauty") ||
    categoryLower.includes("bakım")
  ) {
    businessType = "BeautySalon";
  }

  const breadcrumbSchema = {
    "@type": "BreadcrumbList",
    "@id": `${publicUrl}#breadcrumb`,
    itemListElement: [
      {
        "@type": "ListItem",
        position: 1,
        name: "Ana Sayfa",
        item: siteUrl,
      },
      {
        "@type": "ListItem",
        position: 2,
        name: store.name,
        item: publicUrl,
      },
    ],
  };

  const openingHoursSpecification = store.working_hours
    ? Object.entries(store.working_hours as Record<string, { start: string; end: string; active: boolean }>)
        .filter(([, hours]) => hours.active)
        .map(([day, hours]) => ({
          "@type": "OpeningHoursSpecification",
          dayOfWeek: [
            "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"
          ][parseInt(day) - 1],
          opens: hours.start,
          closes: hours.end,
        }))
    : undefined;

  const jsonLd = {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": businessType,
        "@id": `${publicUrl}#business`,
        name: store.name,
        description: store.description || store.corporate_bio,
        image: store.shelf_image_url || store.logo_url,
        logo: store.logo_url,
        telephone: phoneDigits ? `+${phoneDigits}` : undefined,
        url: publicUrl,
        address: hasPhysicalLocation
          ? {
              "@type": "PostalAddress",
              streetAddress: store.address,
              addressCountry: "TR",
            }
          : undefined,
        geo: hasPhysicalLocation
          ? {
              "@type": "GeoCoordinates",
              latitude: store.latitude,
              longitude: store.longitude,
            }
          : undefined,
        openingHoursSpecification: openingHoursSpecification,
      },
      {
        "@type": "WebPage",
        "@id": `${publicUrl}#webpage`,
        url: publicUrl,
        name: `${store.name} | Vixrex`,
        description: store.description || store.corporate_bio,
      },
      ...(visibleProducts.length > 0
        ? [
            {
              "@type": "ItemList",
              "@id": `${publicUrl}#products`,
              name: `${store.name} ürünleri`,
              itemListElement: visibleProducts.slice(0, 12).map((product, index) => {
                return {
                  "@type": "ListItem",
                  position: index + 1,
                  url: buildSiteUrl(
                    `/v/${store.slug}/urun/${getProductUrlSlug(product, index)}`
                  ),
                  name: product.name,
                };
              }),
            },
          ]
        : []),
      breadcrumbSchema,
    ],
  };

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />

      <div className="min-h-screen bg-[#071322] px-3 py-4 text-white sm:px-6 sm:py-8">
        <main className="mx-auto flex w-full max-w-[1180px] flex-col gap-5 animate-fade-in">
          <section className="relative overflow-hidden rounded-[28px] border border-[#25415F] bg-[#0E1B2E] shadow-[0_24px_70px_rgba(0,0,0,0.28)]">
            {heroImage && (
              <Image
                src={heroImage}
                alt={`${store.name} vitrin görseli`}
                fill
                className="object-cover opacity-55"
                priority
              />
            )}
            <div className="absolute inset-0 bg-[linear-gradient(90deg,rgba(7,19,34,0.96),rgba(7,19,34,0.78),rgba(7,19,34,0.48))]" />
            <div className="relative flex min-h-[390px] flex-col justify-between gap-10 p-5 sm:p-8 lg:p-9">
              <div className="flex items-center justify-between gap-3">
                <a href="/" className="text-lg font-black tracking-tight text-white">
                  Vix<span className="text-[#38A0E4]">rex</span>
                </a>
                <div className="flex items-center gap-2">
                  {articles.length > 0 && (
                    <Link
                      href={`/v/${store.slug}/yazilar`}
                      className="rounded-xl border border-white/10 bg-white/10 px-3 py-2 text-xs font-extrabold text-white/90"
                    >
                      İçerikler
                    </Link>
                  )}
                  <span
                    className={`rounded-xl px-3 py-2 text-xs font-extrabold ${
                      store.status === "Kapalı"
                        ? "bg-rose-500/15 text-rose-200"
                        : "bg-emerald-400/15 text-emerald-200"
                    }`}
                  >
                    {store.status || "Açık"}
                  </span>
                </div>
              </div>

              <div className="grid items-end gap-6 lg:grid-cols-[1fr_360px]">
                <div className="flex flex-col items-start gap-5">
                  <div className="flex items-center gap-4">
                    {store.logo_url ? (
                      <Image
                        src={store.logo_url}
                        alt={`${store.name} logo`}
                        width={96}
                        height={96}
                        className="h-24 w-24 rounded-full border-2 border-white/60 object-contain shadow-2xl bg-white"
                      />
                    ) : (
                      <div className="flex h-24 w-24 items-center justify-center rounded-full border-2 border-white/60 bg-[#071322] text-4xl font-black text-[#CFE8FF] shadow-2xl">
                        {store.name ? store.name.substring(0, 1).toUpperCase() : "V"}
                      </div>
                    )}
                    <div>
                      <div className="flex flex-wrap items-center gap-2">
                        {store.kategori && (
                          <span className="rounded-full bg-white/12 px-3 py-1 text-xs font-extrabold text-white/85">
                            {store.kategori}
                          </span>
                        )}
                        {store.business_type && (
                          <span className="rounded-full bg-[#38A0E4]/20 px-3 py-1 text-xs font-extrabold text-[#B9E1FF]">
                            {store.business_type}
                          </span>
                        )}
                      </div>
                      <h1 className="mt-3 max-w-2xl text-4xl font-black leading-tight tracking-tight text-white sm:text-5xl">
                        {store.name}
                      </h1>
                    </div>
                  </div>
                  <p className="max-w-2xl text-sm font-semibold leading-7 text-[#D7E4F5] sm:text-base">
                    {displayDescription}
                  </p>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  {whatsappActionUrl && (
                    <Link
                      href={whatsappActionUrl}
                      className="flex items-center justify-center gap-2 rounded-2xl bg-[#25D366] px-4 py-3 text-center text-sm font-black text-white shadow-lg shadow-emerald-950/20 transition hover:opacity-90"
                    >
                      <svg className="h-4 w-4 fill-current shrink-0" viewBox="0 0 24 24">
                        <path d="M.057 24l1.687-6.163c-1.041-1.804-1.588-3.849-1.587-5.946C.002 5.465 5.468 0 12.145 0c3.24.001 6.285 1.26 8.577 3.557 2.292 2.297 3.55 5.344 3.546 8.584-.007 6.68-5.473 12.145-12.15 12.145-2.002-.002-3.973-.496-5.73-1.447L0 24zm6.59-4.846c1.6.95 3.188 1.449 4.825 1.451 5.436 0 9.86-4.42 9.864-9.858.002-2.634-1.025-5.11-2.89-6.98-1.866-1.87-4.348-2.9-6.988-2.9-5.442 0-9.87 4.42-9.874 9.86-.001 1.743.46 3.447 1.336 4.965l-.988 3.6 3.727-.978zm11.218-7.206c-.3-.149-1.774-.875-2.046-.974-.272-.1-.471-.149-.669.149-.198.3-.769.949-.943 1.149-.174.198-.348.223-.648.074-1.037-.518-1.797-.939-2.51-2.155-.188-.323.188-.3.539-.999.061-.124.03-.235-.015-.335-.045-.1-.471-1.136-.646-1.559-.17-.41-.357-.354-.471-.354-.108-.002-.23-.002-.353-.002-.124 0-.325.046-.496.232-.172.186-.656.641-.656 1.562 0 .921.67 1.81.764 1.937.094.124 1.318 2.012 3.194 2.818.446.193.795.308 1.067.394.448.143.855.123 1.176.075.358-.054 1.774-.725 2.022-1.425.249-.699.249-1.295.173-1.424-.075-.127-.272-.201-.57-.35z"/>
                      </svg>
                      WhatsApp&apos;tan Sor
                    </Link>
                  )}
                  {instagramUrl && (
                    <Link
                      href={instagramUrl}
                      className="flex items-center justify-center gap-2 rounded-2xl bg-[#E1306C] px-4 py-3 text-center text-sm font-black text-white shadow-lg shadow-pink-950/20 transition hover:opacity-90"
                    >
                      <svg className="h-4 w-4 fill-current shrink-0" viewBox="0 0 24 24">
                        <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.051.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 1 0 0 12.324 6.162 6.162 0 0 0 0-12.324zM12 16a4 4 0 1 1 0-8 4 4 0 0 1 0 8zm6.406-11.845a1.44 1.44 0 1 0 0 2.881 1.44 1.44 0 0 0 0-2.881z"/>
                      </svg>
                      Instagram
                    </Link>
                  )}
                  {websiteUrl && (
                    <Link
                      href={websiteUrl}
                      className="flex items-center justify-center gap-2 rounded-2xl border border-white/12 bg-white/10 px-4 py-3 text-center text-sm font-black text-white transition hover:bg-white/15"
                    >
                      <svg className="h-4 w-4 fill-none stroke-current shrink-0" strokeWidth="2" viewBox="0 0 24 24">
                        <circle cx="12" cy="12" r="10"></circle>
                        <path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20"></path>
                        <path d="M2 12h20"></path>
                      </svg>
                      Web Sitesi
                    </Link>
                  )}
                  {mapsUrl && (
                    <Link
                      href={mapsUrl}
                      className="flex items-center justify-center gap-2 rounded-2xl bg-[#38A0E4] px-4 py-3 text-center text-sm font-black text-white shadow-lg shadow-sky-950/20 transition hover:opacity-90"
                    >
                      <svg className="h-4 w-4 fill-none stroke-current shrink-0" strokeWidth="2" viewBox="0 0 24 24">
                        <path d="M12 2a8 8 0 0 0-8 8c0 5.25 8 12 8 12s8-6.75 8-12a8 8 0 0 0-8-8z"></path>
                        <circle cx="12" cy="10" r="3"></circle>
                      </svg>
                      Yol Tarifi
                    </Link>
                  )}
                  {isBookingEnabled && (
                    <Link
                      href={`/v/${store.slug}/randevu`}
                      className="col-span-2 rounded-2xl border border-[#38A0E4]/35 bg-[#38A0E4]/18 px-4 py-3 text-center text-sm font-black text-[#D7EEFF]"
                    >
                      Randevu Al
                    </Link>
                  )}
                </div>
              </div>
            </div>
          </section>

          <section className="grid gap-5 lg:grid-cols-[minmax(0,1fr)_360px]">
            <div className="flex flex-col gap-5">
              {collections.length > 0 && (
                <div className="rounded-[22px] border border-[#25415F] bg-[#0E1B2E]/95 p-4 shadow-[0_18px_45px_rgba(0,0,0,0.18)] sm:p-5">
                  <div className="mb-4 flex items-center justify-between gap-3">
                    <h2 className="text-base font-black text-white">Öne Çıkan Koleksiyonlar</h2>
                    <span className="text-xs font-extrabold text-[#9DB2C8]">
                      {visibleProducts.length} ürün
                    </span>
                  </div>
                  <div className="flex flex-wrap gap-2">
                    {collections.map((collection) => (
                      <div
                        key={collection.name}
                        className="rounded-2xl border border-[#25415F] bg-[#13243A] px-4 py-3"
                      >
                        <div className="text-sm font-black text-white">{collection.name}</div>
                        <div className="mt-1 text-[11px] font-bold text-[#7BC7FF]">
                          {collection.count} ürün
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {visibleProducts.length > 0 && (
                <Suspense fallback={
                  <div className="rounded-[22px] border border-[#25415F] bg-[#0E1B2E]/95 p-4 shadow-[0_18px_45px_rgba(0,0,0,0.18)] sm:p-5">
                    <div className="mb-4 flex items-center justify-between gap-3">
                      <h2 className="text-base font-black text-white">Ürünler</h2>
                    </div>
                    <div className="grid grid-cols-2 gap-3 md:grid-cols-3 xl:grid-cols-4">
                      {Array.from({ length: 8 }).map((_, i) => (
                        <div key={i} className="animate-pulse rounded-2xl border border-[#25415F] bg-[#13243A] p-2">
                          <div className="aspect-square rounded-xl bg-[#162A42]" />
                          <div className="mt-3 space-y-2">
                            <div className="h-4 rounded bg-[#162A42]" />
                            <div className="h-3 w-1/2 rounded bg-[#162A42]" />
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                }>
                  <ProductCatalog
                    storeSlug={store.slug}
                    products={visibleProducts}
                    categoryMap={(categories || []).map((c) => ({ id: c.id, name: c.name }))}
                  />
                </Suspense>
              )}

              {store.corporate_bio && (
                <div className="rounded-[22px] border border-[#25415F] bg-[#0E1B2E]/95 p-5">
                  <h2 className="mb-3 text-base font-black text-white">Dükkan Hikayesi</h2>
                  <p className="whitespace-pre-wrap text-sm font-semibold leading-7 text-[#C4D1E3]">
                    {store.corporate_bio}
                  </p>
                </div>
              )}
            </div>

            <aside className="flex flex-col gap-5">
              <div className="rounded-[22px] border border-[#25415F] bg-[#0E1B2E]/95 p-4">
                <h2 className="mb-3 text-base font-black text-white">Profil Araçları</h2>
                <div className="grid grid-cols-2 gap-3">
                  {visibleProducts.length > 0 && (
                    <div className="rounded-2xl border border-[#25415F] bg-[#162A42] p-3">
                      <div className="text-sm font-black text-white">Katalog</div>
                      <div className="mt-1 text-[11px] font-bold text-[#9DB2C8]">
                        {visibleProducts.length} ürün
                      </div>
                    </div>
                  )}
                  <div className="rounded-2xl border border-[#25415F] bg-[#162A42] p-3">
                    <div className="text-sm font-black text-white">vCard</div>
                    <div className="mt-1 text-[11px] font-bold text-[#9DB2C8]">Rehber bilgileri</div>
                  </div>
                  {referencesUrl && (
                    <Link
                      href={referencesUrl}
                      className="rounded-2xl border border-[#25415F] bg-[#162A42] p-3 transition hover:border-[#818CF8]"
                    >
                      <div className="text-sm font-black text-white">Referanslar</div>
                      <div className="mt-1 text-[11px] font-bold text-[#9DB2C8]">Yorumları gör</div>
                    </Link>
                  )}
                  <Link
                    href={publicUrl}
                    className="rounded-2xl border border-[#25415F] bg-[#162A42] p-3 transition hover:border-[#38A0E4]"
                  >
                    <div className="text-sm font-black text-white">QR Paylaş</div>
                    <div className="mt-1 text-[11px] font-bold text-[#9DB2C8]">Linki aç</div>
                  </Link>
                </div>
              </div>

              <div className="rounded-[22px] border border-[#25415F] bg-[#0E1B2E]/95 p-4">
                <div className="flex items-center gap-4">
                  <div className="rounded-2xl bg-white p-2">
                    <Image
                      src={`https://api.qrserver.com/v1/create-qr-code/?size=140x140&data=${encodeURIComponent(publicUrl)}`}
                      alt={`${store.name} QR kodu`}
                      width={112}
                      height={112}
                      className="h-[112px] w-[112px]"
                    />
                  </div>
                  <div className="min-w-0">
                    <h2 className="text-sm font-black text-white">Vitrini Paylaş</h2>
                    <p className="mt-1 text-xs font-semibold leading-5 text-[#9DB2C8]">
                      Bu QR veya bağlantı ile müşteriler doğrudan vitrine ulaşır.
                    </p>
                    <p className="mt-3 truncate rounded-xl bg-[#071322] px-3 py-2 text-[11px] font-bold text-[#C4D1E3]">
                      {publicUrl}
                    </p>
                  </div>
                </div>
              </div>

              <div className="rounded-[22px] border border-[#25415F] bg-[#0E1B2E]/95 p-4">
                <h2 className="mb-3 text-base font-black text-white">İletişim</h2>
                <div className="space-y-3 text-sm font-semibold text-[#C4D1E3]">
                  {store.address && <p>{store.address}</p>}
                  {typeof store.working_hours === "string" &&
                    store.working_hours && <p>{store.working_hours}</p>}
                  {mapsUrl && (
                    <Link href={mapsUrl} className="block rounded-2xl bg-[#38A0E4] px-4 py-3 text-center text-sm font-black text-white">
                      Yol Tarifi Al
                    </Link>
                  )}
                  {store.google_business_link && (
                    <Link
                      href={store.google_business_link}
                      className="block rounded-2xl border border-amber-300/30 bg-amber-300/10 px-4 py-3 text-center text-sm font-black text-amber-100"
                    >
                      Google Yorumu
                    </Link>
                  )}
                </div>
              </div>

              {marketplaceLinks.length > 0 && (
                <div className="rounded-[22px] border border-[#25415F] bg-[#0E1B2E]/95 p-4">
                  <h2 className="mb-3 text-base font-black text-white">Satış Kanalları</h2>
                  <div className="grid grid-cols-2 gap-3">
                    {marketplaceLinks.map((link: MarketplaceLinkItem, i: number) => (
                      <Link
                        key={link.id || i}
                        href={normalizeExternalUrl(link.url) || publicUrl}
                        className="rounded-2xl border border-[#25415F] bg-[#162A42] p-3 transition hover:border-[#38A0E4]"
                      >
                        <span className="block truncate text-xs font-black text-[#7BC7FF]">
                          {link.platform}
                        </span>
                        {link.subtitle && (
                          <span className="mt-1 block truncate text-[10px] font-bold text-[#9DB2C8]">
                            {link.subtitle}
                          </span>
                        )}
                      </Link>
                    ))}
                  </div>
                </div>
              )}

              {galleryItems.length > 0 && (
                <div className="rounded-[22px] border border-[#25415F] bg-[#0E1B2E]/95 p-4">
                  <h2 className="mb-3 text-base font-black text-white">Galeri</h2>
                  <div className="grid grid-cols-3 gap-2">
                    {galleryItems.slice(0, 6).map((item: GalleryItem, i: number) => (
                      <div key={item.id || i} className="aspect-square overflow-hidden rounded-xl bg-[#162A42]">
                        <Image
                          src={item.imageUrl}
                          alt={item.title || "Vitrin görseli"}
                          width={200}
                          height={200}
                          className="h-full w-full object-cover"
                        />
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {articles.length > 0 && (
                <div className="rounded-[22px] border border-[#25415F] bg-[#0E1B2E]/95 p-4">
                  <div className="mb-3 flex items-center justify-between gap-3">
                    <h2 className="text-base font-black text-white">İçerik ve Duyurular</h2>
                    <Link href={`/v/${store.slug}/yazilar`} className="text-xs font-black text-[#7BC7FF]">
                      Tümünü Gör
                    </Link>
                  </div>
                  <div className="grid gap-3">
                    {articles.map((article) => (
                      <Link
                        key={article.id}
                        href={`/v/${store.slug}/yazilar/${article.slug}`}
                        className="rounded-2xl border border-[#25415F] bg-[#162A42] p-3 transition hover:border-[#38A0E4]"
                      >
                        <h3 className="truncate text-xs font-black text-white">{article.title}</h3>
                        <p className="mt-1 line-clamp-2 text-[10px] font-semibold text-[#9DB2C8]">
                          {article.summary || article.content.substring(0, 100)}
                        </p>
                      </Link>
                    ))}
                  </div>
                </div>
              )}
            </aside>
          </section>

          <footer className="pb-8 pt-2 text-center text-xs font-bold text-[#7890AA]">
            Bu vitrin Vixrex ile oluşturuldu.
          </footer>
        </main>
      </div>
    </>
  );
}
