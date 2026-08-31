"use client";

import Link from "next/link";
import type { ReactNode } from "react";
import { KesfetIkonu, StorefrontIkonu } from "@/components/site/icons";

type Props = {
  sorgu: string;
  sorguyuDegistir: (deger: string) => void;
};

function KisiIkonu() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
      <circle cx="12" cy="8" r="3.5" />
      <path d="M5 20c.6-4 3-6 7-6s6.4 2 7 6" />
    </svg>
  );
}

function AsistanIkonu() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
      <path d="M7 18.5 3.5 21l.9-4.2A8 8 0 1 1 7 18.5Z" />
      <path d="M8.5 10.5h.01M12 10.5h.01M15.5 10.5h.01" strokeLinecap="round" />
    </svg>
  );
}

const MENU: Array<{
  etiket: string;
  href: string;
  ikon: ReactNode;
  secili?: boolean;
}> = [
  { etiket: "Vitrinim", href: "/app", ikon: <StorefrontIkonu boyut={20} /> },
  { etiket: "Keşfet", href: "/kesfet", ikon: <KesfetIkonu boyut={20} />, secili: true },
  { etiket: "Vixrex", href: "/#vixrex-hero", ikon: <AsistanIkonu /> },
  { etiket: "Profil", href: "/app/profil", ikon: <KisiIkonu /> },
];

/** Flutter ShellSidebar'ın masaüstü Keşfet karşılığı. */
export function KesfetYanMenu({ sorgu, sorguyuDegistir }: Props) {
  return (
    <aside
      aria-label="Uygulama menüsü"
      className="sticky top-0 hidden h-screen w-[220px] shrink-0 flex-col border-r border-lp-border bg-lp-surface min-[901px]:flex"
    >
      <Link
        href="/"
        aria-label="Vixrex ana sayfa"
        className="flex items-center gap-3 border-b border-lp-border px-5 py-6 text-lp-text focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-lp-primary"
      >
        <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-lp-primary/15 text-lp-primary">
          <StorefrontIkonu boyut={20} />
        </span>
        <span className="text-[18px] font-black">Vixrex</span>
      </Link>

      <div className="px-3 pb-2 pt-4">
        <label htmlFor="kesfet-yan-arama" className="sr-only">
          Vitrin veya ürün ara
        </label>
        <div className="relative">
          <svg className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-lp-muted" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
            <circle cx="11" cy="11" r="7" />
            <path d="m20 20-4.5-4.5" />
          </svg>
          <input
            id="kesfet-yan-arama"
            type="search"
            value={sorgu}
            onChange={(event) => sorguyuDegistir(event.target.value)}
            placeholder="Vitrin veya ürün ara"
            className="h-11 w-full rounded-xl border border-lp-border bg-lp-bg-light pl-10 pr-3 text-[13px] font-semibold text-lp-text placeholder:text-lp-muted focus:border-lp-primary focus:outline-none focus:ring-2 focus:ring-lp-primary/30"
          />
        </div>
      </div>

      <nav className="flex-1 px-3 py-1" aria-label="Ana bölümler">
        {MENU.map((oge) => (
          <Link
            key={oge.etiket}
            href={oge.href}
            aria-current={oge.secili ? "page" : undefined}
            className={`relative my-1 flex min-h-11 items-center gap-3 rounded-xl px-3 text-[13px] font-bold transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-primary ${
              oge.secili
                ? "bg-lp-primary/15 text-lp-text before:absolute before:inset-y-0 before:left-0 before:w-[3px] before:rounded-full before:bg-lp-primary"
                : "text-lp-muted hover:bg-lp-surface-soft hover:text-lp-text"
            }`}
          >
            <span className={oge.secili ? "text-lp-primary" : "text-current"}>{oge.ikon}</span>
            {oge.etiket}
          </Link>
        ))}
      </nav>

      <p className="px-4 py-4 text-[11px] font-semibold text-lp-muted">v1.0.0</p>
    </aside>
  );
}
