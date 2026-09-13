"use client";

import { useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { supabase } from "@/lib/supabase";
import { sahipOturumuAc } from "@/lib/ownerCookie";
import type { User } from "@supabase/supabase-js";
import {
  taslagiOku,
  taslagiTemizle,
  type AsistanCevaplari,
} from "@/lib/landingAsistanAkisi";
import { importLandingFlowStateIfNeeded } from "@/lib/ownerFlowImport";
import {
  OwnerProductManager,
  type OwnerProduct,
  type OwnerProductCategory,
} from "@/components/owner/OwnerProductManager";
import { OwnerDashboardMetrics } from "@/components/owner/OwnerDashboardMetrics";
import { OwnerNotificationLink } from "@/components/owner/OwnerNotificationLink";
import { VitrinimEditor } from "@/components/owner/VitrinimEditor";
import { PUBLIC_STORE_SELECT } from "@/lib/publicStoreSelect";

interface Store {
  id: string;
  slug: string;
  name: string;
  is_published: boolean;
  kategori: string | null;
  updated_at: string | null;
  products: OwnerProduct[];
  product_categories: OwnerProductCategory[];
}

interface BootstrapOwnerState {
  has_store?: boolean;
  slug?: string;
  reason?: string;
}

export const dynamic = "force-dynamic";

export default function AppPage() {
  const router = useRouter();
  const [, setUser] = useState<User | null>(null);
  const [stores, setStores] = useState<Store[]>([]);
  const [yukleniyor, setYukleniyor] = useState(true);
  const [olusturuyor, setOlusturuyor] = useState(false);
  const [yeniAd, setYeniAd] = useState("");
  const [hata, setHata] = useState("");
  const [flowState, setFlowState] = useState<Record<string, unknown> | null>(null);
  const [showNameForm, setShowNameForm] = useState(false);
  const [workingDraft, setWorkingDraft] = useState<Record<string, unknown>>({});
  const [asistanTaslagi, setAsistanTaslagi] = useState<AsistanCevaplari>({});

  const magazaDetayiniGetir = useCallback(async function magazaDetayiniGetir(
    slug: string,
    draftOverride?: Record<string, unknown> | null
  ): Promise<boolean> {
    const { data: storeData, error: storeError } = await supabase
      .from("stores")
      .select(`${PUBLIC_STORE_SELECT},updated_at`)
      .eq("slug", slug)
      .maybeSingle();

    if (storeError || !storeData) {
      console.error(
        "[app/bootstrap] store detail query failed",
        storeError?.message ?? "STORE_NOT_FOUND"
      );
      return false;
    }

    const storeRow = storeData as unknown as Record<string, unknown>;
    const storeId = String(storeRow.id ?? "");
    if (!storeId) return false;

    const [productsResult, categoriesResult] = await Promise.all([
      supabase
        .from("products")
        .select("id, slug, name, description, price_text, price_amount, currency, image_urls, category_id, stock_status, stock_quantity, brand, barcode, metadata, variants, seo_title, seo_description, old_price_amount, badge_tag, fulfillment_region, product_categories(name,product_template_key)")
        .eq("store_id", storeId),
      supabase
        .from("product_categories")
        .select("id, name, product_template_key")
        .eq("store_id", storeId),
    ]);

    if (productsResult.error || categoriesResult.error) {
      console.error(
        "[app/bootstrap] catalog query failed",
        productsResult.error?.message ?? categoriesResult.error?.message
      );
    }

    setWorkingDraft(draftOverride ?? storeRow);
    setStores([
      {
        ...(storeData as unknown as Store),
        products: (productsResult.data as unknown as OwnerProduct[]) ?? [],
        product_categories:
          (categoriesResult.data as unknown as OwnerProductCategory[]) ?? [],
      },
    ]);
    return true;
  }, []);

  const magazalariGetir = useCallback(async function magazalariGetir(showLoading = true) {
    if (showLoading) setYukleniyor(true);
    setHata("");

    let { data: durum, error: durumHatasi } = await supabase.rpc(
      "get_owner_workspace_bootstrap"
    );

    if (durumHatasi) {
      console.warn(
        "[app/bootstrap] birleşik bootstrap kullanılamadı; güvenli yedek yol kullanılıyor.",
        durumHatasi.code
      );
      const eskiBootstrap = await supabase.rpc("bootstrap_owner_state");
      if (eskiBootstrap.error) {
        setHata("Vitrin bilgileri yüklenemedi. Lütfen sayfayı yenileyip tekrar dene.");
        setStores([]);
        if (showLoading) setYukleniyor(false);
        return;
      }
      durum = eskiBootstrap.data;
      durumHatasi = null;
    }

    const sonuc = (durum ?? {}) as Record<string, unknown>;
    const yeniStore = (sonuc as { store?: Store | null }).store;
    const yeniFlow = (sonuc as { flow_state?: Record<string, unknown> | null }).flow_state ?? null;
    const yeniWorkingDraft = (sonuc as { working_draft?: { draft_data?: Record<string, unknown> } | null }).working_draft;
    setFlowState(yeniFlow);
    const eskiSonuc = sonuc as BootstrapOwnerState;
    const slug =
      yeniStore && typeof yeniStore === "object" && (yeniStore as Store).slug
        ? (yeniStore as Store).slug.trim()
        : eskiSonuc.has_store === true
          ? eskiSonuc.slug?.trim() ?? ""
          : "";

    if (slug) {
      const tamam = await magazaDetayiniGetir(
        slug,
        yeniWorkingDraft?.draft_data ?? null
      );
      if (!tamam) {
        setHata("Vitrin bilgileri yüklenemedi. Lütfen sayfayı yenileyip tekrar dene.");
        setStores([]);
      }
      if (showLoading) setYukleniyor(false);
      return;
    }

    setStores([]);
    if (showLoading) setYukleniyor(false);
  }, [magazaDetayiniGetir]);

  useEffect(() => {
    async function init() {
      let {
        data: { session },
      } = await supabase.auth.getSession();
      if (!session) {
        try {
          const { data: anonData } = await supabase.auth.signInAnonymously();
          if (anonData?.session) {
            session = anonData.session;
          } else {
            router.push("/giris");
            return;
          }
        } catch {
          router.push("/giris");
          return;
        }
      }
      setUser(session.user);

      await importLandingFlowStateIfNeeded();

      const taslak = taslagiOku();
      if (Object.keys(taslak).length > 0) {
        setAsistanTaslagi(taslak);
        if (taslak.name) setYeniAd(taslak.name);
      }

      await sahipOturumuAc();
      await magazalariGetir();
    }
    init();
  }, [router, magazalariGetir]);

  async function magazaOlustur(e: React.FormEvent) {
    e.preventDefault();
    setHata("");

    if (!yeniAd.trim()) {
      setHata("İşletme adı zorunludur.");
      return;
    }

    setOlusturuyor(true);

    const {
      data: { session },
    } = await supabase.auth.getSession();
    if (!session) {
      setHata("Oturum bulunamadı.");
      setOlusturuyor(false);
      return;
    }

    const res = await fetch("/api/create-store", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${session.access_token}`,
      },
      body: JSON.stringify({ name: yeniAd.trim(), ...asistanTaslagi }),
    });

    const sonuc = await res.json();
    if (!res.ok) {
      setHata(sonuc?.error || sonuc?.message || "Vitrin oluşturulamadı.");
      setOlusturuyor(false);
      return;
    }

    taslagiTemizle();
    setAsistanTaslagi({});
    setYeniAd("");
    setShowNameForm(false);
    await sahipOturumuAc();
    await magazalariGetir(false);
    setOlusturuyor(false);
  }

  if (yukleniyor) {
    return (
      <main className="owner-shell min-h-screen p-5 sm:p-8">
        <div className="mx-auto max-w-[1120px] animate-pulse space-y-5">
          <div className="h-10 w-56 rounded-xl bg-white/10" />
          <div className="h-36 rounded-3xl bg-white/5" />
        </div>
      </main>
    );
  }

  if (stores.length === 0) {
    return (
      <main className="owner-shell min-h-screen px-4 py-10 sm:px-6">
        <div className="mx-auto max-w-xl owner-card p-6 sm:p-8">
          <h1 className="text-2xl font-black text-[var(--owner-text)]">Vitrinini oluştur</h1>
          <p className="mt-2 text-sm leading-6 text-[var(--owner-muted)]">
            Tek vitrin hesabını oluşturup düzenlemeye devam et.
          </p>
          {hata ? <p className="owner-error mt-4 text-sm">{hata}</p> : null}
          {!showNameForm ? (
            <button type="button" className="owner-button-primary mt-5" onClick={() => setShowNameForm(true)}>
              Devam Et
            </button>
          ) : (
            <form onSubmit={magazaOlustur} className="mt-5 space-y-4">
              <label className="block space-y-2">
                <span className="owner-label">İşletme adı</span>
                <input className="owner-input" value={yeniAd} onChange={(e) => setYeniAd(e.target.value)} maxLength={80} autoFocus />
              </label>
              <button className="owner-button-primary w-full" disabled={olusturuyor}>{olusturuyor ? "Oluşturuluyor…" : "Vitrini Oluştur"}</button>
            </form>
          )}
        </div>
      </main>
    );
  }

  const store = stores[0];

  return (
    <main className="owner-shell min-h-screen px-4 py-6 sm:px-6 sm:py-8">
      <div className="mx-auto max-w-[1120px]">
        {hata ? <p className="owner-error mb-4 text-sm">{hata}</p> : null}
        <div className="mb-6 flex flex-wrap items-center justify-between gap-3">
          <div>
            <h1 className="text-2xl font-black text-[var(--owner-text)]">Vitrinim</h1>
            <p className="mt-1 text-sm text-[var(--owner-muted)]">{store.name}</p>
          </div>
          <div className="flex items-center gap-2">
            <OwnerNotificationLink />
            <Link href={`/v/${store.slug}`} target="_blank" className="owner-button-secondary">Vitrini Gör</Link>
          </div>
        </div>

        <OwnerDashboardMetrics storeSlug={store.slug} />
        <VitrinimEditor
          store={store as never}
          flowState={flowState}
          workingDraft={workingDraft}
          onRefresh={() => magazalariGetir(false)}
        />
        <OwnerProductManager
          storeSlug={store.slug}
          products={store.products ?? []}
          categories={store.product_categories ?? []}
          onRefresh={() => magazalariGetir(false)}
        />
      </div>
    </main>
  );
}
