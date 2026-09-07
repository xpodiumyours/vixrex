"use client";

import type { ReactNode } from "react";
import { usePathname } from "next/navigation";

type SiteChromeBoundaryProps = Readonly<{
  children: ReactNode;
  header: ReactNode;
  footer: ReactNode;
}>;

export function SiteChromeBoundary({
  children,
  header,
  footer,
}: SiteChromeBoundaryProps) {
  const pathname = usePathname();
  const kesfetMi = pathname === "/kesfet" || pathname.startsWith("/kesfet/");
  const anaSayfaMi = pathname === "/";

  return (
    <>
      {!anaSayfaMi && !kesfetMi ? header : null}
      <main className="flex-1">{children}</main>
      {!kesfetMi ? footer : null}
    </>
  );
}
