"use client";

import { useEffect, useState, useCallback } from "react";
import { useParams, useRouter } from "next/navigation";
import Link from "next/link";
import { supabase } from "@/lib/supabase";
import { sahipOturumuAc } from "@/lib/ownerCookie";

/**
 * Randevu yönetim sayfası — sahibin tüm randevularını gördüğü ve
 * onaylayıp/reddedebildiği yüzey.
 *
 * Flutter'daki BookingManagementScreen'in web karşılığı.
 * 3 sekme: Bekleyen / Bugün / Yaklaşan
 *
 * POST istekleri Supabase erişim jetonuyla yapılır — respond_to_appointment
 * RPC'si auth.uid() gerektirir.
 */

interface Randevu {
  id: string;
  store_slug: string;
  customer_name: string;
  customer_phone: string;
  customer_notes: string | null;
  service_title: string;
  service_price: string | null;
  service_duration: number;
  appointment_time: string;
  status: string;
  appointment_reschedule_requests: RescheduleRequest[];
}

interface RescheduleRequest {
  id: string;
  status: string;
  requested_time: string;
}

type Sekme = "bekleyen" | "bugun" | "yaklasan";

const DURUM_RENK: Record<string, { metin: string; sinif: string }> = {
  confirmed: {
    metin: "Onaylandı",
    sinif: "bg-green-500/20 text-green-400",
  },
  rejected: { metin: "Reddedildi", sinif: "bg-red-500/20 text-red-400" },
  cancelled_by_customer: {
    metin: "Müşteri İptal",
    sinif: "bg-white/10 text-white/40",
  },
  cancelled_by_store: {
    metin: "İşletme İptal",
    sinif: "bg-white/10 text-white/40",
  },
  expired: { metin: "Süresi Doldu", sinif: "bg-white/10 text-white/40" },
  pending: {
    metin: "Onay Bekliyor",
    sinif: "bg-amber-500/20 text-amber-400",
  },
};

function formatDateTime(isoStr: string): string {
  try {
    const dt = new Date(isoStr);
    return dt.toLocaleDateString("tr-TR", {
      day: "numeric",
      month: "long",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  } catch {
    return isoStr;
  }
}

function isToday(isoStr: string): boolean {
  const d = new Date(isoStr);
  const now = new Date();
  return (
    d.getFullYear() === now.getFullYear() &&
    d.getMonth() === now.getMonth() &&
    d.getDate() === now.getDate()
  );
}

function isUpcoming(isoStr: string): boolean {
  return new Date(isoStr) > new Date();
}

export default function RandevuYonetimPage() {
  const params = useParams();
  const router = useRouter();
  const slug = params.slug as string;

  const [randevular, setRandevular] = useState<Randevu[]>([]);
  const [yukleniyor, setYukleniyor] = useState(true);
  const [hata, setHata] = useState<string | null>(null);
  const [aktifSekme, setAktifSekme] = useState<Sekme>("bekleyen");
  const [islemYapiliyor, setIslemYapiliyor] = useState<string | null>(null);

  const randevulariGetir = useCallback(async () => {
    setHata(null);

    const {
      data: { session },
    } = await supabase.auth.getSession();
    if (!session) {
      router.push("/giris");
      return;
    }

    try {
      const res = await fetch(
        `/api/appointments?slug=${encodeURIComponent(slug)}`,
        {
          headers: { Authorization: `Bearer ${session.access_token}` },
        }
      );
      const sonuc = await res.json();
      if (!res.ok) {
        if (res.status === 401) {
          const kuruldu = await sahipOturumuAc();
          if (kuruldu) {
            const res2 = await fetch(
              `/api/appointments?slug=${encodeURIComponent(slug)}`,
              {
                headers: { Authorization: `Bearer ${session.access_token}` },
              }
            );
            const sonuc2 = await res2.json();
            if (res2.ok) {
              setRandevular(sonuc2.randevular ?? []);
              return;
            }
          }
          setHata(
            "Oturumunuz bulunamadı veya süresi dolmuş. Panodan giriş yapın."
          );
          return;
        }
        setHata(sonuc.hata || "Randevular yüklenemedi.");
        return;
      }
      setRandevular(sonuc.randevular ?? []);
    } catch {
      setHata("Bağlantı kurulamadı.");
    } finally {
      setYukleniyor(false);
    }
  }, [slug, router]);

  useEffect(() => {
    async function init() {
      await sahipOturumuAc();
      await randevulariGetir();
    }
    init();
  }, [randevulariGetir]);

  async function randevuyaYanitVer(
    appointmentId: string,
    options: { action?: string; rescheduleAction?: string }
  ) {
    setIslemYapiliyor(appointmentId);

    const {
      data: { session },
    } = await supabase.auth.getSession();
    if (!session) return;

    try {
      const res = await fetch("/api/appointments", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${session.access_token}`,
        },
        body: JSON.stringify({ slug, appointmentId, ...options }),
      });
      if (!res.ok) {
        const sonuc = await res.json();
        setHata(sonuc.hata || "İşlem gerçekleştirilemedi.");
        return;
      }
      await randevulariGetir();
    } catch {
      setHata("Bağlantı kurulamadı.");
    } finally {
      setIslemYapiliyor(null);
    }
  }

  const filtrelenmis = randevular.filter((r) => {
    if (aktifSekme === "bekleyen") return r.status === "pending";
    if (aktifSekme === "bugun") return isToday(r.appointment_time);
    return isUpcoming(r.appointment_time) && r.status !== "expired";
  });

  const bekleyenSayisi = randevular.filter(
    (r) => r.status === "pending"
  ).length;
  const bugunSayisi = randevular.filter((r) =>
    isToday(r.appointment_time)
  ).length;
  const yaklasanSayisi = randevular.filter(
    (r) => isUpcoming(r.appointment_time) && r.status !== "expired"
  ).length;

  return (
    <main className="min-h-screen bg-[#0c0d10] px-4 py-8 text-[#f4f1ea] sm:px-6">
      <div className="mx-auto flex w-full max-w-[720px] flex-col gap-6">
        {/* Başlık */}
        <div className="flex items-center justify-between gap-3 rounded-2xl border border-white/8 bg-[#15171c] px-4 py-3">
          <Link
            href={`/v/${slug}`}
            className="inline-flex items-center gap-1 text-sm font-extrabold text-[#E8A87C]"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2.5"
            >
              <polyline points="15 18 9 12 15 6" />
            </svg>
            Vitrine Dön
          </Link>
          <span className="text-xs font-extrabold text-white/45">
            Randevu Yönetimi
          </span>
        </div>

        <h1 className="text-2xl font-extrabold text-white">
          Randevuları Yönet
        </h1>

        {/* Hata */}
        {hata && (
          <div
            className="rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-400"
            role="alert"
          >
            {hata}
          </div>
        )}

        {/* Sekmeler */}
        <div className="flex gap-2">
          {(
            [
              ["bekleyen", "Bekleyen", bekleyenSayisi],
              ["bugun", "Bugün", bugunSayisi],
              ["yaklasan", "Yaklaşan", yaklasanSayisi],
            ] as const
          ).map(([key, label, count]) => (
            <button
              key={key}
              onClick={() => setAktifSekme(key)}
              className={`rounded-xl px-4 py-2 text-xs font-extrabold transition ${
                aktifSekme === key
                  ? "bg-[#E8A87C] text-[#0c0d10]"
                  : "border border-white/10 text-white/50 hover:border-white/25"
              }`}
            >
              {label} ({count})
            </button>
          ))}
        </div>

        {/* Randevu Listesi */}
        {yukleniyor ? (
          <div className="flex items-center justify-center py-12">
            <div className="h-4 w-4 animate-pulse rounded-full bg-[#E8A87C]" />
          </div>
        ) : filtrelenmis.length === 0 ? (
          <div className="rounded-2xl border border-white/8 bg-[#15171c] py-12 text-center">
            <p className="text-sm text-white/40">
              {aktifSekme === "bekleyen"
                ? "Bekleyen randevu talebi bulunmuyor."
                : "Gösterilecek randevu bulunamadı."}
            </p>
          </div>
        ) : (
          <div className="space-y-3">
            {filtrelenmis.map((randevu) => {
              const durum =
                DURUM_RENK[randevu.status] ?? DURUM_RENK.pending;
              const pendingReschedule =
                randevu.appointment_reschedule_requests?.find(
                  (r) => r.status === "pending"
                );
              const isIsleniyor = islemYapiliyor === randevu.id;

              return (
                <div
                  key={randevu.id}
                  className="rounded-2xl border border-white/8 bg-[#15171c] p-4"
                >
                  {/* üst satır: tarih + durum */}
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-extrabold text-white/70">
                      {formatDateTime(randevu.appointment_time)}
                    </span>
                    <span
                      className={`rounded-full px-2.5 py-1 text-[10px] font-extrabold ${durum.sinif}`}
                    >
                      {durum.metin}
                    </span>
                  </div>

                  {/* hizmet bilgisi */}
                  <h3 className="mt-3 text-sm font-extrabold text-white">
                    {randevu.service_title}
                  </h3>
                  <p className="mt-1 text-xs text-[#E8A87C]">
                    {randevu.service_price && randevu.service_price !== "0"
                      ? `${randevu.service_price} · `
                      : ""}
                    {randevu.service_duration} dk
                  </p>

                  {/* müşteri bilgisi */}
                  <div className="mt-3 space-y-1.5 border-t border-white/8 pt-3">
                    <p className="text-xs text-white/50">
                      <span className="font-bold text-white/70">
                        Müşteri:
                      </span>{" "}
                      {randevu.customer_name}
                    </p>
                    <p className="text-xs text-white/50">
                      <span className="font-bold text-white/70">
                        Telefon:
                      </span>{" "}
                      {randevu.customer_phone}
                    </p>
                    {randevu.customer_notes && (
                      <p className="text-xs text-white/40">
                        <span className="font-bold text-white/50">Not:</span>{" "}
                        {randevu.customer_notes}
                      </p>
                    )}
                  </div>

                  {/* değişiklik talebi */}
                  {pendingReschedule && (
                    <div className="mt-3 rounded-xl border border-amber-500/30 bg-amber-500/10 p-3">
                      <p className="text-[10px] font-extrabold text-amber-400">
                        ⚠️ Müşteri tarih değişikliği istedi
                      </p>
                      <p className="mt-1 text-xs text-white/60">
                        Yeni saat:{" "}
                        {formatDateTime(pendingReschedule.requested_time)}
                      </p>
                      <div className="mt-2 flex gap-2">
                        <button
                          onClick={() =>
                            randevuyaYanitVer(randevu.id, {
                              rescheduleAction: "reject",
                            })
                          }
                          disabled={isIsleniyor}
                          className="flex-1 rounded-lg border border-red-500/30 px-3 py-1.5 text-[10px] font-extrabold text-red-400 transition hover:border-red-500/50 disabled:opacity-50"
                        >
                          Reddet
                        </button>
                        <button
                          onClick={() =>
                            randevuyaYanitVer(randevu.id, {
                              rescheduleAction: "approve",
                            })
                          }
                          disabled={isIsleniyor}
                          className="flex-1 rounded-lg bg-green-600 px-3 py-1.5 text-[10px] font-extrabold text-white transition hover:brightness-110 disabled:opacity-50"
                        >
                          Onayla & Güncelle
                        </button>
                      </div>
                    </div>
                  )}

                  {/* aksiyon butonları — yalnızca pending ve değişiklik talebi yoksa */}
                  {randevu.status === "pending" && !pendingReschedule && (
                    <div className="mt-3 flex gap-2">
                      <button
                        onClick={() =>
                          randevuyaYanitVer(randevu.id, { action: "reject" })
                        }
                        disabled={isIsleniyor}
                        className="flex-1 rounded-lg border border-red-500/30 px-3 py-2 text-xs font-extrabold text-red-400 transition hover:border-red-500/50 disabled:opacity-50"
                      >
                        {isIsleniyor ? "..." : "Reddet"}
                      </button>
                      <button
                        onClick={() =>
                          randevuyaYanitVer(randevu.id, {
                            action: "confirm",
                          })
                        }
                        disabled={isIsleniyor}
                        className="flex-1 rounded-lg bg-green-600 px-3 py-2 text-xs font-extrabold text-white transition hover:brightness-110 disabled:opacity-50"
                      >
                        {isIsleniyor ? "..." : "Onayla"}
                      </button>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </div>
    </main>
  );
}
