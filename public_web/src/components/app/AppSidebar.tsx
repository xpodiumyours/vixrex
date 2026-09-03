"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useState, type ReactNode } from "react";
import { KesfetIkonu, StorefrontIkonu } from "@/components/site/icons";
import { SharedVixrexAssistant } from "@/components/vixrex/SharedVixrexAssistant";

/** Vixrex maskotu — Vixrex'i temsil eden tek simge bu. Emoji veya soyut
 * ikon KOYULMAZ: maskot aynı zamanda uygulamanın logosu. */
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
  { href: "/app", label: "Vitrinim", icon: <StorefrontIkonu boyut={20} />, match: (p: string) => p === "/app" || p.startsWith("/app/urunler") },
  { href: "/kesfet", label: "Keşfet", icon: <KesfetIkonu boyut={20} />, match: (p: string) => p.startsWith("/kesfet") },
  // Flutter'da "Vixrex" ayrı bir ekran; Next.js'te henüz karşılığı yok, madde
  // /app'e gidiyor. Eşleşmesi "Vitrinim" ile aynı olduğu için ikisi birden mavi
  // yanıyordu. Kendi sayfası açılana kadar aktif durumu Vitrinim'e bırakıyor.
  // Flutter'da "Vixrex" shell'in ayri bir sekmesi. Web'de de aynisi olsun
  // diye bu madde gezinme yapmaz, asistan panelini yerinde acar.
  { href: null, label: "Vixrex", icon: <MaskotIkonu boyut={20} />, match: () => false },
  { href: "/app/profil", label: "Profil", icon: <KisiIkonu />, match: (p: string) => p.startsWith("/app/profil") || p.startsWith("/app/hesap") || p.startsWith("/app/ayarlar") || p.startsWith("/app/bildirimler") },
] as Array<{ href: string | null; label: string; icon: ReactNode; match: (p: string) => boolean }>;

/** Vixrex Asistan paneli — Flutter'daki Vixrex sekmesinin web karsiligi.
 * Menuden acilir, sayfadan ayrilmaz. */
function AsistanPaneli({ kapat }: { kapat: () => void }) {
  const router = useRouter();
  return (
    <div className="fixed inset-0 z-50 flex justify-end bg-black/60" role="dialog" aria-modal="true" aria-label="Vixrex Asistan">
      <button type="button" aria-label="Paneli kapat" className="flex-1 cursor-default" onClick={kapat} />
      <div className="flex h-full w-full max-w-[460px] flex-col overflow-y-auto border-l border-white/10 bg-[#0B1730]">
        <div className="flex items-center gap-3 border-b border-white/10 px-4 py-3">
          <MaskotIkonu boyut={28} />
          <span className="flex-1 text-[15px] font-black text-white">Vixrex Asistan</span>
          <button
            type="button"
            onClick={kapat}
            aria-label="Kapat"
            className="rounded-lg px-2 py-1 text-white/60 hover:bg-white/10 hover:text-white"
          >
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" aria-hidden="true"><path d="M18 6 6 18M6 6l12 12" /></svg>
          </button>
        </div>
        <SharedVixrexAssistant
          onBrowse={() => {
            kapat();
            router.push("/kesfet");
          }}
        />
      </div>
    </div>
  );
}

export function AppSidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const [q, setQ] = useState("");
  const [asistanAcik, setAsistanAcik] = useState(false);

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
    <>
    <aside className="hidden w-[280px] shrink-0 flex-col border-r border-white/10 bg-[#0B1730] md:flex">
      <div className="flex h-[64px] items-center gap-3 border-b border-white/10 px-5">
        <MaskotIkonu boyut={32} />
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
          const sinif = `flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left text-[13px] font-bold transition-colors ${active ? "bg-[#147DFF] text-white" : "text-white/70 hover:bg-white/5 hover:text-white"}`;
          const govde = (
            <>
              <span className="flex h-5 w-5 items-center justify-center">{item.icon}</span>
              {item.label}
            </>
          );
          return item.href === null ? (
            <button key={item.label} type="button" onClick={() => setAsistanAcik(true)} className={sinif}>
              {govde}
            </button>
          ) : (
            <Link key={item.label} href={item.href} className={sinif}>
              {govde}
            </Link>
          );
        })}
      </nav>

      <div className="border-t border-white/10 p-4">
        <p className="text-[11px] font-bold text-white/30">v1.0.0</p>
      </div>
    </aside>
    {asistanAcik ? <AsistanPaneli kapat={() => setAsistanAcik(false)} /> : null}
    </>
  );
}

export function AppBottomNav() {
  const pathname = usePathname();
  const [asistanAcik, setAsistanAcik] = useState(false);
  return (
    <>
    <nav className="fixed bottom-0 left-0 right-0 z-40 flex items-center justify-around border-t border-white/10 bg-[#0B1730] px-2 py-1 md:hidden">
      {NAV.map((item) => {
        const active = item.match(pathname);
        const sinif = `flex flex-col items-center gap-0.5 rounded-lg px-3 py-1.5 text-[11px] font-bold ${active ? "text-[#147DFF]" : "text-white/60"}`;
        const govde = (
          <>
            <span className="flex h-5 w-5 items-center justify-center">{item.icon}</span>
            {item.label}
          </>
        );
        return item.href === null ? (
          <button key={item.label} type="button" onClick={() => setAsistanAcik(true)} className={sinif}>
            {govde}
          </button>
        ) : (
          <Link key={item.label} href={item.href} className={sinif}>
            {govde}
          </Link>
        );
      })}
    </nav>
    {asistanAcik ? <AsistanPaneli kapat={() => setAsistanAcik(false)} /> : null}
    </>
  );
}
