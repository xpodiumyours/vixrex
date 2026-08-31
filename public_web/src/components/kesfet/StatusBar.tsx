"use client";

import Link from "next/link";
import { useState, type ReactNode } from "react";

export type VitrinDurumu =
  | "yukleniyor"
  | "misafir"
  | "yok"
  | "yayinlanmamis"
  | "yayinli"
  | "hata";

type StatusBarProps = {
  durum: VitrinDurumu;
  sahipSlug?: string | null;
  premium?: { aktif: boolean; bitis: string | null } | null;
};

function Kabuk({ children }: { children: ReactNode }) {
  return (
    <div
      data-testid="kesfet-status-bar"
      className="sticky top-0 z-20 hidden border-b border-lp-border bg-lp-bg-editor px-6 py-4 min-[901px]:block"
    >
      <div className="mx-auto flex w-full max-w-[1200px] items-center justify-between gap-4">
        {children}
      </div>
    </div>
  );
}

export function StatusBar({ durum, sahipSlug, premium }: StatusBarProps) {
  const [kopyalandi, setKopyalandi] = useState(false);

  async function baglantiyiKopyala() {
    if (!sahipSlug) return;
    const baglanti = new URL(`/v/${sahipSlug}`, window.location.origin).href;
    try {
      await navigator.clipboard.writeText(baglanti);
      setKopyalandi(true);
      window.setTimeout(() => setKopyalandi(false), 2_000);
    } catch {
      setKopyalandi(false);
    }
  }

  if (durum === "yukleniyor") {
    return (
      <Kabuk>
        <span className="text-[14px] font-medium text-lp-muted" role="status">
          Vitrin durumu yükleniyor…
        </span>
      </Kabuk>
    );
  }

  if (durum === "misafir") {
    return (
      <Kabuk>
        <span className="text-[14px] font-medium text-lp-text">
          Misafir girişi.{" "}
          <Link href="/giris" className="font-bold text-lp-primary hover:underline">
            Vitrin oluşturmak için hesap açın
          </Link>
          .
        </span>
      </Kabuk>
    );
  }

  if (durum === "yok") {
    return (
      <Kabuk>
        <span className="text-[14px] font-medium text-lp-text">
          Vitrininiz henüz oluşturulmadı.{" "}
          <Link href="/app" className="font-bold text-lp-primary hover:underline">
            Vitrin oluşturarak başlayın
          </Link>
          .
        </span>
      </Kabuk>
    );
  }

  if (durum === "yayinlanmamis") {
    return (
      <Kabuk>
        <span className="text-[14px] font-medium text-lp-text">
          <span className="font-bold text-lp-muted">Yayında değil</span>
          {" — "}
          <Link href="/app" className="font-bold text-lp-primary hover:underline">
            Vitrini yayınla
          </Link>
          .
        </span>
      </Kabuk>
    );
  }

  if (durum === "hata") {
    return (
      <Kabuk>
        <span className="text-[14px] font-medium text-lp-text" role="status">
          Vitrin durumu şu an alınamıyor.{" "}
          <Link href="/app" className="font-bold text-lp-primary hover:underline">
            Vitrinim’e git
          </Link>
          .
        </span>
      </Kabuk>
    );
  }

  if (!sahipSlug) return null;

  return (
    <Kabuk>
      <div className="flex min-w-0 items-center gap-3">
        <span className="shrink-0 text-[14px] font-bold text-emerald-400">Yayında</span>
        {premium?.aktif ? (
          <span className="rounded-full border border-lp-primary/40 bg-lp-primary/10 px-2 py-1 text-[11px] font-black text-lp-primary">
            Premium
          </span>
        ) : null}
        <span className="truncate text-[13px] font-semibold text-lp-muted">/v/{sahipSlug}</span>
      </div>
      <div className="flex shrink-0 items-center gap-3">
        <Link
          href={`/v/${sahipSlug}`}
          className="text-[12px] font-black text-lp-primary hover:underline"
        >
          Vitrini aç
        </Link>
        <button
          type="button"
          onClick={baglantiyiKopyala}
          className="text-[12px] font-black text-lp-primary hover:underline"
        >
          {kopyalandi ? "Kopyalandı" : "Bağlantıyı kopyala"}
        </button>
      </div>
    </Kabuk>
  );
}
