import { describe, it, expect } from "vitest";
import { GET as faturaRedirect } from "@/app/app/fatura/route";
import { NextRequest } from "next/server";

describe("Landing, Fatura Yönlendirme ve Oturum Sözleşmesi", () => {
  it("/app/fatura GET isteği /app/urunler adresine 307/308 ile yönlendirir", () => {
    const req = new NextRequest("https://vixrex.com/app/fatura");
    const res = faturaRedirect(req);
    expect(res.status).toBe(307);
    expect(res.headers.get("location")).toBe("https://vixrex.com/app/urunler");
  });
});
