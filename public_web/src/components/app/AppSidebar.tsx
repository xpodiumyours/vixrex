"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useState, type ReactNode } from "react";

// Flutter'daki karşılıkları: Icons.storefront_rounded, travel_explore_rounded,
// assistant_rounded, person_rounded (bkz. home_shell_screen.dart sidebarItems).
// Önceden burada emoji (🏪🧭✨👤) kullanılıyordu — cihaza/işletim sistemine göre
// renkli, tutarsız görünen glifler basıyordu ve Flutter'ın çizgisel ikon setiyle
// hiç eşleşmiyordu. currentColor kullanan çizgisel SVG'lere çevrildi, böylece
// aktif/pasif renk NAV'daki className ile aynı şekilde yönetiliyor.
const NAV_ICONS: Record<string, ReactNode> = {
  vitrinim: (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 9.5 4.5 4h15L21 9.5" />
      <path d="M3 9.5a2.5 2.5 0 0 0 5 0 2.5 2.5 0 0 0 5 0 2.5 2.5 0 0 0 5 0 2.5 2.5 0 0 0 5 0" />
      <path d="M5 10v9.5a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V10" />
      <path d="M9.5 20.5V15a1 1 0 0 1 1-1h3a1 1 0 0 1 1 1v5.5" />
    </svg>
  ),
  kesfet: (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="11" cy="11" r="8" />
      <path d="m15.8 9-5.4 2.2L9 15.8l5.4-2.2z" />
      <path d="M20.5 20.5 17 17" />
    </svg>
  ),
  vixrex: (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 3v2.5M12 18.5V21M4.9 4.9l1.8 1.8M17.3 17.3l1.8 1.8M3 12h2.5M18.5 12H21M4.9 19.1l1.8-1.8M17.3 6.7l1.8-1.8" />
      <path d="M12 8.5 13.4 11.6 16.5 13 13.4 14.4 12 17.5 10.6 14.4 7.5 13 10.6 11.6z" />
    </svg>
  ),
  profil: (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="8" r="3.5" />
      <path d="M4.5 20a7.5 7.5 0 0 1 15 0" />
    </svg>
  ),
};

const NAV = [
  { href: "/app", label: "Vitrinim", icon: "vitrinim", match: (p: string) => p === "/app" || p.startsWith("/app/urunler") },
  { href: "/kesfet", label: "Keşfet", icon: "kesfet", match: (p: string) => p.startsWith("/kesfet") },
  // Flutter'da "Vixrex" ayrı bir ekran; Next.js'te henüz karşılığı yok, madde
  // /app'e gidiyor. Eşleşmesi "Vitrinim" ile aynı olduğu için ikisi birden mavi
  // yanıyordu. Kendi sayfası açılana kadar aktif durumu Vitrinim'e bırakıyor.
  { href: "/app", label: "Vixrex", icon: "vixrex", match: () => false },
  { href: "/app/profil", label: "Profil", icon: "profil", match: (p: string) => p.startsWith("/app/profil") || p.startsWith("/app/hesap") || p.startsWith("/app/ayarlar") || p.startsWith("/app/bildirimler") },
] as const;

export function AppSidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const [q, setQ] = useState("");

  function onSearch(e: React.FormEvent) {
    e.preventDefault();
    const query = q.trim();
    if (!query) {
      router.push("/kesfet");
    } else {
      router.push(`/kesfet?q=${encodeURIComponent(query)}`);
    }
  }

  return (
    <aside className="hidden w-[280px] shrink-0 flex-col border-r border-white/10 bg-[#0B1730] md:flex">
      <div className="flex h-[64px] items-center gap-3 border-b border-white/10 px-5">
        <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-[#147DFF] text-white">{NAV_ICONS.vitrinim}</span>
        <span className="text-[16px] font-black text-white">Vixrex</span>
      </div>

      <form onSubmit={onSearch} className="p-4">
        <div className="relative">
          <span className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-white/40">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="11" cy="11" r="7"/><path d="M20 20L15.5 15.5"/></svg>
          </span>
          <input
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="Vitrin veya ürün ara"
            className="h-9 w-full rounded-xl border border-white/10 bg-white/[0.06] pl-9 pr-3 text-[13px] font-semibold text-white placeholder:text-white/40 focus:border-[#147DFF] focus:outline-none"
          />
        </div>
      </form>

      <nav className="flex-1 space-y-1 px-3">
        {NAV.map((item) => {
          const active = item.match(pathname);
          return (
            <Link
              key={item.label}
              href={item.href}
              className={`flex items-center gap-3 rounded-xl px-3 py-2.5 text-[13px] font-bold transition-colors ${active ? "bg-[#147DFF] text-white" : "text-white/70 hover:bg-white/5 hover:text-white"}`}
            >
              {NAV_ICONS[item.icon]}
              {item.label}
            </Link>
          );
        })}
      </nav>

      <div className="border-t border-white/10 p-4">
        <p className="text-[11px] font-bold text-white/30">v1.0.0</p>
      </div>
    </aside>
  );
}

export function AppBottomNav() {
  const pathname = usePathname();
  return (
    <nav className="fixed bottom-0 left-0 right-0 z-40 flex items-center justify-around border-t border-white/10 bg-[#0B1730] px-2 py-1 md:hidden">
      {NAV.map((item) => {
        const active = item.match(pathname);
        return (
          <Link key={item.label} href={item.href} className={`flex flex-col items-center gap-0.5 rounded-lg px-3 py-1.5 text-[11px] font-bold ${active ? "text-[#147DFF]" : "text-white/60"}`}>
            {NAV_ICONS[item.icon]}
            {item.label}
          </Link>
        );
      })}
    </nav>
  );
}
