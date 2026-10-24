"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { SharedVixrexAssistant } from "@/components/vixrex/SharedVixrexAssistant";
import { supabase } from "@/lib/supabase";
import { sahipOturumuAc } from "@/lib/ownerCookie";

type Gorunum = "kontrol" | "asistan" | "hata";

type Bootstrap = {
  has_store?: boolean;
  slug?: string;
  store?: { slug?: string } | null;
};

/**
 * Mevcut vitrini olan esnafı aynı vitrinin sahiplik asistanına geri taşır.
 * Hesaba bağlı vitrin önceliklidir. Hesapta vitrin yoksa yalnız doğrulanmış
 * HttpOnly sahip çerezindeki vitrin kullanılabilir; slug tahmin edilmez.
 */
export default function VixrexPage() {
  const router = useRouter();
  const [gorunum, setGorunum] = useState<Gorunum>("kontrol");
  const [hata, setHata] = useState("");

  useEffect(() => {
    let aktif = true;

    async function sahipligiCoz() {
      try {
        const { data: { session }, error: sessionHatasi } = await supabase.auth.getSession();
        if (sessionHatasi) throw new Error("Oturum bilgisi okunamadı. Lütfen yeniden dene.");

        if (session) {
          let { data: bootstrap, error } = await supabase.rpc("get_owner_workspace_bootstrap");
          if (error) {
            const eski = await supabase.rpc("bootstrap_owner_state");
            bootstrap = eski.data;
            error = eski.error;
          }
          if (error) throw new Error("Vitrin sahipliği doğrulanamadı. Lütfen yeniden dene.");

          const sonuc = (bootstrap ?? {}) as Bootstrap;
          const hesapSlug = sonuc.store?.slug?.trim() || (sonuc.has_store === true ? sonuc.slug?.trim() : "") || "";
          if (hesapSlug) {
            // Hesap vitrini bulunduysa çerezi bu hesaba göre kur. Başka bir
            // vitrinin eski çerezine sessizce düşme.
            const oturumAcildi = await sahipOturumuAc();
            if (!oturumAcildi) {
              throw new Error("Vitrinin düzenleme oturumu açılamadı. Vitrinim bölümünden yeniden dene.");
            }
            if (aktif) router.replace("/v/" + encodeURIComponent(hesapSlug) + "?editor=1");
            return;
          }
        }

        // Hesaba bağlı vitrin yoksa aynı tarayıcıdaki imzalı sahiplik
        // oturumunu sunucuda doğrula. Bu yol landing/misafir vitrini içindir.
        const response = await fetch("/api/owner-workspace/current", { cache: "no-store" });
        const current = await response.json() as {
          store?: { slug?: string };
          sebep?: string;
        };
        if (response.ok && current.store?.slug) {
          if (aktif) router.replace("/v/" + encodeURIComponent(current.store.slug) + "?editor=1");
          return;
        }

        if (response.status === 404 && current.sebep === "NO_OWNER_SESSION") {
          if (aktif) setGorunum("asistan");
          return;
        }
        if (response.status === 401 || response.status === 403) {
          throw new Error("Sahiplik oturumunun süresi dolmuş veya geçersiz. Mevcut vitrinin yetkili girişinden tekrar aç.");
        }
        throw new Error("Vitrin bilgisi doğrulanamadı. Lütfen yeniden dene.");
      } catch (error) {
        if (!aktif) return;
        setHata(error instanceof Error ? error.message : "Vitrin bilgisi doğrulanamadı.");
        setGorunum("hata");
      }
    }

    void sahipligiCoz();
    return () => { aktif = false; };
  }, [router]);

  if (gorunum === "kontrol") {
    return <main className="min-h-full bg-lp-bg-editor p-6" role="status">Vitrinin açılıyor…</main>;
  }
  if (gorunum === "hata") {
    return (
      <main className="min-h-full bg-lp-bg-editor p-6">
        <p className="rounded-xl border border-lp-border bg-lp-surface p-4 text-sm text-lp-text" role="alert">{hata}</p>
        <button className="mt-4 rounded-xl bg-lp-primary px-4 py-2 font-bold text-lp-on-primary" onClick={() => router.push("/app")}>Vitrinim</button>
      </main>
    );
  }
  return (
    <main className="min-h-full bg-lp-bg-editor">
      <SharedVixrexAssistant onBrowse={() => router.push("/kesfet")} />
    </main>
  );
}
