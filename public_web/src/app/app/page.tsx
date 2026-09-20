"use client";

import { useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";
import { sahipOturumuAc } from "@/lib/ownerCookie";
import type { User } from "@supabase/supabase-js";
import {
  taslagiOku,
  taslagiTemizle,
  type AsistanCevaplari,
} from "@/lib/landingAsistanAkisi";
import { importLandingFlowStateIfNeeded } from "@/lib/ownerFlowImport";
import type {
  OwnerProduct,
  OwnerProductCategory,
} from "@/components/owner/OwnerProductManager";
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
  // Oturum yalnız yönlendirme için okunuyor; ekranda gösterilmiyor.
  const [, setUser] = useState<User | null>(null);
  const [stores, setStores] = useState<Store[]>([]);
  const [yukleniyor, setYukleniyor] = useState(true);
  const [olusturuyor, setOlusturuyor] = useState(false);
  const [yeniAd, setYeniAd] = useState("");
  const [hata, setHata] = useState("");
  const [workingDraft, setWorkingDraft] = useState<Record<string, unknown>>({});

  // Ana sayfadaki asistanla konuşulduysa cevaplar tarayıcı oturumunda
  // duruyor. Vitrin kurulurken doğrudan kullanılır; kullanıcıya aynı
  // soruları ikinci kez sormayız.
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
        .select("id, slug, name, description, price_text, price_amount, currency, image_urls, category_id, stock_status, stock_quantity, brand, barcode, metadata, variants, old_price_amount, badge_tag, fulfillment_region, product_categories(name, product_template_key)")
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
      // Yeni birleşik RPC canlı şemada geçici olarak bozulursa kullanıcıyı
      // "vitrinin yok" ekranına düşürme. Kalıcı sahiplik RPC'sinden slug'ı
      // alıp aynı RLS korumalı tablolardan vitrini doğrudan yükle.
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
    // PR3-C12: yeni bootstrap (store + flow_state + conversation) — paralel başlangıç kaldırıldı
    const yeniStore = (sonuc as { store?: Store | null }).store;
    const yeniWorkingDraft = (sonuc as { working_draft?: { draft_data?: Record<string, unknown> } | null }).working_draft;
    // Yeni ve eski bootstrap sonuçlarını tek slug yolunda birleştir.
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

    // Hesaba bağlı vitrin bulunamadıysa, aynı tarayıcıdaki doğrulanmış
    // sahiplik oturumunu dene. Kiralık/misafir vitrin /v/[slug] üzerinde
    // HttpOnly owner cookie ile yönetiliyor olabilir; /app bu durumda yeni
    // bir kurulum başlatmamalı, aynı working_draft'ı manuel panelde açmalı.
    try {
      const ownerWorkspaceResponse = await fetch("/api/owner-workspace/current", {
        method: "GET",
        cache: "no-store",
      });
      if (ownerWorkspaceResponse.ok) {
        const ownerWorkspace = (await ownerWorkspaceResponse.json()) as {
          store?: Store | null;
          working_draft?: { draft_data?: Record<string, unknown> } | null;
        };
        if (ownerWorkspace.store?.slug) {
          setStores([ownerWorkspace.store]);
          setWorkingDraft(ownerWorkspace.working_draft?.draft_data ?? {});
          if (showLoading) setYukleniyor(false);
          return;
        }
      }
    } catch (ownerWorkspaceError) {
      console.warn(
        "[app/bootstrap] sahiplik çerezi çalışma alanı okunamadı",
        ownerWorkspaceError
      );
    }

    // Gerçekten vitrin yok: Flutter Web /app gibi doğrudan manuel
    // Vitrinim oluşturma paneline düş. Eski flow_state ayrı bir ekran açmaz;
    // landing taslağı aşağıdaki VitrinimEditor'ü yalnızca önceden doldurur.
    setStores([]);
    setWorkingDraft({});
    if (showLoading) setYukleniyor(false);
    return;
  }, [magazaDetayiniGetir]);



  useEffect(() => {
    async function init() {
      let {
        data: { session },
      } = await supabase.auth.getSession();
      // Flutter web ile parite: Vitrinim anonimken manuel panele açılmalı,
      // Google login'e zorlamamalı. Yoksa Keşfet alt menüdeki Vitrinim
      // tıklaması /giris'e düşüyordu (mobil eşitlik sonrası raporlandı).
      // Mevcut /app akışı korunur — yalnız oturum yoksa Flutter'daki
      // _oturumuGuvenceyeAl gibi anonim oturum denenir, başarısızsa /giris'e düşer.
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

      // PR3-C11: hesap sonrası yerel landing başlangıcını tek active conversation'a aktar
      await importLandingFlowStateIfNeeded();

      // Asistan taslağı varsa vitrin adını doldur — kullanıcı formu boş
      // görmesin, konuştuğu şeyin kaybolmadığını görsün.
      const taslak = taslagiOku();
      if (Object.keys(taslak).length > 0) {
        setAsistanTaslagi(taslak);
        if (taslak.name) setYeniAd(taslak.name);
      }

      // Sahip çerezi kısa ömürlü. Panoya her dönüşte yeniden kuruluyor —
      // yoksa kullanıcı ikinci ziyaretinde ürün ekleyemez/silemez, her
      // çağrı 401 döner. Vitrini olmayan hesapta sessizce başarısız olur,
      // kurulum akışı zaten ayrı.
      await sahipOturumuAc();

      // Düzenleyiciyi ancak sahip çerezi kurulmayı denedikten sonra aç.
      // Böylece ilk alan değişikliği, sayfa daha yeni görünür olmuşken 401
      // ile düşmez.
      await magazalariGetir();
    }
    init();
  }, [router, magazalariGetir]);

  if (yukleniyor) {
    return (
      <main className="owner-shell flex items-center justify-center px-4">
        <div className="owner-card flex items-center gap-3 px-5 py-4" role="status" aria-live="polite">
          <span className="h-3 w-3 animate-pulse rounded-full bg-[var(--owner-primary)]" aria-hidden="true" />
          <span className="text-sm text-[var(--owner-muted)]">Vitrinin yükleniyor…</span>
        </div>
      </main>
    );
  }

  if (stores.length > 0) {
    return (
      <VitrinimEditor
        store={stores[0]}
        initialDraft={workingDraft}
        onRefresh={async () => {
          await magazalariGetir(false);
        }}
      />
    );
  }

  return (
    <main className="owner-shell">
      {/* Flutter'daki Vitrinim ekranıyla hizalı: ikinci üst çubuk (Vixrex/Vitrinim +
          Profil·Ayarlar·Çıkış) ve "Vitrinini yönet" başlığı yok. Gezinme soldaki
          AppSidebar'da; Profil/Ayarlar/Çıkış /app/profil altında. Ekranın en
          üstündeki tek şerit VitrinimEditor'ün yayın durumu çubuğudur. */}
      <div className="w-full">
        {hata ? <p className="owner-error mb-6 text-sm" role="alert">{hata}</p> : null}

        <div className="space-y-6">
          <VitrinimEditor
            store={{ slug: "taslak", name: yeniAd, is_published: false, products: [], product_categories: [] }}
            initialDraft={{ ...asistanTaslagi, ...workingDraft, name: yeniAd }}
            isCreationMode
            onCreate={async (draft) => {
              const ad = String((draft as Record<string, unknown>).name || yeniAd || "").trim();
              if (!ad) {
                setHata("İşletme adı zorunludur.");
                return;
              }
              setOlusturuyor(true);
              setHata("");
              try {
                const { data: { session } } = await supabase.auth.getSession();
                if (!session) {
                  setHata("Oturum bulunamadı.");
                  return;
                }
                const payload: Record<string, unknown> = { name: ad, ...asistanTaslagi };
                // VitrinimEditor draft'ı kolon isimleriyle gelir — direkt ekle
                for (const [k, v] of Object.entries(draft as Record<string, unknown>)) {
                  if (v != null && String(v).trim() !== "") payload[k] = v;
                }
                const res = await fetch("/api/create-store", {
                  method: "POST",
                  headers: { "Content-Type": "application/json", Authorization: `Bearer ${session.access_token}` },
                  body: JSON.stringify(payload),
                });
                const sonuc = await res.json();
                if (!res.ok) {
                  setHata(sonuc.hata || "Vitrin oluşturulamadı.");
                  return;
                }
                taslagiTemizle();
                setAsistanTaslagi({});
                if (sonuc.slug) {
                  if (sonuc.yonlendir) await fetch(sonuc.yonlendir, { redirect: "manual" });
                  else await sahipOturumuAc();
                  router.push(`/v/${sonuc.slug}`);
                } else {
                  await magazalariGetir();
                }
              } finally {
                setOlusturuyor(false);
              }
            }}
            onRefresh={async () => {
              await magazalariGetir(false);
            }}
          />
          {hata ? <p className="owner-error text-sm" role="alert">{hata}</p> : null}
          {olusturuyor ? <p className="text-sm text-[var(--owner-muted)]" role="status">Vitrin oluşturuluyor…</p> : null}
        </div>
      </div>
    </main>
  );
}
