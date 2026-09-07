"use client";

import { useState } from "react";
import { VitrinQrSheet } from "@/components/app/VitrinQrSheet";

function Aksiyon({
  etiket,
  onClick,
  vurgulu = false,
}: {
  etiket: string;
  onClick: () => void;
  vurgulu?: boolean;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`min-h-9 rounded-xl px-3 text-[12px] font-bold ${
        vurgulu
          ? "bg-lp-primary/20 text-lp-primary"
          : "border border-lp-border bg-lp-bg-light text-lp-text"
      }`}
    >
      {etiket}
    </button>
  );
}

export function VitrinPaylasimKarti({
  slug,
  adVar,
  yayinda,
  olusturmaModu,
  yayinaKaydir,
}: {
  slug: string;
  adVar: boolean;
  yayinda: boolean;
  olusturmaModu: boolean;
  yayinaKaydir: () => void;
}) {
  const [qrAcik, setQrAcik] = useState(false);
  const linkVar = adVar && !olusturmaModu && slug !== "taslak";
  const gorunenLink = linkVar ? `vixrex.com/v/${slug}` : null;

  async function kopyala() {
    if (!linkVar) return;
    await navigator.clipboard.writeText(`${window.location.origin}/v/${slug}`);
  }

  function onizle() {
    if (!linkVar) return;
    window.open(`/v/${slug}`, "_blank", "noopener,noreferrer");
  }

  async function paylas() {
    if (!linkVar) return;
    const url = `${window.location.origin}/v/${slug}`;
    if (navigator.share) {
      try {
        await navigator.share({ title: "Vixrex vitrinim", url });
        return;
      } catch {
        // Kullanıcı paylaşım penceresini kapattıysa sessizce kal.
      }
    }
    await navigator.clipboard.writeText(url);
  }

  return (
    <section aria-label="Paylaşım linki">
      <div className="flex items-center gap-3">
        <p className="flex-1 text-[12px] font-extrabold text-lp-muted">Paylaşım linki</p>
        {yayinda && linkVar ? (
          <span className="rounded-lg bg-emerald-500/15 px-2 py-1 text-[11px] font-extrabold text-emerald-400">Canlı</span>
        ) : null}
      </div>

      <div className="mt-2 flex min-h-14 items-center gap-3 rounded-[14px] border border-lp-border bg-lp-bg-light px-3.5 py-3">
        <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-[10px] bg-lp-primary/10 text-lp-primary" aria-hidden="true">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M10 13a5 5 0 0 0 7.1.1l2-2a5 5 0 0 0-7.1-7.1l-1.1 1.1" /><path d="M14 11a5 5 0 0 0-7.1-.1l-2 2A5 5 0 0 0 12 20l1.1-1.1" /></svg>
        </span>
        <span className={`min-w-0 flex-1 truncate text-[14px] font-extrabold ${gorunenLink ? "text-lp-text" : "text-lp-muted"}`}>
          {gorunenLink ?? "İşletme adı yazınca oluşur."}
        </span>
      </div>

      {linkVar && !yayinda ? <p className="mt-1.5 text-[12px] font-semibold text-lp-muted">Yayından sonra tarayıcıda herkese açık açılır.</p> : null}

      {linkVar ? (
        <div className="mt-2.5 flex flex-wrap gap-2">
          <Aksiyon etiket="Kopyala" onClick={() => void kopyala()} />
          <Aksiyon etiket="Önizle" onClick={onizle} />
          {yayinda ? <Aksiyon etiket="Paylaş" onClick={() => void paylas()} /> : null}
          {yayinda ? <Aksiyon etiket="QR Göster" onClick={() => setQrAcik(true)} /> : null}
          {!yayinda ? <Aksiyon etiket="Yayına al" onClick={yayinaKaydir} vurgulu /> : null}
        </div>
      ) : adVar ? (
        <div className="mt-2.5"><Aksiyon etiket="Yayına al" onClick={yayinaKaydir} vurgulu /></div>
      ) : null}

      <VitrinQrSheet slug={yayinda && linkVar ? slug : null} acik={qrAcik} kapat={() => setQrAcik(false)} />
    </section>
  );
}
