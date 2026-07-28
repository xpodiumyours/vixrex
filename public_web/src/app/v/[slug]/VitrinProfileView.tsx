"use client";

import Image from "next/image";
import Link from "next/link";
import { Suspense, type ReactNode, useState } from "react";
import type { VitrinCategoryProfile, PrimaryActionId } from "@/lib/vitrinProfile";
import { getVitrinCopy, normalizeAddressDisplay } from "@/lib/vitrinCopy";
import {
  GlobeIcon,
  GoogleIcon,
  InstagramIcon,
  LinkIcon,
  MapPinIcon,
  MessageIcon,
  WhatsAppIcon,
} from "@/lib/vitrinBrandIcons";
import { normalizeExternalUrl } from "@/lib/products";

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

export interface VitrinProfileViewProps {
  storeName: string;
  storeSlug: string;
  kategori: string | null;
  businessType: string | null;
  status: string | null;
  isClosed?: boolean;
  logoUrl: string | null;
  heroImage: string;
  description: string;
  corporateBio: string | null;
  address: string | null;
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
  description,
  corporateBio,
  address,
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
}: VitrinProfileViewProps) {
  const [copied, setCopied] = useState(false);
  const displayAddress = normalizeAddressDisplay(address);
  const vcardContent = `BEGIN:VCARD\nVERSION:3.0\nFN:${storeName}\nTEL:${whatsappUrl || ""}\nEND:VCARD`;
  const vcardHref = `data:text/vcard;charset=utf-8,${encodeURIComponent(vcardContent)}`;

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
      {/* ===== NAVBAR ===== */}
      <nav className="fixed top-0 left-0 right-0 z-50 h-[68px] bg-[#0B1120]/85 backdrop-blur-xl border-b border-blue-500/15 px-6 sm:px-8 flex items-center justify-between">
        <Link href={`/v/${storeSlug}`} className="flex items-center gap-3 font-extrabold text-xl tracking-tight text-white">
          <svg className="w-7 h-7 text-blue-500" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <rect x="3" y="3" width="7" height="7" rx="1.5" />
            <rect x="14" y="3" width="7" height="7" rx="1.5" />
            <rect x="14" y="14" width="7" height="7" rx="1.5" />
            <rect x="3" y="14" width="7" height="7" rx="1.5" />
          </svg>
          VIX<span className="text-blue-400">REX</span>
        </Link>

        <div className="hidden md:flex items-center gap-8 text-sm font-medium text-slate-400">
          <a href="#urunler" className="hover:text-white transition-colors">Ürünler</a>
          <a href="#kategoriler" className="hover:text-white transition-colors">Kategoriler</a>
          <a href="#iletisim" className="hover:text-white transition-colors">İletişim</a>
          <Link href="https://vixrex.com" className="bg-gradient-to-r from-blue-600 to-blue-700 text-white px-5 py-2.5 rounded-xl font-semibold text-sm shadow-lg shadow-blue-500/25 hover:shadow-blue-500/40 transition">
            Vitrin Oluştur
          </Link>
        </div>
      </nav>

      {/* ===== HERO ===== */}
      <section className="relative w-full min-h-[360px] sm:min-h-[420px] pt-[68px] flex items-end overflow-hidden">
        <div
          className="absolute inset-0 bg-cover bg-center"
          style={{ backgroundImage: `url(${heroImage || 'https://images.unsplash.com/photo-1558171813-4c088753af8f?w=1600&q=80'})` }}
        >
          <div className="absolute inset-0 bg-gradient-to-t from-[#0B1120] via-[#0B1120]/75 to-[#0B1120]/30" />
        </div>

        <div className="relative z-10 w-full max-w-7xl mx-auto px-6 sm:px-8 py-8 sm:py-10 grid md:grid-cols-[1fr_auto] gap-6 items-end">
          <div className="max-w-2xl">
            <div className="inline-flex items-center gap-2 bg-blue-500/12 border border-blue-500/25 text-blue-400 px-3.5 py-1 rounded-full text-xs font-bold uppercase tracking-wider mb-3 backdrop-blur-md">
              <span className="w-2 h-2 rounded-full bg-blue-500 shadow-[0_0_10px_#3B82F6]" />
              {kategori || businessType || "Atölye / Mağaza"}
            </div>

            <h1 className="text-3xl sm:text-5xl font-extrabold tracking-tight mb-2 bg-gradient-to-r from-white to-blue-200 bg-clip-text text-transparent">
              {storeName.toUpperCase()}
            </h1>

            <p className="text-slate-300 text-sm sm:text-base max-w-xl mb-4 leading-relaxed line-clamp-2">
              {description || "Tasarım odaklı butik mağaza. Özel dikim, sınırlı sayıda koleksiyonlar ve küratörlü seçimler."}
            </p>

            <div className="flex flex-wrap gap-4 text-sm text-slate-400">
              {displayAddress && <span className="flex items-center gap-1.5">📍 {displayAddress}</span>}
              <span className="flex items-center gap-1.5">⭐ 4.9 (128 değerlendirme)</span>
              {workingHoursToday && <span className="flex items-center gap-1.5">🕐 {workingHoursToday}</span>}
            </div>
          </div>

          <div className="flex flex-col sm:flex-row md:flex-col gap-3 min-w-[200px]">
            {whatsappUrl && (
              <a
                href={whatsappUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center justify-center gap-2.5 px-7 py-3.5 rounded-xl font-semibold bg-gradient-to-r from-blue-600 to-blue-700 text-white shadow-lg shadow-blue-500/25 hover:shadow-blue-500/40 hover:-translate-y-0.5 transition"
              >
                <WhatsAppIcon size={18} />
                WhatsApp
              </a>
            )}
            {mapsUrl && (
              <a
                href={mapsUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center justify-center gap-2.5 px-7 py-3.5 rounded-xl font-semibold bg-white/5 text-white border border-blue-500/20 backdrop-blur-md hover:bg-white/10 transition"
              >
                <MapPinIcon size={18} />
                Yol Tarifi
              </a>
            )}
          </div>
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
                <Image
                  src={cat.imageUrl || heroImage || "https://images.unsplash.com/photo-1483985988355-763728e1935b?w=600&q=80"}
                  alt={cat.name}
                  fill
                  className="object-cover transition duration-500 group-hover:scale-105"
                />
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
      <div className="max-w-7xl mx-auto px-6 sm:px-8 mb-12">
        <div className="relative overflow-hidden rounded-3xl border border-blue-500/15 bg-gradient-to-r from-blue-500/10 via-cyan-500/5 to-transparent p-8 sm:p-11 grid md:grid-cols-2 gap-8 items-center">
          <div>
            <span className="inline-block bg-gradient-to-r from-blue-600 to-blue-700 text-white text-xs font-extrabold uppercase tracking-wider px-4 py-1.5 rounded-lg mb-4 shadow-md">
              Yeni Sezon
            </span>
            <h2 className="text-2xl sm:text-4xl font-extrabold tracking-tight mb-3 text-white">
              Sonbahar / Kış Koleksiyonu
            </h2>
            <p className="text-slate-300 text-base mb-6 max-w-md leading-relaxed">
              Doğal kumaşlar, sürdürülebilir üretim ve zamansız tasarımlar. Sınırlı sayıda, ön siparişle.
            </p>
            <div className="text-3xl font-extrabold text-blue-400 tracking-tight">
              349 TL <span className="text-sm font-normal text-slate-400">'den başlayan fiyatlarla</span>
            </div>
          </div>

          <div className="h-64 sm:h-72 rounded-2xl overflow-hidden border border-blue-500/15 relative">
            <Image
              src={heroImage || "https://images.unsplash.com/photo-1558171813-4c088753af8f?w=800&q=80"}
              alt="Koleksiyon"
              fill
              className="object-cover"
            />
          </div>
        </div>
      </div>

      {/* ===== PRODUCTS ===== */}
      <section className="max-w-7xl mx-auto px-6 sm:px-8 py-8" id="urunler">
        <div className="flex items-baseline justify-between mb-8">
          <h2 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-white">Tüm Ürünler</h2>
          <span className="text-sm font-semibold text-slate-400">{productCount} Ürün Listeleniyor</span>
        </div>

        <Suspense fallback={<div className="h-64 flex items-center justify-center text-slate-400">Ürünler yükleniyor...</div>}>
          {catalog}
        </Suspense>
      </section>

      {/* ===== CONTACT & LOCATION ===== */}
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
                    <p className="text-xs text-slate-300 leading-relaxed mt-0.5">{displayAddress}</p>
                  </div>
                </div>
              )}

              {whatsappUrl && (
                <div className="flex items-start gap-4 pb-4 border-b border-blue-500/10">
                  <div className="w-10 h-10 rounded-xl bg-slate-800 border border-blue-500/15 flex items-center justify-center text-lg shrink-0">📞</div>
                  <div>
                    <h4 className="text-sm font-bold text-white">Telefon & WhatsApp</h4>
                    <a href={whatsappUrl} target="_blank" rel="noopener noreferrer" className="text-xs font-semibold text-blue-400 hover:text-blue-300">
                      WhatsApp'tan İletişime Geç
                    </a>
                  </div>
                </div>
              )}

              <div className="flex items-start gap-4 pb-4 border-b border-blue-500/10">
                <div className="w-10 h-10 rounded-xl bg-slate-800 border border-blue-500/15 flex items-center justify-center text-lg shrink-0">✉️</div>
                <div>
                  <h4 className="text-sm font-bold text-white">E-posta</h4>
                  <a href={`mailto:merhaba@${storeSlug}.com`} className="text-xs font-semibold text-blue-400 hover:text-blue-300">
                    {`merhaba@${storeSlug}.com`}
                  </a>
                </div>
              </div>

              {workingHoursToday && (
                <div className="flex items-start gap-4">
                  <div className="w-10 h-10 rounded-xl bg-slate-800 border border-blue-500/15 flex items-center justify-center text-lg shrink-0">🕐</div>
                  <div>
                    <h4 className="text-sm font-bold text-white">Çalışma Saatleri</h4>
                    <p className="text-xs text-slate-300 mt-0.5">{workingHoursToday}</p>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Right Map Panel */}
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
        </div>
      </div>

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
                <span className="font-mono text-sm text-slate-300 truncate">vixrex.com/v/{storeSlug}</span>
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
