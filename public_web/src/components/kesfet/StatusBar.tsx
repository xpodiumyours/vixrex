"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";

type StatusBarProps = {
  sahipSlug?: string | null;
  premium?: { aktif: boolean; bitis: string | null } | null;
};

type BootstrapSonucu = {
  has_store?: boolean;
  slug?: string;
  store?: {
    slug?: string;
    is_published?: boolean;
  } | null;
};

export function StatusBar({ sahipSlug = null }: StatusBarProps) {
  const router = useRouter();
  const [slug, setSlug] = useState<string | null>(sahipSlug);
  const [yayinda, setYayinda] = useState(false);
  const [qrAcik, setQrAcik] = useState(false);

  useEffect(() => {
    let aktif = true;

    async function durumuGetir() {
      let bulunanSlug = sahipSlug?.trim() || "";
      let yayinDurumu = false;

      const {
        data: { session },
      } = await supabase.auth.getSession();

      if (session) {
        let { data: bootstrap, error } = await supabase.rpc(
          "get_owner_workspace_bootstrap"
        );

        if (error) {
          const eski = await supabase.rpc("bootstrap_owner_state");
          bootstrap = eski.data;
          error = eski.error;
        }

        if (!error) {
          const sonuc = (bootstrap ?? {}) as BootstrapSonucu;
          bulunanSlug =
            sonuc.store?.slug?.trim() ||
            (sonuc.has_store === true ? sonuc.slug?.trim() || "" : "") ||
            bulunanSlug;

          if (typeof sonuc.store?.is_published === "boolean") {
            yayinDurumu = sonuc.store.is_published;
          } else if (bulunanSlug) {
            const { data: vitrin } = await supabase
              .from("stores")
              .select("is_published")
              .eq("slug", bulunanSlug)
              .maybeSingle();
            yayinDurumu = vitrin?.is_published === true;
          }
        }
      }

      if (!aktif) return;
      setSlug(bulunanSlug || null);
      setYayinda(yayinDurumu);
    }

    void durumuGetir();
    return () => {
      aktif = false;
    };
  }, [sahipSlug]);

  const gorunenLink = slug ? `vixrex.com/v/${slug}` : null;

  async function linkiKopyala() {
    if (!slug) return;
    await navigator.clipboard.writeText(`${window.location.origin}/v/${slug}`);
  }

  return (
    <>
      <div className="hidden min-h-[61px] items-center gap-3 border-b border-lp-primary/20 bg-lp-bg-light px-5 py-3 min-[901px]:flex">
        <div
          className={`flex shrink-0 items-center gap-1.5 rounded-full border px-3 py-1 text-[11px] font-bold ${
            yayinda
              ? "border-emerald-500/40 bg-emerald-500/10 text-emerald-300"
              : "border-lp-border bg-lp-surface-soft text-lp-muted"
          }`}
        >
          <span
            aria-hidden="true"
            className={`h-1.5 w-1.5 rounded-full ${yayinda ? "bg-emerald-400" : "bg-lp-muted"}`}
          />
          {yayinda ? "Yayında" : "Yayında değil"}
        </div>

        <p className="min-w-0 flex-1 truncate text-[11px] font-semibold text-lp-muted">
          {yayinda && gorunenLink ? gorunenLink : "Vitrininiz henüz yayınlanmadı"}
        </p>

        {yayinda && slug ? (
          <div className="flex shrink-0 items-center gap-2">
            <button
              type="button"
              onClick={() => void linkiKopyala()}
              className="min-h-9 rounded-xl border border-lp-border bg-lp-surface px-3 text-[12px] font-black text-lp-text hover:bg-lp-surface-soft"
            >
              Kopyala
            </button>
            <button
              type="button"
              onClick={() => setQrAcik(true)}
              className="min-h-9 rounded-xl border border-lp-border bg-lp-surface px-3 text-[12px] font-black text-lp-text hover:bg-lp-surface-soft"
            >
              QR
            </button>
            <button
              type="button"
              onClick={() => router.push(`/v/${slug}`)}
              className="min-h-9 rounded-xl bg-lp-primary px-4 text-[12px] font-black text-lp-on-primary hover:brightness-110"
            >
              Vitrini aç
            </button>
          </div>
        ) : (
          <button
            type="button"
            onClick={() => router.push("/app/vixrex")}
            className="min-h-9 shrink-0 rounded-xl bg-lp-primary px-4 text-[12px] font-black text-lp-on-primary hover:brightness-110"
          >
            Vitrini yayınla
          </button>
        )}
      </div>

      {qrAcik && slug ? (
        <div
          className="fixed inset-0 z-[70] flex items-center justify-center bg-black/60 p-4"
          onClick={() => setQrAcik(false)}
        >
          <div
            className="w-full max-w-sm rounded-2xl border border-lp-border bg-lp-surface p-6 text-center"
            role="dialog"
            aria-modal="true"
            aria-label="Vitrin QR Kodu"
            onClick={(event) => event.stopPropagation()}
          >
            <h2 className="text-[17px] font-black text-lp-text">Vitrin QR Kodun</h2>
            <p className="mt-1 text-[12px] font-semibold text-lp-muted">
              Yazdırıp tezgâhına koyabilirsin. Müşteri okuttuğunda doğrudan vitrinine gelir.
            </p>
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={`https://api.qrserver.com/v1/create-qr-code/?size=320x320&data=${encodeURIComponent(`${window.location.origin}/v/${slug}`)}`}
              alt="Vitrin QR kodu"
              className="mx-auto mt-5 h-56 w-56 rounded-xl bg-white p-3"
            />
            <p className="mt-3 break-all text-[11px] font-semibold text-lp-muted">
              {`${window.location.origin}/v/${slug}`}
            </p>
            <div className="mt-4 flex gap-2">
              <button
                type="button"
                onClick={() => void linkiKopyala()}
                className="min-h-10 flex-1 rounded-xl border border-lp-border bg-lp-bg-light px-3 text-[12px] font-black text-lp-text"
              >
                Linki Kopyala
              </button>
              <button
                type="button"
                onClick={() => setQrAcik(false)}
                className="min-h-10 flex-1 rounded-xl bg-lp-primary px-3 text-[12px] font-black text-lp-on-primary"
              >
                Kapat
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </>
  );
}
