"use client";

import { usePathname } from "next/navigation";
import { AppBottomNav, AppSidebar } from "@/components/app/AppSidebar";

function shellRotasi(pathname: string): boolean {
  return (
    pathname === "/app" ||
    pathname.startsWith("/app/") ||
    pathname === "/kesfet" ||
    pathname.startsWith("/kesfet/")
  );
}

/**
 * Flutter HomeShellScreen'in Next.js karşılığı.
 *
 * Vitrinim / Keşfet / Vixrex / Profil aynı uygulama kabuğunun çocuklarıdır.
 * Route dosyaları farklı ağaçlarda olsa bile shell root layout altında tek
 * örnek olarak yaşar; sayfa değişimi ikinci sidebar veya ikinci mobil nav
 * üretmez.
 */
export function AppShellBoundary({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();

  if (!shellRotasi(pathname)) return children;

  return (
    <div className="flex min-h-screen bg-lp-bg-editor text-lp-text">
      <AppSidebar />
      <div className="flex min-h-screen min-w-0 flex-1 flex-col">
        <div className="min-w-0 flex-1 pb-[64px] min-[901px]:pb-0">{children}</div>
        <AppBottomNav />
      </div>
    </div>
  );
}
