import { Metadata } from "next";
import { notFound } from "next/navigation";
import { unstable_cache } from "next/cache";
import { supabase } from "@/lib/supabase";
import {
  deriveCollections,
  getProductUrlSlug,
  isPublicCatalogProduct,
  normalizeExternalUrl,
  normalizeWhatsappDigits,
  safeParseJson,
  type ProductItem,
} from "@/lib/products";
import { buildSiteUrl, getSiteUrl } from "@/lib/siteUrl";
import { getVitrinCopy, normalizeAddressDisplay } from "@/lib/vitrinCopy";
import {
  formatTodayLine,
  formatWeekLines,
  resolveOpenState,
  resolveWeekMap,
  toOpeningHoursSpecification,
} from "@/lib/workingHours";
import ProductCatalog from "./ProductCatalog";
import VitrinProfileView from "./VitrinProfileView";
import { resolveVitrinProfile } from "@/lib/vitrinProfile";

export const revalidate = 60;

export async function generateStaticParams() {
  const { data: stores } = await supabase
    .from("stores")
    .select("slug")
    .eq("is_published", true);

  return (stores || []).map((store: { slug: string }) => ({ slug: store.slug }));
}

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
      }))
      .filter((p: ProductItem) => isPublicCatalogProduct(p));

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
  const collections = deriveCollections(visibleProducts);
  const vitrinProfile = resolveVitrinProfile(store.kategori, store.business_type);
  const vitrinCopy = getVitrinCopy(vitrinProfile.id);
  const displayDescription =
    store.description ||
    store.corporate_bio ||
    vitrinCopy.defaultBio(store.name);
  const displayAddress = normalizeAddressDisplay(store.address);

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

  const weekMap = resolveWeekMap(
    (bookingSettings as { working_hours?: unknown } | null)?.working_hours,
    store.working_hours,
  );
  const workingHoursToday = weekMap ? formatTodayLine(weekMap) : null;
  const workingHoursWeek = weekMap ? formatWeekLines(weekMap) : [];
  const openState = resolveOpenState(weekMap, store.status);
  const displayStatus = openState.detail
    ? `${openState.label} · ${openState.detail}`
    : openState.label;

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

  const openingHoursSpecification = weekMap
    ? toOpeningHoursSpecification(weekMap)
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
              streetAddress: displayAddress || store.address,
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

      <VitrinProfileView
        storeName={store.name}
        storeSlug={store.slug}
        kategori={store.kategori}
        businessType={store.business_type}
        status={displayStatus}
        isClosed={!openState.isOpen}
        logoUrl={store.logo_url}
        heroImage={heroImage}
        description={displayDescription}
        corporateBio={store.corporate_bio}
        address={displayAddress}
        workingHoursToday={workingHoursToday}
        workingHoursWeek={workingHoursWeek}
        googleBusinessLink={store.google_business_link}
        publicUrl={publicUrl}
        whatsappUrl={whatsappActionUrl}
        instagramUrl={instagramUrl}
        websiteUrl={websiteUrl}
        mapsUrl={mapsUrl}
        referencesUrl={referencesUrl}
        isBookingEnabled={isBookingEnabled}
        profile={vitrinProfile}
        collections={collections}
        productCount={visibleProducts.length}
        galleryItems={galleryItems}
        marketplaceLinks={marketplaceLinks}
        articles={articles}
        catalog={
          <ProductCatalog
            storeSlug={store.slug}
            products={visibleProducts}
            categoryMap={(categories || []).map((c) => ({ id: c.id, name: c.name }))}
            fallbackImage={store.logo_url || "/vixrex_v_crystal_mascot.png"}
            storeInitial={store.name?.trim()?.[0]?.toUpperCase() || "V"}
          />
        }
      />
    </>
  );
}
