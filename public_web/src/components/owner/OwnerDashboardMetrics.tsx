"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";

type TopProduct = {
  slug: string;
  name: string;
  views: number;
  likes: number;
  comments: number;
  cart_adds: number;
  orders: number;
};

type TrafficSource = {
  source: string;
  count: number;
};

type RecentComment = {
  id: string;
  product_slug: string;
  product_name: string;
  author_name: string;
  body: string;
  status: string;
  created_at: string;
};

type OlcerOzeti = {
  days: number;
  period_start?: string;
  period_end?: string;
  unique_visitors: number;
  store_views: number;
  product_views: number;
  likes: number;
  comments: number;
  cart_adds: number;
  whatsapp_orders: number;
  whatsapp_clicks: number;
  conversion_percent: number;
  traffic_sources: TrafficSource[];
  top_products: TopProduct[];
  recent_comments: RecentComment[];
};

type PanoOzeti = {
  bugunkuZiyaret: number;
  premiumAktif: boolean;
  premiumBitis: string | null;
  olcer: OlcerOzeti | null;
};

function sourceLabel(source: string) {
  const labels: Record<string, string> = {
    direct: "Doğrudan",
    qr: "QR",
    share: "Paylaşım",
    google: "Google",
    instagram: "Instagram",
    facebook: "Facebook",
    whatsapp: "WhatsApp",
    twitter: "X / Twitter",
    tiktok: "TikTok",
    diger_site: "Diğer site",
    unknown: "Bilinmeyen",
  };
  return labels[source] ?? source;
}

function metric(value: number | undefined) {
  return Number.isFinite(Number(value)) ? Number(value) : 0;
}

export function OwnerDashboardMetrics() {
  const [ozet, setOzet] = useState<PanoOzeti | null>(null);
  const [hata, setHata] = useState("");
  const [yorumIslemi, setYorumIslemi] = useState<string | null>(null);

  useEffect(() => {
    let iptalEdildi = false;

    async function ozetiGetir() {
      const {
        data: { session },
      } = await supabase.auth.getSession();
      if (!session) return;

      const response = await fetch("/api/owner-dashboard/summary", {
        headers: { authorization: `Bearer ${session.access_token}` },
      });
      const sonuc = await response.json().catch(() => ({}));
      if (iptalEdildi) return;

      if (!response.ok) {
        setHata(sonuc.hata ?? "Vitrin Ölçer bilgileri şu anda alınamıyor.");
        return;
      }

      setOzet({
        bugunkuZiyaret: Number(sonuc.bugunkuZiyaret) || 0,
        premiumAktif: sonuc.premiumAktif === true,
        premiumBitis:
          typeof sonuc.premiumBitis === "string" ? sonuc.premiumBitis : null,
        olcer: sonuc.olcer && typeof sonuc.olcer === "object"
          ? (sonuc.olcer as OlcerOzeti)
          : null,
      });
    }

    void ozetiGetir().catch(() => {
      if (!iptalEdildi) setHata("Vitrin Ölçer bilgileri şu anda alınamıyor.");
    });

    return () => {
      iptalEdildi = true;
    };
  }, []);

  async function yorumDurumunuDegistir(id: string, mevcutDurum: string) {
    if (yorumIslemi) return;
    const yeniDurum = mevcutDurum === "hidden" ? "published" : "hidden";
    setYorumIslemi(id);
    try {
      const { error } = await supabase.rpc("set_product_comment_status", {
        p_comment_id: id,
        p_status: yeniDurum,
      });
      if (error) throw error;
      setOzet((current) => {
        if (!current?.olcer) return current;
        return {
          ...current,
          olcer: {
            ...current.olcer,
            recent_comments: current.olcer.recent_comments.map((item) =>
              item.id === id ? { ...item, status: yeniDurum } : item,
            ),
          },
        };
      });
    } catch {
      setHata("Yorum durumu değiştirilemedi.");
    } finally {
      setYorumIslemi(null);
    }
  }

  if (hata && !ozet) {
    return <p className="mt-4 text-xs font-semibold text-red-300" role="status">{hata}</p>;
  }

  const olcer = ozet?.olcer;

  return (
    <section className="mt-4 rounded-2xl border border-lp-border bg-lp-surface p-4 min-[901px]:p-5" aria-labelledby="vitrin-olcer-title">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <p className="text-[11px] font-black uppercase tracking-[0.14em] text-lp-secondary">Vitrin Ölçer</p>
          <h2 id="vitrin-olcer-title" className="mt-1 text-[18px] font-black text-lp-text">Müşteri hareketleri</h2>
          <p className="mt-1 text-[12px] font-semibold text-lp-muted">
            Ham ziyaretçi kimliği gösterilmez; yalnız işletme performans özeti görünür.
            {olcer ? ` Son ${olcer.days} gün aynı dönem üzerinden hesaplanır.` : ""}
          </p>
        </div>
        <div className="rounded-full border border-lp-border bg-lp-bg-light px-3 py-1.5 text-[11px] font-black text-lp-muted">
          Bugün {ozet ? ozet.bugunkuZiyaret : "—"} ziyaret
        </div>
      </div>

      {!olcer ? (
        <p className="mt-4 rounded-xl border border-amber-400/20 bg-amber-400/5 px-4 py-3 text-xs font-semibold leading-5 text-amber-200">
          Ölçüm veritabanı kapısı bu ortamda henüz uygulanmadı. Mevcut vitrin çalışmaya devam eder; yeni ölçüm verisi hazır olduğunda bu panel kendiliğinden açılır.
        </p>
      ) : (
        <>
          <div className="mt-4 grid grid-cols-2 gap-2 min-[720px]:grid-cols-4">
            {[
              ["Ziyaretçi", metric(olcer.unique_visitors)],
              ["Ürün görüntüleme", metric(olcer.product_views)],
              ["Beğeni", metric(olcer.likes)],
              ["Yorum", metric(olcer.comments)],
              ["Sepete ekleme", metric(olcer.cart_adds)],
              ["WhatsApp sipariş", metric(olcer.whatsapp_orders)],
              ["WhatsApp tıklama", metric(olcer.whatsapp_clicks)],
              ["Dönüşüm", `%${metric(olcer.conversion_percent)}`],
            ].map(([label, value]) => (
              <div key={String(label)} className="rounded-xl border border-lp-border bg-lp-bg-light p-3">
                <p className="text-[10px] font-black uppercase tracking-[0.08em] text-lp-muted">{label}</p>
                <p className="mt-1 text-[22px] font-black text-lp-text">{value}</p>
              </div>
            ))}
          </div>

          <div className="mt-4 grid gap-4 min-[901px]:grid-cols-2">
            <div className="rounded-xl border border-lp-border bg-lp-bg-light p-4">
              <h3 className="text-[13px] font-black text-lp-text">En çok ilgi gören ürünler</h3>
              {olcer.top_products.length > 0 ? (
                <div className="mt-3 space-y-2">
                  {olcer.top_products.map((product) => (
                    <div key={product.slug} className="rounded-lg border border-lp-border bg-lp-surface px-3 py-2.5">
                      <p className="truncate text-[12px] font-black text-lp-text">{product.name}</p>
                      <p className="mt-1 text-[11px] font-semibold text-lp-muted">
                        {product.views} görüntüleme · {product.likes} beğeni · {product.cart_adds} sepet · {product.orders} sipariş geçişi
                      </p>
                    </div>
                  ))}
                </div>
              ) : <p className="mt-3 text-xs font-semibold text-lp-muted">Henüz ürün hareketi yok.</p>}
            </div>

            <div className="rounded-xl border border-lp-border bg-lp-bg-light p-4">
              <h3 className="text-[13px] font-black text-lp-text">Ziyaret kaynakları</h3>
              {olcer.traffic_sources.length > 0 ? (
                <div className="mt-3 space-y-2">
                  {olcer.traffic_sources.map((item) => (
                    <div key={item.source} className="flex items-center justify-between gap-3 text-[12px]">
                      <span className="font-bold text-lp-muted">{sourceLabel(item.source)}</span>
                      <span className="font-black text-lp-text">{item.count}</span>
                    </div>
                  ))}
                </div>
              ) : <p className="mt-3 text-xs font-semibold text-lp-muted">Henüz kaynak verisi yok.</p>}
            </div>
          </div>

          <div className="mt-4 rounded-xl border border-lp-border bg-lp-bg-light p-4">
            <div className="flex items-center justify-between gap-3">
              <h3 className="text-[13px] font-black text-lp-text">Son yorumlar</h3>
              <span className="text-[11px] font-bold text-lp-muted">İşletme sahibi gizleyebilir</span>
            </div>
            {olcer.recent_comments.length > 0 ? (
              <div className="mt-3 space-y-2">
                {olcer.recent_comments.map((item) => (
                  <article key={item.id} className="rounded-lg border border-lp-border bg-lp-surface p-3">
                    <div className="flex items-start justify-between gap-3">
                      <div className="min-w-0">
                        <p className="truncate text-[11px] font-black text-lp-secondary">
                          {item.product_name} · {item.author_name}
                          {item.status === "hidden" ? " · gizli" : ""}
                        </p>
                        <p className="mt-1 break-words text-[12px] font-semibold leading-5 text-lp-text">{item.body}</p>
                      </div>
                      <button
                        type="button"
                        disabled={yorumIslemi === item.id}
                        onClick={() => void yorumDurumunuDegistir(item.id, item.status)}
                        className="shrink-0 rounded-lg border border-lp-border px-2.5 py-1.5 text-[10px] font-black text-red-300 disabled:opacity-50"
                      >
                        {item.status === "hidden" ? "Göster" : "Gizle"}
                      </button>
                    </div>
                  </article>
                ))}
              </div>
            ) : <p className="mt-3 text-xs font-semibold text-lp-muted">Henüz yorum yok.</p>}
          </div>
        </>
      )}

      {hata && ozet ? <p className="mt-3 text-xs font-semibold text-red-300" role="status">{hata}</p> : null}
    </section>
  );
}
