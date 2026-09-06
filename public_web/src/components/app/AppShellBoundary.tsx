"use client";

import { usePathname } from "next/navigation";
import { AppShellProvider } from "@/components/app/AppShellContext";
import { AppBottomNav, AppSidebar } from "@/components/app/AppSidebar";
import { StatusBar } from "@/components/kesfet/StatusBar";

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

/** Flutter HomeShellScreen'in Next.js karşılığı: tek sidebar, tek durum çubuğu,
 * tek mobil NavigationBar ve dört ana yüz. */
export function AppShellBoundary({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();

  if (!shellRotasi(pathname)) return children;

  return (
    <AppShellProvider>
      <div className="flex min-h-screen bg-lp-bg-editor text-lp-text">
        <AppSidebar />
        <div className="flex min-h-screen min-w-0 flex-1 flex-col">
          <StatusBar />
          <div className="min-w-0 flex-1 pb-[68px] min-[901px]:pb-0">{children}</div>
          <AppBottomNav />
        </div>
      </div>
    </AppShellProvider>
  );
}
