// Sahip oturumu proxy katmanı (implementation_plan.md §5.2, Commit 4).
//
// Next.js 16 proxy.ts, Node.js runtime'da çalışır. Bu katman yalnızca ince bir
// yönlendirme işi yapar: geçerli ve istenen slug'a bağlı sahip çerezi varsa
// /v/:slug yanıtını private, no-store sunar ve isteğe x-owner-mode işaretini
// ekler. İstemciden gelen aynı adlı başlık her durumda silinir.
//
// Müşteri isteği (çerez yoksa) hiç değiştirilmeden mevcut public davranışla
// sunulur.

import { NextRequest, NextResponse } from "next/server";
import {
  OWNER_SESSION_COOKIE,
  verifyOwnerSession,
} from "./lib/ownerSession";

export default function proxy(request: NextRequest) {
  const requestHeaders = new Headers(request.headers);
  requestHeaders.delete("x-owner-mode");

  const encodedSlug = request.nextUrl.pathname.split("/")[2] ?? "";
  let slug = "";
  try {
    slug = decodeURIComponent(encodedSlug);
  } catch {
    // Bozuk URL bileşeni sahip yetkisi kazanamaz.
  }

  const ownerToken = request.cookies.get(OWNER_SESSION_COOKIE)?.value;
  if (!slug || !verifyOwnerSession(ownerToken, slug)) {
    return NextResponse.next({ request: { headers: requestHeaders } });
  }

  requestHeaders.set("x-owner-mode", "1");

  return NextResponse.next({
    request: { headers: requestHeaders },
    headers: { "cache-control": "private, no-store" },
  });
}

export const config = {
  matcher: ["/v/:path*"],
};
