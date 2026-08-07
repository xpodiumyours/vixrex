"use client";

import { useEffect, useState } from "react";
import OwnerAssistantPanel from "./OwnerAssistantPanel";
import type {
  VitrinFeaturedBanner,
  VitrinAboutSection,
  VitrinGallerySection,
  VitrinFaqItem,
  VitrinCollection,
  VitrinMarketplaceLink,
  VitrinArticleTeaser,
  VitrinGalleryItem,
} from "./VitrinProfileView";
import type { VitrinCategoryProfile } from "@/lib/vitrinProfile";

export interface WorkingDraftData {
  store_id: string;
  slug: string;
  draft_data: Record<string, unknown>;
  draft_version: number;
  base_live_version: number;
  live_version: number;
  version_conflict: boolean;
  created: boolean;
}

export interface OwnerWorkspaceShellProps {
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
  catalog: React.ReactNode;
  isPreviewMode?: boolean;
  draft?: WorkingDraftData | null;
  sessionExpiresAt?: number | null;
}

export default function OwnerWorkspaceShell({
  draft,
  sessionExpiresAt,
  ...vitrinProps
}: OwnerWorkspaceShellProps) {
  const [open, setOpen] = useState(false);
  const [isDesktop, setIsDesktop] = useState(false);
  const [sessionSecondsLeft, setSessionSecondsLeft] = useState<number | null>(null);

  useEffect(() => {
    const mq = window.matchMedia("(min-width: 1024px)");
    const update = () => setIsDesktop(mq.matches);
    update();
    mq.addEventListener("change", update);
    return () => mq.removeEventListener("change", update);
  }, []);

  useEffect(() => {
    if (!sessionExpiresAt) return;
    const tick = () => {
      const left = Math.max(0, Math.ceil((sessionExpiresAt - Date.now()) / 1000));
      setSessionSecondsLeft(left);
    };
    tick();
    const id = setInterval(tick, 1000);
    return () => clearInterval(id);
  }, [sessionExpiresAt]);

  const hiddenOnMobile = !open && !isDesktop;

  const [tazeleniyor, setTazeleniyor] = useState(false);
  const [tazelemeHatasi, setTazelemeHatasi] = useState<string | null>(null);

  /// Taslağı canlı vitrinden tazeler.
  ///
  /// Uyarının ÇARESİ buydu (bulgu 10). Eskiden sadece "Yeniden Yükle"
  /// vardı ve o aynı eski taslağı tekrar getiriyordu; tek çıkış yolu
  /// "Değişiklikleri bırak"tı — esnaf için "işimi kaybedeceğim" demek.
  const taslagiTazele = async () => {
    if (tazeleniyor || !draft?.slug) return;
    setTazeleniyor(true);
    setTazelemeHatasi(null);
    try {
      const yanit = await fetch("/api/owner-refresh", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ slug: draft.slug }),
      });
      const govde = await yanit.json();
      if (!yanit.ok) {
        setTazelemeHatasi(govde?.hata ?? "Taslak tazelenemedi.");
        return;
      }
      window.location.reload();
    } catch {
      setTazelemeHatasi("Bağlantı kurulamadı. Tekrar dene.");
    } finally {
      setTazeleniyor(false);
    }
  };

  const formatSessionTime = (seconds: number) => {
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return `${m}:${s.toString().padStart(2, "0")}`;
  };

  return (
    <>
      {draft?.version_conflict && (
        <div className="fixed top-0 left-0 right-0 z-[70] bg-amber-600 text-white text-xs font-bold px-4 py-2 flex items-center justify-between gap-3">
          <span>
            {tazelemeHatasi ??
              "Canlı vitrin değişmiş — burada gördüğün eski hâli."}
          </span>
          <button
            onClick={taslagiTazele}
            disabled={tazeleniyor}
            className="shrink-0 rounded bg-white/20 px-2.5 py-1 hover:bg-white/30 disabled:opacity-60"
          >
            {tazeleniyor ? "Alınıyor…" : "Canlı sürümü al"}
          </button>
        </div>
      )}

      <button
        onClick={() => setOpen((v) => !v)}
        className="fixed bottom-5 left-5 z-[70] lg:hidden bg-slate-700 text-white rounded-full w-14 h-14 shadow-lg flex items-center justify-center text-xl"
        aria-label="Sahip çalışma alanını aç"
      >
        ✎
      </button>

      <aside
        aria-hidden={hiddenOnMobile ? true : undefined}
        {...(hiddenOnMobile ? { inert: true } : {})}
        className={`fixed top-0 right-0 z-[65] h-full w-full sm:w-96 bg-[#0B1120] border-l border-white/10 shadow-2xl overflow-y-auto transition-transform duration-200 ${
          open ? "translate-x-0" : "translate-x-full"
        } lg:translate-x-0`}
      >
        <div className="p-5 pt-14">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-white font-bold text-base">Sahip Çalışma Alanı</h2>
            <button
              onClick={() => setOpen(false)}
              className="lg:hidden text-white/60 text-lg"
              aria-label="Kapat"
            >
              ✕
            </button>
          </div>

          <div className="space-y-3 text-xs text-slate-400 mb-4 p-3 rounded-lg bg-white/5 border border-white/10">
            <div className="flex justify-between">
              <span>Taslak sürümü</span>
              <span className="font-mono text-white">{draft?.draft_version ?? 1}</span>
            </div>
            <div className="flex justify-between">
              <span>Canlı sürüm</span>
              <span className="font-mono text-white">{draft?.live_version ?? 1}</span>
            </div>
            <div className="flex justify-between">
              <span>Oturum kalan</span>
              <span className="font-mono text-white font-bold">
                {sessionSecondsLeft !== null ? formatSessionTime(sessionSecondsLeft) : "—"}
              </span>
            </div>
            {draft?.version_conflict && (
              <div className="text-amber-400 text-center font-semibold">
                ⚠️ Sürüm çakışması — canlı veri değişmiş
              </div>
            )}
          </div>

          <div className="rounded-lg border border-dashed border-white/15 bg-white/[0.02] p-4 text-center">
            <p className="text-sm font-medium text-slate-300">
              Düzenleme Vixrex Asistan&apos;da
            </p>
            <p className="mt-1 text-xs leading-relaxed text-slate-500">
              Sağ alttaki 🦊 düğmesine basın veya vitrinde değiştirmek
              istediğiniz yazıya tıklayın.
            </p>
          </div>

          <div className="mt-6 pt-4 border-t border-white/10 text-xs text-slate-500 space-y-1">
            <p>Değişiklikler çalışma taslağına kaydedilir.</p>
            <p>Müşteriler göremez — yalnız siz bu panelde görürsünüz.</p>
            <p>Yayınlandığında canlı vitrin güncellenir.</p>
          </div>
        </div>
      </aside>

      <OwnerAssistantPanel
        slug={vitrinProps.storeSlug}
        draftData={(draft?.draft_data ?? {}) as Record<string, unknown>}
      />
    </>
  );
}