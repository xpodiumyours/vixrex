"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { useAppShell } from "@/components/app/AppShellContext";
import { VitrinQrSheet } from "@/components/app/VitrinQrSheet";
import { supabase } from "@/lib/supabase";

type BootstrapSonucu = {
  has_store?: boolean;
  slug?: string;
  store?: { slug?: string; is_published?: boolean } | null;
};

export function StatusBar() {
  const router = useRouter();
  const { statusVersion } = useAppShell();
  const [slug, setSlug] = useState<string | null>(null);
  const [yayinda, setYayinda] = useState<boolean | null>(null);
  const [yukleniyor, setYukleniyor] = useState(true);
  const [qrAcik, setQrAcik] = useState(false);

  useEffect(() => {
    let aktif = true;

    async function durumuGetir() {
      let bulunanSlug = "";
      let yayinDurumu: boolean | null = null;
      try {
        const { data: { session }, error: sessionError } = await supabase.auth.getSession();
        if (sessionError) throw sessionError;

        if (session) {
          let { data: bootstrap, error } = await supabase.rpc("get_owner_workspace_bootstrap");
          if (error) {
            const eski = await supabase.rpc("bootstrap_owner_state");
            bootstrap = eski.data;
            error = eski.error;
          }

          if (error) throw error;
          if (!error) {
            const sonuc = (bootstrap ?? {}) as BootstrapSonucu;
            bulunanSlug = sonuc.store?.slug?.trim() || (sonuc.has_store === true ? sonuc.slug?.trim() || "" : "");
            if (typeof sonuc.store?.is_published === "boolean") {
              yayinDurumu = sonuc.store.is_published;
            } else if (bulunanSlug) {
              const { data: vitrin } = await supabase.from("stores").select("is_published").eq("slug", bulunanSlug).maybeSingle();
              yayinDurumu = typeof vitrin?.is_published === "boolean" ? vitrin.is_published : null;
            }
          }
        }

        if (!bulunanSlug) {
          const response = await fetch("/api/owner-workspace/current", { cache: "no-store" });
          if (response.ok) {
            const current = await response.json();
            bulunanSlug = typeof current.store?.slug === "string" ? current.store.slug : "";
            yayinDurumu = typeof current.store?.is_published === "boolean" ? current.store.is_published : null;
          }
        }
      } catch {
        yayinDurumu = null;
      }

      if (!aktif) return;
      setSlug(bulunanSlug || null);
      setYayinda(yayinDurumu);
      setYukleniyor(false);
    }

    void durumuGetir();
    return () => { aktif = false; };
  }, [statusVersion]);

  async function linkiKopyala() {
    if (!slug) return;
    await navigator.clipboard.writeText(`${window.location.origin}/v/${slug}`);
  }

  return (
    <>
      <div className="hidden min-h-[61px] items-center gap-3 border-b border-[#182E5B] bg-lp-bg-light px-5 py-3 min-[901px]:flex">
        <div className={`flex shrink-0 items-center gap-1.5 rounded-full border px-3 py-[5px] text-[12px] font-bold ${yayinda ? "border-emerald-500/40 bg-emerald-500/10 text-emerald-400" : "border-lp-border bg-lp-surface-soft text-lp-muted"}`}>
          <span className={`h-1.5 w-1.5 rounded-full ${yayinda ? "bg-emerald-400" : "bg-lp-muted"}`} aria-hidden="true" />
          {yukleniyor ? "Yükleniyor…" : yayinda === null ? "Vitrin durumu" : yayinda ? "Yayında" : "Yayında değil"}
        </div>
        <p className="min-w-0 flex-1 truncate text-[12px] font-semibold text-lp-muted">
          {yayinda && slug ? `vixrex.com/v/${slug}` : yayinda === false ? "Vitrininiz henüz yayınlanmadı" : yukleniyor ? "Vitrin bilgileri yükleniyor" : "Vitrin bilgisi doğrulanamadı"}
        </p>

        {yayinda && slug ? (
          <div className="flex shrink-0 items-center gap-2">
            <button type="button" onClick={() => void linkiKopyala()} className="min-h-9 rounded-xl border border-lp-border bg-lp-surface px-3 text-[12px] font-bold text-lp-text-alt hover:bg-lp-surface-soft">Kopyala</button>
            <button type="button" onClick={() => setQrAcik(true)} className="min-h-9 rounded-xl border border-lp-border bg-lp-surface px-3 text-[12px] font-bold text-lp-text-alt hover:bg-lp-surface-soft">QR</button>
            <button type="button" onClick={() => router.push(`/v/${slug}`)} className="min-h-9 rounded-xl bg-lp-primary px-4 text-[12px] font-black text-lp-on-primary hover:brightness-110">Vitrini aç</button>
          </div>
        ) : (
          <button type="button" onClick={() => router.push(yayinda === false ? "/app/vixrex" : "/app")} className="min-h-9 shrink-0 rounded-xl bg-lp-primary px-4 text-[12px] font-black text-lp-on-primary hover:brightness-110">{yayinda === false ? "Vitrini yayınla" : "Vitrinim"}</button>
        )}
      </div>
      <VitrinQrSheet slug={slug} acik={qrAcik} kapat={() => setQrAcik(false)} />
    </>
  );
}
