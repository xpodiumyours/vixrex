"use client";

import { useState } from "react";
import { supabase } from "@/lib/supabase";

/** Hesapsız vitrin uyarısı — Google ile hesap bağlama şeridi.
 *
 * Mobilde asistanın ana işini (vitrini düzenleme + sohbet) itmemesi için
 * tek satırlık kompakt uyarı olarak görünür; açıklama masaüstünde korunur.
 * Kimlik bağlama mantığı değişmez.
 */
export function HesapBaglaSeridi({ slug }: { slug: string }) {
  const [baglaniyor, setBaglaniyor] = useState(false);
  const [hata, setHata] = useState("");

  async function bagla() {
    setHata("");
    setBaglaniyor(true);
    try {
      const {
        data: { session },
      } = await supabase.auth.getSession();
      if (!session) {
        const { error: anonHata } = await supabase.auth.signInAnonymously();
        if (anonHata) {
          setHata("Bağlantı başlatılamadı. Lütfen tekrar dene.");
          setBaglaniyor(false);
          return;
        }
      }
      const { error } = await supabase.auth.linkIdentity({
        provider: "google",
        options: {
          redirectTo: `${window.location.origin}/hesap-bagla?slug=${encodeURIComponent(slug)}`,
        },
      });
      if (error) {
        setHata("Google ile bağlanamadı. Lütfen tekrar dene.");
        setBaglaniyor(false);
      }
      // Başarılıysa tarayıcı Google'a yönlenir; bundan sonrası
      // /hesap-bagla sayfasının işi.
    } catch {
      setHata("Bir şeyler ters gitti. Lütfen tekrar dene.");
      setBaglaniyor(false);
    }
  }

  return (
    <div className="border-b border-white/10 bg-amber-500/10 px-3 py-2.5 sm:px-4 sm:py-3">
      <div className="flex items-center gap-3 sm:block">
        <div className="min-w-0 flex-1">
          <p className="truncate text-[11px] font-black text-amber-400 sm:text-[12px]">
            Vitrinini hesabına bağla
          </p>
          <p className="mt-1 hidden text-[11px] leading-[1.45] text-slate-400 sm:block">
            Şu an vitrinin bu cihaza bağlı. Telefonunu değiştirirsen özelleştirmelerini
            kaybedersin.
          </p>
        </div>

        <button
          type="button"
          disabled={baglaniyor}
          onClick={() => void bagla()}
          className="shrink-0 rounded-lg bg-amber-500 px-3 py-2 text-[10px] font-black text-black transition-colors hover:bg-amber-400 disabled:opacity-60 sm:mt-2 sm:w-full sm:rounded-xl sm:text-[11px]"
        >
          {baglaniyor ? "Bağlanıyor…" : "Google ile bağla"}
        </button>
      </div>

      {hata ? (
        <p className="mt-2 text-[10px] font-bold text-red-400" role="alert">
          {hata}
        </p>
      ) : null}
    </div>
  );
}
