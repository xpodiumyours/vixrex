import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

// /api/fatura-metin — anahtarsız giriş. Yazılan/yapıştırılan metin ya da
// satır listesi AYNI zincirden geçer: deterministik satır ayırma → katalog
// eşleştirme → işlem kaydı → taslak. Ücretli okuyucu çağrısı yapılmaz.

const mocks = vi.hoisted(() => ({
  get: vi.fn((): string | undefined => "owner-cookie"),
  verifyOwner: vi.fn((): { storeId: string; slug: string } | null => ({
    storeId: "store-1",
    slug: "deneme-vitrin",
  })),
  verifyEditToken: vi.fn(async (): Promise<{ slug: string }> => {
    throw new Error("STORE_AUTH_FAILED");
  }),
  rpc: vi.fn(async () => ({ data: { allowed: true }, error: null })),
}));

vi.mock("next/headers", () => ({ cookies: vi.fn(async () => ({ get: mocks.get })) }));
vi.mock("@/lib/ownerSession", () => ({
  OWNER_SESSION_COOKIE: "vixrex_owner_session",
  verifyOwnerSession: mocks.verifyOwner,
}));
vi.mock("@/lib/instagramServer", () => ({ verifyStoreEditToken: mocks.verifyEditToken }));
vi.mock("@/lib/supabaseAdmin", () => ({
  getSupabaseAdmin: () => ({
    rpc: mocks.rpc,
    // Mağaza bulunamazsa islemKaydet null döner; metin zinciri yine de
    // satır + taslak üretir. Bu test DB'ye yazmaz.
    from: () => ({
      select: () => ({
        eq: () => ({
          order: () => ({
            limit: async () => ({ data: [], error: null }),
          }),
          maybeSingle: async () => ({ data: null, error: null }),
        }),
      }),
    }),
  }),
}));

import { POST as faturaMetin } from "@/app/api/fatura-metin/route";

function istek(govde: Record<string, unknown>) {
  return new NextRequest("http://localhost/api/fatura-metin", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ slug: "deneme-vitrin", ...govde }),
  });
}

describe("/api/fatura-metin — anahtarsız giriş", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.get.mockReturnValue("owner-cookie");
    mocks.verifyOwner.mockReturnValue({ storeId: "store-1", slug: "deneme-vitrin" });
    mocks.rpc.mockResolvedValue({ data: { allowed: true }, error: null });
  });

  it("yapıştırılan metni aynı zincirden geçirip taslak üretir", async () => {
    const cevap = await faturaMetin(
      istek({
        metin: "ELT1302 Elit Erkek Elastan Sıfır Yaka 8681128321677 Siyah L 2 Adet 137,00 274,00",
      }),
    );
    const govde = await cevap.json();

    expect(cevap.status).toBe(200);
    expect(govde.kaynak).toBe("metin");
    expect(govde.satirlar).toHaveLength(1);
    expect(govde.satirlar[0].model).toBe("ELT1302");
    expect(govde.satirlar[0].adet).toBe(2);
    expect(Array.isArray(govde.taslaklar)).toBe(true);
    expect("islemKimligi" in govde).toBe(true);
  });

  it("tek tek yazılan satır listesini de kabul eder", async () => {
    const cevap = await faturaMetin(
      istek({
        satirlar: [{ model: "16747", ad: "Interlok Takım", adet: 8, alisBirimFiyat: 450 }],
      }),
    );
    const govde = await cevap.json();

    expect(cevap.status).toBe(200);
    expect(govde.satirlar).toHaveLength(1);
    expect(govde.satirlar[0].model).toBe("16747");
  });

  it("boş girişi 422 ile reddeder", async () => {
    const cevap = await faturaMetin(istek({ metin: "   " }));
    expect(cevap.status).toBe(422);
  });

  it("oturum yoksa 401 döner", async () => {
    mocks.verifyOwner.mockReturnValue(null);
    const cevap = await faturaMetin(istek({ metin: "ELT1302 test 2 Adet 10,00 20,00" }));
    expect(cevap.status).toBe(401);
  });

  it("hız sınırı aşılınca 429 döner", async () => {
    mocks.rpc.mockResolvedValue({ data: { allowed: false, retry_after_seconds: 30 }, error: null } as never);
    const cevap = await faturaMetin(istek({ metin: "ELT1302 test 2 Adet 10,00 20,00" }));
    expect(cevap.status).toBe(429);
  });
});
