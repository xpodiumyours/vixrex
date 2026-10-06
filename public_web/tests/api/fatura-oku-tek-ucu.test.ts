import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

// /api/fatura-oku — Vixrex'in TEK okuma ucu. Görüntü → OpenAI gpt-5.6-luna
// → katı JSON → belge aritmetiği → katalog eşleştirme.
//
// Bu test gerçek OpenAI'ye bağlanmaz (fetch mock'lanır); zincirin kendisinin
// doğru sırayla çalıştığını ve iki kimlik yolunun da (çerez + editToken)
// kabul edildiğini kanıtlar.

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
process.env.OPENAI_API_KEY = "test-okuyucu-anahtari";

function siteyiAyiranOkuma(govde: unknown) {
  const okuma = vi.fn(async (url: string) => {
    const adres = String(url);
    if (adres.includes("api.openai.com")) return okuyucuCevabi(govde);
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

  it("fotoğrafı okuyucuya gönderir, satırı ayırır, katalogla eşleştirir", async () => {
    const cevap = await faturaOku(istek());
    const govde = await cevap.json();

    expect(cevap.status).toBe(200);
    expect(govde.satirlar).toHaveLength(1);
    expect(govde.satirlar[0].model).toBe("ELT1302");
    expect(govde.satirlar[0].adet).toBe(2);
    expect(govde.satirlar[0].alisBirimFiyat).toBe(137);
    expect(govde.satirlar[0].hamSatir).toContain("ELT1302");
    expect(govde.tedarikci).toBe("Seher Mensucat");
    expect(govde.tedarikciVergiNo).toBe("1234567890");
    expect(govde.tedarikciAdres).toBe("İstanbul");
    expect(govde.tedarikciSite).toBe("sehermensucat.com");
    const cagri = vi.mocked(fetch).mock.calls.find((satir) => String(satir[0]).includes("api.openai.com"));
    const istekGovdesi = JSON.parse(String((cagri?.[1] as RequestInit).body));
    expect(istekGovdesi.model).toBe("gpt-5.6-luna");
    expect(istekGovdesi.reasoning.effort).toBe("none");
    expect(istekGovdesi.text.format.strict).toBe(true);
    expect(istekGovdesi.input[0].content[1].detail).toBe("high");
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
    const fotografOkuma = okuma.mock.calls.filter((cagri) => String(cagri[0]).includes("api.openai.com"));
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

  it("aynı fotoğraf kayıtlıysa ikinci okuma yapılmaz", async () => {
    mocks.parmak.mockResolvedValue("eski-islem");
    mocks.yukle.mockResolvedValue({
      satirlar: [],
      belgeToplami: 10,
      belgeAdedi: 1,
      tedarikci: "Eski",
      tedarikciVergiNo: "",
      tedarikciAdres: "",
      tedarikciSite: "",
      tedarikciDijitalIz: null,
      aramaDurumu: null,
      islemKimligi: "eski-islem",
      belge: null,
    });
    const cevap = await faturaOku(istek());
    const govde = await cevap.json();
    expect(cevap.status).toBe(200);
    expect(govde.tekrar).toBe(true);
    expect(vi.mocked(fetch)).not.toHaveBeenCalled();
    expect(mocks.kullanimYaz).not.toHaveBeenCalled();
  });

  it("günlük tavan dolunca okuma yapılmaz", async () => {
    mocks.harcama = [{ cost_usd: 1 }];
    const cevap = await faturaOku(istek());
    expect(cevap.status).toBe(503);
    expect((await cevap.json()).hata).toContain("sınır");
    expect(vi.mocked(fetch)).not.toHaveBeenCalled();
    expect(mocks.kaydet).not.toHaveBeenCalled();
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
