"use client";

import { useEffect } from "react";
import { kaydetVitrinKaynakHandoff } from "@/lib/vitrinSourceHandoff";

function vitrinPathFromTarget(target: EventTarget | null): string | null {
  if (!(target instanceof Element)) return null;
  const anchor = target.closest("a[href]");
  if (!(anchor instanceof HTMLAnchorElement)) return null;

  let url: URL;
  try {
    url = new URL(anchor.href, window.location.href);
  } catch {
    return null;
  }

  if (url.origin !== window.location.origin) return null;
  if (!/^\/v\/[^/]+\/?$/.test(url.pathname)) return null;
  return url.pathname;
}

export default function KesfetVitrinSourceMarker() {
  useEffect(() => {
    const mark = (event: MouseEvent) => {
      const path = vitrinPathFromTarget(event.target);
      if (!path) return;
      kaydetVitrinKaynakHandoff("kesfet", path);
    };

    document.addEventListener("click", mark, true);
    return () => document.removeEventListener("click", mark, true);
  }, []);

  return null;
}
