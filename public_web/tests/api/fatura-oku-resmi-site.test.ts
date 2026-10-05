import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

// /api/fatura-oku — belgede yazmayan ama modelin bildiği firmanin resmi sitesi.
// O adres zincire verilir; zincir vergi no/adresle DOĞRULARSA kayıtta kalır,
// doğrulamazsa silinir. Doğrulanmamış adres esnafın gördüğü satıra düşmez.

const mocks = vi.hoisted(() => ({
  get: vi.fn((): string | undefined => "owner-cookie"),
  kaydet: vi.fn(),
  yukle: vi.fn(),
  kalici: null as Record<string, unknown> | null,
  verifyOwner: vi.fn((): { storeId: string; slug: string } | null => ({
    storeId: "store-1",
    slug: "deneme-vitrin",
  })),
  verifyEditToken: vi.fn(async (): Promise<{ slug: string }> => {
    throw new Error("STORE_AUTH_FAILED");
  }),
  rpc: vi.fn(
    async (): Promise<{ data: { allowed: boolean; retry_after_seconds?: number }; error: null }> => ({
      data: { allowed: true },
      error: null,
    }),
  ),
  zincir: vi.fn(),
  iz: null as Record<string, unknown> | null,
}));

vi.mock("next/headers", () => ({ cookies: vi.fn(async () => ({ get: mocks.get })) }));
vi.mock("@/lib/ownerSession", () => ({
  OWNER_SESSION_COOKIE: "vixrex_owner_session",
  verifyOwnerSession: mocks.verifyOwner,
}));
vi.mock("@/lib/instagramServer", () => ({ verifyStoreEditToken: mocks.verifyEditToken }));
vi.mock("@/lib/rentDemoSecurity", () => ({
  getClientIp: () => "127.0.0.1",
  fingerprintClient: (ip: string) => `fp-${ip}`,
}));
vi.mock("@/lib/supabaseAdmin", () => ({
  getSupabaseAdmin: () => ({
    rpc: mocks.rpc,
    from: () => ({
      select: () => ({ eq: () => ({ maybeSingle: async () => ({ data: { id: "store-1" }, error: null }) }) }),
    }),
  }),
}));
vi.mock("@/lib/faturaIslemKaydi", () => ({
  belgeParmakIzi: (bayt: Buffer) => `fp-${bayt.length}`,
  islemKaydet: mocks.kaydet,
  ayniAlisverisAdaylari: async () => [],
}));
vi.mock("@/lib/faturaIslemOku", () => ({
  islemiYukle: async () => mocks.kalici,
  islemYaniti: (k: Record<string, unknown>) => k,
  parmakIzindenIslemBul: async () => null,
}));
vi.mock("@/lib/faturaTaslagi", () => ({ faturaTaslaklari: () => [] }));
vi.mock("@/lib/faturaEslestir", () => ({
  faturaSatirlariniDijitalIzle: mocks.zincir,
  sonucOzeti: () => ({ kanitli: 0, eksik: 1, celiski: 0, izYok: 0 }),
}));

import { POST as faturaOku } from "@/app/api/fatura-oku/route";

const PNG_BASE64 =
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=";

function istek(): NextRequest {
  const form = new FormData();
  form.set("slug", "deneme-vitrin");
  form.set("dosya", new File([Buffer.from(PNG_BASE64, "base64")], "fatura.png", { type: "image/png" }));
  return new NextRequest("http://localhost/api/fatura-oku", { method: "POST", body: form });
}

function modelCevabi(govde: unknown): Response {
  return new Response(
    JSON.stringify({
      choices: [{ message: { content: JSON.stringify(govde) } }],
      usage: { cost: 0.0016 },
    }),
    { status: 200 },
  );
}

const OKUMA = {
  tedarikci: "Ornek Tekstil",
  tedarikci_vergi_no: "1234567890",
  tedarikci_adres: "Istanbul",
  tedarikci_site: "",
  tedarikci_resmi_site: "ornektekstil.com",
  belge_turu: "fatura",
  belge_no: "1",
  belge_tarihi: "01.10.2026",
  satirlar: [
    {
      ham_satir: "500 g Peynir 2 AD 80,00 160,00",
      model: "",
      ad: "500 g Peynir",
      barkod: "",
      varyant: "",
      beden: "",
      marka: "",
      adet: 2,
      birim_fiyat: 80,
      tutar: 160,
    },
  ],
  toplam_adet: 2,
  toplam_tutar: 160,
  mal_bedeli: 160,
  kdv_tutari: 0,
  indirim_tutari: null,
  odenecek_toplam: 160,
};

const IZ = {
  firma: "Ornek Tekstil",
  alan: "ornektekstil.com",
  platform: "",
  izinDurumu: "yok",
  kaynak: "https://ornektekstil.com",
};

process.env.SUPABASE_URL = "https://proje.supabase.co";
process.env.SUPABASE_SERVICE_ROLE_KEY = "service-role-test-anahtari";
process.env.OPENROUTER_API_KEY = "test-okuyucu-anahtari";

function zincireVerilenSite(): unknown {
  return (mocks.zincir.mock.calls as unknown[][])[0]?.[2];
}

describe("okuma — firmanin resmi sitesi zincire girer, doğrulanmazsa kayda girmez", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.kalici = null;
    mocks.kaydet.mockImplementation(async (girdi: Record<string, unknown>) => {
      mocks.kalici = {
        ...girdi,
        islemKimligi: "11111111-1111-4111-8111-111111111111",
        durum: "hazir",
        belge: girdi,
        tedarikciDijitalIz: girdi.tedarikciIz,
      };
      return "11111111-1111-4111-8111-111111111111";
    });
    mocks.get.mockReturnValue("owner-cookie");
    mocks.verifyOwner.mockReturnValue({ storeId: "store-1", slug: "deneme-vitrin" });
    mocks.rpc.mockResolvedValue({ data: { allowed: true }, error: null });
    mocks.iz = { ...IZ };
    mocks.zincir.mockImplementation(async () => ({
      satirlar: [
        {
          model: "",
          ad: "500 g Peynir",
          barkod: "",
          varyant: "",
          beden: "",
          adet: 2,
          alisBirimFiyat: 80,
          satirToplam: 160,
          guven: 1,
          katalog: null,
          sonuc: "eksik",
        },
      ],
      tedarikciIz: mocks.iz,
      aramaDurumu: { erisimHatasi: false, sinirDoldu: false },
    }));
    vi.stubGlobal(
      "fetch",
      vi.fn(async (url: string) => {
        expect(url).toContain("openrouter.ai");
        return modelCevabi(OKUMA);
      }),
    );
  });

  it("zincir doğrulanan adresi kullanırsa kayıtta ve yanıtta kalır", async () => {
    const cevap = await faturaOku(istek());
    const govde = await cevap.json();

    expect(mocks.zincir).toHaveBeenCalledTimes(1);
    expect(zincireVerilenSite()).toBe("ornektekstil.com");
    expect(cevap.status).toBe(200);
    expect(govde.tedarikciSite).toBe("ornektekstil.com");
  });

  it("zincir doğrulamazsa adres kayda girmez, esnafın satırına düşmez", async () => {
    mocks.iz = null;

    const cevap = await faturaOku(istek());
    const govde = await cevap.json();

    expect(zincireVerilenSite()).toBe("ornektekstil.com");
    expect(govde.tedarikciSite).toBe("");
    expect(govde.tedarikciDijitalIz).toBeNull();
  });

  it("belgede site yazıyorsa o kazanır, modelin adresi hiç kullanılmaz", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => modelCevabi({ ...OKUMA, tedarikci_site: "belgedeki-site.com" })),
    );
    mocks.iz = null;

    const cevap = await faturaOku(istek());
    const govde = await cevap.json();

    expect(zincireVerilenSite()).toBe("belgedeki-site.com");
    expect(govde.tedarikciSite).toBe("belgedeki-site.com");
  });
});
