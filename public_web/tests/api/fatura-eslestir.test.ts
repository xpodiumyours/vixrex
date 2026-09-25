import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";
import seherHam from "@/data/uretici-katalog-seher.json";
import type { UreticiUrunu } from "@/lib/ureticiKatalog";

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

function istek(satirlar: unknown[], slug = "deneme-vitrin") {
  return new NextRequest("http://localhost/api/fatura-eslestir", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ slug, satirlar }),
  });
}

describe("/api/fatura-eslestir — OCR kaynağından bağımsız katalog eşleştirme", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.get.mockReturnValue("owner-cookie");
    mocks.verifyOwner.mockReturnValue({ storeId: "store-1", slug: "deneme-vitrin" });
    mocks.rpc.mockResolvedValue({ data: { allowed: true }, error: null });
  });

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

  it("gerçek katalog kodları HTTP üzerinden eşleşir ve resmî ad/fotoğraf döner", async () => {
    const cevap = await faturaEslestir(
      istek([
        { model: "ELT1302", ad: "elastan sıfır yaka", barkod: "", adet: 2, alisBirimFiyat: 137, guven: 0.9 },
        { model: "TER0101", ad: "penye atlet", barkod: "", adet: 18, alisBirimFiyat: 63.5, guven: 0.85 },
      ]),
    );
    const govde = await cevap.json();

    expect(cevap.status).toBe(200);
    expect(govde.katalogEslesmesi).toBe(2);
    expect(govde.satirlar[0].katalog.resmiAd).toContain("ELT1302");
    expect(govde.satirlar[0].katalog.gorseller.length).toBeGreaterThan(0);
    expect(govde.satirlar[1].katalog.marka).toBeTruthy();
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

  it.each([1234, 5678, 9012])(
    "tohum=%i: rastgele 15 satır — katalogdaki gerçek ürünlerin hepsi bulunur, uydurma ürün bulunmaz",
    async (tohum) => {
      let durum = tohum >>> 0;
      const rastgele = () => {
        durum |= 0;
        durum = (durum + 0x6d2b79f5) | 0;
        let t = Math.imul(durum ^ (durum >>> 15), 1 | durum);
        t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
        return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
      };
      const havuz = seherHam as UreticiUrunu[];
      const gercekKodlar = new Set<string>();
      while (gercekKodlar.size < 12) gercekKodlar.add(havuz[Math.floor(rastgele() * havuz.length)].kod);

      const satirlar = [...gercekKodlar].map((model) => ({ model, ad: "", guven: 0.8 }));
      satirlar.push({ model: "UYDURMA9999", ad: "gerçek olmayan ürün", guven: 0.3 });

      const cevap = await faturaEslestir(istek(satirlar));
      const govde = await cevap.json();

      expect(govde.katalogEslesmesi).toBe(12); // 12 gerçek + 1 uydurma
      const uydurma = govde.satirlar.find((s: { model: string }) => s.model === "UYDURMA9999");
      expect(uydurma.katalog).toBeNull();
    },
  );
});
