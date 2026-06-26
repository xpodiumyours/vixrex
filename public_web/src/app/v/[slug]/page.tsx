import { Metadata } from "next";
import { notFound } from "next/navigation";
import Link from "next/link";
import { unstable_cache } from "next/cache";
import { supabase } from "@/lib/supabase";

export const revalidate = 300;

interface PageProps {
  params: Promise<{ slug: string }>;
}

interface GalleryItem {
  id?: string;
  imageUrl: string;
  title?: string;
}

interface ProductItem {
  id?: string;
  name: string;
  description?: string;
  price?: string;
  imagePath?: string;
  stockStatus?: string;
}

interface OfferingItem {
  id?: string;
  title: string;
  description?: string;
  price?: string;
  durationMinutes?: number;
}

interface MarketplaceLinkItem {
  id?: string;
  platform: string;
  url: string;
  subtitle?: string;
}

function safeParseJson<T>(value: unknown): T[] {
  if (!value) return [];
  if (Array.isArray(value)) return value as T[];
  if (typeof value === "string") {
    try {
      return JSON.parse(value) as T[];
    } catch {
      return [];
    }
  }
  return [];
}

function normalizeWhatsappDigits(value: unknown): string {
  const digits = String(value || "").replace(/[^0-9]/g, "");
  if (digits.startsWith("0") && digits.length === 11) return `90${digits.slice(1)}`;
  if (digits.startsWith("5") && digits.length === 10) return `90${digits}`;
  return digits;
}

function normalizeExternalUrl(value: unknown): string | null {
  const url = String(value || "").trim();
  if (!url) return null;
  return url.startsWith("http") ? url : `https://${url}`;
}

async function _getStoreData(slug: string) {
  const { data: store, error } = await supabase
    .from("stores")
    .select("*")
    .eq("slug", slug)
    .eq("is_published", true)
    .single();

  if (error || !store) return null;

  const { data: bookingSettings } = await supabase
    .from("booking_settings")
    .select("*")
    .eq("store_slug", slug)
    .maybeSingle();

  const { data: articles } = await supabase
    .from("store_articles")
    .select("*")
    .eq("store_slug", slug)
    .eq("status", "published")
    .order("published_at", { ascending: false, nullsFirst: false })
    .order("created_at", { ascending: false })
    .limit(3);

  return {
    store,
    bookingSettings,
    articles: articles || [],
  };
}

const getStoreData = (slug: string) =>
  unstable_cache(
    () => _getStoreData(slug),
    [`store-${slug}`],
    { tags: [`store-${slug}`], revalidate: 300 }
  )();

export async function generateMetadata(props: PageProps): Promise<Metadata> {
  const params = await props.params;
  const data = await getStoreData(params.slug);
  if (!data) return {};

  const { store } = data;
  const title = `${store.name} - VitrinX`;
  const description =
    store.description || store.corporate_bio || `${store.name} Dijital Vitrini`;
  const image = store.shelf_image_url || store.logo_url || "";

  return {
    title,
    description,
    alternates: {
      canonical: `/v/${store.slug}`,
    },
    openGraph: {
      title,
      description,
      images: image ? [{ url: image }] : [],
      type: "profile",
    },
  };
}

export default async function StorePage(props: PageProps) {
  const params = await props.params;
  const data = await getStoreData(params.slug);
  if (!data) notFound();

  const { store, bookingSettings, articles } = data;

  const galleryItems = safeParseJson<GalleryItem>(store.gallery_items);
  const products = safeParseJson<ProductItem>(store.products);
  const offerings = safeParseJson<OfferingItem>(store.offerings);
  const marketplaceLinks = safeParseJson<MarketplaceLinkItem>(store.marketplace_links);

  const publicUrl = `https://vitrinx.app/v/${store.slug}`;
  const heroImage =
    store.shelf_image_url || galleryItems[0]?.imageUrl || store.logo_url || "";
  const hasPhysicalLocation =
    store.address && store.latitude != null && store.longitude != null;
  const isBookingEnabled = bookingSettings?.is_enabled ?? false;
  const phoneDigits = normalizeWhatsappDigits(store.whatsapp);
  const waBaseUrl = phoneDigits ? `https://wa.me/${phoneDigits}` : null;
  const whatsappActionUrl = waBaseUrl
    ? `${waBaseUrl}?text=${encodeURIComponent(`Merhaba, ${store.name} vitrininiz hakkında bilgi almak istiyorum.`)}`
    : null;
  const productWhatsappUrl = (productName: string) =>
    waBaseUrl
      ? `${waBaseUrl}?text=${encodeURIComponent(`Merhaba, ${store.name} vitrininizdeki '${productName}' hakkında bilgi almak istiyorum.`)}`
      : null;
  const instagramValue = String(store.instagram || "").trim();
  const instagramUrl = instagramValue
    ? `https://instagram.com/${instagramValue.replace("@", "").replace("/", "")}`
    : null;
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
  const featuredProducts = products.slice(0, 6);
  const featuredOfferings = offerings.slice(0, 6);

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

  const serviceSchemas = offerings.map((offering) => ({
    "@type": "Service",
    "@id": `https://vitrinx.app/v/${store.slug}#service-${offering.id}`,
    name: offering.title,
    description: offering.description || undefined,
    provider: {
      "@type": businessType,
      "@id": `https://vitrinx.app/v/${store.slug}#business`,
    },
    offers: offering.price
      ? {
          "@type": "Offer",
          price: offering.price.replace(/[^0-9.]/g, "") || "0.00",
          priceCurrency: "TRY",
        }
      : undefined,
  }));

  const breadcrumbSchema = {
    "@type": "BreadcrumbList",
    "@id": `https://vitrinx.app/v/${store.slug}#breadcrumb`,
    itemListElement: [
      {
        "@type": "ListItem",
        position: 1,
        name: "Ana Sayfa",
        item: "https://vitrinx.app",
      },
      {
        "@type": "ListItem",
        position: 2,
        name: store.name,
        item: publicUrl,
      },
    ],
  };

  const jsonLd = {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": businessType,
        "@id": `https://vitrinx.app/v/${store.slug}#business`,
        name: store.name,
        description: store.description || store.corporate_bio,
        image: store.shelf_image_url || galleryItems[0]?.imageUrl || store.logo_url,
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
      },
      {
        "@type": "WebPage",
        "@id": `https://vitrinx.app/v/${store.slug}#webpage`,
        url: publicUrl,
        name: `${store.name} | VitrinX`,
        description: store.description || store.corporate_bio,
      },
      breadcrumbSchema,
      ...serviceSchemas,
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
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={heroImage}
                alt={`${store.name} vitrin görseli`}
                className="absolute inset-0 h-full w-full object-cover opacity-55"
              />
            )}
            <div className="absolute inset-0 bg-[linear-gradient(90deg,rgba(7,19,34,0.96),rgba(7,19,34,0.78),rgba(7,19,34,0.48))]" />
            <div className="relative flex min-h-[390px] flex-col justify-between gap-10 p-5 sm:p-8 lg:p-9">
              <div className="flex items-center justify-between gap-3">
                <Link href="/" className="text-lg font-black tracking-tight text-white">
                  Vitrin<span className="text-[#38A0E4]">X</span>
                </Link>
                <div className="flex items-center gap-2">
                  {articles.length > 0 && (
                    <Link
                      href={`/v/${store.slug}/yazilar`}
                      className="rounded-xl border border-white/10 bg-white/10 px-3 py-2 text-xs font-extrabold text-white/90"
                    >
                      Yazılar
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
                      // eslint-disable-next-line @next/next/no-img-element
                      <img
                        src={store.logo_url}
                        alt={`${store.name} logo`}
                        className="h-24 w-24 rounded-full border-2 border-white/60 object-cover shadow-2xl"
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
                      className="rounded-2xl bg-[#25D366] px-4 py-3 text-center text-sm font-black text-white shadow-lg shadow-emerald-950/20"
                    >
                      WhatsApp
                    </Link>
                  )}
                  {instagramUrl && (
                    <Link
                      href={instagramUrl}
                      className="rounded-2xl bg-[#E1306C] px-4 py-3 text-center text-sm font-black text-white shadow-lg shadow-pink-950/20"
                    >
                      Instagram
                    </Link>
                  )}
                  {websiteUrl && (
                    <Link
                      href={websiteUrl}
                      className="rounded-2xl border border-white/12 bg-white/10 px-4 py-3 text-center text-sm font-black text-white"
                    >
                      Web Sitesi
                    </Link>
                  )}
                  {mapsUrl && (
                    <Link
                      href={mapsUrl}
                      className="rounded-2xl bg-[#38A0E4] px-4 py-3 text-center text-sm font-black text-white shadow-lg shadow-sky-950/20"
                    >
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
              {featuredProducts.length > 0 && (
                <div className="rounded-[22px] border border-[#25415F] bg-[#0E1B2E]/95 p-4 shadow-[0_18px_45px_rgba(0,0,0,0.18)] sm:p-5">
                  <div className="mb-4 flex items-center justify-between gap-3">
                    <h2 className="text-base font-black text-white">Öne Çıkan Ürünler</h2>
                    {products.length > featuredProducts.length && (
                      <span className="text-xs font-extrabold text-[#9DB2C8]">
                        +{products.length - featuredProducts.length} ürün
                      </span>
                    )}
                  </div>
                  <div className="grid grid-cols-2 gap-3 md:grid-cols-3">
                    {featuredProducts.map((product: ProductItem, i: number) => {
                      const inquiryUrl = productWhatsappUrl(product.name);
                      const card = (
                        <>
                          <div className="aspect-[1.2] overflow-hidden rounded-xl bg-[#162A42]">
                            {product.imagePath ? (
                              // eslint-disable-next-line @next/next/no-img-element
                              <img
                                src={product.imagePath}
                                alt={product.name}
                                className="h-full w-full object-cover"
                              />
                            ) : (
                              <div className="flex h-full w-full items-center justify-center text-xs font-black text-[#9DB2C8]">
                                Ürün
                              </div>
                            )}
                          </div>
                          <div className="mt-3 min-w-0">
                            <h3 className="truncate text-sm font-black text-white">{product.name}</h3>
                            {product.description && (
                              <p className="mt-1 line-clamp-1 text-[11px] font-semibold text-[#9DB2C8]">
                                {product.description}
                              </p>
                            )}
                            <div className="mt-2 flex items-center justify-between gap-2">
                              <span className="truncate text-xs font-black text-[#7BC7FF]">
                                {product.price || "Fiyat sorun"}
                              </span>
                              {product.stockStatus && (
                                <span className="rounded-full bg-emerald-400/12 px-2 py-0.5 text-[10px] font-extrabold text-emerald-200">
                                  {product.stockStatus}
                                </span>
                              )}
                            </div>
                          </div>
                        </>
                      );

                      return inquiryUrl ? (
                        <Link
                          key={product.id || i}
                          href={inquiryUrl}
                          className="rounded-2xl border border-[#25415F] bg-[#13243A] p-2 transition hover:border-[#38A0E4]/70"
                        >
                          {card}
                        </Link>
                      ) : (
                        <div
                          key={product.id || i}
                          className="rounded-2xl border border-[#25415F] bg-[#13243A] p-2"
                        >
                          {card}
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}

              {featuredOfferings.length > 0 && (
                <div className="rounded-[22px] border border-[#25415F] bg-[#0E1B2E]/95 p-4 sm:p-5">
                  <h2 className="mb-3 text-base font-black text-white">Hizmetler</h2>
                  <div className="divide-y divide-[#25415F]">
                    {featuredOfferings.map((offering: OfferingItem, i: number) => (
                      <div key={offering.id || i} className="flex items-center justify-between gap-4 py-3">
                        <div className="min-w-0">
                          <h3 className="truncate text-sm font-black text-white">{offering.title}</h3>
                          {offering.description && (
                            <p className="mt-1 line-clamp-1 text-xs font-semibold text-[#9DB2C8]">
                              {offering.description}
                            </p>
                          )}
                        </div>
                        <div className="shrink-0 text-right">
                          <div className="text-sm font-black text-[#7BC7FF]">
                            {offering.price || "Fiyat sorun"}
                          </div>
                          {offering.durationMinutes ? (
                            <div className="text-[10px] font-bold text-[#9DB2C8]">
                              {offering.durationMinutes} dk
                            </div>
                          ) : null}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {store.corporate_bio && (
                <div className="rounded-[22px] border border-[#25415F] bg-[#0E1B2E]/95 p-5">
                  <h2 className="mb-3 text-base font-black text-white">Hakkımızda</h2>
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
                  <div className="rounded-2xl border border-[#25415F] bg-[#162A42] p-3">
                    <div className="text-sm font-black text-white">Katalog</div>
                    <div className="mt-1 text-[11px] font-bold text-[#9DB2C8]">
                      {products.length || offerings.length} kayıt
                    </div>
                  </div>
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
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img
                      src={`https://api.qrserver.com/v1/create-qr-code/?size=140x140&data=${encodeURIComponent(publicUrl)}`}
                      alt={`${store.name} QR kodu`}
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
                  {store.working_hours && <p>{store.working_hours}</p>}
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
                        {/* eslint-disable-next-line @next/next/no-img-element */}
                        <img
                          src={item.imageUrl}
                          alt={item.title || "Vitrin görseli"}
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
                    <h2 className="text-base font-black text-white">Son Yazılar</h2>
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
            Bu vitrin VitrinX ile oluşturuldu.
          </footer>
        </main>
      </div>
    </>
  );
}
