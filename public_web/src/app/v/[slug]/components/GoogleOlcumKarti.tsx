"use client";

import { useEffect, useRef, useState } from "react";
import { supabase } from "@/lib/supabase";

type Olcum = {
  gun: number;
  vitrinGoruntuleme: number;
  urunGoruntuleme: number;
  whatsapp: number;
  telefon: number;
  yolTarifi: number;
  kaynaklar?: {
    google?: number;
    haritalar?: number;
    dogrudan?: number;
    instagram?: number;
    diger?: number;
  };
};

function sayi(deger: number | undefined) {
  return (deger ?? 0).toLocaleString("tr-TR");
}

export function GoogleOlcumKarti() {
  const [olcum, setOlcum] = useState<Olcum | null>(null);
  const [acik, setAcik] = useState(false);
  const kutuRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    let iptal = false;
    const getir = async () => {
      try {
        const {
          data: { session },
        } = await supabase.auth.getSession();
        if (!session || session.user.is_anonymous) return;
        const yanit = await fetch("/api/owner-dashboard/google-olcum?gun=7", {
          headers: { authorization: `Bearer ${session.access_token}` },
        });
        if (!yanit.ok || iptal) return;
        setOlcum((await yanit.json()) as Olcum);
      } catch {
        setOlcum(null);
      }
    };
    void getir();
    return () => {
      iptal = true;
    };
  }, []);

  useEffect(() => {
    if (!acik) return;
    const kapat = (olay: MouseEvent) => {
      if (!kutuRef.current?.contains(olay.target as Node)) setAcik(false);
    };
    document.addEventListener("mousedown", kapat);
    return () => document.removeEventListener("mousedown", kapat);
  }, [acik]);

  if (!olcum) return null;

  const goruntuleme = olcum.vitrinGoruntuleme + olcum.urunGoruntuleme;
  const kaynaklar = olcum.kaynaklar ?? {};
  const kaynakSatirlari = [
    { ad: "Google arama", deger: kaynaklar.google ?? 0 },
    { ad: "Google Haritalar", deger: kaynaklar.haritalar ?? 0 },
    { ad: "Doğrudan", deger: kaynaklar.dogrudan ?? 0 },
    { ad: "Instagram", deger: kaynaklar.instagram ?? 0 },
    { ad: "Diğer", deger: kaynaklar.diger ?? 0 },
  ].filter((satir) => satir.deger > 0);

  return (
    <div ref={kutuRef} className="relative">
      <button
        type="button"
        onClick={() => setAcik((onceki) => !onceki)}
        aria-expanded={acik}
        aria-label="Google'ın saydığı rakamlar"
        className="flex h-7 items-center gap-1.5 rounded-lg border border-emerald-400/30 bg-emerald-500/10 px-2 text-[10px] font-bold text-emerald-200 transition hover:bg-emerald-500/20"
      >
        <span className="grid h-3.5 w-3.5 place-items-center rounded-full bg-white/90 text-[8px] font-black text-[#1a73e8]">
          G
        </span>
        <span className="tabular-nums">{sayi(goruntuleme)}</span>
        <span className="hidden font-medium text-emerald-300/80 sm:inline">görüntüleme</span>
      </button>

      {acik ? (
        <div className="absolute right-0 top-9 z-40 w-64 space-y-2.5 rounded-xl border border-emerald-400/25 bg-[#0b162a] p-3 text-[10px] text-slate-300 shadow-2xl">
          <div>
            <p className="text-[11px] font-bold text-white">Google ne saydı?</p>
            <p className="text-slate-500">Son {olcum.gun} gün · Google Analytics</p>
          </div>

          <div className="grid grid-cols-2 gap-1.5">
            <div className="rounded-lg border border-white/10 bg-white/[0.04] px-2 py-1.5">
              <p className="text-[9px] text-slate-500">Vitrin görüntüleme</p>
              <p className="text-sm font-black tabular-nums text-white">{sayi(olcum.vitrinGoruntuleme)}</p>
            </div>
            <div className="rounded-lg border border-white/10 bg-white/[0.04] px-2 py-1.5">
              <p className="text-[9px] text-slate-500">Ürün sayfası</p>
              <p className="text-sm font-black tabular-nums text-white">{sayi(olcum.urunGoruntuleme)}</p>
            </div>
            <div className="rounded-lg border border-white/10 bg-white/[0.04] px-2 py-1.5">
              <p className="text-[9px] text-slate-500">WhatsApp tıklama</p>
              <p className="text-sm font-black tabular-nums text-emerald-300">{sayi(olcum.whatsapp)}</p>
            </div>
            <div className="rounded-lg border border-white/10 bg-white/[0.04] px-2 py-1.5">
              <p className="text-[9px] text-slate-500">Yol tarifi</p>
              <p className="text-sm font-black tabular-nums text-sky-300">{sayi(olcum.yolTarifi)}</p>
            </div>
            <div className="rounded-lg border border-white/10 bg-white/[0.04] px-2 py-1.5">
              <p className="text-[9px] text-slate-500">Telefon tıklama</p>
              <p className="text-sm font-black tabular-nums text-white">{sayi(olcum.telefon)}</p>
            </div>
          </div>

          <div className="space-y-1 border-t border-white/10 pt-2">
            <p className="text-[9px] font-bold uppercase tracking-wide text-slate-500">Nereden geldiler</p>
            {kaynakSatirlari.length === 0 ? (
              <p className="text-slate-500">Henüz kaynak verisi yok.</p>
            ) : (
              kaynakSatirlari.map((satir) => (
                <div key={satir.ad} className="flex items-center justify-between">
                  <span>{satir.ad}</span>
                  <span className="font-black tabular-nums text-white">{sayi(satir.deger)}</span>
                </div>
              ))
            )}
          </div>
        </div>
      ) : null}
    </div>
  );
}
