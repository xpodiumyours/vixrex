"use client";

import { useState } from "react";
import { supabase } from "@/lib/supabase";

/** Hesapsız vitrin uyarısı — Google ile hesap bağlama şeridi.
 *
 * 2026-09-03 (Çalışma masası / Yön C): bu blok "Sahip Çalışma Alanı"
 * çekmecesinin içindeydi. Çekmece kalktı — ekranda tek panel var, o da
 * Vixrex Asistan — ve bu uyarı oraya, başlığın hemen altına taşındı.
 * Mantık aynen korundu: linkIdentity bağlanacak bir oturum bulamazsa
 * sessizce hiçbir şey yapmıyor, o yüzden önce anonim oturum güvenceye
 * alınıyor (diğer sayfalardaki kurulu desenle aynı).
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
    <div className="border-b border-white/10 bg-amber-500/10 px-4 py-3">
      <p className="text-[12px] font-black text-amber-400">
        Vitrinini kaydetmek için hesabına bağla
      </p>
      <p className="mt-1 text-[11px] leading-[1.45] text-slate-400">
        Şu an vitrinin bu cihaza bağlı. Telefonunu değiştirirsen özelleştirmelerini
        kaybedersin.
      </p>
      {hata ? (
        <p className="mt-2 text-[10px] font-bold text-red-400" role="alert">
          {hata}
        </p>
      ) : null}
      <button
        type="button"
        disabled={baglaniyor}
        onClick={() => void bagla()}
        className="mt-2 flex w-full items-center justify-center rounded-xl bg-amber-500 px-3 py-2 text-[11px] font-black text-black transition-colors hover:bg-amber-400 disabled:opacity-60"
      >
        {baglaniyor ? "Bağlanıyor…" : "Google ile bağla"}
      </button>
    </div>
  );
}
