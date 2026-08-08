"use client";

import Image from "next/image";
import { getAppUrl } from "@/lib/siteUrl";

/** Eylem butonunun arkasındaki şema alanı.
 *
 * Sahip modunda bu butonlar LİNK DEĞİL, düzenleme kancasıdır. Eskiden
 * esnaf kendi WhatsApp'ına mesaj atıyor ya da kendi haritasına gidiyordu;
 * düzenleme kutusu hiç açılmıyordu (2026-08-07, bulgu 6). Casper:
 * "whatsaptan kendi kendimize mesaj atmak veya instagramda kendi
 * sayfamızı açmak için değil".
 *
 * Ziyaretçi modunda hiçbir şey değişmez — editableProps boş nesne döner.
 */
const EYLEM_ALANI: Record<string, string> = {
  telefon: "telefon",
  whatsapp: "whatsapp",
  maps: "adres",
  website: "website",
};
import Link from "next/link";
import { Suspense, type ReactNode, useState } from "react";
import type { VitrinCategoryProfile } from "@/lib/vitrinProfile";
import { normalizeAddressDisplay } from "@/lib/vitrinCopy";
import {
  GlobeIcon,
  InstagramIcon,
  LinkIcon,
  MapPinIcon,
  MessageIcon,
  WhatsAppIcon,
} from "@/lib/vitrinBrandIcons";
import { editableProps } from "@/lib/vitrinEditableProps";
import { heroActions } from "@/lib/vitrinHeroActions";

export interface VitrinGalleryItem {
  id?: string;
  imageUrl: string;
  title?: string;
}

export interface VitrinMarketplaceLink {
  id?: string;
  platform: string;
  url: string;
  subtitle?: string;
}

export interface VitrinArticleTeaser {
  id: string;
  slug: string;
  title: string;
  summary?: string | null;
  content: string;
}

export interface VitrinCollection {
  name: string;
  count: number;
  imageUrl?: string;
}

export interface VitrinFeaturedBanner {
  label: string;
  title: string;
  description: string;
  priceText: string;
  imageUrl: string;
}

export interface VitrinAboutValue {
  id?: string;
  title: string;
  description: string;
}

export interface VitrinAboutSection {
  kicker: string;
  title: string;
  body: string;
  imageUrl: string;
  imageCaption: string;
  values: VitrinAboutValue[];
}

export interface VitrinGallerySection {
  kicker: string;
  title: string;
  items: VitrinGalleryItem[];
}

export interface VitrinFaqItem {
  id?: string;
  question: string;
  answer: string;
}

export interface VitrinProfileViewProps {
  storeName: string;
  storeSlug: string;
  kategori: string | null;
  businessType: string | null;
  status: string | null;
  isClosed?: boolean;
  logoUrl: string | null;
  heroImage: string;
  heroBadge?: string | null;
  description: string;
  corporateBio: string | null;
  address: string | null;
  phone?: string | null;
  phoneUrl?: string | null;
  email?: string | null;
  featuredBanner?: VitrinFeaturedBanner | null;
  aboutSection?: VitrinAboutSection | null;
  gallerySection?: VitrinGallerySection | null;
  faqItems?: VitrinFaqItem[];
  showStorefrontRating?: boolean;
  ratingScore?: number | null;
  reviewCount?: number | null;
  workingHoursToday: string | null;
  workingHoursWeek: Array<{ day: string; hours: string; isToday: boolean }>;
  googleBusinessLink: string | null;
  publicUrl: string;
  whatsappUrl: string | null;
  instagramUrl: string | null;
  websiteUrl: string | null;
  mapsUrl: string | null;
  mapsEmbedUrl: string | null;
  referencesUrl: string | null;
  isBookingEnabled: boolean;
  profile: VitrinCategoryProfile;
  collections: VitrinCollection[];
  productCount: number;
  galleryItems: VitrinGalleryItem[];
  marketplaceLinks: VitrinMarketplaceLink[];
  articles: VitrinArticleTeaser[];
  catalog: ReactNode;
  isPreviewMode?: boolean;
  /**
   * Sahip modu. Yalnız true iken vitrindeki öğelere tıkla-düzenle
   * işaretleri eklenir. Müşteri görünümünde bu öznitelikler DOM'a hiç
   * yazılmaz — koruma sınırı 3 (sahip araçları müşteri yanıtına sızmaz).
   */
  ownerMode?: boolean;
  /** Kiralık demo vitrin mi — kiralama bandı yalnız burada çıkar. */
  isDemo?: boolean;
}

export default function VitrinProfileView({
  storeName,
  storeSlug,
  kategori,
  businessType,
  status,
  isClosed,
  logoUrl,
  heroImage,
  heroBadge,
  description,
  corporateBio,
  address,
  phone,
  phoneUrl,
  email,
  featuredBanner,
  aboutSection,
  gallerySection,
  faqItems = [],
  showStorefrontRating = false,
  ratingScore = null,
  reviewCount = null,
  workingHoursToday,
  workingHoursWeek,
  googleBusinessLink,
  publicUrl,
  whatsappUrl,
  instagramUrl,
  websiteUrl,
  mapsUrl,
  mapsEmbedUrl,
  referencesUrl,
  isBookingEnabled,
  profile,
  collections,
  productCount,
  galleryItems,
  marketplaceLinks,
  articles,
  catalog,
  isPreviewMode = false,
  ownerMode = false,
  isDemo = false,
}: VitrinProfileViewProps) {
  const [copied, setCopied] = useState(false);
  const displayAddress = normalizeAddressDisplay(address);
  const displayBadge = String(heroBadge || kategori || businessType || "").trim();
  const showOpenBadge =
    typeof isClosed === "boolean" && (Boolean(workingHoursToday) || isClosed);
  const displayPhone = String(phone || "").trim();
  const displayEmail = String(email || "").trim();
  const hasPhone = Boolean(phoneUrl && displayPhone);
  const featuredLabel = String(featuredBanner?.label || "").trim();
  const featuredTitle = String(featuredBanner?.title || "").trim();
  const featuredDescription = String(featuredBanner?.description || "").trim();
  const featuredPriceText = String(featuredBanner?.priceText || "").trim();
  const featuredImageUrl = String(featuredBanner?.imageUrl || "").trim();
  const showFeaturedBanner = Boolean(
    featuredLabel ||
      featuredTitle ||
      featuredDescription ||
      featuredPriceText ||
      featuredImageUrl
  );
  const aboutTitle = String(aboutSection?.title || "").trim();
  const aboutKicker = String(aboutSection?.kicker || "").trim();
  const aboutBody = String(aboutSection?.body || "").trim();
  const aboutImageUrl = String(aboutSection?.imageUrl || "").trim();
  const aboutImageCaption = String(aboutSection?.imageCaption || "").trim();
  const aboutParagraphs = aboutBody
    .split(/\n+/)
    .map((part) => part.trim())
    .filter(Boolean);
  const aboutValues = (aboutSection?.values || []).filter(
    (value) => value.title.trim() && value.description.trim()
  );
  const showAbout =
    Boolean(aboutTitle) && (aboutParagraphs.length > 0 || aboutValues.length > 0);
  const galleryMeta = gallerySection || {
    kicker: "",
    title: "",
    items: galleryItems,
  };
  const visibleGalleryItems = (galleryMeta.items || []).filter((item) =>
    String(item.imageUrl || "").trim()
  );
  const showGallery = visibleGalleryItems.length > 0;
  const galleryKicker = String(galleryMeta.kicker || "").trim();
  const galleryTitle = String(galleryMeta.title || "").trim() || "Galeri";
  const visibleFaqItems = (faqItems || []).filter(
    (item) => item.question.trim() && item.answer.trim()
  );
  const showFaq = visibleFaqItems.length > 0;
  const visibleArticles = (articles || []).filter((article) =>
    String(article.title || "").trim()
  );
  const showArticles = visibleArticles.length > 0;
  const showRating =
    showStorefrontRating &&
    typeof ratingScore === "number" &&
    Number.isFinite(ratingScore);
  const showContact =
    Boolean(displayAddress) ||
    hasPhone ||
    Boolean(whatsappUrl) ||
    Boolean(displayEmail) ||
    Boolean(workingHoursToday) ||
    Boolean(mapsEmbedUrl) ||
    Boolean(mapsUrl);
  const telForVcard = displayPhone || "";
  const vcardContent = `BEGIN:VCARD\nVERSION:3.0\nFN:${storeName}\nTEL:${telForVcard}\nEMAIL:${displayEmail}\nEND:VCARD`;
  const vcardHref = `data:text/vcard;charset=utf-8,${encodeURIComponent(vcardContent)}`;
  const primaryActionClass =
    "flex items-center justify-center gap-2.5 px-7 py-3.5 rounded-xl font-semibold bg-gradient-to-r from-blue-600 to-blue-700 text-white shadow-lg shadow-blue-500/25 hover:shadow-blue-500/40 hover:-translate-y-0.5 transition";
  const ghostActionClass =
    "flex items-center justify-center gap-2.5 px-7 py-3.5 rounded-xl font-semibold bg-white/5 text-white border border-blue-500/20 backdrop-blur-md hover:bg-white/10 transition";

  // Hero butonları kategori profiline göre üretilir (vitrinHeroActions).
  const heroButonlari = heroActions(profile, {
    phoneUrl: phoneUrl ?? null,
    whatsappNumarasi: whatsappUrl?.match(/wa\.me\/([0-9]+)/)?.[1] ?? null,
    mapsUrl: mapsUrl ?? null,
    websiteUrl: websiteUrl ?? null,
  });

  const handleCopyUrl = () => {
    if (typeof navigator !== "undefined" && navigator.clipboard) {
      navigator.clipboard.writeText(publicUrl);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  };

  const formattedUrlDisplay = publicUrl.replace(/^https?:\/\//i, "");

  return (
    <div className="min-h-screen bg-[#0B1120] text-[#F8FAFC] font-sans selection:bg-blue-500 selection:text-white">
      {isPreviewMode && (
        <div className="fixed top-0 left-0 right-0 z-[60] h-9 bg-amber-500 text-[#0B1120] text-xs sm:text-sm font-bold flex items-center justify-center gap-2">
          Taslak önizleme — bu vitrin henüz yayında değil, müşteriler göremez.
        </div>
      )}
      {/* ===== NAVBAR ===== */}
      <nav
        className={`fixed left-0 right-0 z-50 h-[68px] bg-[#0B1120]/85 backdrop-blur-xl border-b border-blue-500/15 px-6 sm:px-8 flex items-center justify-between ${isPreviewMode ? "top-9" : "top-0"}`}
      >
        {/* Kök rota başka uygulama hostuna yönlenir; RSC yerine tam sayfa geçişi gerekir. */}
        {/* eslint-disable-next-line @next/next/no-html-link-for-pages */}
        <a href="/" className="flex items-center gap-3 font-extrabold text-xl tracking-tight text-white">
          <svg className="w-7 h-7 text-blue-500" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <rect x="3" y="3" width="7" height="7" rx="1.5" />
            <rect x="14" y="3" width="7" height="7" rx="1.5" />
            <rect x="14" y="14" width="7" height="7" rx="1.5" />
            <rect x="3" y="14" width="7" height="7" rx="1.5" />
          </svg>
          VIX<span className="text-blue-400">REX</span>
        </a>

        <div className="hidden md:flex items-center gap-8 text-sm font-medium text-slate-400">
          {productCount > 0 && (
            <a href="#urunler" className="hover:text-white transition-colors">Ürünler</a>
          )}
          {collections.length > 0 && (
            <a href="#kategoriler" className="hover:text-white transition-colors">Kategoriler</a>
          )}
          {showAbout && (
            <a href="#hakkimizda" className="hover:text-white transition-colors">Hakkımızda</a>
          )}
          {showGallery && (
            <a href="#galeri" className="hover:text-white transition-colors">Galeri</a>
          )}
          {showFaq && (
            <a href="#sss" className="hover:text-white transition-colors">SSS</a>
          )}
          {showContact && (
            <a href="#iletisim" className="hover:text-white transition-colors">İletişim</a>
          )}
          <Link href={getAppUrl()} className="bg-gradient-to-r from-blue-600 to-blue-700 text-white px-5 py-2.5 rounded-xl font-semibold text-sm shadow-lg shadow-blue-500/25 hover:shadow-blue-500/40 transition">
            Vitrin Oluştur
          </Link>
        </div>
      </nav>

      {/* ===== HERO ===== */}
      <section
        className={`relative w-full min-h-[360px] sm:min-h-[420px] flex items-end overflow-hidden ${isPreviewMode ? "pt-[104px]" : "pt-[68px]"}`}
      >
        {/* Kapak yoksa SAHTE FOTOĞRAF BASILMAZ.
            Eskiden burada sabit bir Unsplash adresi vardı: kapak
            koymamış her işletme — butikçi de, kuaför de — aynı yabancı
            fotoğrafla açılıyordu. Esnaf "ben bunu koymadım" diyordu ve
            haklıydı; kendi vitrini gibi hissettirmiyordu.
            Yerine kendi renk dilimizde sade bir zemin: boş görünmüyor,
            ama sahip olmadığı bir şeyi de sahiplenmiyor. */}
        <div
          className={
            heroImage
              ? "absolute inset-0 bg-cover bg-center"
              : "absolute inset-0 bg-gradient-to-br from-[#111C33] via-[#0B1120] to-[#16223D]"
          }
          style={heroImage ? { backgroundImage: `url(${heroImage})` } : undefined}
        >
          <div className="absolute inset-0 bg-gradient-to-t from-[#0B1120] via-[#0B1120]/75 to-[#0B1120]/30" />
        </div>

        <div className="relative z-10 w-full max-w-7xl mx-auto px-6 sm:px-8 py-8 sm:py-10 grid md:grid-cols-[1fr_auto] gap-6 items-end">
          <div className="max-w-2xl">
            {(displayBadge || showOpenBadge) && (
              <div className="flex flex-wrap items-center gap-2 mb-3">
                {displayBadge && (
                  <div
                    {...editableProps("heroRozet", ownerMode)}
                    className="inline-flex items-center gap-2 bg-blue-500/12 border border-blue-500/25 text-blue-400 px-3.5 py-1 rounded-full text-xs font-bold uppercase tracking-wider backdrop-blur-md"
                  >
                    <span className="w-2 h-2 rounded-full bg-blue-500 shadow-[0_0_10px_#3B82F6]" />
                    {displayBadge}
                  </div>
                )}
                {showOpenBadge && (
                  <div
                    className={`inline-flex items-center gap-2 px-3.5 py-1 rounded-full text-xs font-bold uppercase tracking-wider backdrop-blur-md ${
                      isClosed
                        ? "bg-red-500/12 border border-red-500/25 text-red-300"
                        : "bg-green-500/12 border border-green-500/25 text-green-300"
                    }`}
                  >
                    <span
                      className={`w-2 h-2 rounded-full ${
                        isClosed
                          ? "bg-red-500 shadow-[0_0_10px_#EF4444]"
                          : "bg-green-500 shadow-[0_0_10px_#22C55E]"
                      }`}
                    />
                    {isClosed ? "Şu an kapalı" : "Şu an açık"}
                  </div>
                )}
              </div>
            )}

            <div className="flex items-center gap-3 sm:gap-4 mb-2">
              <div className="w-12 h-12 sm:w-14 sm:h-14 rounded-xl overflow-hidden border border-blue-500/20 bg-blue-500/10 flex items-center justify-center shrink-0">
                {logoUrl ? (
                  <Image
                    src={logoUrl}
                    alt={storeName}
                    width={56}
                    height={56}
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <span className="text-blue-400 font-extrabold text-xl sm:text-2xl uppercase">
                    {storeName.charAt(0)}
                  </span>
                )}
              </div>

              <h1
                {...editableProps("isletmeAdi", ownerMode)}
                className="text-3xl sm:text-5xl font-extrabold tracking-tight bg-gradient-to-r from-white to-blue-200 bg-clip-text text-transparent"
              >
                {storeName.toUpperCase()}
              </h1>
            </div>

            {description.trim() && (
              <p
                {...editableProps("kisaTanitim", ownerMode)}
                className="text-slate-300 text-sm sm:text-base max-w-xl mb-4 leading-relaxed line-clamp-2"
              >
                {description}
              </p>
            )}

            {(displayAddress || displayEmail || workingHoursToday || showRating) && (
              <div className="flex flex-wrap gap-4 text-sm text-slate-400">
                {displayAddress && <span className="flex items-center gap-1.5">📍 {displayAddress}</span>}
                {showRating && (
                  <span className="flex items-center gap-1.5">
                    ⭐ {ratingScore!.toFixed(1)}
                    {typeof reviewCount === "number" && reviewCount > 0
                      ? ` (${reviewCount} değerlendirme)`
                      : ""}
                  </span>
                )}
                {displayEmail && (
                  <a href={`mailto:${displayEmail}`} className="flex items-center gap-1.5 hover:text-blue-300 transition">
                    ✉️ {displayEmail}
                  </a>
                )}
                {workingHoursToday && <span className="flex items-center gap-1.5">🕐 {workingHoursToday}</span>}
              </div>
            )}
          </div>

          {heroButonlari.length > 0 && (
            <div className="flex flex-col sm:flex-row md:flex-col gap-3 min-w-[200px]">
              {heroButonlari.map((buton, index) => (
                <a
                  key={buton.anahtar}
                  href={buton.href}
                  {...(buton.disKapi
                    ? { target: "_blank", rel: "noopener noreferrer" }
                    : {})}
                  {...editableProps(EYLEM_ALANI[buton.anahtar] ?? "", ownerMode)}
                  className={index === 0 ? primaryActionClass : ghostActionClass}
                >
                  {buton.anahtar === "telefon" && (
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
                      <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z" />
                    </svg>
                  )}
                  {buton.anahtar === "whatsapp" && <WhatsAppIcon size={18} />}
                  {buton.anahtar === "maps" && <MapPinIcon size={18} />}
                  {buton.anahtar === "website" && <GlobeIcon size={18} />}
                  {buton.etiket}
                </a>
              ))}
            </div>
          )}
        </div>
      </section>

      {/* ===== CATEGORIES ===== */}
      {collections.length > 0 && (
        <section className="max-w-7xl mx-auto px-6 sm:px-8 py-12" id="kategoriler">
          <div className="flex items-baseline justify-between mb-8">
            <h2 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-white">Kategoriler</h2>
            <a href="#urunler" className="text-sm font-semibold text-blue-400 hover:text-blue-300 transition">Tümünü gör →</a>
          </div>

          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4">
            {collections.map((cat, idx) => (
              <div
                key={cat.name}
                className="group relative h-44 rounded-2xl overflow-hidden cursor-pointer border border-blue-500/15 hover:border-blue-500/30 transition shadow-lg"
              >
                {/* Aynı kural: görseli olmayan kategoriye yabancı bir
                    fotoğraf konmaz. Kendi kapağı varsa o kullanılır,
                    yoksa sade zemin — ad zaten üstünde yazıyor. */}
                {cat.imageUrl || heroImage ? (
                  <Image
                    src={cat.imageUrl || heroImage}
                    alt={cat.name}
                    fill
                    className="object-cover transition duration-500 group-hover:scale-105"
                  />
                ) : (
                  <div className="absolute inset-0 bg-gradient-to-br from-[#16223D] to-[#0B1120]" />
                )}
                <div className="absolute inset-0 bg-gradient-to-t from-[#0B1120]/90 via-transparent to-transparent" />
                <div className="absolute bottom-4 left-4 z-10 text-base font-bold text-white">{cat.name}</div>
                <div className="absolute bottom-4 right-4 z-10 text-xs font-semibold text-slate-300 bg-black/40 backdrop-blur-md px-3 py-1 rounded-full">
                  {cat.count} ürün
                </div>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* ===== FEATURED BANNER ===== */}
      {showFeaturedBanner && (
        <div className="max-w-7xl mx-auto px-6 sm:px-8 mb-12">
          <div
            className={`relative overflow-hidden rounded-3xl border border-blue-500/15 bg-gradient-to-r from-blue-500/10 via-cyan-500/5 to-transparent p-8 sm:p-11 ${
              featuredImageUrl ? "grid md:grid-cols-2 gap-8 items-center" : ""
            }`}
          >
            <div>
              {featuredLabel && (
                <span
                  {...editableProps("bantEtiket", ownerMode)}
                  className="inline-block bg-gradient-to-r from-blue-600 to-blue-700 text-white text-xs font-extrabold uppercase tracking-wider px-4 py-1.5 rounded-lg mb-4 shadow-md"
                >
                  {featuredLabel}
                </span>
              )}
              {featuredTitle && (
                <h2
                  {...editableProps("bantBaslik", ownerMode)}
                  className="text-2xl sm:text-4xl font-extrabold tracking-tight mb-3 text-white"
                >
                  {featuredTitle}
                </h2>
              )}
              {featuredDescription && (
                <p
                  {...editableProps("bantAciklama", ownerMode)}
                  className="text-slate-300 text-base mb-6 max-w-md leading-relaxed"
                >
                  {featuredDescription}
                </p>
              )}
              {featuredPriceText && (
                <div
                  {...editableProps("bantFiyat", ownerMode)}
                  className="text-3xl font-extrabold text-blue-400 tracking-tight"
                >
                  {featuredPriceText}
                </div>
              )}
            </div>

            {featuredImageUrl && (
              <div {...editableProps("bantGorsel", ownerMode)} className="h-64 sm:h-72 rounded-2xl overflow-hidden border border-blue-500/15 relative">
                <Image
                  src={featuredImageUrl}
                  alt={featuredTitle || featuredLabel || "Öne çıkan kampanya"}
                  fill
                  className="object-cover"
                />
              </div>
            )}
          </div>
        </div>
      )}

      {/* ===== PRODUCTS ===== */}
      {productCount > 0 && (
        <section className="max-w-7xl mx-auto px-6 sm:px-8 py-8" id="urunler">
          <div className="flex items-baseline justify-between mb-8">
            <h2 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-white">Tüm Ürünler</h2>
            <span className="text-sm font-semibold text-slate-400">{productCount} Ürün Listeleniyor</span>
          </div>

          <Suspense fallback={<div className="h-64 flex items-center justify-center text-slate-400">Ürünler yükleniyor...</div>}>
            {catalog}
          </Suspense>
        </section>
      )}

      {/* ===== ABOUT ===== */}
      {showAbout && (
        <section className="max-w-7xl mx-auto px-6 sm:px-8 py-12" id="hakkimizda">
          <div className={`grid gap-10 items-start ${aboutImageUrl ? "md:grid-cols-2" : ""}`}>
            {aboutImageUrl && (
              <div {...editableProps("hakkindaGorsel", ownerMode)} className="relative min-h-[280px] rounded-3xl overflow-hidden border border-blue-500/15">
                <Image
                  src={aboutImageUrl}
                  alt={aboutTitle}
                  fill
                  className="object-cover"
                />
                {aboutImageCaption && (
                  <p
                    {...editableProps("hakkindaGorselAlt", ownerMode)}
                    className="absolute bottom-0 left-0 right-0 bg-[#0B1120]/80 px-4 py-3 text-xs text-slate-200"
                  >
                    {aboutImageCaption}
                  </p>
                )}
              </div>
            )}
            <div>
              {aboutKicker && (
                <p
                  {...editableProps("hakkindaUstBaslik", ownerMode)}
                  className="text-xs font-bold uppercase tracking-[0.18em] text-blue-400 mb-3"
                >
                  {aboutKicker}
                </p>
              )}
              <h2
                {...editableProps("hakkindaBaslik", ownerMode)}
                className="text-2xl sm:text-4xl font-extrabold tracking-tight text-white mb-5 leading-tight"
              >
                {aboutTitle}
              </h2>
              <div
                {...editableProps("hakkindaMetin", ownerMode)}
                className="space-y-4 text-slate-300 text-sm sm:text-base leading-relaxed"
              >
                {aboutParagraphs.map((paragraph) => (
                  <p key={paragraph.slice(0, 24)}>{paragraph}</p>
                ))}
              </div>
              {aboutValues.length > 0 && (
                <div className="mt-8 grid sm:grid-cols-3 gap-4">
                  {aboutValues.map((value, index) => (
                    <div
                      key={value.id || value.title}
                      className="rounded-2xl border border-blue-500/15 bg-slate-900/50 p-4"
                    >
                      <span className="text-xs font-extrabold text-blue-400">
                        {String(index + 1).padStart(2, "0")}
                      </span>
                      <h3 className="mt-2 text-sm font-bold text-white">{value.title}</h3>
                      <p className="mt-1 text-xs text-slate-400 leading-relaxed">{value.description}</p>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </section>
      )}

      {/* ===== GALLERY ===== */}
      {showGallery && (
        <section className="max-w-7xl mx-auto px-6 sm:px-8 py-12" id="galeri">
          <div className="flex items-baseline justify-between mb-8 gap-4">
            <div>
              {galleryKicker && (
                <p
                  {...editableProps("galeriUstBaslik", ownerMode)}
                  className="text-xs font-bold uppercase tracking-[0.18em] text-blue-400 mb-2"
                >
                  {galleryKicker}
                </p>
              )}
              <h2
                {...editableProps("galeriBaslik", ownerMode)}
                className="text-2xl sm:text-3xl font-extrabold tracking-tight text-white"
              >
                {galleryTitle}
              </h2>
            </div>
            {showContact && (
              <a href="#iletisim" className="text-sm font-semibold text-blue-400 hover:text-blue-300 transition shrink-0">
                Mağazaya gel →
              </a>
            )}
          </div>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3 sm:gap-4 auto-rows-[160px] sm:auto-rows-[200px]">
            {visibleGalleryItems.slice(0, 8).map((item, index) => (
              <figure
                key={item.id || item.imageUrl}
                className={`relative overflow-hidden rounded-2xl border border-blue-500/15 ${
                  index === 0 ? "md:col-span-2 md:row-span-2" : ""
                }`}
              >
                <Image
                  src={item.imageUrl}
                  alt={item.title || "Galeri"}
                  fill
                  className="object-cover transition duration-500 hover:scale-105"
                />
                {item.title && (
                  <figcaption className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-[#0B1120]/90 to-transparent px-3 py-3 text-xs font-semibold text-white">
                    {item.title}
                  </figcaption>
                )}
              </figure>
            ))}
          </div>
        </section>
      )}

      {/* ===== ARTICLES ===== */}
      {showArticles && (
        <section className="max-w-7xl mx-auto px-6 sm:px-8 py-12" id="blog">
          <div className="flex items-baseline justify-between mb-8">
            <h2 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-white">Yazılar</h2>
            <Link href={`/v/${storeSlug}/yazilar`} className="text-sm font-semibold text-blue-400 hover:text-blue-300 transition">
              {visibleArticles.length} yazı →
            </Link>
          </div>
          <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {visibleArticles.slice(0, 3).map((article) => (
              <Link
                key={article.id}
                href={`/v/${storeSlug}/yazilar/${article.slug}`}
                className="rounded-2xl border border-blue-500/15 bg-slate-900/60 p-5 hover:border-blue-500/30 transition"
              >
                <h3 className="text-base font-bold text-white mb-2 line-clamp-2">{article.title}</h3>
                <p className="text-xs text-slate-400 line-clamp-3">
                  {article.summary || article.content}
                </p>
                <span className="mt-4 inline-block text-xs font-semibold text-blue-400">Yazıyı oku →</span>
              </Link>
            ))}
          </div>
        </section>
      )}

      {/* ===== FAQ ===== */}
      {showFaq && (
        <section className="max-w-7xl mx-auto px-6 sm:px-8 py-12" id="sss">
          <div className="grid lg:grid-cols-[0.9fr_1.1fr] gap-8 items-start">
            <div>
              <p className="text-xs font-bold uppercase tracking-[0.18em] text-blue-400 mb-3">SSS</p>
              <h2 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-white mb-3">
                Sıkça sorulan sorular
              </h2>
              <p className="text-sm text-slate-400 leading-relaxed">
                Sipariş, stok ve mağaza ziyareti hakkında merak edilenler.
              </p>
            </div>
            <div className="space-y-3">
              {visibleFaqItems.map((item, index) => (
                <details
                  key={item.id || item.question}
                  open={index === 0}
                  className="rounded-2xl border border-blue-500/15 bg-slate-900/60 px-5 py-4"
                >
                  <summary className="cursor-pointer list-none text-sm font-bold text-white pr-6 relative after:content-['+'] after:absolute after:right-0 after:top-0 after:text-blue-400">
                    {item.question}
                  </summary>
                  <p className="mt-3 text-sm text-slate-300 leading-relaxed">{item.answer}</p>
                </details>
              ))}
            </div>
          </div>
        </section>
      )}

      {/* ===== CONTACT & LOCATION ===== */}
      {showContact && (
      <div className="max-w-7xl mx-auto px-6 sm:px-8 py-12" id="iletisim">
        <div className="grid md:grid-cols-2 gap-6">
          {/* Left Contact Panel */}
          <div className="relative overflow-hidden rounded-3xl bg-slate-900/60 border border-blue-500/15 backdrop-blur-xl p-8">
            <div className="flex items-center gap-3 text-lg font-bold text-white mb-6">
              <div className="w-9 h-9 rounded-xl bg-blue-500/15 border border-blue-500/20 flex items-center justify-center text-lg">📍</div>
              İletişim & Konum
            </div>

            <div className="space-y-5">
              {displayAddress && (
                <div className="flex items-start gap-4 pb-4 border-b border-blue-500/10">
                  <div className="w-10 h-10 rounded-xl bg-slate-800 border border-blue-500/15 flex items-center justify-center text-lg shrink-0">🏠</div>
                  <div>
                    <h4 className="text-sm font-bold text-white">Adres</h4>
                    <p
                      {...editableProps("adres", ownerMode)}
                      className="text-xs text-slate-300 leading-relaxed mt-0.5"
                    >
                      {displayAddress}
                    </p>
                  </div>
                </div>
              )}

              {hasPhone && (
                <div className="flex items-start gap-4 pb-4 border-b border-blue-500/10">
                  <div className="w-10 h-10 rounded-xl bg-slate-800 border border-blue-500/15 flex items-center justify-center text-lg shrink-0">📞</div>
                  <div
                    {...editableProps("telefon", ownerMode)}
                  >
                    <h4 className="text-sm font-bold text-white">Telefon</h4>
                    <a href={phoneUrl!} className="text-xs font-semibold text-blue-400 hover:text-blue-300">
                      {displayPhone}
                    </a>
                  </div>
                </div>
              )}

              {whatsappUrl && (
                <div className="flex items-start gap-4 pb-4 border-b border-blue-500/10">
                  <div className="w-10 h-10 rounded-xl bg-slate-800 border border-blue-500/15 flex items-center justify-center text-lg shrink-0">💬</div>
                  <div>
                    <h4 className="text-sm font-bold text-white">WhatsApp</h4>
                    <a href={whatsappUrl} target="_blank" rel="noopener noreferrer" {...editableProps("whatsapp", ownerMode)} className="text-xs font-semibold text-blue-400 hover:text-blue-300">
                      WhatsApp&apos;tan İletişime Geç
                    </a>
                  </div>
                </div>
              )}

              {displayEmail && (
                <div className="flex items-start gap-4 pb-4 border-b border-blue-500/10">
                  <div className="w-10 h-10 rounded-xl bg-slate-800 border border-blue-500/15 flex items-center justify-center text-lg shrink-0">✉️</div>
                  <div
                    {...editableProps("eposta", ownerMode)}
                  >
                    <h4 className="text-sm font-bold text-white">E-posta</h4>
                    <a href={`mailto:${displayEmail}`} className="text-xs font-semibold text-blue-400 hover:text-blue-300">
                      {displayEmail}
                    </a>
                  </div>
                </div>
              )}

              {websiteUrl && (
                <div className="flex items-start gap-4 pb-4 border-b border-blue-500/10">
                  <div className="w-10 h-10 rounded-xl bg-slate-800 border border-blue-500/15 flex items-center justify-center text-lg shrink-0">🌐</div>
                  <div
                    {...editableProps("website", ownerMode)}
                  >
                    <h4 className="text-sm font-bold text-white">Web Sitesi</h4>
                    <a href={websiteUrl} target="_blank" rel="noopener noreferrer" className="text-xs font-semibold text-blue-400 hover:text-blue-300">
                      {websiteUrl.replace(/^https?:\/\//i, "")}
                    </a>
                  </div>
                </div>
              )}

              {workingHoursToday && (
                <div className="flex items-start gap-4 pb-4 border-b border-blue-500/10">
                  <div className="w-10 h-10 rounded-xl bg-slate-800 border border-blue-500/15 flex items-center justify-center text-lg shrink-0">🕐</div>
                  <div>
                    <h4 className="text-sm font-bold text-white">Çalışma Saatleri</h4>
                    <p
                      {...editableProps("calismaSaatleri", ownerMode)}
                      className="text-xs text-slate-300 mt-0.5"
                    >
                      {workingHoursToday}
                    </p>
                  </div>
                </div>
              )}

              {marketplaceLinks.length > 0 && (
                <div className="flex items-start gap-4 pb-4 border-b border-blue-500/10">
                  <div className="w-10 h-10 rounded-xl bg-slate-800 border border-blue-500/15 flex items-center justify-center text-lg shrink-0">🛒</div>
                  <div>
                    <h4 className="text-sm font-bold text-white">Pazaryeri Bağlantıları</h4>
                    <div className="mt-0.5 space-y-0.5">
                      {marketplaceLinks.map((link) => (
                        <a
                          key={link.id || link.url || link.platform}
                          href={link.url}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="block text-xs font-semibold text-blue-400 hover:text-blue-300"
                        >
                          {link.platform}
                        </a>
                      ))}
                    </div>
                  </div>
                </div>
              )}

              {googleBusinessLink && (
                <div className="flex items-start gap-4 pb-4 border-b border-blue-500/10">
                  <div className="w-10 h-10 rounded-xl bg-slate-800 border border-blue-500/15 flex items-center justify-center text-lg shrink-0">🏢</div>
                  <div>
                    <h4 className="text-sm font-bold text-white">Google İşletme Profili</h4>
                    <a href={googleBusinessLink} target="_blank" rel="noopener noreferrer" className="text-xs font-semibold text-blue-400 hover:text-blue-300">
                      {googleBusinessLink.replace(/^https?:\/\//i, "")}
                    </a>
                  </div>
                </div>
              )}

              {referencesUrl && (
                <div className="flex items-start gap-4">
                  <div className="w-10 h-10 rounded-xl bg-slate-800 border border-blue-500/15 flex items-center justify-center text-lg shrink-0">📇</div>
                  <div>
                    <h4 className="text-sm font-bold text-white">Referanslar</h4>
                    <a href={referencesUrl} target="_blank" rel="noopener noreferrer" className="text-xs font-semibold text-blue-400 hover:text-blue-300">
                      {referencesUrl.replace(/^https?:\/\//i, "")}
                    </a>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Right Map Panel */}
          {(mapsEmbedUrl || mapsUrl) && (
          <div className="relative overflow-hidden rounded-3xl bg-slate-900/60 border border-blue-500/15 backdrop-blur-xl p-8 flex flex-col justify-between">
            <div className="flex items-center gap-3 text-lg font-bold text-white mb-4">
              <div className="w-9 h-9 rounded-xl bg-blue-500/15 border border-blue-500/20 flex items-center justify-center text-lg">🗺️</div>
              Harita & Navigasyon
            </div>

            <div className="h-60 rounded-2xl overflow-hidden border border-blue-500/15 mb-4 relative">
              {mapsEmbedUrl ? (
                <iframe
                  src={mapsEmbedUrl}
                  width="100%"
                  height="100%"
                  style={{ border: 0, filter: "invert(90%) hue-rotate(180deg) contrast(0.85)" }}
                  allowFullScreen
                  loading="lazy"
                  referrerPolicy="no-referrer-when-downgrade"
                />
              ) : (
                <div className="w-full h-full flex items-center justify-center bg-slate-800/60 text-slate-400 text-sm">
                  🗺️ Konum bilgisi bulunamadı
                </div>
              )}
            </div>

            <div className="flex gap-3">
              {mapsUrl && (
                <a href={mapsUrl} target="_blank" rel="noopener noreferrer" className="flex-1 py-3 px-4 rounded-xl text-xs font-bold text-center bg-gradient-to-r from-blue-600 to-blue-700 text-white shadow-md hover:shadow-blue-500/30 transition">
                  🗺️ Yol Tarifi Al
                </a>
              )}
              <a href={vcardHref} download={`${storeSlug}.vcf`} className="flex-1 py-3 px-4 rounded-xl text-xs font-bold text-center bg-white/5 border border-blue-500/20 text-white hover:bg-white/10 transition">
                📱 Rehbere Ekle
              </a>
            </div>
          </div>
          )}
        </div>
      </div>
      )}

      {/* ===== SHARE & QR SECTION ===== */}
      <div className="max-w-7xl mx-auto px-6 sm:px-8 mb-16">
        <div className="relative overflow-hidden rounded-3xl bg-slate-900/60 border border-blue-500/15 backdrop-blur-xl p-8 sm:p-10">
          <div className="flex items-center gap-3 mb-8">
            <div className="w-11 h-11 rounded-xl bg-gradient-to-r from-blue-600 to-blue-700 flex items-center justify-center text-white shadow-lg shadow-blue-500/25">
              🔗
            </div>
            <div>
              <h3 className="text-xl font-bold text-white">Vitrini Paylaş</h3>
              <p className="text-xs text-slate-400 font-medium">Tek link, her yerde kolay paylaşım</p>
            </div>
          </div>

          <div className="grid lg:grid-cols-[auto_1fr] gap-8 items-center">
            {/* QR Code */}
            <div className="relative p-1 rounded-3xl bg-gradient-to-r from-blue-500/25 to-cyan-500/15 mx-auto">
              <div className="bg-white p-5 rounded-2xl relative text-center">
                <Image
                  src={`https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent(publicUrl)}`}
                  alt="QR Code"
                  width={160}
                  height={160}
                  className="rounded-lg block"
                />
                <span className="absolute -bottom-3 left-1/2 -translate-x-1/2 bg-[#0B1120] border border-blue-500/30 text-blue-400 text-[11px] font-bold px-4 py-1 rounded-full whitespace-nowrap shadow-lg">
                  Tara ve ziyaret et
                </span>
              </div>
            </div>

            {/* Share Links & URL Box */}
            <div className="space-y-5">
              <div className="bg-slate-800/80 border border-blue-500/20 rounded-2xl p-4 flex items-center justify-between gap-4">
                <span className="font-mono text-sm text-slate-300 truncate">{formattedUrlDisplay}</span>
                <button
                  onClick={handleCopyUrl}
                  className="px-4 py-2 rounded-xl bg-blue-500/15 border border-blue-500/30 text-blue-400 text-xs font-bold hover:bg-blue-500/25 transition shrink-0"
                >
                  {copied ? "Kopyalandı!" : "Kopyala"}
                </button>
              </div>

              <div className="h-px bg-gradient-to-r from-transparent via-blue-500/20 to-transparent" />

              <div className="text-xs font-bold uppercase tracking-wider text-slate-400">Sosyal Medyada Paylaş</div>

              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                <a href={`https://api.whatsapp.com/send?text=${encodeURIComponent(publicUrl)}`} target="_blank" rel="noopener noreferrer" className="flex flex-col items-center gap-2 p-4 rounded-2xl bg-slate-800/60 border border-emerald-500/30 hover:border-emerald-500/60 hover:shadow-[0_8px_24px_rgba(34,197,94,0.15)] transition group">
                  <WhatsAppIcon size={24} className="text-[#22C55E] group-hover:scale-110 transition duration-300" />
                  <span className="text-xs font-bold text-slate-300 group-hover:text-white">WhatsApp</span>
                </a>
                <a href={instagramUrl || "#"} target="_blank" rel="noopener noreferrer" className="flex flex-col items-center gap-2 p-4 rounded-2xl bg-slate-800/60 border border-pink-500/30 hover:border-pink-500/60 hover:shadow-[0_8px_24px_rgba(236,72,153,0.15)] transition group">
                  <InstagramIcon size={24} className="text-[#EC4899] group-hover:scale-110 transition duration-300" />
                  <span className="text-xs font-bold text-slate-300 group-hover:text-white">Instagram</span>
                </a>
                <a href={`sms:?body=${encodeURIComponent(publicUrl)}`} className="flex flex-col items-center gap-2 p-4 rounded-2xl bg-slate-800/60 border border-blue-500/30 hover:border-blue-500/60 transition group">
                  <MessageIcon size={24} className="text-[#60A5FA] group-hover:scale-110 transition duration-300" />
                  <span className="text-xs font-bold text-slate-300 group-hover:text-white">Mesaj</span>
                </a>
                <button onClick={handleCopyUrl} className="flex flex-col items-center gap-2 p-4 rounded-2xl bg-slate-800/60 border border-amber-500/30 hover:border-amber-500/60 hover:shadow-[0_8px_24px_rgba(245,158,11,0.15)] transition group">
                  <LinkIcon size={24} className="text-[#F59E0B] group-hover:scale-110 transition duration-300" />
                  <span className="text-xs font-bold text-slate-300 group-hover:text-white">Link</span>
                </button>
              </div>
            </div>
          </div>

          <div className="mt-8 text-center text-xs font-medium text-slate-400">
            <strong className="text-blue-500 font-extrabold tracking-widest">VIXREX</strong> ile oluşturuldu
          </div>
        </div>
      </div>

      {/* ===== KİRALA — yalnız hazır demo vitrinlerde =====
          Hedef HTML'de bu bölüm vardı, gerçek vitrinde yoktu. İş modelinin
          giriş kapısı burası: esnaf Google'dan hazır bir vitrine düşüyor,
          beğeniyor, buradan kiralıyor.
          Para ödeyen esnafın kendi vitrininde ÇIKMAZ — isDemo şartı bunun
          içindir. */}
      {isDemo && (
        <section
          id="kirala"
          className="border-t border-blue-500/15 bg-gradient-to-b from-blue-950/30 to-transparent py-14"
        >
          <div className="max-w-4xl mx-auto px-6 sm:px-8 text-center">
            <p className="text-xs font-bold uppercase tracking-widest text-blue-400">
              Kiralık vitrin standardı
            </p>
            <h2 className="mt-3 text-2xl sm:text-3xl font-extrabold text-white">
              Bu hazır {profile.label.toLowerCase()} vitrinini işletmenize göre
              kişiselleştirin
            </h2>
            <p className="mt-3 text-sm text-slate-300 leading-relaxed">
              Kiraladığınızda bu vitrin sizin olur: adınız, ürünleriniz,
              fotoğraflarınız. Vixrex Asistan ile yazıya tıklayıp
              değiştirirsiniz — kod bilmeniz gerekmez.
            </p>

            <ul className="mt-6 grid gap-3 sm:grid-cols-3 text-left">
              {[
                `${profile.label} sektörüne özel hazır içerik ve görseller`,
                "Her yazıyı, fotoğrafı ve bölümü değiştirme imkânı",
                "İşletmenize özel paylaşım linki ve QR kod",
              ].map((madde) => (
                <li
                  key={madde}
                  className="rounded-xl border border-blue-500/15 bg-white/[0.03] px-4 py-3 text-xs leading-relaxed text-slate-300"
                >
                  {madde}
                </li>
              ))}
            </ul>

            <div className="mt-8 inline-flex flex-col items-center rounded-2xl border border-blue-500/25 bg-[#0B1120] px-8 py-6">
              <span className="text-[11px] font-semibold uppercase tracking-wider text-slate-400">
                Başlangıç paketi
              </span>
              <span className="mt-1 text-3xl font-extrabold text-white">
                499 TL
                <span className="ml-1 text-sm font-semibold text-slate-400">
                  + KDV / ay
                </span>
              </span>
              <Link
                href={getAppUrl()}
                className="mt-4 rounded-xl bg-gradient-to-r from-blue-600 to-blue-700 px-8 py-3 text-sm font-bold text-white shadow-lg shadow-blue-500/25 transition hover:shadow-blue-500/40"
              >
                Bu vitrini kirala
              </Link>
              <span className="mt-3 text-[11px] text-slate-400">
                İlk 14 gün ücretsiz deneme
              </span>
            </div>
          </div>
        </section>
      )}

      {/* ===== FOOTER ===== */}
      <footer className="border-t border-blue-500/15 py-10 text-center">
        <div className="text-xl font-extrabold tracking-widest bg-gradient-to-r from-blue-500 to-blue-400 bg-clip-text text-transparent mb-2">
          VIXREX
        </div>
        <p className="text-xs text-slate-400">Bu vitrin Vixrex ile oluşturuldu · Dijital vitrinlerin yeni nesli</p>
      </footer>
    </div>
  );
}
