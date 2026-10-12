import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  get: vi.fn((): { name: string; value: string } | undefined => ({ name: "sess", value: "owner-cookie" })),
  verifyOwner: vi.fn(
    (deger?: string | null): { storeId: string; slug: string } | null =>
      deger ? { storeId: "store-1", slug: "deneme-vitrin" } : null,
  ),
  verifyEditToken: vi.fn(async (): Promise<{ slug: string }> => {
    throw new Error("STORE_AUTH_FAILED");
  }),
  rpc: vi.fn(
    async (): Promise<{ data: unknown; error: null }> => ({ data: { allowed: true }, error: null }),
  ),
  parmak: vi.fn(async (): Promise<string | null> => null),
  yukle: vi.fn(async (): Promise<unknown> => null),
  kaydet: vi.fn(async (_girdi?: unknown): Promise<string | null> => "islem-1"),
  fetch: vi.fn(),
}));

vi.mock("next/headers", () => ({ cookies: async () => ({ get: mocks.get }) }));
vi.mock("@/lib/ownerSession", () => ({
  OWNER_SESSION_COOKIE: "vixrex_owner_session",
  verifyOwnerSession: mocks.verifyOwner,
}));
vi.mock("@/lib/instagramServer", () => ({ verifyStoreEditToken: mocks.verifyEditToken }));
vi.mock("@/lib/rentDemoSecurity", () => ({
  getClientIp: () => "9.9.9.9",
  fingerprintClient: (ip: string) => `fp:${ip}`,
}));
vi.mock("@/lib/supabaseAdmin", () => ({
  getSupabaseAdmin: () => ({
    rpc: mocks.rpc,
    from: () => ({
      select: () => ({
        eq: () => ({
          maybeSingle: async () => ({ data: { id: "store-1" }, error: null }),
        }),
      }),
    }),
  }),
}));
vi.mock("@/lib/faturaIslemKaydi", async (importOriginal) => ({
  ...await importOriginal<typeof import("@/lib/faturaIslemKaydi")>(),
  islemKaydet: mocks.kaydet,
}));
vi.mock("@/lib/faturaIslemOku", async (importOriginal) => ({
  ...await importOriginal<typeof import("@/lib/faturaIslemOku")>(),
  parmakIzindenIslemBul: mocks.parmak,
  islemiYukle: mocks.yukle,
  islemYaniti: (islem: { satirlar: unknown[] }) => ({ tamam: true, satirlar: islem.satirlar }),
}));

import { POST as faturaOku } from "@/app/api/fatura-oku/route";
import { GORU_MODELI } from "@/lib/faturaGoru";

const PNG_IMZA = new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0, 0, 0, 13]);

function pngDosya(): File {
  return new File([PNG_IMZA], "fatura.png", { type: "image/png" });
}

function istek(dosyalar: File[] = [pngDosya()], alanlar: Record<string, string> = {}): NextRequest {
  const form = new FormData();
  form.set("slug", "deneme-vitrin");
  for (const dosya of dosyalar) form.append("dosya", dosya);
  for (const [ad, deger] of Object.entries(alanlar)) form.set(ad, deger);
  return new NextRequest("http://localhost/api/fatura-oku", { method: "POST", body: form });
}

function lunaCevabi(satirlar: unknown[], ozel: Record<string, unknown> = {}) {
  const govde = {
    tedarikci: "Seher Mensucat",
    tedarikci_vergi_no: "1234567890",
    tedarikci_adres: "Istanbul",
    tedarikci_site: "sehermensucat.com",
    belge_turu: "fatura",
    belge_no: "F-2026-001",
    belge_tarihi: "12.10.2026",
    satirlar,
    toplam_adet: 2,
    toplam_tutar: 998,
    mal_bedeli: 846.44,
    kdv_tutari: 151.56,
    odenecek_toplam: 998,
    ...ozel,
  };
  return {
    choices: [{ message: { content: JSON.stringify(govde) } }],
    usage: { prompt_tokens: 120, completion_tokens: 60, cost: 0.01 },
  };
}

function cevapUcur(cevap: unknown): void {
  mocks.fetch.mockResolvedValue({ ok: true, status: 200, json: async () => cevap });
}

interface GonderilenGovde {
  model: string;
  temperature?: number;
  messages: Array<{ content: Array<{ type: string; image_url?: { url: string } }> }>;
}

function gonderilenGovde(): GonderilenGovde {
  return JSON.parse(String(mocks.fetch.mock.calls[0][1].body));
}

const LUNA_SATIR = {
  ham_satir: "ELT1001 Elit Fanila 2 AD499,00",
  model: "ELT1001",
  ad: "Elit Fanila",
  barkod: "8680000000001",
  varyant: "",
  beden: "L",
  marka: "Elit",
  adet: 2,
  birim: "adet",
  birim_fiyat: 499,
  tutar: 998,
  site_aciklama: "Pamuklu fanila",
  site_sayfa: "https://seher.example/elt1001",
  site_gorseller: ["https://seher.example/1.jpg"],
  kategori: "Atlet",
};

beforeEach(() => {
  process.env.OPENROUTER_API_KEY = "test-okuyucu-anahtari";
  process.env.OPENROUTER_PRESET = "fatura-okuma";
  delete process.env.OPENROUTER_FATURA_PRESET;
  mocks.get.mockReturnValue({ name: "sess", value: "owner-cookie" });
  mocks.verifyOwner.mockReset().mockImplementation((deger?: string | null) =>
    deger ? { storeId: "store-1", slug: "deneme-vitrin" } : null,
  );
  mocks.verifyEditToken.mockRejectedValue(new Error("STORE_AUTH_FAILED"));
  mocks.rpc.mockReset().mockResolvedValue({ data: { allowed: true }, error: null });
  mocks.parmak.mockReset().mockResolvedValue(null);
  mocks.yukle.mockReset().mockResolvedValue(null);
  mocks.kaydet.mockReset().mockResolvedValue("islem-1");
  mocks.fetch.mockReset();
  vi.stubGlobal("fetch", mocks.fetch);
});

describe("/api/fatura-oku — tek okuma ucu", () => {
  it("tek istekte okur, preset bagina gider ve islemi kaydeder", async () => {
    cevapUcur(lunaCevabi([LUNA_SATIR]));

    const cevap = await faturaOku(istek());
    const govde = await cevap.json();

    expect(cevap.status).toBe(200);
    expect(mocks.fetch).toHaveBeenCalledTimes(1);
    expect(mocks.fetch.mock.calls[0][0]).toBe("https://openrouter.ai/api/v1/chat/completions");

    const istekGovdesi = gonderilenGovde();
    expect(istekGovdesi.model).toBe("@preset/fatura-okuma");
    expect(istekGovdesi.temperature).toBeUndefined();
    const gorsel = istekGovdesi.messages[0].content.find(
      (parca: { type: string }) => parca.type === "image_url",
    );
    expect(gorsel?.image_url?.url).toMatch(/^data:image\/png;base64,/);

    expect(mocks.kaydet).toHaveBeenCalledTimes(1);
    const kayit = mocks.kaydet.mock.calls[0][0] as unknown as {
      tedarikci: string;
      satirlar: Array<{ model: string; sonuc: string }>;
    };
    expect(kayit.tedarikci).toBe("Seher Mensucat");
    expect(kayit.satirlar[0].model).toBe("ELT1001");

    expect(govde.tamam).toBe(true);
    expect(govde.islemKimligi).toBe("islem-1");
    expect(govde.tedarikci).toBe("Seher Mensucat");
    expect(govde.belgeToplami).toBe(998);
    expect(govde.belgeNo).toBe("F-2026-001");
    expect(govde.satirlar[0].sonuc).toBe("kanitli");
    expect(govde.satirlar[0].adet).toBe(2);
    expect(govde.satirlar[0].alisBirimFiyat).toBe(499);
    expect(govde.satirlar[0].katalog.firma).toBe("Seher Mensucat");
    expect(govde.satirlar[0].katalog.kaynak).toBe("https://seher.example/elt1001");
    expect(govde.satirlar[0].katalog.resmiAd).toBe("Elit Fanila");
    expect(Array.isArray(govde.taslaklar)).toBe(true);
    expect(govde.taslaklar.length).toBe(1);
  });

  it("preset yokken model ve temperature koda gore gider", async () => {
    delete process.env.OPENROUTER_PRESET;
    cevapUcur(lunaCevabi([LUNA_SATIR]));

    const cevap = await faturaOku(istek());

    expect(cevap.status).toBe(200);
    const istekGovdesi = gonderilenGovde();
    expect(istekGovdesi.model).toBe(GORU_MODELI);
    expect(istekGovdesi.temperature).toBe(0);
  });

  it("Luna satir dondurmezse 422 doner ve islem kaydedilmez", async () => {
    cevapUcur(lunaCevabi([]));

    const cevap = await faturaOku(istek());

    expect(cevap.status).toBe(422);
    expect(mocks.kaydet).not.toHaveBeenCalled();
  });

  it("Luna bos metin dondururse anlasilir hata verir", async () => {
    cevapUcur({ choices: [{ message: { content: "" } }], usage: {} });

    const cevap = await faturaOku(istek());
    const govde = await cevap.json();

    expect(cevap.status).toBe(422);
    expect(govde.hata).toBeTruthy();
  });

  it("Luna metni cozulemezse okuma ucu 500 doner", async () => {
    cevapUcur({ choices: [{ message: { content: "bozuk metin" } }], usage: {} });

    const cevap = await faturaOku(istek());

    expect(cevap.status).toBe(500);
  });

  it("limit dolmissa okuma yapmadan 429 doner", async () => {
    mocks.rpc.mockResolvedValue({ data: [{ allowed: false, retry_after_seconds: 45 }], error: null });

    const cevap = await faturaOku(istek());
    const govde = await cevap.json();

    expect(cevap.status).toBe(429);
    expect(govde.hata).toContain("45");
    expect(mocks.fetch).not.toHaveBeenCalled();
  });

  it("oturum ve edit token yoksa 401 doner", async () => {
    mocks.get.mockReturnValue(undefined);

    const cevap = await faturaOku(istek());

    expect(cevap.status).toBe(401);
    expect(mocks.fetch).not.toHaveBeenCalled();
  });

  it("edit token ile Flutter istegi kabul edilir", async () => {
    mocks.get.mockReturnValue(undefined);
    mocks.verifyEditToken.mockResolvedValue({ slug: "deneme-vitrin" });
    cevapUcur(lunaCevabi([LUNA_SATIR]));

    const cevap = await faturaOku(istek([pngDosya()], { editToken: "duzenleme-anahtari" }));

    expect(cevap.status).toBe(200);
    expect(mocks.verifyEditToken).toHaveBeenCalledWith("deneme-vitrin", "duzenleme-anahtari");
  });

  it("bir faturaya ait 4 fotograf kabul edilmez", async () => {
    const cevap = await faturaOku(istek([pngDosya(), pngDosya(), pngDosya(), pngDosya()]));

    expect(cevap.status).toBe(413);
    expect(mocks.fetch).not.toHaveBeenCalled();
  });

  it("sayfalarin toplami 4 MB'i gecerse 413 doner", async () => {
    const buyuk = new File([Buffer.alloc(4 * 1024 * 1024 + 1)], "buyuk.png", { type: "image/png" });

    const cevap = await faturaOku(istek([buyuk]));

    expect(cevap.status).toBe(413);
    expect(mocks.fetch).not.toHaveBeenCalled();
  });

  it("gercek imzasi olmayan dosya reddedilir", async () => {
    const sahte = new File([new Uint8Array(13)], "sahte.png", { type: "image/png" });

    const cevap = await faturaOku(istek([sahte]));

    expect(cevap.status).toBe(415);
    expect(mocks.fetch).not.toHaveBeenCalled();
  });

  it("okuyucu anahtari yoksa 503 doner", async () => {
    delete process.env.OPENROUTER_API_KEY;

    const cevap = await faturaOku(istek());

    expect(cevap.status).toBe(503);
    expect(mocks.fetch).not.toHaveBeenCalled();
  });

  it("kalici islem kaydi basarili olmassa okunmus satirlar teslim edilmez", async () => {
    mocks.kaydet.mockResolvedValue(null);
    cevapUcur(lunaCevabi([LUNA_SATIR]));

    const cevap = await faturaOku(istek());

    expect(cevap.status).toBe(503);
    expect(mocks.fetch).toHaveBeenCalledTimes(1);
  });

  it("ayni fatura parmak iziyle kayitliysa yeniden okumaz", async () => {
    mocks.parmak.mockResolvedValue("eski-kimlik");
    mocks.yukle.mockResolvedValue({
      islemKimligi: "eski-kimlik",
      satirlar: [
        {
          hamSatir: "ESKI SATIR",
          model: "ESKI-1",
          ad: "Eski Kart",
          barkod: "",
          varyant: "",
          beden: "",
          marka: "",
          adet: 1,
          birim: "adet",
          alisBirimFiyat: 1,
          satirToplam: 1,
          guven: 1,
          sonuc: "kanitli",
          katalog: {
            firma: "Firma",
            kaynakFirma: "Firma",
            dayanak: "ad",
            izinDurumu: "yok",
            resmiAd: "Eski Kart",
            marka: "",
            aciklama: "Aciklama",
            gorseller: [],
            gorselAdaylari: [],
            kaynak: "https://ornek.example/1",
          },
        },
      ],
    });

    const cevap = await faturaOku(istek());
    const govde = await cevap.json();

    expect(cevap.status).toBe(200);
    expect(mocks.fetch).not.toHaveBeenCalled();
    expect(govde.satirlar[0].model).toBe("ESKI-1");
    expect(govde.taslaklar.length).toBe(1);
  });

  it("iki sayfayi ayni Luna isteginde okur", async () => {
    cevapUcur(lunaCevabi([LUNA_SATIR]));

    const cevap = await faturaOku(istek([pngDosya(), pngDosya()]));

    expect(cevap.status).toBe(200);
    expect(mocks.fetch).toHaveBeenCalledTimes(1);
    const istekGovdesi = gonderilenGovde();
    const gorseller = istekGovdesi.messages[0].content.filter(
      (parca: { type: string }) => parca.type === "image_url",
    );
    expect(gorseller).toHaveLength(2);
    expect(mocks.kaydet).toHaveBeenCalledTimes(1);
  });

  it("PDF ayni Luna okumasindan gecer", async () => {
    const pdf = new File(
      [new Uint8Array([0x25, 0x50, 0x44, 0x46, 0x2d, 0x31, 0x2e, 0x36, 0x0a, 0, 0, 0])],
      "fatura.pdf",
      { type: "application/pdf" },
    );
    cevapUcur(lunaCevabi([LUNA_SATIR]));

    const cevap = await faturaOku(istek([pdf]));

    expect(cevap.status).toBe(200);
    const istekGovdesi = gonderilenGovde();
    const gorsel = istekGovdesi.messages[0].content.find(
      (parca: { type: string }) => parca.type === "image_url",
    );
    expect(gorsel?.image_url?.url).toMatch(/^data:application\/pdf;base64,/);
  });

  it("gercek sifir ile eksik rakam karistirilmaz", async () => {
    const sifirli = { ...LUNA_SATIR, model: "SIFIR", adet: 0, birim_fiyat: 0 };
    const eksik: Record<string, unknown> = { ...LUNA_SATIR, model: "EKSIK" };
    delete eksik.adet;
    delete eksik.birim_fiyat;
    cevapUcur(lunaCevabi([sifirli, eksik]));

    const cevap = await faturaOku(istek());
    const govde = await cevap.json();

    expect(cevap.status).toBe(200);
    expect(govde.satirlar[0].adet).toBe(0);
    expect(govde.satirlar[0].alisBirimFiyat).toBe(0);
    expect(govde.satirlar[1].adet).toBeNull();
    expect(govde.satirlar[1].alisBirimFiyat).toBeNull();
  });

  it("belge toplamlari cevapta aynen doner", async () => {
    cevapUcur(lunaCevabi([LUNA_SATIR], { toplam_tutar: 1234.5, mal_bedeli: 1000, kdv_tutari: 234.5 }));

    const cevap = await faturaOku(istek());
    const govde = await cevap.json();

    expect(cevap.status).toBe(200);
    expect(govde.belgeToplami).toBe(1234.5);
    expect(govde.belgeAdedi).toBe(2);
    expect(govde.belgeTuru).toBe("fatura");
    expect(govde.tedarikciVergiNo).toBe("1234567890");
  });
});
