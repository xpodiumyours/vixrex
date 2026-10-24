"use client";

import { useEffect, useState, useCallback } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";
import { OwnerProductManager, type OwnerProduct, type OwnerProductCategory } from "@/components/owner/OwnerProductManager";
import { isletmeUrunSablonu } from "@/lib/businessCategories";

interface Store {
  id: string;
  slug: string;
  name: string;
  kategori: string | null;
  business_type: string | null;
  products: OwnerProduct[];
  product_categories: OwnerProductCategory[];
}

export const dynamic = "force-dynamic";

export default function UrunlerPage() {
  const router = useRouter();
  const [store, setStore] = useState<Store | null>(null);
  const [yukleniyor, setYukleniyor] = useState(true);
  const [hata, setHata] = useState("");

  const yukle = useCallback(async () => {
    setYukleniyor(true);
    setHata("");
    try {
      const { data: { session }, error: sessionError } = await supabase.auth.getSession();
      if (sessionError) throw new Error("Vitrin bilgileri yüklenemedi. Lütfen tekrar dene.");
      if (session) {
        const { data: durum, error: durumHatasi } = await supabase.rpc("bootstrap_owner_state");
        const bootstrap = durum as { has_store?: boolean; slug?: string } | null;
        if (durumHatasi) throw new Error("Vitrin bilgileri yüklenemedi. Lütfen tekrar dene.");
        if (!durumHatasi && bootstrap?.has_store === true) {
          const slug = String(bootstrap.slug ?? "").trim();
          if (!slug) throw new Error("Vitrin bilgileri okunamadı. Lütfen tekrar dene.");
          const { data, error } = await supabase
            .from("stores")
            .select("id, slug, name, kategori, business_type, products(id, slug, name, description, price_text, price_amount, currency, image_urls, category_id, stock_status, stock_quantity, brand, barcode, metadata, variants, old_price_amount, badge_tag, fulfillment_region, is_visible, source_type, product_categories(name, product_template_key)), product_categories(id, name, product_template_key)")
            .eq("slug", slug)
            .maybeSingle();
          if (error || !data) throw new Error("Ürünler yüklenemedi. Lütfen tekrar dene.");
          setStore(data as unknown as Store);
          return;
        }
      }

      const response = await fetch("/api/owner-workspace/current", { cache: "no-store" });
      const workspace = await response.json() as { store?: Store; sebep?: string };
      if (response.ok && workspace.store?.slug) {
        setStore(workspace.store);
        return;
      }
      if (response.status === 401 || response.status === 403) {
        throw new Error("Vitrin sahiplik oturumun geçersiz veya süresi dolmuş. Vitrinine yeniden giriş yap.");
      }
      if (response.status === 404 && workspace.sebep === "NO_OWNER_SESSION") {
        if (!session) {
          router.push("/giris");
          return;
        }
        throw new Error("Vitrin bulunamadı. Önce vitrin oluştur.");
      }
      throw new Error("Vitrin bilgileri yüklenemedi. Lütfen tekrar dene.");
    } catch (error) {
      setHata(error instanceof Error ? error.message : "Ürünler yüklenemedi. Lütfen tekrar dene.");
    } finally {
      setYukleniyor(false);
    }
  }, [router]);

  useEffect(() => {
    void Promise.resolve().then(yukle);
  }, [yukle]);

  if (yukleniyor && !store) {
    return (
      <div className="owner-shell p-6">
        <div className="mx-auto max-w-[900px] space-y-4">
          <div className="h-8 w-40 animate-pulse rounded bg-white/10" />
          <div className="h-32 animate-pulse rounded-2xl bg-white/5" />
        </div>
      </div>
    );
  }

  if (!store) {
    return (
      <div className="owner-shell p-6">
        <div className="mx-auto max-w-[900px] rounded-2xl border border-white/10 bg-white/5 p-8 text-center">
          <p className="text-sm font-bold text-white">{hata || "Vitrin yok"}</p>
          <Link href="/app" className="owner-button-primary mt-4 inline-flex">Vitrinime dön</Link>
        </div>
      </div>
    );
  }

  return (
    <div className="owner-shell p-6">
      <div className="mx-auto max-w-[900px] space-y-4">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-[22px] font-black text-white">Faturadan ürün kartı</h1>
            <p className="text-sm text-white/60">{store.name}</p>
          </div>
          <Link href="/app" className="owner-button-secondary">← Pano</Link>
        </div>
        {hata && <p role="alert" className="owner-error text-sm">{hata}</p>}
        <OwnerProductManager storeSlug={store.slug} products={store.products ?? []} categories={store.product_categories ?? []} varsayilanUrunTipi={isletmeUrunSablonu(store.kategori, store.business_type)} storeName={store.name} onRefresh={yukle} />
      </div>
    </div>
  );
}
