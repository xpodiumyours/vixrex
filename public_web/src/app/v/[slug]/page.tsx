import { Metadata } from "next";
import { cookies } from "next/headers";
import { notFound } from "next/navigation";
import { unstable_cache } from "next/cache";
import { supabase } from "@/lib/supabase";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
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
import OwnerWorkspaceShell, { WorkingDraftData } from "./OwnerWorkspaceShell";
import { resolveVitrinProfile } from "@/lib/vitrinProfile";

export const revalidate = 60;
// generateStaticParams yalnızca yayınlı slug'ları önceden üretiyor. Sahip
// oturumu çerezi okunduğu için sayfa isteğe göre değişiyor
// — Next.js bu ikisini aynı anda "statik" modda çalıştırmaya çalışınca
// DYNAMIC_SERVER_USAGE hatasıyla çöküyordu (canlıda doğrulandı). Route'u
// tamamen dinamik yapmak bu çakışmayı ortadan kaldırıyor; asıl veri sorgusu
// zaten unstable_cache ile ayrıca 60sn önbelleklendiği için performans kaybı
// sınırlı.
export const dynamic = "force-dynamic";

export async function generateStaticParams() {
  const { data: stores } = await supabase
    .from("stores")
    .select("slug")
    .eq("is_published", true);

  return (stores || []).map((store: { slug: string }) => ({ slug: store.slug }));
}

interface PageProps {
  params: Promise<{ slug: string }>;
  searchParams: Promise<Record<string, string | string[] | undefined>>;
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
  phone: string | null;
  email: string | null;
  hero_badge: string | null;
  instagram: string | null;
  website: string | null;
  address: string | null;
  status: string | null;
  marketplace_links: unknown;
  gallery_items: unknown;
  products: unknown;
  faq_items: unknown;
  about_kicker: string | null;
  about_title: string | null;
  about_image_url: string | null;
  about_image_caption: string | null;
  about_values: unknown;
  gallery_section_kicker: string | null;
  gallery_section_title: string | null;
  show_storefront_rating: boolean | null;
  show_directions_link: boolean | null;
  references_link: string | null;
  shelf_image_url: string | null;
  logo_url: string | null;
  working_hours: unknown;
  is_published: boolean;
  is_demo?: boolean | null;
  kategori: string | null;
  latitude: number | null;
  longitude: number | null;
  google_business_link: string | null;
  product_storage_version: number | null;
  theme_preset?: string | null;
  rating_score?: number | null;
  review_count?: number | null;
  featured_banner_label: string | null;
  featured_banner_title: string | null;
  featured_banner_description: string | null;
  featured_banner_image_url: string | null;
  featured_banner_price_text: string | null;
}

interface ProductRow {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  price_text: string | null;
  price_amount: number | null;
  old_price_amount?: number | null;
  badge_tag?: string | null;
  fulfillment_region?: string | null;
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
  "id,slug,name,business_type,description,corporate_bio,whatsapp,phone,email," +
  "hero_badge,instagram,website,address,status,marketplace_links,gallery_items," +
  "products,faq_items,about_kicker,about_title,about_image_url,about_image_caption," +
  "about_values,gallery_section_kicker,gallery_section_title," +
  "show_storefront_rating,show_directions_link,references_link,shelf_image_url," +
  "logo_url,working_hours,is_published,is_demo,kategori,latitude,longitude," +
  "google_business_link,product_storage_version,featured_banner_label," +
  "featured_banner_title,featured_banner_description,featured_banner_image_url," +
  "featured_banner_price_text,rating_score,review_count";

async function _buildStoreDataBundle(store: PublicStoreRow) {
  const slug = store.slug;
  try {
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
          "id,name,slug,description,price_text,price_amount,old_price_amount,badge_tag,fulfillment_region,currency,stock_status,image_urls,category_id,is_visible,is_active,source_type,sort_order"
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
        oldPriceAmount: (p.old_price_amount as number | null) ?? null,
        badgeTag: (p.badge_tag as string | null) ?? null,
        fulfillmentRegion: (p.fulfillment_region as string | null) ?? null,
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

async function _getStoreData(slug: string) {
  const { data, error: storeError } = await supabase
    .from("stores")
    .select(PUBLIC_STORE_SELECT)
    .eq("slug", slug)
    .eq("is_published", true)
    .maybeSingle();

  if (storeError) {
    console.error(`Public store query failed for slug=${slug}:`, storeError);
    throw storeError;
  }
  if (!data) return null;

  return _buildStoreDataBundle(data as unknown as PublicStoreRow);
}

const getStoreData = (slug: string) =>
  unstable_cache(
    () => _getStoreData(slug),
    [`store-${slug}`],
    { tags: [`store-${slug}`, `products-${slug}`], revalidate: 60 }
  )();

// getStorePreviewData KALDIRILDI (Commit 12): kalıcı edit_token ile açılan
// önizleme yolu tamamen kapatıldı. Taslağı görmenin tek yolu doğrulanmış
// sahip oturumudur — aşağıdaki getWorkingDraft.

/// Sahip çalışma alanı: get_working_draft_for_session RPC'si ile çalışma taslağını getirir.
/// HMAC çerezi doğrulanır; session_token çerezden okunur; yetki owner_sessions tablosundan gelir.
async function getWorkingDraft(sessionToken: string): Promise<WorkingDraftData | null> {
  const { data, error } = await supabase.rpc("get_working_draft_for_session", {
    p_session_token: sessionToken,
  });

  if (error) {
    console.error(`Working draft query failed:`, error);
    return null;
  }
  if (!data) return null;

  return data as unknown as WorkingDraftData;
}

export async function generateMetadata(props: PageProps): Promise<Metadata> {
  const params = await props.params;
  const ownerToken = (await cookies()).get(OWNER_SESSION_COOKIE)?.value;
  const ownerSession = verifyOwnerSession(ownerToken, params.slug);
  if (ownerSession) {
    return { robots: { index: false, follow: false } };
  }

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

  const cookieStore = await cookies();
  // DİKKAT: bu çerezin TAMAMI (imzalı paket), oturum tokenının kendisi DEĞİL.
  // Gerçek 64 hex karakterlik token paketin içindedir ve yalnız
  // verifyOwnerSession() ile çıkarılır. İkisine aynı ad verilirse RPC'ye
  // yanlış değer gider ve INVALID_SESSION_TOKEN alınır.
  const ownerSessionCookie = cookieStore.get(OWNER_SESSION_COOKIE)?.value;
  const ownerSession = ownerSessionCookie
    ? verifyOwnerSession(ownerSessionCookie, params.slug)
    : null;
  let isOwnerMode = Boolean(ownerSession);

  let data;
  let draft: WorkingDraftData | null = null;
  let sessionExpiresAt: number | null = null;

  if (isOwnerMode && ownerSession && ownerSessionCookie) {
    // RPC'ye çerez değil, paketin içinden çıkarılan gerçek token gider.
    draft = await getWorkingDraft(ownerSession.sessionToken);

    // Fail-closed: draft yüklenemezse owner modunu kapat
    if (!draft) {
      isOwnerMode = false;
    } else {
      if (ownerSession) {
        try {
          const payloadPart = ownerSessionCookie.split(".")[0];
          const decoded = JSON.parse(
            Buffer.from(payloadPart.replace(/-/g, "+").replace(/_/g, "/"), "base64").toString("utf-8")
          );
          sessionExpiresAt = decoded.exp ?? null;
        } catch {
          sessionExpiresAt = null;
        }
      }
    }
  }

  if (isOwnerMode && draft) {
    data = draft?.draft_data
      ? await _buildStoreDataBundle({
          ...draft.draft_data,
          id: draft.store_id,
          slug: draft.slug,
          is_published: true,
        } as unknown as PublicStoreRow)
      : await getStoreData(params.slug);
  } else {
    data = await getStoreData(params.slug);
  }

  if (!data) {
    notFound();
  }

  const { store, bookingSettings, articles, visibleProducts, categories } = data;

  const galleryItems = safeParseJson<GalleryItem>(store.gallery_items);
  const marketplaceLinks = safeParseJson<MarketplaceLinkItem>(store.marketplace_links);
  const faqItems = safeParseJson<{ id?: string; question?: string; answer?: string }>(
    store.faq_items
  )
    .map((item) => ({
      id: String(item.id || ""),
      question: String(item.question || "").trim(),
      answer: String(item.answer || "").trim(),
    }))
    .filter((item) => item.question && item.answer);
  const aboutValues = safeParseJson<{ id?: string; title?: string; description?: string }>(
    store.about_values
  )
    .map((item) => ({
      id: String(item.id || ""),
      title: String(item.title || "").trim(),
      description: String(item.description || "").trim(),
    }))
    .filter((item) => item.title && item.description);
  const aboutSection = {
    kicker: String(store.about_kicker || "").trim(),
    title: String(store.about_title || "").trim(),
    body: String(store.corporate_bio || "").trim(),
    imageUrl: String(store.about_image_url || "").trim(),
    imageCaption: String(store.about_image_caption || "").trim(),
    values: aboutValues,
  };
  const gallerySection = {
    kicker: String(store.gallery_section_kicker || "").trim(),
    title: String(store.gallery_section_title || "").trim(),
    items: galleryItems
      .map((item) => ({
        id: item.id,
        imageUrl: String(item.imageUrl || "").trim(),
        title: String(item.title || "").trim(),
      }))
      .filter((item) => item.imageUrl),
  };
  const showDirectionsLink = store.show_directions_link !== false;
  const showStorefrontRating = store.show_storefront_rating === true;
  const ratingScore =
    typeof store.rating_score === "number" ? store.rating_score : null;
  const reviewCount =
    typeof store.review_count === "number" ? store.review_count : null;

  const siteUrl = getSiteUrl();
  const publicUrl = buildSiteUrl(`/v/${store.slug}`);
  const heroImage =
    store.shelf_image_url || store.logo_url || "";
  const hasPhysicalLocation =
    store.address && store.latitude != null && store.longitude != null;
  const isBookingEnabled = bookingSettings?.is_enabled ?? false;
  const whatsappDigits = normalizeWhatsappDigits(store.whatsapp);
  const waBaseUrl = whatsappDigits ? `https://wa.me/${whatsappDigits}` : null;
  const whatsappActionUrl = waBaseUrl
    ? `${waBaseUrl}?text=${encodeURIComponent(`Merhaba, ${store.name} vitrininiz hakkında bilgi almak istiyorum.`)}`
    : null;
  const displayPhone = String(store.phone || "").trim();
  const phoneDigits = normalizeWhatsappDigits(displayPhone);
  const phoneUrl = phoneDigits ? `tel:+${phoneDigits}` : null;
  const displayEmail = String(store.email || "").trim();
  const displayHeroBadge = String(store.hero_badge || "").trim();
  const phoneDigitsForSchema = phoneDigits || whatsappDigits;
  const featuredBanner = (() => {
    const label = String(store.featured_banner_label || "").trim();
    const title = String(store.featured_banner_title || "").trim();
    const description = String(store.featured_banner_description || "").trim();
    const priceText = String(store.featured_banner_price_text || "").trim();
    const imageUrl = String(store.featured_banner_image_url || "").trim();
    if (!label && !title && !description && !priceText && !imageUrl) {
      return null;
    }
    return { label, title, description, priceText, imageUrl };
  })();
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
  const mapsUrl = showDirectionsLink
    ? hasPhysicalLocation
      ? `https://www.google.com/maps/search/?api=1&query=${store.latitude},${store.longitude}`
      : store.address
        ? `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(store.address)}`
        : null
    : null;
  const mapsEmbedUrl =
    store.latitude != null && store.longitude != null
      ? `https://maps.google.com/maps?q=${store.latitude},${store.longitude}&output=embed`
      : store.address
        ? `https://maps.google.com/maps?q=${encodeURIComponent(store.address)}&output=embed`
        : null;
  const rawCollections = deriveCollections(visibleProducts);
  const collections = rawCollections.map((col) => {
    const firstProduct = visibleProducts.find(
      (p) => p.category === col.name && Array.isArray(p.imageUrls) && (p.imageUrls as string[]).length > 0
    );
    const imageUrl = (firstProduct?.imageUrls as string[] | undefined)?.[0] ?? undefined;
    return { ...col, imageUrl };
  });
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
        telephone: phoneDigitsForSchema ? `+${phoneDigitsForSchema}` : undefined,
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
        heroBadge={displayHeroBadge || null}
        description={displayDescription}
        corporateBio={store.corporate_bio}
        address={displayAddress}
        phone={displayPhone || null}
        phoneUrl={phoneUrl}
        email={displayEmail || null}
        featuredBanner={featuredBanner}
        aboutSection={aboutSection}
        gallerySection={gallerySection}
        faqItems={faqItems}
        showStorefrontRating={showStorefrontRating}
        ratingScore={ratingScore}
        reviewCount={reviewCount}
        workingHoursToday={workingHoursToday}
        workingHoursWeek={workingHoursWeek}
        googleBusinessLink={store.google_business_link}
        publicUrl={publicUrl}
        whatsappUrl={whatsappActionUrl}
        instagramUrl={instagramUrl}
        websiteUrl={websiteUrl}
        mapsUrl={mapsUrl}
        mapsEmbedUrl={mapsEmbedUrl}
        referencesUrl={referencesUrl}
        isBookingEnabled={isBookingEnabled}
        profile={vitrinProfile}
        collections={collections}
        productCount={visibleProducts.length}
        galleryItems={gallerySection.items}
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
        isPreviewMode={isOwnerMode}
        ownerMode={isOwnerMode}
        isDemo={Boolean(store.is_demo)}
      />
      {isOwnerMode ? (
        <OwnerWorkspaceShell
          storeName={store.name}
          storeSlug={store.slug}
          kategori={store.kategori}
          businessType={store.business_type}
          status={displayStatus}
          isClosed={!openState.isOpen}
          logoUrl={store.logo_url}
          heroImage={heroImage}
          heroBadge={displayHeroBadge || null}
          description={displayDescription}
          corporateBio={store.corporate_bio}
          address={displayAddress}
          phone={displayPhone || null}
          phoneUrl={phoneUrl}
          email={displayEmail || null}
          featuredBanner={featuredBanner}
          aboutSection={aboutSection}
          gallerySection={gallerySection}
          faqItems={faqItems}
          showStorefrontRating={showStorefrontRating}
          ratingScore={ratingScore}
          reviewCount={reviewCount}
          workingHoursToday={workingHoursToday}
          workingHoursWeek={workingHoursWeek}
          googleBusinessLink={store.google_business_link}
          publicUrl={publicUrl}
          whatsappUrl={whatsappActionUrl}
          instagramUrl={instagramUrl}
          websiteUrl={websiteUrl}
          mapsUrl={mapsUrl}
          mapsEmbedUrl={mapsEmbedUrl}
          referencesUrl={referencesUrl}
          isBookingEnabled={isBookingEnabled}
          profile={vitrinProfile}
          collections={collections}
          productCount={visibleProducts.length}
          galleryItems={gallerySection.items}
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
          isPreviewMode={true}
          draft={draft}
          sessionExpiresAt={sessionExpiresAt}
        />
      ) : null}
    </>
  );
}
