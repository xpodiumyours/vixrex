"use client";

import { useCallback, useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import Link from "next/link";
import { supabase } from "@/lib/supabase";
import { sahipOturumuAc } from "@/lib/ownerCookie";

interface SiparisKalemi {
  id: string;
  productName: string;
  unitPriceKurus: number;
  quantity: number;
}

interface Siparis {
  id: string;
  customerName: string;
  customerPhone: string;
  customerNote: string;
  fulfillment: string;
  paymentMethod: string;
  status: string;
  statusLabel: string;
  paymentStatus: string;
  amountKurus: number;
  createdAt: string;
  items: SiparisKalemi[];
}

const DURUM_RENK: Record<string, string> = {
  new: "bg-amber-500/20 text-amber-400",
  confirmed: "bg-green-500/20 text-green-400",
  delivered: "bg-blue-500/20 text-blue-400",
  cancelled: "bg-white/10 text-[var(--owner-muted)]",
};

function kurusMetni(kurus: number): string {
  const tam = Math.floor(kurus / 100);
  const kurusKisim = kurus % 100;
  return kurusKisim === 0
    ? `${tam} TL`
    : `${tam},${kurusKisim.toString().padStart(2, "0")} TL`;
}

function tarihMetni(isoStr: string): string {
  const tarih = new Date(isoStr);
  if (Number.isNaN(tarih.getTime())) return isoStr;
  const gun = String(tarih.getDate()).padStart(2, "0");
  const ay = String(tarih.getMonth() + 1).padStart(2, "0");
  const yil = String(tarih.getFullYear()).slice(-2);
  const saat = String(tarih.getHours()).padStart(2, "0");
  const dakika = String(tarih.getMinutes()).padStart(2, "0");
  return `${gun}.${ay}.${yil} · ${saat}:${dakika}`;
}

function whatsappBaglantisi(telefon: string): string {
  const rakam = telefon.replace(/[^\d]/g, "");
  return `https://wa.me/${rakam}`;
}

export default function SiparisYonetimPage() {
  const params = useParams();
  const router = useRouter();
  const slug = params.slug as string;

  const [siparisler, setSiparisler] = useState<Siparis[]>([]);
  const [yukleniyor, setYukleniyor] = useState(true);
  const [hata, setHata] = useState<string | null>(null);
  const [islemYapiliyor, setIslemYapiliyor] = useState<string | null>(null);

  const siparisleriGetir = useCallback(async () => {
    let {
      data: { session },
    } = await supabase.auth.getSession();
    setHata(null);
    if (!session) {
      try {
        const { data: anonData } = await supabase.auth.signInAnonymously();
        if (anonData?.session) session = anonData.session;
        else {
          router.push("/giris");
          return;
        }
      } catch {
        router.push("/giris");
        return;
      }
    }

    const istekAt = () =>
      fetch(`/api/owner-orders?slug=${encodeURIComponent(slug)}`, {
        headers: { Authorization: `Bearer ${session!.access_token}` },
      });

    try {
      let res = await istekAt();
      if (res.status === 401) {
        const kuruldu = await sahipOturumuAc();
        if (kuruldu) res = await istekAt();
      }
      const sonuc = await res.json();
      if (!res.ok) {
        setHata(sonuc?.hata ?? "Siparişler yüklenemedi.");
        setSiparisler([]);
      } else {
        setSiparisler((sonuc.siparisler ?? []) as Siparis[]);
      }
    } catch {
      setHata("Bağlantı kurulamadı. Lütfen tekrar dene.");
    }
    setYukleniyor(false);
  }, [slug, router]);

  useEffect(() => {
    async function init() {
      await siparisleriGetir();
    }
    init();
  }, [siparisleriGetir]);

  async function durumDegistir(orderId: string, status: string) {
    setIslemYapiliyor(orderId);
    setHata(null);
    try {
      const res = await fetch("/api/owner-orders", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ slug, orderId, status }),
      });
      const sonuc = await res.json();
      if (!res.ok) {
        setHata(sonuc?.hata ?? "Sipariş güncellenemedi.");
      }
    } catch {
      setHata("Bağlantı kurulamadı. Lütfen tekrar dene.");
    }
    await siparisleriGetir();
    setIslemYapiliyor(null);
  }

  return (
    <main className="owner-shell px-4 py-8 sm:px-6">
      <div className="mx-auto max-w-3xl">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <p className="text-xs font-bold uppercase tracking-[0.16em] text-[var(--owner-secondary)]">
              Vixrex
            </p>
            <h1 className="mt-1 text-xl font-bold text-[var(--owner-text)]">
              Siparişlerim
            </h1>
          </div>
          <Link
            href={`/v/${slug}`}
            className="owner-button-secondary min-h-11 px-4 py-2 text-sm"
          >
            Vitrine dön
          </Link>
        </div>

        <p className="mt-3 text-sm text-[var(--owner-muted)]">
          Müşterilerin vitrininden verdiği siparişler burada görünür.
        </p>

        {hata ? (
          <p className="owner-error mb-4 mt-4 text-sm" role="alert">
            {hata}
          </p>
        ) : null}

        {yukleniyor ? (
          <div className="owner-card mt-4 p-5 text-sm text-[var(--owner-muted)]" role="status">
            Siparişler yükleniyor…
          </div>
        ) : siparisler.length === 0 ? (
          <div className="owner-card mt-4 p-8 text-center text-sm leading-6 text-[var(--owner-muted)]">
            Henüz sipariş yok. Ürün sayfalarındaki &quot;Sipariş ver&quot; düğmesiyle
            gelen siparişler burada birikir.
          </div>
        ) : (
          <div className="mt-4 space-y-3">
            {siparisler.map((siparis) => (
              <article key={siparis.id} className="owner-card p-4">
                <div className="flex flex-wrap items-start justify-between gap-2">
                  <div className="min-w-0">
                    <p className="text-sm font-black text-[var(--owner-text)]">
                      {siparis.customerName}
                    </p>
                    <a
                      href={`tel:${siparis.customerPhone.replace(/[^\d]/g, "")}`}
                      className="owner-link mt-1 block text-sm text-[var(--owner-muted)]"
                    >
                      {siparis.customerPhone}
                    </a>
                  </div>
                  <div className="flex flex-wrap items-center gap-2">
                    <span
                      className={`rounded-full px-2.5 py-1 text-xs font-bold ${DURUM_RENK[siparis.status] ?? DURUM_RENK.new}`}
                    >
                      {siparis.statusLabel}
                    </span>
                    <span className="rounded-full bg-white/10 px-2.5 py-1 text-xs font-bold text-[var(--owner-muted)]">
                      {siparis.paymentMethod === "online" ? "Online ödeme" : "Kapıda ödeme"}
                      {siparis.paymentStatus === "paid" ? " · ödendi" : ""}
                    </span>
                    <span className="rounded-full bg-white/10 px-2.5 py-1 text-xs font-bold text-[var(--owner-muted)]">
                      {siparis.fulfillment === "delivery" ? "Kurye" : "Gel-al"}
                    </span>
                  </div>
                </div>

                <ul className="mt-3 space-y-1">
                  {siparis.items.map((kalem) => (
                    <li
                      key={kalem.id}
                      className="flex items-center justify-between gap-3 text-sm text-[var(--owner-muted)]"
                    >
                      <span>
                        {kalem.productName} × {kalem.quantity}
                      </span>
                      <span>{kurusMetni(kalem.unitPriceKurus * kalem.quantity)}</span>
                    </li>
                  ))}
                </ul>

                <div className="mt-3 flex flex-wrap items-center justify-between gap-2 border-t border-[var(--owner-border)] pt-3">
                  <div>
                    <p className="text-xs text-[var(--owner-muted)]">
                      {tarihMetni(siparis.createdAt)}
                    </p>
                    <p className="mt-1 text-sm font-black text-[var(--owner-text)]">
                      Toplam {kurusMetni(siparis.amountKurus)}
                    </p>
                    {siparis.customerNote ? (
                      <p className="mt-1 text-xs leading-5 text-[var(--owner-muted)]">
                        Not: {siparis.customerNote}
                      </p>
                    ) : null}
                  </div>
                  <div className="flex flex-wrap items-center gap-2">
                    <a
                      href={whatsappBaglantisi(siparis.customerPhone)}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="owner-button-secondary min-h-11 px-4 py-2 text-sm"
                    >
                      WhatsApp
                    </a>
                    {siparis.status === "new" ? (
                      <button
                        type="button"
                        disabled={islemYapiliyor === siparis.id}
                        onClick={() => durumDegistir(siparis.id, "confirmed")}
                        className="owner-button-primary min-h-11 px-4 py-2 text-sm"
                      >
                        Onayla
                      </button>
                    ) : null}
                    {siparis.status === "new" || siparis.status === "confirmed" ? (
                      <>
                        <button
                          type="button"
                          disabled={islemYapiliyor === siparis.id}
                          onClick={() => durumDegistir(siparis.id, "delivered")}
                          className="owner-button-secondary min-h-11 px-4 py-2 text-sm"
                        >
                          Teslim edildi
                        </button>
                        <button
                          type="button"
                          disabled={islemYapiliyor === siparis.id}
                          onClick={() => durumDegistir(siparis.id, "cancelled")}
                          className="owner-button-secondary min-h-11 px-4 py-2 text-sm"
                        >
                          İptal
                        </button>
                      </>
                    ) : null}
                  </div>
                </div>
              </article>
            ))}
          </div>
        )}
      </div>
    </main>
  );
}
