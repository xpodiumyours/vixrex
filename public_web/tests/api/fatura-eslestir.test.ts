import { NextRequest } from "next/server";
import sharp from "sharp";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import seherHam from "../../data/katalog/uretici-katalog-seher-mensucat.json";
import type { UreticiUrunu } from "@/lib/ureticiKatalog";

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

function istek(satirlar: unknown[], slug = "deneme-vitrin", tedarikci = "", tedarikciSite = "") {
  return new NextRequest("http://localhost/api/fatura-eslestir", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ slug, satirlar, tedarikci, tedarikciSite }),
  });
}

const LUNA_SITE = "https://seher-mensucat.example";

async function lunaFoto(): Promise<Buffer> {
  const gurultu = Buffer.alloc(1200 * 1200 * 3);
  for (let i = 0; i < gurultu.length; i += 97) gurultu[i] = (i * 13) % 251;
  return sharp(gurultu, { raw: { width: 1200, height: 1200, channels: 3 } }).jpeg({ quality: 80 }).toBuffer();
}

function lunaHatti(foto: Buffer) {
  return vi.fn(async (url: string, init?: RequestInit) => {
    const adres = String(url);
    if (adres.includes("openrouter.ai")) {
      const govde = JSON.parse(String(init?.body ?? "{}"));
      const metin = JSON.stringify(govde.input ?? "");
      if (metin.includes("resmi web sitesi")) {
        return new Response(JSON.stringify({
          output: [{ type: "message", content: [{ type: "output_text", text: JSON.stringify({ alan: "seher-mensucat.example", kaynak: LUNA_SITE }) }] }],
        }), { status: 200 });
      }
      if (govde.tools) {
        const sorgu = metin.toUpperCase();
        if (sorgu.includes("UYDURMA9999") || sorgu.includes("ZZZ9999")) {
          return new Response(JSON.stringify({
            output: [{ type: "message", content: [{ type: "output_text", text: JSON.stringify({ sayfa: "", gorsel: "" }) }] }],
          }), { status: 200 });
        }
        const kod = (metin.match(/[A-Z0-9]{4,}/) || ["URUN"])[0].toUpperCase();
        return new Response(JSON.stringify({
          output: [{ type: "message", content: [{ type: "output_text", text: JSON.stringify({ sayfa: `${LUNA_SITE}/urun/${kod}`, gorsel: `${LUNA_SITE}/gorsel/${kod}.jpg` }) }] }],
        }), { status: 200 });
      }
      if (metin.includes("SAYFA:")) {
        const kod = (metin.match(/[A-Z0-9]{4,}/) || ["URUN"])[0].toUpperCase();
        return new Response(JSON.stringify({
          output: [{ type: "message", content: [{ type: "output_text", text: JSON.stringify({ aciklama: `${kod} resmi ürün açıklaması` }) }] }],
        }), { status: 200 });
      }
      if (metin.includes("gerçek ürün fotoğrafı")) {
        return new Response(JSON.stringify({
          output: [{ type: "message", content: [{ type: "output_text", text: JSON.stringify({ uygun: true }) }] }],
        }), { status: 200 });
      }
      return new Response(JSON.stringify({
        output: [{ type: "message", content: [{ type: "output_text", text: JSON.stringify({ alan: "seher-mensucat.example", kaynak: LUNA_SITE }) }] }],
      }), { status: 200 });
    }
    if (adres.startsWith(`${LUNA_SITE}/urun/`)) {
      const kod = adres.split("/").pop() ?? "URUN";
      return new Response(`<html><body>${kod} resmi ürün açıklaması detaylı metin</body></html>`, { status: 200 });
    }
    if (adres.startsWith(`${LUNA_SITE}/gorsel/`)) {
      return new Response(new Uint8Array(foto), { status: 200 });
    }
    return new Response("{}", { status: 404 });
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

  it("Luna site sayfasında bulursa kart kanitli olur", async () => {
    const eski = process.env.OPENROUTER_API_KEY;
    process.env.OPENROUTER_API_KEY = "test-luna";
    const foto = await lunaFoto();
    vi.stubGlobal("fetch", lunaHatti(foto));
    try {
      const cevap = await faturaEslestir(
        istek([
          { model: "ELT1302", ad: "ELT1302 elastan sıfır yaka", barkod: "", adet: 2, alisBirimFiyat: 137, guven: 0.9 },
          { model: "TER0101", ad: "TER0101 penye atlet", barkod: "", adet: 18, alisBirimFiyat: 63.5, guven: 0.85 },
        ], "deneme-vitrin", "Seher Mensucat", LUNA_SITE),
      );
      const govde = await cevap.json();

      expect(cevap.status).toBe(200);
      expect(govde.katalogEslesmesi).toBe(2);
      expect(govde.satirlar[0].katalog.resmiAd).toContain("ELT1302");
      expect(govde.satirlar[0].katalog.izinDurumu).not.toBe("var");
      expect(govde.satirlar[0].katalog.gorseller.length).toBeGreaterThan(0);
      expect(govde.satirlar[0].katalog.kaynak).toContain("seher-mensucat.example");
    } finally {
      if (eski === undefined) delete process.env.OPENROUTER_API_KEY;
      else process.env.OPENROUTER_API_KEY = eski;
    }
  });

  it("katalogda olmayan kod tahmin üretmez, katalog null döner", async () => {
    const cevap = await faturaEslestir(istek([{ model: "ZZZ9999", ad: "bilinmeyen ürün" }]));
    const govde = await cevap.json();
    expect(govde.satirlar[0].katalog).toBeNull();
  });

  it("anahtar yoksa Luna çalışmaz, satır eksik kalır", async () => {
    const eski = process.env.OPENROUTER_API_KEY;
    delete process.env.OPENROUTER_API_KEY;
    try {
      const cevap = await faturaEslestir(
        istek([{ model: "ELT1302", ad: "ELT1302 elastan sıfır yaka", guven: 0.9 }], "deneme-vitrin", "Seher Mensucat", LUNA_SITE),
      );
      const govde = await cevap.json();
      expect(cevap.status).toBe(200);
      expect(govde.satirlar[0].sonuc).toBe("eksik");
      expect(govde.satirlar[0].katalog).toBeNull();
    } finally {
      if (eski !== undefined) process.env.OPENROUTER_API_KEY = eski;
    }
  });

  it("Luna adayı bulamazsa satır eksik kalır", async () => {
    const eski = process.env.OPENROUTER_API_KEY;
    process.env.OPENROUTER_API_KEY = "test-luna";
    vi.stubGlobal("fetch", vi.fn(async (url: string) => {
      if (String(url).includes("openrouter.ai")) {
        return new Response(JSON.stringify({
          output: [{ type: "message", content: [{ type: "output_text", text: JSON.stringify({ sayfa: "", gorsel: "" }) }] }],
        }), { status: 200 });
      }
      return new Response("{}", { status: 404 });
    }));
    try {
      const cevap = await faturaEslestir(
        istek([{ model: "ELT1302", ad: "ELT1302 elastan sıfır yaka", guven: 0.9 }], "deneme-vitrin", "Seher Mensucat", LUNA_SITE),
      );
      const govde = await cevap.json();
      expect(cevap.status).toBe(200);
      expect(govde.satirlar[0].sonuc).toBe("eksik");
      expect(govde.satirlar[0].katalog).toBeNull();
    } finally {
      if (eski === undefined) delete process.env.OPENROUTER_API_KEY;
      else process.env.OPENROUTER_API_KEY = eski;
    }
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
    "tohum=%i: Luna gerçek kodları bulur, uydurma ürünü boş bırakır",
    async (tohum) => {
      const eski = process.env.OPENROUTER_API_KEY;
      process.env.OPENROUTER_API_KEY = "test-luna";
      const foto = await lunaFoto();
      vi.stubGlobal("fetch", lunaHatti(foto));
      try {
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

        const satirlar = [...gercekKodlar].map((model) => ({ model, ad: model, guven: 0.8 }));
        satirlar.push({ model: "UYDURMA9999", ad: "UYDURMA9999 gerçek olmayan ürün", guven: 0.3 });

        const cevap = await faturaEslestir(istek(satirlar, "deneme-vitrin", "Seher Mensucat", LUNA_SITE));
        const govde = await cevap.json();

        expect(govde.katalogEslesmesi).toBe(12); // 12 gerçek + 1 uydurma
        const uydurma = govde.satirlar.find((s: { model: string }) => s.model === "UYDURMA9999");
        expect(uydurma.katalog).toBeNull();
      } finally {
        if (eski === undefined) delete process.env.OPENROUTER_API_KEY;
        else process.env.OPENROUTER_API_KEY = eski;
      }
    },
  );
});
