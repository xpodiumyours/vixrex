"use client";

import Link from "next/link";
import type { ReactNode } from "react";
import { KesfetIkonu, StorefrontIkonu } from "@/components/site/icons";

type Props = {
  sorgu: string;
  sorguyuDegistir: (deger: string) => void;
  aktifBolum?: "vitrinim" | "kesfet" | "vixrex";
  vixrexAc: () => void;
};

function KisiIkonu() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
      <circle cx="12" cy="8" r="3.5" />
      <path d="M5 20c.6-4 3-6 7-6s6.4 2 7 6" />
    </svg>
  );
}

/** Vixrex maskotu — Vixrex'i temsil eden tek simge bu. Yerine soyut bir
 * ikon (konuşma balonu, artı-kare) KOYULMAZ: maskot aynı zamanda
 * uygulamanın logosu, iki yüzeyde de aynı görünmeli. */
function MaskotIkonu({ boyut = 20 }: { boyut?: number }) {
  return (
    <img
      src="/images/vixrex_maskot_ikon.png"
      alt=""
      aria-hidden="true"
      className="object-contain"
      style={{ width: boyut, height: boyut }}
    />
  );
}

const MENU: Array<{
  etiket: string;
  href: string;
  ikon: ReactNode;
}> = [
  { etiket: "Vitrinim", href: "/app", ikon: <StorefrontIkonu boyut={20} /> },
  { etiket: "Keşfet", href: "/kesfet", ikon: <KesfetIkonu boyut={20} /> },
  { etiket: "Vixrex", href: "#vixrex-asistan", ikon: <MaskotIkonu boyut={20} /> },
  { etiket: "Profil", href: "/app/profil", ikon: <KisiIkonu /> },
];

/** Flutter ShellSidebar'ın masaüstü Keşfet karşılığı — mobilde aynı 4 hedef alt barda. */
export function KesfetYanMenu({
  sorgu,
  sorguyuDegistir,
  aktifBolum = "kesfet",
  vixrexAc,
}: Props) {
  return (
    <>
      <aside
        aria-label="Uygulama menüsü"
        className="sticky top-0 hidden h-screen w-[220px] shrink-0 flex-col border-r border-lp-border bg-lp-surface min-[901px]:flex"
      >
        <Link
          href="/"
          aria-label="Vixrex ana sayfa"
          className="flex items-center gap-3 border-b border-lp-border px-5 py-6 text-lp-text focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-lp-primary"
        >
          <MaskotIkonu boyut={34} />
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
          {MENU.map((oge) => {
            const aktif = oge.etiket === "Vixrex"
              ? aktifBolum === "vixrex"
              : oge.etiket === "Keşfet"
                ? aktifBolum === "kesfet"
                : oge.etiket === "Vitrinim" && aktifBolum === "vitrinim";
            const className = `relative my-1 flex min-h-11 w-full items-center gap-3 rounded-xl px-3 text-left text-[13px] font-bold transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-primary ${
              aktif
                ? "bg-lp-primary/15 text-lp-text before:absolute before:inset-y-0 before:left-0 before:w-[3px] before:rounded-full before:bg-lp-primary"
                : "text-lp-muted hover:bg-lp-surface-soft hover:text-lp-text"
            }`;
            const content = (
              <>
                <span className={aktif ? "text-lp-primary" : "text-current"}>{oge.ikon}</span>
                {oge.etiket}
              </>
            );
            return oge.etiket === "Vixrex" ? (
              <button
                key={oge.etiket}
                type="button"
                onClick={vixrexAc}
                aria-current={aktif ? "page" : undefined}
                className={className}
              >
                {content}
              </button>
            ) : (
              <Link
                key={oge.etiket}
                href={oge.href}
                aria-current={aktif ? "page" : undefined}
                className={className}
              >
                {content}
              </Link>
            );
          })}
        </nav>

        <p className="px-4 py-4 text-[11px] font-semibold text-lp-muted">v1.0.0</p>
      </aside>

      {/* Mobil sabit alt menü — masaüstü yan menüyle aynı dört hedef */}
      <nav
        aria-label="Mobil uygulama menüsü"
        className="fixed inset-x-0 bottom-0 z-30 flex h-[64px] items-center justify-around border-t border-lp-border bg-lp-surface px-1 pb-[env(safe-area-inset-bottom)] min-[901px]:hidden"
      >
        {MENU.map((oge) => {
          const aktif = oge.etiket === "Vixrex"
            ? aktifBolum === "vixrex"
            : oge.etiket === "Keşfet"
              ? aktifBolum === "kesfet"
              : oge.etiket === "Vitrinim" && aktifBolum === "vitrinim";
          const mobilClass =
            "flex min-h-11 flex-1 flex-col items-center justify-center gap-0.5 rounded-xl px-1 py-1 text-[10px] font-bold leading-none transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-primary " +
            (aktif ? "text-lp-primary" : "text-lp-muted");
          const mobilContent = (
            <>
              <span className={aktif ? "text-lp-primary" : "text-current"}>{oge.ikon}</span>
              <span>{oge.etiket}</span>
            </>
          );
          return oge.etiket === "Vixrex" ? (
            <button
              key={`mobil-${oge.etiket}`}
              type="button"
              onClick={vixrexAc}
              aria-label="Vixrex Asistan"
              aria-current={aktif ? "page" : undefined}
              className={mobilClass}
            >
              {mobilContent}
            </button>
          ) : (
            <Link
              key={`mobil-${oge.etiket}`}
              href={oge.href}
              aria-current={aktif ? "page" : undefined}
              className={mobilClass}
            >
              {mobilContent}
            </Link>
          );
        })}
      </nav>
    </>
  );
}
