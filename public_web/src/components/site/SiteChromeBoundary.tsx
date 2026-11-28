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
  const anaSayfaMi = !pathname || pathname === "/" || pathname === "";
  const kesfetMi = Boolean(pathname && (pathname === "/kesfet" || pathname.startsWith("/kesfet/")));

  return (
    <>
      {!anaSayfaMi && !kesfetMi ? header : null}
      {kesfetMi ? (
        <div className="flex-1">{children}</div>
      ) : (
        <main className="flex-1">{children}</main>
      )}
      {footer}
    </>
  );
}
