"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";

type PanoOzeti = {
  bugunkuZiyaret: number;
  premiumAktif: boolean;
  premiumBitis: string | null;
};

function premiumMetni(ozet: PanoOzeti): string {
  if (!ozet.premiumAktif) return "Premium aktif değil";
  if (!ozet.premiumBitis) return "Premium / deneme aktif";

  const bitis = new Date(ozet.premiumBitis);
  if (Number.isNaN(bitis.getTime())) return "Premium / deneme aktif";

  const tarih = new Intl.DateTimeFormat("tr-TR", {
    day: "numeric",
    month: "long",
    year: "numeric",
  }).format(bitis);
  return `Premium / deneme ${tarih} tarihine kadar aktif`;
}

export function OwnerDashboardMetrics() {
  const [ozet, setOzet] = useState<PanoOzeti | null>(null);
  const [hata, setHata] = useState("");

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
        setHata(sonuc.hata ?? "Pano bilgileri şu anda alınamıyor.");
        return;
      }

      setOzet({
        bugunkuZiyaret: Number(sonuc.bugunkuZiyaret) || 0,
        premiumAktif: sonuc.premiumAktif === true,
        premiumBitis:
          typeof sonuc.premiumBitis === "string" ? sonuc.premiumBitis : null,
      });
    }

    void ozetiGetir().catch(() => {
      if (!iptalEdildi) setHata("Pano bilgileri şu anda alınamıyor.");
    });

    return () => {
      iptalEdildi = true;
    };
  }, []);

  if (hata) {
    return (
      <p className="mt-3 text-xs text-[var(--owner-muted)]" role="status">
        {hata}
      </p>
    );
  }

  return (
    <div className="mt-4 grid gap-3 sm:grid-cols-2" aria-live="polite">
      <div className="owner-card p-4">
        <p className="text-xs font-bold uppercase tracking-[0.12em] text-[var(--owner-muted)]">
          Bugünkü ziyaret
        </p>
        <p className="mt-2 text-3xl font-extrabold text-[var(--owner-text)]">
          {ozet ? ozet.bugunkuZiyaret : "—"}
        </p>
        <p className="mt-1 text-xs text-[var(--owner-muted)]">
          Vitrinini bugün görüntüleyen kişi sayısı
        </p>
      </div>

      <div className="owner-card p-4">
        <p className="text-xs font-bold uppercase tracking-[0.12em] text-[var(--owner-muted)]">
          Vitrin durumu
        </p>
        <p className="mt-2 text-base font-bold text-[var(--owner-text)]">
          {ozet ? premiumMetni(ozet) : "Yükleniyor…"}
        </p>
        <p className="mt-1 text-xs text-[var(--owner-muted)]">
          Yayın ve üyelik süren
        </p>
      </div>
    </div>
  );
}
