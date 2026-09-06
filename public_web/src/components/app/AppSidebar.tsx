"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import type { ReactNode } from "react";
import { KesfetIkonu, StorefrontIkonu } from "@/components/site/icons";
import { useAppShell } from "@/components/app/AppShellContext";

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

function KisiIkonu() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
      <circle cx="12" cy="8" r="3.5" />
      <path d="M5 20c.6-4 3-6 7-6s6.4 2 7 6" />
    </svg>
  );
}

const NAV = [
  {
    href: "/app",
    label: "Vitrinim",
    icon: <StorefrontIkonu boyut={20} />,
    match: (p: string) => p === "/app" || p.startsWith("/app/urunler"),
  },
  {
    href: "/kesfet",
    label: "Keşfet",
    icon: <KesfetIkonu boyut={20} />,
    match: (p: string) => p.startsWith("/kesfet"),
  },
  {
    href: "/app/vixrex",
    label: "Vixrex",
    icon: <MaskotIkonu boyut={20} />,
    match: (p: string) => p === "/app/vixrex",
  },
  {
    href: "/app/profil",
    label: "Profil",
    icon: <KisiIkonu />,
    match: (p: string) => p === "/app/profil",
  },
] as Array<{ href: string; label: string; icon: ReactNode; match: (p: string) => boolean }>;

export function AppSidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const { globalSearch, setGlobalSearch } = useAppShell();

  function onSearch(e: React.FormEvent) {
    e.preventDefault();
    const query = globalSearch.trim();
    router.push(query ? `/kesfet?q=${encodeURIComponent(query)}` : "/kesfet");
  }

  return (
    <aside className="hidden h-screen w-[220px] shrink-0 flex-col border-r border-lp-border bg-lp-surface min-[901px]:sticky min-[901px]:top-0 min-[901px]:flex">
      <Link
        href="/"
        aria-label="Vixrex ana sayfa"
        className="flex items-center gap-3 border-b border-lp-border px-5 py-6 text-lp-text focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-lp-primary"
      >
        <MaskotIkonu boyut={34} />
        <span className="text-[18px] font-black">Vixrex</span>
      </Link>

      <form onSubmit={onSearch} className="px-3 pb-2 pt-4">
        <label htmlFor="app-shell-search" className="sr-only">Vitrin veya ürün ara</label>
        <div className="relative">
          <svg className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-lp-muted" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
            <circle cx="11" cy="11" r="7" />
            <path d="m20 20-4.5-4.5" />
          </svg>
          <input
            id="app-shell-search"
            value={globalSearch}
            onChange={(e) => setGlobalSearch(e.target.value)}
            placeholder="Vitrin veya ürün ara"
            className="h-11 w-full rounded-xl border border-lp-border bg-lp-bg-light pl-10 pr-3 text-[13px] font-semibold text-lp-text placeholder:text-lp-muted focus:border-lp-secondary focus:outline-none focus:ring-2 focus:ring-lp-primary/30"
          />
        </div>
      </form>

      <nav className="flex-1 px-3 py-1" aria-label="Ana bölümler">
        {NAV.map((item) => {
          const active = item.match(pathname);
          return (
            <Link
              key={item.label}
              href={item.href}
              aria-current={active ? "page" : undefined}
              className={`relative my-1 flex min-h-11 items-center gap-3 rounded-xl px-3 text-[13px] font-bold transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-primary ${
                active
                  ? "bg-lp-primary/15 text-lp-text before:absolute before:inset-y-0 before:left-0 before:w-[3px] before:rounded-full before:bg-lp-primary"
                  : "text-lp-muted hover:bg-lp-surface-soft hover:text-lp-text"
              }`}
            >
              <span className={active ? "text-lp-secondary" : "text-current"}>{item.icon}</span>
              {item.label}
            </Link>
          );
        })}
      </nav>

      <p className="px-4 py-4 text-[11px] font-semibold text-lp-muted">v1.0.0</p>
    </aside>
  );
}

export function AppBottomNav() {
  const pathname = usePathname();

  return (
    <nav
      aria-label="Mobil uygulama menüsü"
      className="fixed inset-x-0 bottom-0 z-40 flex h-[68px] items-center justify-around border-t border-lp-border bg-lp-bg-editor px-1 pb-[env(safe-area-inset-bottom)] min-[901px]:hidden"
    >
      {NAV.map((item) => {
        const active = item.match(pathname);
        return (
          <Link
            key={item.label}
            href={item.href}
            aria-current={active ? "page" : undefined}
            className={`flex min-h-11 flex-1 flex-col items-center justify-center gap-0.5 px-1 py-1 text-[11px] leading-none transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-primary ${
              active ? "font-bold text-lp-secondary" : "font-normal text-lp-muted"
            }`}
          >
            <span className={`flex min-h-7 min-w-12 items-center justify-center rounded-full px-3 py-1 ${active ? "bg-lp-primary/20 text-lp-secondary" : "text-current"}`}>
              <span className="scale-110">
                {item.label === "Vixrex" ? <MaskotIkonu boyut={24} /> : item.icon}
              </span>
            </span>
            <span>{item.label}</span>
          </Link>
        );
      })}
    </nav>
  );
}
