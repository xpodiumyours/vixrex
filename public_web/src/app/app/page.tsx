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
import { vixRexHizliSecenekler } from "@/lib/vixrexMesajlari";
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
  const [user, setUser] = useState<User | null>(null);
  const [stores, setStores] = useState<Store[]>([]);
  const [yukleniyor, setYukleniyor] = useState(true);
  const [olusturuyor, setOlusturuyor] = useState(false);
  const [yeniAd, setYeniAd] = useState("");
  const [hata, setHata] = useState("");
  const [flowState, setFlowState] = useState<Record<string, unknown> | null>(null);
  const [showNameForm, setShowNameForm] = useState(false);
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
        .select("id, slug, name, description, price_text, image_urls, category_id, stock_status, product_categories(name)")
        .eq("store_id", storeId),
      supabase
        .from("product_categories")
        .select("id, name")
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
    const yeniFlow = (sonuc as { flow_state?: Record<string, unknown> | null }).flow_state ?? null;
    const yeniWorkingDraft = (sonuc as { working_draft?: { draft_data?: Record<string, unknown> } | null }).working_draft;
    setFlowState(yeniFlow);
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

    // Mağaza yok: akış varsa devam, yoksa ortak karşılama (PR2)
    setStores([]);
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
      // Ana sayfadaki asistanla konuşan kullanıcı kategori, WhatsApp ve
      // adresi zaten söylemişti. Onları burada tekrar sormak, "kaldığın
      // yerden devam edeceğiz" sözünü tutmamak olurdu.
      body: JSON.stringify({ name: yeniAd.trim(), ...asistanTaslagi }),
    });

    const sonuc = await res.json();
    setOlusturuyor(false);

    if (!res.ok) {
      setHata(sonuc.hata || "Vitrin oluşturulamadı.");
      return;
    }

    // Taslak kullanıldı, yerinde bırakma: ikinci bir vitrin kurulmaya
    // çalışılırsa eski cevaplar sessizce geri gelirdi.
    taslagiTemizle();
    setAsistanTaslagi({});

    // Vitrin oluşturuldu — sahip oturumunu aç ve vitrine git.
    //
    // Buradaki eski "basitleştirme" çalışmıyordu: `edit_token`'ı doğrudan
    // `ocode` olarak gönderiyordu. `/api/owner-session` ise
    // `consume_owner_session` çağırıyor ve TEK KULLANIMLIK KOD bekliyor —
    // canlıda doğrulandı, `edit_token` kabul etmiyor. Kod bulunamadığı
    // için çerez hiç kurulmuyordu ve bütün ürün işlemleri 401 alıyordu.
    if (sonuc.slug) {
      if (sonuc.yonlendir) {
        await fetch(sonuc.yonlendir, { redirect: "manual" });
      } else {
        await sahipOturumuAc();
      }
      router.push(`/v/${sonuc.slug}`);
    }
  }

  async function cikisYap() {
    await supabase.auth.signOut();
    router.push("/");
    router.refresh();
  }

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
      <header className="border-b border-[var(--owner-border)] bg-[var(--owner-bg)]/90 px-4 py-4 sm:px-6">
        <div className="mx-auto flex max-w-5xl flex-wrap items-center justify-between gap-3">
          <div>
            <p className="text-xs font-bold uppercase tracking-[0.16em] text-[var(--owner-secondary)]">Vixrex</p>
            <h1 className="mt-1 text-xl font-bold text-[var(--owner-text)]">Vitrinim</h1>
          </div>
          <div className="flex min-w-0 items-center gap-2">
            <span className="max-w-32 truncate text-xs text-[var(--owner-muted)] sm:max-w-none">{user?.email}</span>
            <Link
              href="/app/profil"
              className="owner-button-secondary min-h-11 shrink-0 px-3 py-2 text-xs"
            >
              Profil
            </Link>
            <Link
              href="/app/ayarlar"
              className="owner-button-secondary min-h-11 shrink-0 px-3 py-2 text-xs"
            >
              Ayarlar
            </Link>
            <button
              type="button"
              onClick={cikisYap}
              className="owner-button-secondary min-h-11 shrink-0 px-3 py-2 text-xs"
            >
              Çıkış Yap
            </button>
          </div>
        </div>
      </header>

      <div className="mx-auto max-w-5xl px-4 py-8 sm:px-6 sm:py-10">
        <div className="mb-6 max-w-2xl">
          <h2 className="text-2xl font-bold text-[var(--owner-text)] sm:text-3xl">
            Vitrinini yönet
          </h2>
          <p className="mt-2 text-sm leading-6 text-[var(--owner-muted)] sm:text-base">
            İşletme bilgilerini, ürünlerini ve yayın durumunu aynı vitrin üzerinden yönet.
          </p>
        </div>

        {hata ? <p className="owner-error mb-6 text-sm" role="alert">{hata}</p> : null}

        {stores.length === 0 ? (
          flowState ? (
            <section className="owner-card p-5 sm:p-8" aria-labelledby="vitrin-devam-title">
              <div>
                <p className="text-xs font-bold uppercase tracking-[0.16em] text-[var(--owner-secondary)]">Devam Ediyor</p>
                <h2 id="vitrin-devam-title" className="mt-2 text-xl font-bold text-[var(--owner-text)]">
                  Kurulumun kaldığı yerden devam ediyor
                </h2>
                <p className="mt-2 max-w-lg text-sm leading-6 text-[var(--owner-muted)]">
                  {flowState && typeof flowState === "object" && "current_step" in flowState
                    ? `Sıradaki adım: ${String((flowState as { current_step?: string }).current_step ?? "devam")}`
                    : "Önceki adımda bıraktığın yerden devam edebilirsin."}
                </p>
                {flowState && typeof flowState === "object" && "selected_template" in flowState && (flowState as { selected_template?: string }).selected_template ? (
                  <p className="mt-2 text-sm text-[var(--owner-text-alt)]">Seçilen şablon: {(flowState as { selected_template: string }).selected_template}</p>
                ) : null}
              </div>
              <div className="mt-6">
                <button
                  type="button"
                  onClick={() => setShowNameForm(true)}
                  className="owner-button-primary"
                >
                  Devam Et
                </button>
              </div>
              {showNameForm ? (
                <form onSubmit={magazaOlustur} className="mt-6 space-y-4" aria-busy={olusturuyor}>
                  <div className="space-y-2">
                    <label htmlFor="isletme-adi" className="owner-label">İşletme Adı</label>
                    <input
                      id="isletme-adi"
                      type="text"
                      placeholder="Ör. Aymira Giyim"
                      value={yeniAd}
                      onChange={(e) => setYeniAd(e.target.value)}
                      className="owner-input text-sm"
                      autoComplete="organization"
                      required
                    />
                  </div>
                  <button type="submit" disabled={olusturuyor} className="owner-button-primary w-full">
                    {olusturuyor ? "Vitrin oluşturuluyor…" : "Vitrin Oluştur"}
                  </button>
                </form>
              ) : null}
            </section>
          ) : (
            <div className="space-y-6">
              <div className="owner-card p-5 sm:p-6 bg-lp-surface border border-lp-border">
                <p className="text-xs font-bold uppercase tracking-[0.16em] text-[var(--owner-secondary)]">Vixrex Asistan</p>
                <p className="mt-2 text-sm leading-6 text-[var(--owner-muted)]">
                  Hazır şablonla başla ya da aşağıda bilgilerini doldur — her iki yol aynı vitrin formuna çıkar.
                </p>
                <div className="mt-4 grid gap-2 sm:grid-cols-3">
                  <Link href="/kesfet?yalniz_kiralik=1" className="owner-button-primary flex items-center justify-center gap-2 text-xs">
                    {vixRexHizliSecenekler.find((h) => h.id === "hazir_vitrin_sec")?.etiket ?? "Hazır Vitrin Seç"}
                  </Link>
                  <Link href="/kesfet" className="owner-button-secondary flex items-center justify-center gap-2 text-xs">
                    {vixRexHizliSecenekler.find((h) => h.id === "bakiniyorum")?.etiket ?? "Bakınıyorum"}
                  </Link>
                  <span className="hidden sm:flex items-center justify-center text-xs text-[var(--owner-muted)]">↓ Aşağıda formu doldur</span>
                </div>
              </div>
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
          )
        ) : (
          <section aria-labelledby="vitrinim-title">
            <h2 id="vitrinim-title" className="sr-only">Vitrinim</h2>
            <div className="grid gap-4">
              <Link
                href={`/v/${stores[0].slug}`}
                className="owner-card owner-link group block p-5 no-underline transition hover:border-[var(--owner-primary)] sm:p-6"
              >
                <div className="flex flex-col gap-5 sm:flex-row sm:items-center sm:justify-between">
                  <div className="min-w-0">
                    <div className="flex flex-wrap items-center gap-3">
                      <h3 className="truncate text-lg font-bold text-[var(--owner-text)] group-hover:text-[var(--owner-secondary)]">
                        {stores[0].name}
                      </h3>
                      <span
                        className={`rounded-full border px-2.5 py-1 text-xs font-bold ${
                          stores[0].is_published
                            ? "border-[var(--owner-success)]/40 bg-[var(--owner-success)]/10 text-[var(--owner-success)]"
                            : "border-[var(--owner-warning)]/40 bg-[var(--owner-warning)]/10 text-[var(--owner-warning)]"
                        }`}
                      >
                        {stores[0].is_published ? "Yayında" : "Taslak"}
                      </span>
                    </div>
                    <p className="mt-2 truncate text-xs text-[var(--owner-muted)]">
                      /v/{stores[0].slug}
                    </p>
                    {stores[0].kategori ? (
                      <p className="mt-2 text-sm text-[var(--owner-text-alt)]">{stores[0].kategori}</p>
                    ) : null}
                  </div>
                  <span className="owner-button-primary inline-flex shrink-0 items-center justify-center sm:min-w-40">
                    Vitrini Yönet
                  </span>
                </div>
              </Link>
              <OwnerDashboardMetrics />
            </div>
            <OwnerProductManager
              storeSlug={stores[0].slug}
              products={stores[0].products ?? []}
              categories={stores[0].product_categories ?? []}
              onRefresh={async () => {
                await magazalariGetir(false);
              }}
            />

            {/* Yönetim bağlantıları */}
            <div className="mt-6 grid gap-3 sm:grid-cols-2">
              <Link
                href={`/v/${stores[0].slug}/blog-yonetim`}
                className="owner-card owner-link group flex items-center gap-3 p-4 no-underline transition hover:border-[var(--owner-primary)]"
              >
                <span className="text-2xl">📝</span>
                <div>
                  <p className="text-sm font-bold text-[var(--owner-text)] group-hover:text-[var(--owner-secondary)]">
                    Blog Yönetimi
                  </p>
                  <p className="text-xs text-[var(--owner-muted)]">
                    Yazılarını düzenle ve yeni yazı oluştur
                  </p>
                </div>
              </Link>
              <Link
                href={`/v/${stores[0].slug}/randevu-yonetim`}
                className="owner-card owner-link group flex items-center gap-3 p-4 no-underline transition hover:border-[var(--owner-primary)]"
              >
                <span className="text-2xl">📅</span>
                <div>
                  <p className="text-sm font-bold text-[var(--owner-text)] group-hover:text-[var(--owner-secondary)]">
                    Randevu Yönetimi
                  </p>
                  <p className="text-xs text-[var(--owner-muted)]">
                    Bekleyen randevuları onayla veya reddet
                  </p>
                </div>
              </Link>
              <OwnerNotificationLink />
              <Link
                href="/app/hesap"
                className="owner-card owner-link group flex items-center gap-3 p-4 no-underline transition hover:border-[var(--owner-primary)]"
              >
                <span className="text-2xl">⚙️</span>
                <div>
                  <p className="text-sm font-bold text-[var(--owner-text)] group-hover:text-[var(--owner-secondary)]">
                    Hesap
                  </p>
                  <p className="text-xs text-[var(--owner-muted)]">
                    Profil, ayarlar ve hesap yönetimi
                  </p>
                </div>
              </Link>
              <Link
                href="/yardim"
                className="owner-card owner-link group flex items-center gap-3 p-4 no-underline transition hover:border-[var(--owner-primary)]"
              >
                <span className="text-2xl" aria-hidden="true">❓</span>
                <div>
                  <p className="text-sm font-bold text-[var(--owner-text)] group-hover:text-[var(--owner-secondary)]">
                    Yardım ve Destek
                  </p>
                  <p className="text-xs text-[var(--owner-muted)]">
                    Kullanım bilgileri ve sık sorulan sorular
                  </p>
                </div>
              </Link>

            </div>
          </section>
        )}
      </div>
    </main>
  );
}
