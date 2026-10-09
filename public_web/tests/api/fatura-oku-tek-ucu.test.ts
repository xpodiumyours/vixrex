import { NextRequest } from "next/server";
import sharp from "sharp";
import { beforeEach, describe, expect, it, vi } from "vitest";

vi.mock("node:dns/promises", () => ({
  resolve4: async () => ["8.8.8.8"],
  resolve6: async () => [],
}));

// Tek fatura okuma ucu: OpenRouter görsel okuma → belge doğrulama →
// OpenRouter kaynak arama/okuma → mevcut ürün taslağı.
// Dış API cevapları mock ile sağlanır; gerçek kaynak doğruluğu ayrıca ölçülür.

const mocks = vi.hoisted(() => ({
  get: vi.fn((): string | undefined => "owner-cookie"),
  admin: vi.fn(),
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
  parmak: vi.fn(async (): Promise<string | null> => null),
  harcama: [] as Array<{ cost_usd: number }>,
  kullanimYaz: vi.fn(async () => ({ error: null as { message: string } | null })),
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
    from: (tablo: string) => {
      if (tablo === "invoice_read_usage") {
        return {
          select: () => ({
            eq: () => ({
              gte: async () => ({ data: mocks.harcama, error: null }),
            }),
          }),
          insert: mocks.kullanimYaz,
        };
      }
      return {
        select: () => ({
          eq: () => ({
            maybeSingle: async () => ({ data: { id: "store-1" }, error: null }),
          }),
        }),
      };
    },
  }),
}));

vi.mock("@/lib/faturaIslemKaydi", async (importOriginal) => ({
  ...await importOriginal<typeof import("@/lib/faturaIslemKaydi")>(),
  islemKaydet: mocks.kaydet,
  ayniAlisverisAdaylari: async () => [],
}));

vi.mock("@/lib/faturaIslemOku", async (importOriginal) => ({
  ...await importOriginal<typeof import("@/lib/faturaIslemOku")>(),
  islemiYukle: mocks.yukle,
  parmakIzindenIslemBul: mocks.parmak,
}));

import { POST as faturaOku } from "@/app/api/fatura-oku/route";

// Gerçek fatura formatındaki 1x1 PNG (gerçek dosya-türü kontrolünü geçmesi
// için doğru PNG imzasıyla).
const PNG_BASE64 =
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=";

function pngDosyasi(): File {
  const bayt = Buffer.from(PNG_BASE64, "base64");
  return new File([bayt], "fatura.png", { type: "image/png" });
}

function istek(args: { slug?: string; editToken?: string; dosyaVarMi?: boolean } = {}) {
  const form = new FormData();
  form.set("slug", args.slug ?? "deneme-vitrin");
  if (args.editToken) form.set("editToken", args.editToken);
  if (args.dosyaVarMi !== false) form.set("dosya", pngDosyasi());
  return new NextRequest("http://localhost/api/fatura-oku", { method: "POST", body: form });
}

process.env.SUPABASE_URL = "https://proje.supabase.co";
process.env.SUPABASE_SERVICE_ROLE_KEY = "service-role-test-anahtari";
process.env.OPENROUTER_API_KEY = "test-okuyucu-anahtari";
delete process.env.OPENAI_API_KEY;

function siteyiAyiranOkuma(govde: unknown) {
  const okuma = vi.fn(async (url: string) => {
    const adres = String(url);
    if (adres.includes("openrouter.ai/api/v1/responses")) return okuyucuCevabi(govde);
    if (adres.includes("sehermensucat.com")) {
      return new Response(
        "<html><head><title>Seher Mensucat</title></head><body>Seher Mensucat 1234567890 İstanbul</body></html>",
        { status: 200, headers: { "content-type": "text/html" } },
      );
    }
    return new Response("{}", { status: 404 });
  });
  return okuma;
}

/** Okuyucunun döndüğü yapılandırılmış cevabı taklit eder. */
function okuyucuCevabi(govde: unknown) {
  return new Response(
    JSON.stringify({
      output_text: JSON.stringify(govde),
      usage: {
        input_tokens: 1200,
        output_tokens: 400,
        input_tokens_details: { cached_tokens: 0 },
        output_tokens_details: { reasoning_tokens: 0 },
      },
    }),
    { status: 200 },
  );
}

const TEK_SATIR = {
  tedarikci: "Seher Mensucat",
  tedarikci_vergi_no: "1234567890",
  tedarikci_adres: "İstanbul",
  tedarikci_site: "sehermensucat.com",
  satirlar: [
    {
      ham_satir: "ELT1302 Elit Erkek Elastan Sıfır Yaka 8681128321677 Siyah L 2 137,00 274,00",
      model: "ELT1302",
      ad: "Elit Erkek Elastan Sıfır Yaka",
      barkod: "8681128321677",
      varyant: "Siyah",
      beden: "L",
      adet: 2,
      birim: "Adet",
      birim_fiyat: 137,
      tutar: 274,
    },
  ],
  toplam_adet: 2,
  toplam_tutar: 274,
};

describe("/api/fatura-oku — tek okuma ucu", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.kalici = null;
    mocks.yukle.mockImplementation(async () => mocks.kalici);
    mocks.kaydet.mockImplementation(async (girdi) => {
      mocks.kalici = { ...girdi, islemKimligi: "11111111-1111-4111-8111-111111111111", durum: "hazir", belge: girdi, tedarikciDijitalIz: girdi.tedarikciIz };
      return "11111111-1111-4111-8111-111111111111";
    });
    mocks.get.mockReturnValue("owner-cookie");
    mocks.verifyOwner.mockReturnValue({ storeId: "store-1", slug: "deneme-vitrin" });
    mocks.rpc.mockResolvedValue({ data: { allowed: true }, error: null });
    mocks.parmak.mockResolvedValue(null);
    mocks.harcama = [];
    mocks.kullanimYaz.mockResolvedValue({ error: null });
    vi.stubGlobal("fetch", siteyiAyiranOkuma(TEK_SATIR));
  });

  it("fotoğrafı okuyucuya gönderir, satırı ayırır, site alanı yoksa kart kurmaz", async () => {
    const cevap = await faturaOku(istek());
    const govde = await cevap.json();

    expect(cevap.status).toBe(200);
    expect(govde.satirlar).toHaveLength(1);
    expect(govde.satirlar[0].model).toBe("ELT1302");
    expect(govde.satirlar[0].adet).toBe(2);
    expect(govde.satirlar[0].birim).toBe("Adet");
    expect(govde.satirlar[0].alisBirimFiyat).toBe(137);
    expect(govde.satirlar[0].hamSatir).toContain("ELT1302");
    expect(govde.tedarikci).toBe("Seher Mensucat");
    expect(govde.tedarikciVergiNo).toBe("1234567890");
    expect(govde.tedarikciAdres).toBe("İstanbul");
    expect(govde.tedarikciSite).toBe("sehermensucat.com");
    expect(govde.satirlar[0].katalog).toBeNull();
    expect(govde.satirlar[0].sonuc).toBe("eksik");
    const cagri = vi.mocked(fetch).mock.calls.find((satir) => String(satir[0]).includes("openrouter.ai/api/v1/responses"));
    const istekGovdesi = JSON.parse(String((cagri?.[1] as RequestInit).body));
    expect(istekGovdesi.model).toBe("openai/gpt-5.6-luna");
    expect(istekGovdesi.reasoning.effort).toBe("none");
    expect(istekGovdesi.provider.require_parameters).toBe(true);
    expect(istekGovdesi.text.format.strict).toBe(true);
    expect(istekGovdesi.text.format.schema.properties.tedarikci.description).toMatch(/Supplier name/);
    expect(istekGovdesi.text.format.schema.properties.satirlar.items.required).toContain("birim");
    expect(istekGovdesi.text.format.schema.properties.satirlar.items.properties.ad.description).toMatch(/Product name/);
    expect(istekGovdesi.text.format.schema.properties.satirlar.items.properties.birim.description).toMatch(/Measure unit/);
    expect(istekGovdesi.input[0].content[1].detail).toBe("original");
    expect(istekGovdesi.tools).toBeUndefined();
    expect(istekGovdesi.include).toBeUndefined();
    const soru = String(istekGovdesi.input[0].content[0].text);
    expect(soru).not.toContain("asil urun fotografi");
    expect(soru).toContain("baska yerden tamamlama");
    const okumaCagrilari = vi.mocked(fetch).mock.calls.filter((satir) => String(satir[0]).includes("openrouter.ai/api/v1/responses"));
    expect(okumaCagrilari).toHaveLength(2);
    const arama = JSON.parse(String((okumaCagrilari[1]?.[1] as RequestInit).body));
    expect(arama.model).toBe("openai/gpt-5.6-luna");
    expect(arama.reasoning.effort).toBe("low");
    expect(arama.max_tool_calls).toBe(4);
    expect(arama.tools.map((arac: { type: string }) => arac.type)).toEqual([
      "openrouter:web_search", "openrouter:web_fetch",
    ]);
    expect(arama.tools[0].parameters.allowed_domains).toEqual(["sehermensucat.com"]);
    expect(arama.tools[1].parameters.allowed_domains).toEqual(["sehermensucat.com"]);
    expect(arama.text.format.strict).toBe(true);
  });

  it("modelin yazdığı fotoğraf adresi kart kurmaz", async () => {
    vi.stubGlobal("fetch", siteyiAyiranOkuma({
      ...TEK_SATIR,
      satirlar: [{
        ...TEK_SATIR.satirlar[0],
        model: "ELT1001",
        ad: "Faturadaki fanila",
        urun_aciklama: "Sitede yazan açıklama",
        urun_gorsel: "https://firma.example/urun.jpg",
        urun_sayfa: "https://firma.example/urun",
      }],
    }));

    const cevap = await faturaOku(istek());
    const govde = await cevap.json();

    expect(cevap.status).toBe(200);
    expect(govde.satirlar[0].sonuc).toBe("eksik");
    expect(govde.satirlar[0].katalog).toBeNull();
  });

  it("firmanın sayfasındaki fotoğraf ve açıklama kartı kurar", async () => {
    const gurultu = Buffer.alloc(1200 * 1200 * 3);
    for (let i = 0; i < gurultu.length; i += 97) gurultu[i] = (i * 13) % 251;
    const foto = await sharp(gurultu, { raw: { width: 1200, height: 1200, channels: 3 } }).jpeg({ quality: 80 }).toBuffer();
    const sayfa = "https://sehermensucat.com/elt1302";
    const gorsel = "https://cdn.sehermensucat.com/elt1302.jpg";
    vi.stubGlobal("fetch", vi.fn(async (url: string, init?: RequestInit) => {
      const adres = String(url);
      if (adres.includes("openrouter.ai/api/v1/responses")) {
        const istekGovdesi = JSON.parse(String(init?.body ?? "{}"));
        if (istekGovdesi.tools) {
          return new Response(JSON.stringify({
            status: "completed",
            output_text: JSON.stringify({
              eslesti: true,
              urun_adi: "Elit Erkek Elastan Sıfır Yaka",
              aciklama: "ELT1302 erkek elastan fanila",
              kaynak_sayfa: sayfa,
              gorsel_adresi: gorsel,
              kanit: "ELT1302 8681128321677 Siyah L",
              eslesme_dayanagi: "kod",
            }),
            usage: {
              input_tokens: 100,
              output_tokens: 20,
              input_tokens_details: { cached_tokens: 0 },
              output_tokens_details: { reasoning_tokens: 0 },
              server_tool_use: { web_fetch_requests: 1 },
            },
          }), { status: 200 });
        }
        return okuyucuCevabi(TEK_SATIR);
      }
      if (adres === gorsel) return new Response(new Uint8Array(foto), { status: 200 });
      return new Response("{}", { status: 404 });
    }));

    const cevap = await faturaOku(istek());
    const govde = await cevap.json();

    expect(cevap.status).toBe(200);
    expect(govde.satirlar[0].sonuc).toBe("kanitli");
    expect(govde.satirlar[0].ad).toBe("Elit Erkek Elastan Sıfır Yaka");
    expect(govde.satirlar[0].katalog.aciklama).toBe("ELT1302 erkek elastan fanila");
    expect(govde.satirlar[0].katalog.gorseller).toEqual([gorsel]);
    expect(govde.satirlar[0].katalog.kaynak).toBe(sayfa);
  });

  it("model ve barkod yoksa ürün adı bulunan satırı kaybetmez", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () =>
        okuyucuCevabi({
          tedarikci: "Örnek Toptan",
          satirlar: [
            {
              ham_satir: "500 g Süzme Peynir 3 AD 80,00 240,00",
              model: "",
              ad: "500 g Süzme Peynir",
              barkod: "",
              varyant: "",
              beden: "",
              adet: 3,
              birim: "AD",
              birim_fiyat: 80,
              tutar: 240,
            },
          ],
          toplam_adet: 3,
          toplam_tutar: 240,
        }),
      ),
    );

    const cevap = await faturaOku(istek());
    const govde = await cevap.json();

    expect(cevap.status).toBe(200);
    expect(govde.satirlar).toHaveLength(1);
    expect(govde.satirlar[0].ad).toBe("500 g Süzme Peynir");
    expect(govde.satirlar[0].birim).toBe("AD");
    expect(govde.satirlar[0].model).toBe("");
    expect(govde.satirlar[0].barkod).toBe("");
    expect(govde.satirlar[0].katalog).toBeNull();
  });

  it("çerez yoksa ama editToken geçerliyse Flutter isteği de kabul edilir", async () => {
    mocks.verifyOwner.mockReturnValue(null);
    mocks.verifyEditToken.mockResolvedValue({ slug: "deneme-vitrin" });

    const cevap = await faturaOku(istek({ editToken: "gecerli-token" }));
    expect(cevap.status).toBe(200);
  });

  it("çerez de editToken de yoksa reddeder", async () => {
    mocks.verifyOwner.mockReturnValue(null);
    const cevap = await faturaOku(istek());
    expect(cevap.status).toBe(401);
  });

  it("okuma ucu boş yazı dönerse anlaşılır hata verir", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => new Response(JSON.stringify({ tamam: true, yazi: "" }), { status: 200 })),
    );
    const cevap = await faturaOku(istek());
    expect(cevap.status).toBe(422);
  });

  it("dosya PNG/JPG/WebP değilse reddeder", async () => {
    const form = new FormData();
    form.set("slug", "deneme-vitrin");
    form.set("dosya", new File([Buffer.from("gecersiz-icerik")], "x.txt", { type: "text/plain" }));
    const cevap = await faturaOku(new NextRequest("http://localhost/api/fatura-oku", { method: "POST", body: form }));
    expect(cevap.status).toBe(415);
  });

  it("hız sınırı aşılınca 429 döner", async () => {
    mocks.rpc.mockResolvedValue({ data: { allowed: false, retry_after_seconds: 30 }, error: null });
    const cevap = await faturaOku(istek());
    expect(cevap.status).toBe(429);
  });

  it("belge toplamı tutmuyorsa vitrine yazılmaz", async () => {
    const okuma = siteyiAyiranOkuma({ ...TEK_SATIR, toplam_adet: 75, toplam_tutar: 6034 });
    vi.stubGlobal("fetch", okuma);

    const cevap = await faturaOku(istek());
    const govde = await cevap.json();

    expect(cevap.status).toBe(422);
    expect(govde.hata).toContain("Fotoğraf tutmadı");
    expect(mocks.kaydet).not.toHaveBeenCalled();
    const fotografOkuma = okuma.mock.calls.filter((cagri) => String(cagri[0]).includes("openrouter.ai/api/v1/responses"));
    expect(fotografOkuma).toHaveLength(1);
  });

  it("belge toplamı tutuyorsa belge gerçeği cevapta döner", async () => {
    const cevap = await faturaOku(istek());
    const govde = await cevap.json();

    expect(cevap.status).toBe(200);
    expect(govde.belgeAdedi).toBe(2);
    expect(govde.belgeToplami).toBe(274);
  });
  it("kalıcı işlem kaydı başarısızsa okunmuş satırlar başarılı teslim sayılmaz", async () => {
    mocks.kaydet.mockResolvedValue(null);
    const cevap = await faturaOku(istek());
    expect(cevap.status).toBe(503);
    expect(mocks.kaydet).toHaveBeenCalledOnce();
    expect((await cevap.json()).hata).toBeTruthy();
  });

  it("kaydedilen canonical satır yeni okumadan farklıysa kaydedileni döndürür", async () => {
    mocks.yukle.mockImplementation(async () => ({ ...mocks.kalici, satirlar: [{ ...(mocks.kalici?.satirlar as Record<string, unknown>[])[0], model: "KALICI-MODEL", urunId: "urun-kalici" }] }));
    const cevap = await faturaOku(istek());
    const govde = await cevap.json();
    expect(cevap.status).toBe(200);
    expect(govde.satirlar[0].model).toBe("KALICI-MODEL");
    expect(govde.satirlar[0].urunId).toBe("urun-kalici");
    expect(mocks.yukle).toHaveBeenCalledWith(expect.anything(), "store-1", "11111111-1111-4111-8111-111111111111");
  });

  it("aynı fotoğraf kayıtlı olsa da yeniden okunur", async () => {
    mocks.parmak.mockResolvedValue("eski-islem");
    const cevap = await faturaOku(istek());
    expect(cevap.status).toBe(200);
    expect(vi.mocked(fetch)).toHaveBeenCalled();
  });

  it("günlük harcama dolu olsa da fotoğraf okunur", async () => {
    mocks.harcama = [{ cost_usd: 1 }];
    const cevap = await faturaOku(istek());
    expect(cevap.status).toBe(200);
    expect(vi.mocked(fetch)).toHaveBeenCalled();
  });

  it("maliyet yazılamazsa işlem kaydı açılmaz", async () => {
    mocks.kullanimYaz.mockResolvedValue({ error: { message: "yazılamadı" } });
    const cevap = await faturaOku(istek());
    expect(cevap.status).toBe(503);
    expect(mocks.kaydet).not.toHaveBeenCalled();
  });

  it("kalıcı kayıt yeniden okunamazsa başarılı teslim sayılmaz", async () => {
    mocks.yukle.mockResolvedValue(null);
    const cevap = await faturaOku(istek());
    expect(cevap.status).toBe(503);
    expect((await cevap.json()).hata).toContain("tekrar açılamadı");
  });

});
