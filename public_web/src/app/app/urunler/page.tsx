"use client";

import { useEffect, useState, useCallback } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";
import { OwnerProductManager, type OwnerProduct, type OwnerProductCategory } from "@/components/owner/OwnerProductManager";

interface Store {
  id: string;
  slug: string;
  name: string;
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
    const { data: durum, error: durumHatasi } = await supabase.rpc("bootstrap_owner_state");
    const bootstrap = durum as { has_store?: boolean; slug?: string } | null;
    if (durumHatasi || bootstrap?.has_store !== true) {
      setHata("Vitrin bulunamadı. Önce vitrin oluştur.");
      setYukleniyor(false);
      return;
    }
    const slug = String(bootstrap.slug ?? "").trim();
    if (!slug) {
      setHata("Vitrin slug okunamadı.");
      setYukleniyor(false);
      return;
    }
    const { data, error } = await supabase
      .from("stores")
      .select("id, slug, name, products(id, slug, name, description, price_text, price_amount, currency, image_urls, category_id, stock_status, stock_quantity, brand, barcode, metadata, variants, seo_title, seo_description, old_price_amount, badge_tag, fulfillment_region, product_categories(name,product_template_key)), product_categories(id, name, product_template_key)")
      .eq("slug", slug)
      .maybeSingle();
    if (error || !data) {
      setHata("Ürünler yüklenemedi.");
      setYukleniyor(false);
      return;
    }
    setStore(data as unknown as Store);
    setYukleniyor(false);
  }, []);

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (!session) router.push("/giris");
      else yukle();
    });
  }, [router, yukle]);

  if (yukleniyor) {
    return (
      <div className="owner-shell p-6">
        <div className="mx-auto max-w-[900px] space-y-4">
          <div className="h-8 w-40 animate-pulse rounded bg-white/10" />
          <div className="h-32 animate-pulse rounded-2xl bg-white/5" />
        </div>
      </div>
    );
  }

  if (hata || !store) {
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
            <h1 className="text-[22px] font-black text-white">Ürünler</h1>
            <p className="text-sm text-white/60">{store.name} — {store.slug}</p>
          </div>
          <Link href="/app" className="owner-button-secondary">← Pano</Link>
        </div>
        <OwnerProductManager storeSlug={store.slug} products={store.products ?? []} categories={store.product_categories ?? []} onRefresh={yukle} />
      </div>
    </div>
  );
}
