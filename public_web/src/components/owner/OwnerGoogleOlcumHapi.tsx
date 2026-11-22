"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";

type Olcum = {
  gun: number;
  vitrinGoruntuleme: number;
  urunGoruntuleme: number;
  whatsapp: number;
  yolTarifi: number;
};

function sayi(deger: number | undefined) {
  return (deger ?? 0).toLocaleString("tr-TR");
}

export function OwnerGoogleOlcumHapi() {
  const [olcum, setOlcum] = useState<Olcum | null>(null);

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

  if (!olcum) return null;

  const goruntuleme = olcum.vitrinGoruntuleme + olcum.urunGoruntuleme;

  return (
    <div className="flex shrink-0 items-center gap-1 whitespace-nowrap rounded-full border border-lp-border bg-lp-surface px-2 py-1 text-[10px] font-bold text-lp-muted min-[901px]:gap-2 min-[901px]:px-3 min-[901px]:py-[5px] min-[901px]:text-[12px]">
      <span
        className="grid h-4 w-4 place-items-center rounded-full bg-white text-[9px] font-black text-[#1a73e8] min-[901px]:h-[18px] min-[901px]:w-[18px] min-[901px]:text-[10px]"
        aria-hidden="true"
      >
        G
      </span>
      <span className="font-black tabular-nums text-lp-text">{sayi(goruntuleme)}</span>
      <span>Görüntüleme</span>
      <span className="font-black tabular-nums text-[#25D366]">{sayi(olcum.whatsapp)}</span>
      <span>WhatsApp</span>
      <span className="font-black tabular-nums text-lp-secondary">{sayi(olcum.yolTarifi)}</span>
      <span>Yol tarifi</span>
    </div>
  );
}
