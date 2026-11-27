"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import type { ReactNode } from "react";
import { KesfetIkonu, StorefrontIkonu } from "@/components/site/icons";
import { useAppShell } from "@/components/app/AppShellContext";
import { VixrexAvatar } from "@/app/v/[slug]/components/VixrexAvatar";

function MaskotIkonu({ boyut = 20, opacity = 1 }: { boyut?: number; opacity?: number }) {
  return (
    <div style={{ opacity }}>
      <VixrexAvatar size={boyut} decorative />
    </div>
  );
}

function KisiIkonu({ boyut = 20 }: { boyut?: number }) {
  return (
    <svg width={boyut} height={boyut} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
      <circle cx="12" cy="8" r="3.5" />
      <path d="M5 20c.6-4 3-6 7-6s6.4 2 7 6" />
    </svg>
  );
}

function FaturaIkonu({ boyut = 18 }: { boyut?: number }) {
  return (
    <svg width={boyut} height={boyut} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
      <path d="M14 2H6a2 2 0 0 0-2 2v16l3-2 3 2 3-2 3 2 2-1.3V8Z" />
      <path d="M14 2v6h6M8 13h8M8 9h4" />
    </svg>
  );
}

function UrunlerIkonu({ boyut = 18 }: { boyut?: number }) {
  return (
    <svg width={boyut} height={boyut} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
      <rect x="3" y="4" width="7" height="7" rx="1.5" />
      <rect x="14" y="4" width="7" height="7" rx="1.5" />
      <rect x="3" y="14" width="7" height="7" rx="1.5" />
      <rect x="14" y="14" width="7" height="7" rx="1.5" />
    </svg>
  );
}

function BildirimIkonu({ boyut = 18 }: { boyut?: number }) {
  return (
    <svg width={boyut} height={boyut} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
      <path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9" />
      <path d="M13.7 21a2 2 0 0 1-3.4 0" />
    </svg>
  );
}

function AyarIkonu({ boyut = 18 }: { boyut?: number }) {
  return (
    <svg width={boyut} height={boyut} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
      <circle cx="12" cy="12" r="3" />
      <path d="M19.4 15a1.7 1.7 0 0 0 .3 1.9l.1.1-2.8 2.8-.1-.1a1.7 1.7 0 0 0-1.9-.3 1.7 1.7 0 0 0-1 1.6V21h-4v-.1A1.7 1.7 0 0 0 9 19.3a1.7 1.7 0 0 0-1.9.3l-.1.1L4.2 17l.1-.1a1.7 1.7 0 0 0 .3-1.9A1.7 1.7 0 0 0 3 14H3v-4h.1A1.7 1.7 0 0 0 4.7 9a1.7 1.7 0 0 0-.3-1.9L4.2 7 7 4.2l.1.1A1.7 1.7 0 0 0 9 4.7 1.7 1.7 0 0 0 10 3.1V3h4v.1A1.7 1.7 0 0 0 15 4.7a1.7 1.7 0 0 0 1.9-.3l.1-.1L19.8 7l-.1.1A1.7 1.7 0 0 0 19.3 9a1.7 1.7 0 0 0 1.6 1H21v4h-.1a1.7 1.7 0 0 0-1.5 1Z" />
    </svg>
  );
}

type NavItem = {
  href: string;
  label: string;
  icon: (boyut: number, active: boolean) => ReactNode;
  match: (p: string) => boolean;
};

const NAV: NavItem[] = [
  {
    href: "/app",
    label: "Vitrinim",
    icon: (boyut) => <StorefrontIkonu boyut={boyut} />,
    match: (p: string) => p === "/app" || p.startsWith("/app/urunler"),
  },
  {
    href: "/kesfet",
    label: "Keşfet",
    icon: (boyut) => <KesfetIkonu boyut={boyut} />,
    match: (p: string) => p.startsWith("/kesfet"),
  },
  {
    href: "/app/vixrex",
    label: "Vixrex",
    icon: (boyut, active) => <MaskotIkonu boyut={boyut} opacity={active ? 1 : 0.7} />,
    match: (p: string) => p === "/app/vixrex",
  },
  {
    href: "/app/profil",
    label: "Profil",
    icon: (boyut) => <KisiIkonu boyut={boyut} />,
    match: (p: string) => p === "/app/profil",
  },
];

export function AppSidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const { globalSearch, setGlobalSearch } = useAppShell();
  const kesfetSayfasi = pathname.startsWith("/kesfet");

  function onSearch(e: React.FormEvent) {
    e.preventDefault();
    const query = globalSearch.trim();
    router.push(query ? `/kesfet?q=${encodeURIComponent(query)}` : "/kesfet", { scroll: false });
  }

  return (
    <aside className="vixrex-app-sidebar hidden h-screen shrink-0 flex-col border-r border-lp-border bg-lp-surface min-[901px]:sticky min-[901px]:top-0 min-[901px]:flex">
      <Link
        href="/"
        aria-label="Vixrex ana sayfa"
        className="flex items-center gap-3 border-b border-lp-border px-5 py-6 text-lp-text focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-lp-primary"
      >
        <MaskotIkonu boyut={34} />
        <span className="text-[18px] font-black">Vixrex</span>
      </Link>

      {kesfetSayfasi ? null : (
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
              className="vixrex-app-sidebar-search h-11 w-full pl-10 pr-3 text-[13px] font-semibold placeholder:text-lp-muted focus:outline-none"
            />
          </div>
        </form>
      )}

      <nav className="flex-1 overflow-y-auto px-3 py-1" aria-label="Ana bölümler">
        {NAV.map((item) => {
          const active = item.match(pathname);
          return (
            <Link
              key={item.label}
              href={item.href}
              prefetch
              scroll={false}
              aria-current={active ? "page" : undefined}
              className={`relative my-[2px] flex min-h-11 items-center gap-3 rounded-xl px-3 text-[13px] transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-primary ${
                active
                  ? "vixrex-app-sidebar-item-active font-extrabold text-lp-text before:absolute before:inset-y-0 before:left-0 before:w-[3px] before:rounded-full before:bg-lp-primary"
                  : "font-semibold text-lp-muted hover:bg-lp-surface-soft hover:text-lp-text"
              }`}
            >
              <span className={active ? "text-lp-secondary" : "text-current"}>{item.icon(20, active)}</span>
              {item.label}
            </Link>
          );
        })}

        <div className="mt-4 border-t border-lp-border/70 pt-3">
          <p className="px-3 pb-1.5 text-[10px] font-extrabold uppercase tracking-[0.08em] text-lp-muted">
            Mağaza Yönetimi
          </p>
          <Link
            href="/app/urunler?fatura=1"
            className="my-1 flex min-h-10 items-center gap-2.5 rounded-xl border border-lp-primary/40 bg-lp-primary/15 px-3 text-[12.5px] font-extrabold text-lp-text transition-colors hover:bg-lp-primary/25 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-primary"
          >
            <span className="text-lp-secondary"><FaturaIkonu boyut={18} /></span>
            Faturadan Ürün Ekle
          </Link>
          <Link
            href="/app/urunler"
            className={`my-[2px] flex min-h-10 items-center gap-2.5 rounded-xl px-3 text-[12.5px] transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-primary ${
              pathname.startsWith("/app/urunler")
                ? "font-extrabold text-lp-text bg-lp-surface-soft"
                : "font-semibold text-lp-muted hover:bg-lp-surface-soft hover:text-lp-text"
            }`}
          >
            <span className="text-current"><UrunlerIkonu boyut={18} /></span>
            Ürünlerim
          </Link>
          <Link
            href="/app/bildirimler"
            className={`my-[2px] flex min-h-10 items-center gap-2.5 rounded-xl px-3 text-[12.5px] transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-primary ${
              pathname.startsWith("/app/bildirimler")
                ? "font-extrabold text-lp-text bg-lp-surface-soft"
                : "font-semibold text-lp-muted hover:bg-lp-surface-soft hover:text-lp-text"
            }`}
          >
            <span className="text-current"><BildirimIkonu boyut={18} /></span>
            Bildirimler
          </Link>
          <Link
            href="/app/ayarlar"
            className={`my-[2px] flex min-h-10 items-center gap-2.5 rounded-xl px-3 text-[12.5px] transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-primary ${
              pathname.startsWith("/app/ayarlar") || pathname.startsWith("/app/hesap")
                ? "font-extrabold text-lp-text bg-lp-surface-soft"
                : "font-semibold text-lp-muted hover:bg-lp-surface-soft hover:text-lp-text"
            }`}
          >
            <span className="text-current"><AyarIkonu boyut={18} /></span>
            Ayarlar
          </Link>
        </div>
      </nav>

      <p className="px-4 pb-8 pt-4 text-[11px] font-semibold text-lp-muted">v1.0.0</p>
    </aside>
  );
}

export function AppBottomNav() {
  const pathname = usePathname();

  return (
    <nav
      aria-label="Mobil uygulama menüsü"
      className="vixrex-app-bottom-nav fixed inset-x-0 bottom-0 z-40 flex items-center justify-around border-t border-lp-border bg-lp-bg-editor px-1 pb-[env(safe-area-inset-bottom)] min-[901px]:hidden"
    >
      {NAV.map((item) => {
        const active = item.match(pathname);
        const iconSize = item.label === "Vixrex" ? 24 : 22;
        return (
          <Link
            key={item.label}
            href={item.href}
            prefetch
            scroll={false}
            aria-current={active ? "page" : undefined}
            className={`flex min-h-11 flex-1 flex-col items-center justify-center gap-0.5 px-1 py-1 text-[11px] leading-none transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-primary ${
              active ? "font-bold text-lp-secondary" : "font-normal text-lp-muted"
            }`}
          >
            <span className={`flex min-h-7 min-w-12 items-center justify-center rounded-full px-3 py-1 ${active ? "vixrex-app-nav-indicator-active text-lp-secondary" : "text-current"}`}>
              {item.icon(iconSize, active)}
            </span>
            <span>{item.label}</span>
          </Link>
        );
      })}
    </nav>
  );
}
