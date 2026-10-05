import { NextRequest } from "next/server";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

vi.mock("node:dns/promises", async (importOriginal) => ({
  ...await importOriginal<typeof import("node:dns/promises")>(),
  resolve4: vi.fn(async () => ["8.8.8.8"]),
  resolve6: vi.fn(async () => []),
}));

// /api/fatura-eslestir — fotoğrafı KİM okumuş olursa olsun (telefon, Başak,
// elle giriş), aynı satırların aynı şekilde katalogla eşleştiğini kanıtlar.
// Bu uç nokta OCR kaynağından bağımsızdır; girdi olarak yapılandırılmış
// satır alır, fotoğraf almaz.

const mocks = vi.hoisted(() => ({
  get: vi.fn(() => "owner-cookie"),
  admin: vi.fn(),
  verifyOwner: vi.fn((): { storeId: string; slug: string } | null => ({
    storeId: "store-1",
    slug: "deneme-vitrin",
  })),
  rpc: vi.fn(
    async (): Promise<{ data: { allowed: boolean; retry_after_seconds?: number }; error: null }> => ({
      data: { allowed: true },
      error: null,
    }),
  ),
  verifyEditToken: vi.fn(async (): Promise<{ slug: string }> => {
    throw new Error("STORE_AUTH_FAILED");
  }),
}));
vi.mock("next/headers", () => ({ cookies: vi.fn(async () => ({ get: mocks.get })) }));
vi.mock("@/lib/ownerSession", () => ({
  OWNER_SESSION_COOKIE: "vixrex_owner_session",
  verifyOwnerSession: mocks.verifyOwner,
}));
vi.mock("@/lib/rentDemoSecurity", () => ({
  getClientIp: () => "127.0.0.1",
  fingerprintClient: (ip: string) => `fp-${ip}`,
}));
vi.mock("@/lib/supabaseAdmin", () => ({
  getSupabaseAdmin: () => ({ rpc: mocks.rpc }),
}));
vi.mock("@/lib/instagramServer", () => ({
  verifyStoreEditToken: mocks.verifyEditToken,
}));
mocks.admin.mockImplementation(() => ({ rpc: mocks.rpc }));

import { POST as faturaEslestir } from "@/app/api/fatura-eslestir/route";

function istek(satirlar: unknown[], slug = "deneme-vitrin", tedarikci = "") {
  return new NextRequest("http://localhost/api/fatura-eslestir", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ slug, satirlar, tedarikci }),
  });
}

describe("/api/fatura-eslestir — OCR kaynağından bağımsız katalog eşleştirme", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.get.mockReturnValue("owner-cookie");
    mocks.verifyOwner.mockReturnValue({ storeId: "store-1", slug: "deneme-vitrin" });
    mocks.rpc.mockResolvedValue({ data: { allowed: true }, error: null });
    vi.stubGlobal("fetch", vi.fn(async () => new Response("{}", { status: 404 })));
  });

  afterEach(() => { vi.unstubAllGlobals(); });

  it("oturum yoksa reddeder", async () => {
    mocks.verifyOwner.mockReturnValue(null);
    const cevap = await faturaEslestir(istek([{ model: "ELT1302" }]));
    expect(cevap.status).toBe(401);
  });

  it("çerez yoksa ama geçerli editToken varsa Flutter isteği de kabul edilir", async () => {
    mocks.verifyOwner.mockReturnValue(null); // tarayıcı çerezi yok — Flutter'ın hâli
    mocks.verifyEditToken.mockResolvedValue({ slug: "deneme-vitrin" });

    const istekGovdesi = new NextRequest("http://localhost/api/fatura-eslestir", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        slug: "deneme-vitrin",
        editToken: "gecerli-token",
        satirlar: [{ model: "ELT1302" }],
      }),
    });
    const cevap = await faturaEslestir(istekGovdesi);
    expect(cevap.status).toBe(200);
  });

  it("katalogda olmayan kod tahmin üretmez, katalog null döner", async () => {
    const cevap = await faturaEslestir(istek([{ model: "ZZZ9999", ad: "bilinmeyen ürün" }]));
    const govde = await cevap.json();
    expect(govde.satirlar[0].katalog).toBeNull();
  });

  it("500 satırlık istek 200'e kırpılır, sistem çökmez", async () => {
    const cokSatir = Array.from({ length: 500 }, (_, i) => ({ model: `X${i}`, ad: `ürün ${i}` }));
    const cevap = await faturaEslestir(istek(cokSatir));
    const govde = await cevap.json();
    expect(cevap.status).toBe(200);
    expect(govde.toplamSatir).toBe(200);
  });

  it("hız sınırı aşılınca 429 döner", async () => {
    mocks.rpc.mockResolvedValue({ data: { allowed: false, retry_after_seconds: 30 }, error: null });
    const cevap = await faturaEslestir(istek([{ model: "ELT1302" }]));
    expect(cevap.status).toBe(429);
  });
});
