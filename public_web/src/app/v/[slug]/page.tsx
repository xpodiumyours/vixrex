import { Metadata } from "next";
import { notFound } from "next/navigation";
import Link from "next/link";
import { unstable_cache } from "next/cache";
import { supabase } from "@/lib/supabase";

export const revalidate = 300; // Enable 5-minute ISR (Incremental Static Regeneration)

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

// unstable_cache: Supabase SDK fetch'leri cache tag sistemiyle entegre eder.
// revalidateTag('store-<slug>') çağrıldığında bu cache anında temizlenir.
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
  const description = store.description || store.corporate_bio || `${store.name} Dijital Vitrini`;
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

  const hasPhysicalLocation = store.address && store.latitude != null && store.longitude != null;
  const isBookingEnabled = bookingSettings?.is_enabled ?? false;

  // Clean phone number for WhatsApp
  const phoneDigits = String(store.whatsapp || "").replace(/[^0-9]/g, "");
  const waUrl = phoneDigits ? `https://wa.me/${phoneDigits}` : null;

  // Google Maps directions
  const mapsUrl = hasPhysicalLocation 
    ? `https://www.google.com/maps/search/?api=1&query=${store.latitude},${store.longitude}`
    : store.address 
      ? `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(store.address)}`
      : null;

  // Determine Google Rich Schema business type based on category
  const categoryLower = (store.kategori || "").toLowerCase();
  let businessType = "LocalBusiness";
  if (categoryLower.includes("kuaför") || categoryLower.includes("hair")) {
    businessType = "HairSalon";
  } else if (categoryLower.includes("güzellik") || categoryLower.includes("beauty") || categoryLower.includes("bakım")) {
    businessType = "BeautySalon";
  }

  // Build service schema graphs
  const serviceSchemas = offerings.map((offering) => ({
    "@type": "Service",
    "@id": `https://vitrinx.app/v/${store.slug}#service-${offering.id}`,
    "name": offering.title,
    "description": offering.description || undefined,
    "provider": {
      "@type": businessType,
      "@id": `https://vitrinx.app/v/${store.slug}#business`
    },
    "offers": offering.price ? {
      "@type": "Offer",
      "price": offering.price.replace(/[^0-9.]/g, "") || "0.00",
      "priceCurrency": "TRY"
    } : undefined
  }));

  // Build BreadcrumbList schema graph
  const breadcrumbSchema = {
    "@type": "BreadcrumbList",
    "@id": `https://vitrinx.app/v/${store.slug}#breadcrumb`,
    "itemListElement": [
      {
        "@type": "ListItem",
        "position": 1,
        "name": "Ana Sayfa",
        "item": "https://vitrinx.app"
      },
      {
        "@type": "ListItem",
        "position": 2,
        "name": store.name,
        "item": `https://vitrinx.app/v/${store.slug}`
      }
    ]
  };

  // JSON-LD Structured Data
  const jsonLd = {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": businessType,
        "@id": `https://vitrinx.app/v/${store.slug}#business`,
        "name": store.name,
        "description": store.description || store.corporate_bio,
        "image": store.shelf_image_url || galleryItems[0]?.imageUrl || store.logo_url,
        "logo": store.logo_url,
        "telephone": phoneDigits ? `+${phoneDigits}` : undefined,
        "url": `https://vitrinx.app/v/${store.slug}`,
        "address": hasPhysicalLocation ? {
          "@type": "PostalAddress",
          "streetAddress": store.address,
          "addressCountry": "TR"
        } : undefined,
        "geo": hasPhysicalLocation ? {
          "@type": "GeoCoordinates",
          "latitude": store.latitude,
          "longitude": store.longitude
        } : undefined
      },
      {
        "@type": "WebPage",
        "@id": `https://vitrinx.app/v/${store.slug}#webpage`,
        "url": `https://vitrinx.app/v/${store.slug}`,
        "name": `${store.name} | VitrinX`,
        "description": store.description || store.corporate_bio
      },
      breadcrumbSchema,
      ...serviceSchemas
    ]
  };

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />

      <div className="container py-8 flex-1 flex flex-col gap-6 animate-fade-in">
        {/* Navigation / Header band */}
        <div className="flex justify-between items-center bg-white dark:bg-[#131A22] border border-[#D0E4E8] dark:border-[#243141] rounded-2xl p-4 shadow-sm">
          <Link href="/" className="text-sm font-bold text-[#64748B] hover:text-[#10D8D8] flex items-center gap-1">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polyline points="15 18 9 12 15 6"/></svg>
            VitrinX
          </Link>
          <div className="flex gap-2">
            {articles.length > 0 && (
              <Link href={`/v/${store.slug}/yazilar`} className="text-xs font-bold px-3 py-1.5 bg-[#10D8D8]/10 text-[#0EA8B0] rounded-lg">
                Yazılar
              </Link>
            )}
            <span className={`text-xs font-bold px-3 py-1.5 rounded-lg ${store.status === "Açık" ? "bg-emerald-500/10 text-emerald-600" : "bg-red-500/10 text-red-600"}`}>
              {store.status || "Açık"}
            </span>
          </div>
        </div>

        {/* Store Title Card */}
        <div className="card flex flex-col sm:flex-row items-center sm:items-start text-center sm:text-left gap-6 bg-white dark:bg-[#131A22]">
          {store.logo_url ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={store.logo_url} alt={`${store.name} Logo`} className="w-20 h-20 rounded-full border border-[#D0E4E8] dark:border-[#243141] object-cover" />
          ) : (
            <div className="w-20 h-20 rounded-full bg-gradient-to-br from-[#10D8D8] to-[#38A0E4] text-white flex items-center justify-center font-bold text-3xl">
              {store.name ? store.name[0].toUpperCase() : "V"}
            </div>
          )}
          <div className="flex-1 space-y-2">
            <div className="flex flex-col sm:flex-row sm:items-center gap-2">
              <h1 className="text-2xl font-extrabold">{store.name}</h1>
              {store.kategori && (
                <span className="inline-block px-2.5 py-0.5 bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 text-xs font-bold rounded-full w-max mx-auto sm:mx-0">
                  {store.kategori}
                </span>
              )}
            </div>
            {store.business_type && <p className="text-sm font-semibold text-[#0EA8B0]">{store.business_type}</p>}
            {store.description && <p className="text-sm text-[#475569] dark:text-[#CBD5E1] leading-relaxed">{store.description}</p>}
          </div>
        </div>

        {/* Online Booking Highlight */}
        {isBookingEnabled && (
          <div className="bg-brand-gradient text-white p-6 rounded-2xl shadow-md flex flex-col md:flex-row items-center justify-between gap-4">
            <div className="space-y-1 text-center md:text-left">
              <h2 className="text-lg font-bold">Çevrimiçi Randevu Alın</h2>
              <p className="text-xs text-white/80">Hizmetlerimiz için hemen ücretsiz randevu talebi oluşturun.</p>
            </div>
            <Link href={`/v/${store.slug}/randevu`} className="px-6 py-3 bg-white text-[#0EA8B0] hover:bg-[#F0F8F8] font-bold rounded-xl shadow-sm transition-transform active:scale-95 text-sm">
              Randevu Sihirbazı
            </Link>
          </div>
        )}

        {/* Gallery / Cover Image */}
        {galleryItems.length > 0 ? (
          <div className="space-y-2">
            <h2 className="text-base font-extrabold px-1">Galeri & Reyonlar</h2>
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
              {galleryItems.map((item: GalleryItem, i: number) => (
                <div key={item.id || i} className="group relative aspect-square rounded-xl overflow-hidden border border-[#D0E4E8] dark:border-[#243141]">
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img src={item.imageUrl} alt={item.title || "Vitrin Görseli"} className="w-full h-full object-cover transition-transform duration-300 group-hover:scale-105" />
                  {item.title && (
                    <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/80 to-transparent p-3 text-white text-[11px] font-bold">
                      {item.title}
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        ) : store.shelf_image_url ? (
          <div className="rounded-2xl overflow-hidden aspect-video border border-[#D0E4E8] dark:border-[#243141]">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src={store.shelf_image_url} alt="Vitrin Raf Görseli" className="w-full h-full object-cover" />
          </div>
        ) : null}

        {/* Bio / About */}
        {store.corporate_bio && (
          <div className="card space-y-3 bg-white dark:bg-[#131A22]">
            <h2 className="text-base font-extrabold">Hakkımızda</h2>
            <p className="text-sm text-[#475569] dark:text-[#CBD5E1] leading-relaxed whitespace-pre-wrap">{store.corporate_bio}</p>
          </div>
        )}

        {/* Interactive Actions Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {/* Contact Details */}
          <div className="card space-y-4 bg-white dark:bg-[#131A22] flex flex-col justify-between">
            <h2 className="text-base font-extrabold">İletişim & Adres</h2>
            <div className="space-y-3 text-sm">
              {store.address && (
                <div className="flex gap-2">
                  <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="text-[#64748B] shrink-0"><path d="M12 2a8 8 0 0 0-8 8c0 5.25 8 12 8 12s8-6.75 8-12a8 8 0 0 0-8-8z"/><circle cx="12" cy="10" r="3"/></svg>
                  <span className="text-[#475569] dark:text-[#CBD5E1]">{store.address}</span>
                </div>
              )}
              {store.working_hours && (
                <div className="flex gap-2">
                  <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="text-[#64748B] shrink-0"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                  <span className="text-[#475569] dark:text-[#CBD5E1]">{store.working_hours}</span>
                </div>
              )}
            </div>
            <div className="flex flex-col gap-2 pt-2">
              {waUrl && (
                <Link href={waUrl} className="btn-primary py-2.5 rounded-xl text-xs gap-1.5">
                  <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"/></svg>
                  WhatsApp Sipariş & Destek
                </Link>
              )}
              {mapsUrl && (
                <Link href={mapsUrl} className="btn-secondary py-2.5 rounded-xl text-xs gap-1.5">
                  <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polygon points="3 6 9 3 15 6 21 3 21 18 15 21 9 18 3 21"/><line x1="9" y1="3" x2="9" y2="18"/><line x1="15" y1="6" x2="15" y2="21"/></svg>
                  Haritada Yol Tarifi
                </Link>
              )}
            </div>
          </div>

          {/* Social Links & Review QR */}
          <div className="card space-y-4 bg-white dark:bg-[#131A22] flex flex-col justify-between">
            <h2 className="text-base font-extrabold">Bağlantılar & Yorumlar</h2>
            <div className="flex flex-col gap-2">
              {store.instagram && (
                <Link href={`https://instagram.com/${store.instagram.replace("@", "")}`} className="flex items-center justify-between p-3 bg-slate-50 dark:bg-slate-900 border border-[#D0E4E8] dark:border-[#243141] rounded-xl hover:bg-slate-100 text-xs font-bold">
                  <span className="flex items-center gap-2">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" className="text-pink-500"><rect x="2" y="2" width="20" height="20" rx="5" ry="5"/><path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"/><line x1="17.5" y1="6.5" x2="17.51" y2="6.5"/></svg>
                    Instagram
                  </span>
                  <span className="text-[#64748B]">{store.instagram}</span>
                </Link>
              )}
              {store.website && (
                <Link href={store.website.startsWith("http") ? store.website : `https://${store.website}`} className="flex items-center justify-between p-3 bg-slate-50 dark:bg-slate-900 border border-[#D0E4E8] dark:border-[#243141] rounded-xl hover:bg-slate-100 text-xs font-bold">
                  <span className="flex items-center gap-2">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" className="text-[#38A0E4]"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>
                    Web Sitemiz
                  </span>
                  <span className="text-clip overflow-hidden max-w-[150px] text-[#64748B]">{store.website}</span>
                </Link>
              )}
            </div>
            {store.google_business_link && (
              <Link href={store.google_business_link} className="btn-secondary py-2.5 rounded-xl text-xs gap-1.5 border-amber-300 bg-amber-50 hover:bg-amber-100 text-[#EA580C] dark:bg-[#1B242F] dark:border-amber-900">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
                Google&apos;da Bizi Değerlendirin
              </Link>
            )}
          </div>
        </div>

        {/* Offerings & Services */}
        {offerings.length > 0 && (
          <div className="card space-y-4 bg-white dark:bg-[#131A22]">
            <h2 className="text-base font-extrabold">Hizmetlerimiz</h2>
            <div className="divide-y divide-slate-100 dark:divide-slate-800">
              {offerings.map((offering: OfferingItem, i: number) => (
                <div key={offering.id || i} className="py-3 flex justify-between items-center gap-4">
                  <div className="space-y-0.5">
                    <h3 className="font-bold text-sm text-[#182028] dark:text-white">{offering.title}</h3>
                    {offering.description && <p className="text-xs text-[#64748B] dark:text-[#94A3B8]">{offering.description}</p>}
                  </div>
                  <div className="text-right shrink-0">
                    <div className="text-sm font-bold text-[#0EA8B0]">{offering.price || "Fiyat Sorun"}</div>
                    {offering.durationMinutes && <div className="text-[10px] text-slate-400 font-semibold">{offering.durationMinutes} dk</div>}
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Products List */}
        {products.length > 0 && (
          <div className="card space-y-4 bg-white dark:bg-[#131A22]">
            <h2 className="text-base font-extrabold">Ürün Kataloğumuz</h2>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {products.map((product: ProductItem, i: number) => (
                <div key={product.id || i} className="p-4 border border-[#D0E4E8] dark:border-[#243141] rounded-xl flex gap-3 items-start bg-slate-50/50 dark:bg-slate-900/30">
                  {product.imagePath && (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={product.imagePath} alt={product.name} className="w-16 h-16 object-cover rounded-lg border border-[#D0E4E8] dark:border-[#243141] shrink-0" />
                  )}
                  <div className="flex-1 space-y-1">
                    <h3 className="font-bold text-sm leading-tight text-[#182028] dark:text-white">{product.name}</h3>
                    {product.description && <p className="text-xs text-[#64748B] dark:text-[#94A3B8] leading-relaxed line-clamp-2">{product.description}</p>}
                    <div className="flex items-center justify-between pt-1">
                      <span className="text-xs font-extrabold text-[#38A0E4]">{product.price || "Fiyat Sorun"}</span>
                      {product.stockStatus && (
                        <span className={`text-[10px] font-bold px-1.5 py-0.5 rounded ${product.stockStatus === "Mevcut" ? "bg-emerald-500/10 text-emerald-600" : "bg-rose-500/10 text-rose-600"}`}>
                          {product.stockStatus}
                        </span>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Marketplace links */}
        {marketplaceLinks.length > 0 && (
          <div className="space-y-2">
            <h2 className="text-base font-extrabold px-1">Online Satış Kanallarımız</h2>
            <div className="grid grid-cols-2 gap-3">
              {marketplaceLinks.map((link: MarketplaceLinkItem, i: number) => (
                <Link key={link.id || i} href={link.url.startsWith("http") ? link.url : `https://${link.url}`} className="p-3 bg-white dark:bg-[#131A22] border border-[#D0E4E8] dark:border-[#243141] rounded-xl hover:bg-slate-50 dark:hover:bg-slate-900/50 flex flex-col gap-1 shadow-sm">
                  <span className="text-xs font-extrabold text-[#38A0E4]">{link.platform}</span>
                  {link.subtitle && <span className="text-[10px] text-[#64748B] dark:text-[#94A3B8] font-bold line-clamp-1">{link.subtitle}</span>}
                </Link>
              ))}
            </div>
          </div>
        )}

        {/* Blog Posts Highlight */}
        {articles.length > 0 && (
          <div className="card space-y-4 bg-white dark:bg-[#131A22]">
            <div className="flex justify-between items-center">
              <h2 className="text-base font-extrabold">Son Yazılarımız</h2>
              <Link href={`/v/${store.slug}/yazilar`} className="text-xs font-bold text-[#10D8D8] hover:underline">
                Tümünü Gör
              </Link>
            </div>
            <div className="grid gap-3">
              {articles.map((article) => (
                <Link key={article.id} href={`/v/${store.slug}/yazilar/${article.slug}`} className="p-3 border border-[#D0E4E8] dark:border-[#243141] hover:border-[#10D8D8] rounded-xl flex gap-3 bg-slate-50/50 dark:bg-slate-900/30">
                  {article.cover_image_url && (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={article.cover_image_url} alt={article.title} className="w-12 h-12 object-cover rounded-lg border shrink-0" />
                  )}
                  <div className="space-y-1">
                    <h3 className="font-bold text-xs text-[#182028] dark:text-white line-clamp-1">{article.title}</h3>
                    <p className="text-[10px] text-[#64748B] dark:text-[#94A3B8] line-clamp-2">{article.summary || article.content.substring(0, 100)}</p>
                  </div>
                </Link>
              ))}
            </div>
          </div>
        )}
      </div>
    </>
  );
}
