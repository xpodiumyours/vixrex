"use client";

import { useEffect, useState } from "react";
import OwnerAssistantPanel from "./OwnerAssistantPanel";
import { hazirlikRaporu } from "@/lib/vitrinReadiness";
import { vixRexMesajlari } from "@/lib/vixrexMesajlari";
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
import type { AssistantHandoffV1 } from "@/lib/assistantHandoff";

export interface WorkingDraftData {
  store_id: string;
  slug: string;
  draft_data: Record<string, unknown>;
  draft_version: number;
  base_live_version: number;
  live_version: number;
  version_conflict: boolean;
  created: boolean;
  assistant_handoff?: unknown;
  /** "Boş geç" denen isteğe bağlı alanlar (ADR 0002, 3. alt-faz). */
  atlanan_alanlar?: string[];
  /** Kiralık şablon vitrinin premium süresi AKTİF mi — sunucuda hesaplanır
   * (React purity: istemci render'ında Date.now() çağrılmaz). */
  is_premium_active?: boolean;
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
  assistantHandoff?: AssistantHandoffV1 | null;
  bookingSettings?: Record<string, unknown> | null;
  campaignBanner?: { label: string; title: string; description: string; priceText: string; imageUrl: string } | null;
}

export default function OwnerWorkspaceShell({
  draft,
  sessionExpiresAt,
  assistantHandoff,
  bookingSettings,
  campaignBanner,
  ...vitrinProps
}: OwnerWorkspaceShellProps) {
  const [open, setOpen] = useState(false);
  const [isDesktop, setIsDesktop] = useState(false);
  const [sessionSecondsLeft, setSessionSecondsLeft] = useState<number | null>(null);
  // sayfa yüklendiğindeki sabit değerden başlar, her başarılı uzatmada
  // güncellenir — bkz. aşağıdaki "aktifken oturumu uzat" efekti.
  const [effectiveExpiresAt, setEffectiveExpiresAt] = useState<number | null>(
    sessionExpiresAt ?? null
  );

  useEffect(() => {
    const mq = window.matchMedia("(min-width: 1024px)");
    const update = () => setIsDesktop(mq.matches);
    update();
    mq.addEventListener("change", update);
    return () => mq.removeEventListener("change", update);
  }, []);

  useEffect(() => {
    if (!effectiveExpiresAt) return;
    const tick = () => {
      const left = Math.max(0, Math.ceil((effectiveExpiresAt - Date.now()) / 1000));
      setSessionSecondsLeft(left);
    };
    tick();
    const id = setInterval(tick, 1000);
    return () => clearInterval(id);
  }, [effectiveExpiresAt]);

  /// Sahip çalışma alanı açıkken (sekme görünürken) oturumu birkaç dakikada
  /// bir sessizce uzatır — "bankacılık usulü" kayan oturum (Casper
  /// 2026-08-13). Sekme arka plana alınırsa/kapatılırsa uzatma durur; oturum
  /// gerçekten terk edilirse kendi başına düşer, bu KASITLI (güvenlik).
  useEffect(() => {
    if (!sessionExpiresAt) return;
    let cancelled = false;

    const uzat = async () => {
      if (document.visibilityState !== "visible") return;
      try {
        const yanit = await fetch("/api/owner-session-extend", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ slug: vitrinProps.storeSlug }),
        });
        if (cancelled || !yanit.ok) return;
        const govde = await yanit.json();
        if (typeof govde?.expiresAt === "number") {
          setEffectiveExpiresAt(govde.expiresAt);
        }
      } catch {
        // Geçici ağ hatası sessizce yutulur — oturum hemen düşmez, bir
        // sonraki denemede (5 dk sonra veya sekme tekrar aktifleşince)
        // toparlanır.
      }
    };

    const id = setInterval(uzat, 5 * 60 * 1000);
    const onVisible = () => {
      if (document.visibilityState === "visible") uzat();
    };
    document.addEventListener("visibilitychange", onVisible);

    return () => {
      cancelled = true;
      clearInterval(id);
      document.removeEventListener("visibilitychange", onVisible);
    };
  }, [sessionExpiresAt, vitrinProps.storeSlug]);

  const hiddenOnMobile = !open && !isDesktop;

  // Faz G2 (Tek Asistan planı): panel oturum/sürüm paneli olarak kalır,
  // asistan işi almaz — yalnız AssistantState'in Next.js tarafındaki
  // karşılığı olan hazirlikRaporu'dan tek cümlelik özet gösterir. Bu,
  // asistanın söylediğiyle AYNI kaynaktan geliyor (useOwnerDraft'ın da
  // kullandığı fonksiyon) — panel kendi kararını üretmez.
  const rapor = hazirlikRaporu(
    (draft?.draft_data ?? {}) as Record<string, unknown>,
    new Set(
      Array.isArray(draft?.atlanan_alanlar) ? draft.atlanan_alanlar : []
    )
  );

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
            {tazelemeHatasi ?? vixRexMesajlari["taslak_cakismasi"]}
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

          <div className="rounded-lg border border-white/10 bg-white/[0.03] p-4">
            <div className="mb-2 flex items-center justify-between gap-2">
              <p className="text-sm font-semibold text-white">
                {rapor.temelTamam
                  ? "Vitrin yayına hazır"
                  : "Kurulum sürüyor"}
              </p>
              <span className="shrink-0 font-mono text-xs text-slate-400">
                %{rapor.yuzde} · {rapor.doluSayisi}/{rapor.toplamSayisi}
              </span>
            </div>
            {rapor.sonrakiAdim && (
              <p className="text-xs leading-relaxed text-slate-400">
                {rapor.sonrakiAdim}
              </p>
            )}
            <p className="mt-3 text-xs leading-relaxed text-slate-500">
              Düzenleme Vixrex Asistan&apos;da — sağ alttaki düğmeye basın
              veya vitrinde değiştirmek istediğiniz yazıya tıklayın.
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
        assistantHandoff={assistantHandoff}
        atlananAlanlar={
          Array.isArray(draft?.atlanan_alanlar) ? draft.atlanan_alanlar : []
        }
        premiumAktifMi={Boolean(draft?.is_premium_active)}
        bookingSettings={bookingSettings ?? null}
        aboutSection={vitrinProps.aboutSection ? { kicker: vitrinProps.aboutSection.kicker ?? '', title: vitrinProps.aboutSection.title ?? '', body: vitrinProps.aboutSection.body ?? '', imageUrl: vitrinProps.aboutSection.imageUrl ?? '', imageCaption: vitrinProps.aboutSection.imageCaption ?? '', values: (vitrinProps.aboutSection.values ?? []).map(v => ({ id: v.id ?? '', title: v.title ?? '', description: v.description ?? '' })) } : null}
        faqItems={(vitrinProps.faqItems ?? []).map(f => ({ id: f.id ?? '', question: f.question ?? '', answer: f.answer ?? '' }))}
        campaignBanner={campaignBanner ?? null}
        marketplaceLinks={(vitrinProps.marketplaceLinks ?? []).map((m) => ({ id: m.id ?? '', platform: m.platform ?? '', url: m.url ?? '', subtitle: m.subtitle ?? '' }))}
        galleryItems={(vitrinProps.galleryItems ?? []).map((g) => ({ id: g.id || '', imageUrl: g.imageUrl || '', title: g.title || '' }))}
      />
    </>
  );
}
