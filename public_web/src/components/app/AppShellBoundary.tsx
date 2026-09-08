"use client";

import type { ReactNode } from "react";
import { useEffect, useLayoutEffect, useRef, useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import { AppShellProvider } from "@/components/app/AppShellContext";
import { AppBottomNav, AppSidebar } from "@/components/app/AppSidebar";
import { StatusBar } from "@/components/kesfet/StatusBar";

type AnaSekme = "vitrinim" | "kesfet" | "vixrex" | "profil";

const ANA_SEKME_ROTA: Record<AnaSekme, string> = {
  vitrinim: "/app",
  kesfet: "/kesfet",
  vixrex: "/app/vixrex",
  profil: "/app/profil",
};

function anaSekmeAnahtari(pathname: string): AnaSekme | null {
  if (pathname === ANA_SEKME_ROTA.vitrinim) return "vitrinim";
  if (pathname === ANA_SEKME_ROTA.kesfet) return "kesfet";
  if (pathname === ANA_SEKME_ROTA.vixrex) return "vixrex";
  if (pathname === ANA_SEKME_ROTA.profil) return "profil";
  return null;
}

function shellRotasi(pathname: string): boolean {
  return (
    pathname === "/app" ||
    pathname.startsWith("/app/urunler") ||
    pathname === "/app/vixrex" ||
    pathname === "/app/profil" ||
    pathname === "/kesfet" ||
    pathname.startsWith("/kesfet/")
  );
}

/**
 * Flutter IndexedStack karşılığı.
 *
 * Dört ana ekran ilk ziyaretinde mount edilir ve sekme değişince unmount olmaz.
 * Böylece form/arama/sohbet/scroll durumu korunur; kullanıcı yeni bir uygulama
 * açılıyormuş gibi sert bir gövde değişimi görmez. Alt ekranlar (ürün/kategori
 * gibi) normal route olarak çalışmaya devam eder ve ana sekme cache'ini bozmaz.
 */
function KaliciAnaSekmeler({ pathname, children }: { pathname: string; children: ReactNode }) {
  const aktifSekme = anaSekmeAnahtari(pathname);
  const kaydirmaKonumlari = useRef<Partial<Record<AnaSekme, number>>>({});
  const oncekiSekme = useRef<AnaSekme | null>(null);

  // İlk ziyaret edilen ana ekranın React ağacını sakla; geri dönünce yeniden
  // oluşturmak yerine aynı mounted örneği göster. Bu önbellek render sırasında
  // okunduğu için ref değil state: ref'e render içinde dokunmak React'in
  // eşzamanlı çalışmasında güvenli değil ve okunan değer eskiyebilir.
  const [sekmeGovdeleri, setSekmeGovdeleri] = useState<
    Partial<Record<AnaSekme, ReactNode>>
  >(() => (aktifSekme ? { [aktifSekme]: children } : {}));

  // Yeni bir ana sekmeye ilk kez girildiğinde önbelleğe ekle. Koşul yalnız
  // sekme değişiminde sağlandığı için bu güncelleme kendini tetiklemez.
  if (aktifSekme && !sekmeGovdeleri[aktifSekme]) {
    setSekmeGovdeleri((onceki) =>
      onceki[aktifSekme] ? onceki : { ...onceki, [aktifSekme]: children }
    );
  }

  useLayoutEffect(() => {
    const onceki = oncekiSekme.current;
    if (onceki && onceki !== aktifSekme) {
      kaydirmaKonumlari.current[onceki] = window.scrollY;
    }

    if (aktifSekme) {
      const hedef = kaydirmaKonumlari.current[aktifSekme] ?? 0;
      const frame = window.requestAnimationFrame(() => {
        window.scrollTo({ top: hedef, left: 0, behavior: "auto" });
      });
      oncekiSekme.current = aktifSekme;
      return () => window.cancelAnimationFrame(frame);
    }

    oncekiSekme.current = null;
  }, [aktifSekme]);

  const sekmeler = Object.entries(sekmeGovdeleri) as Array<[AnaSekme, ReactNode]>;

  return (
    <>
      {sekmeler.map(([sekme, govde]) => {
        const aktif = sekme === aktifSekme;
        return (
          <section
            key={sekme}
            hidden={!aktif}
            aria-hidden={!aktif}
            data-app-tab={sekme}
            className="min-h-full min-w-0"
          >
            {govde}
          </section>
        );
      })}

      {!aktifSekme ? <div className="min-h-full min-w-0">{children}</div> : null}
    </>
  );
}

/** Flutter HomeShellScreen'in Next.js karşılığı: tek sidebar, tek durum çubuğu,
 * tek mobil NavigationBar ve dört kalıcı ana yüz. */
export function AppShellBoundary({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const shellIci = shellRotasi(pathname);

  // Ana sekmeleri yalnız uygulama kabuğundayken önden getir. Landing/public
  // sayfalarda gereksiz uygulama isteği üretme.
  useEffect(() => {
    if (!shellIci) return;
    for (const route of Object.values(ANA_SEKME_ROTA)) {
      router.prefetch(route);
    }
  }, [router, shellIci]);

  if (!shellIci) return children;

  return (
    <AppShellProvider>
      <div className="vixrex-app-shell flex min-h-screen bg-lp-bg-editor text-lp-text">
        <AppSidebar />
        <div className="flex min-h-screen min-w-0 flex-1 flex-col">
          <StatusBar />
          <div className="min-w-0 flex-1 pb-[var(--vx-app-bottom-nav-height)] min-[901px]:pb-0">
            <KaliciAnaSekmeler pathname={pathname}>{children}</KaliciAnaSekmeler>
          </div>
          <AppBottomNav />
        </div>
      </div>
    </AppShellProvider>
  );
}
