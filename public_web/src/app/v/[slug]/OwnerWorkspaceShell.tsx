"use client";

import { useEffect, useState } from "react";
import OwnerAssistantPanel from "./OwnerAssistantPanel";
import "./ownerStorefrontPolish.css";
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
  /** Faz 0 (Tek Asistan planı): vitrinin stores.user_id'si dolu mu —
   * ham id hiç gelmez, yalnız bu türetilmiş boolean. "Hesabına bağla"
   * bandının gösterilip gösterilmeyeceğine bununla karar verilir. */
  has_account?: boolean;
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
  isServiceStore?: boolean;
  /** Faz E: yönetim modu önerileri için — fiyatı/açıklaması boş ürün sayısı. */
  urunFiyatsizSayisi?: number;
  urunAciklamasizSayisi?: number;
  galleryItems: VitrinGalleryItem[];
  marketplaceLinks: VitrinMarketplaceLink[];
  articles: VitrinArticleTeaser[];
  isPreviewMode?: boolean;
  draft?: WorkingDraftData | null;
  sessionExpiresAt?: number | null;
  assistantHandoff?: AssistantHandoffV1 | null;
  bookingSettings?: Record<string, unknown> | null;
  campaignBanner?: { label: string; title: string; description: string; priceText: string; imageUrl: string } | null;
  /** Kiralık ŞABLONUN kendisi mi (stores.is_demo) — yalnız ek güvenlik
   * kemeri: müşteri klonları her zaman false doğar, "hesabına bağla"
   * bandı asıl kararı draft.has_account'tan alır (bkz. Faz 0). */
  isDemo?: boolean;
}

export default function OwnerWorkspaceShell({
  draft,
  sessionExpiresAt,
  assistantHandoff,
  bookingSettings,
  campaignBanner,
  isDemo,
  ...vitrinProps
}: OwnerWorkspaceShellProps) {
  const [sessionSecondsLeft, setSessionSecondsLeft] = useState<number | null>(null);
  // sayfa yüklendiğindeki sabit değerden başlar, her başarılı uzatmada
  // güncellenir — bkz. aşağıdaki "aktifken oturumu uzat" efekti.
  const [effectiveExpiresAt, setEffectiveExpiresAt] = useState<number | null>(
    sessionExpiresAt ?? null
  );

  // Kiralık vitrin sahip ekranında yalnız bu oturuma ait görünüm cilasını
  // etkinleştirir. Canlı/müşteri vitrini bu body sınıfını hiç almaz.
  useEffect(() => {
    const kiralikOwner =
      typeof draft?.draft_data?.cloned_from_slug === "string" &&
      draft.draft_data.cloned_from_slug.trim().length > 0;
    document.body.classList.toggle("vixrex-owner-rental-preview", kiralikOwner);
    return () => document.body.classList.remove("vixrex-owner-rental-preview");
  }, [draft]);

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

      {/* 2026-09-03 (Çalışma masası / Yön C): "Sahip Çalışma Alanı"
       * çekmecesi buradaydı. Ekranda iki panel vardı (çekmece + Vixrex
       * Asistan) ve İKİ FARKLI YÜZDE gösteriyorlardı: çekmece sunucudaki
       * draft_data'yı, panel useOwnerDraft'ın canlı taslağını okuyordu.
       * Çekmece kaldırıldı, içeriği asistan paneline taşındı; doluluk
       * artık tek yerden, panelin kendi raporundan geliyor. */}

      <OwnerAssistantPanel
        slug={vitrinProps.storeSlug}
        hesapBagliDegil={!isDemo && draft?.has_account === false}
        oturumSaniye={sessionSecondsLeft}
        yayinlanmamisDegisiklik={(draft?.draft_version ?? 1) > (draft?.live_version ?? 1)}
        draftData={(draft?.draft_data ?? {}) as Record<string, unknown>}
        draftYeniOlusturuldu={Boolean(draft?.created)}
        urunFiyatsizSayisi={vitrinProps.urunFiyatsizSayisi ?? 0}
        urunAciklamasizSayisi={vitrinProps.urunAciklamasizSayisi ?? 0}
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
