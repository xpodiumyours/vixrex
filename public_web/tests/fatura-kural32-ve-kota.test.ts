import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { NextRequest } from "next/server";
import { deflateSync } from "node:zlib";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { SupabaseClient } from "@supabase/supabase-js";

const mocks = vi.hoisted(() => ({
  islemKaydet: vi.fn(),
  admin: vi.fn(),
  rpc: vi.fn(),
  cookies: vi.fn(),
  verifyOwnerSession: vi.fn(),
  ownerSessionStillActive: vi.fn(),
  verifyStoreEditToken: vi.fn(),
  faturayiArkaPlanaGonder: vi.fn(),
  stateIndex: 0,
  stateValues: {} as Record<number, unknown>,
}));

vi.mock("@/lib/faturaIslemKaydi", async (original) => ({
  ...(await original<typeof import("@/lib/faturaIslemKaydi")>()),
  islemKaydet: mocks.islemKaydet,
}));

vi.mock("@/lib/supabaseAdmin", () => ({
  getSupabaseAdmin: mocks.admin,
}));

vi.mock("next/headers", () => ({
  cookies: mocks.cookies,
}));

vi.mock("@/lib/ownerSession", async (original) => ({
  ...(await original<typeof import("@/lib/ownerSession")>()),
  verifyOwnerSession: mocks.verifyOwnerSession,
}));

vi.mock("@/lib/ownerSessionValidity", () => ({
  ownerSessionStillActive: mocks.ownerSessionStillActive,
}));

vi.mock("@/lib/instagramServer", () => ({
  verifyStoreEditToken: mocks.verifyStoreEditToken,
}));

vi.mock("@/lib/faturaArkaPlanIslemi", async (original) => {
  const gercek = await original<typeof import("@/lib/faturaArkaPlanIslemi")>();
  return {
    ...gercek,
    faturayiArkaPlanaGonder: mocks.faturayiArkaPlanaGonder,
  };
});

vi.mock("react", async (importOriginal) => {
  const actual = await importOriginal<typeof import("react")>();
  return {
    ...actual,
    useState(initial: unknown) {
      const idx = mocks.stateIndex++;
      return actual.useState(Object.hasOwn(mocks.stateValues, idx) ? mocks.stateValues[idx] : initial);
    },
  };
});

import {
  kural32MetinTemizle,
  kural32NesneTemizle,
  resmiUrunSayfasiGroundingIleBul,
} from "@/lib/faturaUrunHazirlama";
import { arkaPlanFaturaSonucunuAl } from "@/lib/faturaArkaPlanIslemi";
import { islemYaniti, islemiYukle } from "@/lib/faturaIslemOku";
import InvoiceToProducts from "@/components/owner/InvoiceToProducts";
import { POST as faturaOkuPost } from "@/app/api/fatura-oku/route";

const ISLEM_ID = "33333333-3333-4333-8333-333333333333";

function sahtePdf(sayfaSayisi: number, sikistirilmisObjStm = false): Uint8Array {
  const sayfalar = Array.from({ length: sayfaSayisi }, (_, i) => `${i + 10} 0 obj << /Type /Page >> endobj`).join("\n");
  if (!sikistirilmisObjStm) {
    const icerik = `%PDF-1.4\n1 0 obj << /Type /Pages /Count ${sayfaSayisi} >> endobj\n${sayfalar}\n%%EOF`;
    return new Uint8Array(Buffer.from(icerik, "latin1"));
  }
  const akisVerisi = deflateSync(Buffer.from(`<< /Type /Pages /Count ${sayfaSayisi} >>\n${sayfalar}`, "latin1"));
  const bas = Buffer.from("%PDF-1.5\n1 0 obj << /Type /ObjStm /Length 100 >> stream\n", "latin1");
  const son = Buffer.from("\nendstream\nendobj\n%%EOF", "latin1");
  return new Uint8Array(Buffer.concat([bas, akisVerisi, son]));
}

afterEach(() => {
  vi.unstubAllEnvs();
  vi.clearAllMocks();
});

describe("Kural 32 ticari sır zırhı (A2) ve alış fiyatı koruması", () => {
  it("kural32MetinTemizle IBAN, ETTN/UUID, VKN/TCKN ve açık iskonto/vade ibarelerini temizler", () => {
    const temiz = kural32MetinTemizle(
      "Mavi Jean TR33 0006 1005 1978 6457 8413 26 TR330006100519786457841326 550e8400-e29b-41d4-a716-446655440000 1234567890 %15 iskonto İskonto: 120 TL 60 gün vade Vade: 45 gün Alış fiyatı 120 TL",
    );
    expect(temiz).toBe("Mavi Jean Alış fiyatı 120 TL");
    expect(temiz).not.toContain("TR33");
    expect(temiz).not.toContain("550e8400");
    expect(temiz).not.toContain("1234567890");
    expect(temiz.toLocaleLowerCase("tr-TR")).not.toContain("iskonto");
    expect(temiz.toLocaleLowerCase("tr-TR")).not.toContain("vade");
  });

  it("kural32NesneTemizle yeni ticari sır anahtarlarını siler ve unit_price/birimFiyat/alisFiyati alanlarını korur", () => {
    const temiz = kural32NesneTemizle({
      ad: "Bebek Tulum",
      supplier_name: "Gizli Toptancı",
      supplier_address: "Merter Mah. No:12",
      tedarikci: "Gizli Toptancı",
      tedarikci_adres: "İstanbul",
      vade: "60 gün",
      tevkifat: "5/10",
      dipnot: "Özel vade anlaşması",
      cari_kodu: "CR-102",
      musteri_no: "M-88",
      irsaliye: "IRS-901",
      vergi_dairesi: "Güngören VD",
      seri_no: "A01",
      unit_price: 215,
      birimFiyat: 215,
      alisFiyati: 215,
      alisBirimFiyat: 215,
    });

    expect(temiz.ad).toBe("Bebek Tulum");
    expect(temiz.unit_price).toBe(215);
    expect(temiz.birimFiyat).toBe(215);
    expect(temiz.alisFiyati).toBe(215);
    expect(temiz.alisBirimFiyat).toBe(215);
    for (const yasakli of [
      "supplier_name",
      "supplier_address",
      "tedarikci",
      "tedarikci_adres",
      "vade",
      "tevkifat",
      "dipnot",
      "cari_kodu",
      "musteri_no",
      "irsaliye",
      "vergi_dairesi",
      "seri_no",
    ]) {
      expect(temiz).not.toHaveProperty(yasakli);
    }
  });

  it("resmiUrunSayfasiGroundingIleBul API anahtarını URL yerine x-goog-api-key başlığında gönderir", async () => {
    vi.stubEnv("GEMINI_API_KEY", "AIzaSyGroundingHeaderKey");
    let yakalananUrl = "";
    let yakalananHeaders: Record<string, string> = {};
    const fetcher = vi.fn(async (url, init) => {
      yakalananUrl = String(url);
      yakalananHeaders = (init?.headers ?? {}) as Record<string, string>;
      return {
        ok: true,
        json: async () => ({
          candidates: [
            {
              content: {
                parts: [
                  {
                    text: JSON.stringify({
                      official_domain: "vestel.com.tr",
                      official_product_url: "https://www.vestel.com.tr/tv",
                      official_name: "Vestel TV",
                      image_urls: ["https://www.vestel.com.tr/tv.jpg"],
                    }),
                  },
                ],
              },
            },
          ],
        }),
      };
    }) as unknown as typeof fetch;

    const sonuc = await resmiUrunSayfasiGroundingIleBul({ urunAdi: "Vestel TV" }, fetcher);
    expect(sonuc).not.toBeNull();
    expect(yakalananUrl).toBe(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent",
    );
    expect(yakalananUrl).not.toContain("key=");
    expect(yakalananHeaders["x-goog-api-key"]).toBe("AIzaSyGroundingHeaderKey");
  });

  it("OpenRouter yedek hattı islemKaydet çağrısında 4 sütunlu ticari sırları boş/null kaydeder ve birimFiyat korur", async () => {
    vi.stubEnv("PRESET_AKIS", "yeni");
    mocks.islemKaydet.mockResolvedValue(ISLEM_ID);

    const admin = {
      rpc: vi.fn(async (fn: string) => {
        if (fn === "get_invoice_provider_response") {
          return {
            data: {
              state: "received",
              stage: "cards",
              httpStatus: 200,
              contentType: "application/json",
              fingerprint: "fp-1",
              readResult: {
                tedarikci: "Gizli Toptancı A.Ş.",
                tedarikciVergiNo: "1234567890",
                tedarikciAdres: "Merter Tekstil Merkezi",
                tedarikciSite: "https://mavi.com",
                belgeTuru: "e-fatura",
                belgeNo: "GIB2026000012345",
                belgeTarihi: "2026-11-19",
                malBedeli: 1000,
                kdvTutari: 100,
                indirimTutari: 150,
                odenecekToplam: 950,
                belgeEkleri: { iban: "TR330006100519786457841326", ettn: "550e8400-e29b-41d4-a716-446655440000" },
                belgeAdedi: 2,
                belgeToplami: 1000,
                satirlar: [
                  {
                    satirNo: 1,
                    hamSatir: "MAVI JEAN 2 ADET 500",
                    model: "004222",
                    ad: "Mavi Jean",
                    barkod: "8691234567890",
                    varyant: "SYH",
                    beden: "M",
                    marka: "Mavi",
                    adet: 2,
                    birim: "adet",
                    birimFiyat: 500,
                    tutar: 1000,
                    okumaGuveni: 0.98,
                  },
                ],
              },
              body: JSON.stringify({
                choices: [
                  {
                    finish_reason: "stop",
                    message: {
                      content: JSON.stringify({
                        items: [
                          {
                            row_id: "1",
                            vixrex_product_json: {
                              title: "Mavi Jake Jean",
                              brand: "Mavi",
                              category_suggestion: "Pantolon",
                              variant: "SYH",
                              short_description: "Denim pantolon",
                            },
                            validation: {
                              status: "verified",
                              official_domain: "mavi.com",
                              official_product_url: "https://www.mavi.com/jake",
                            },
                            media: {
                              selected_image_url: "https://img-mavi.akinoncdn.com/products/jake.jpg",
                              image_urls: ["https://img-mavi.akinoncdn.com/products/jake.jpg"],
                            },
                            sources: [{ url: "https://www.mavi.com/jake" }],
                          },
                        ],
                      }),
                    },
                  },
                ],
              }),
            },
            error: null,
          };
        }
        return { data: null, error: null };
      }),
      from: (tablo: string) => {
        const z: Record<string, unknown> = {};
        z.select = () => z;
        z.eq = () => z;
        z.in = () => z;
        z.order = () => z;
        z.update = () => z;
        z.is = () => z;
        z.maybeSingle = async () => {
          if (tablo === "invoice_jobs") {
            return {
              data: {
                id: ISLEM_ID,
                status: "inceleme",
                supplier_name: "",
                supplier_tax_id: "",
                supplier_address: "",
                supplier_site: "https://mavi.com",
                supplier_trace: null,
                document_adet: 2,
                document_total: 1000,
                document_warning: "",
                document_type: "e-fatura",
                document_no: "",
                document_date: null,
                goods_total: 1000,
                vat_total: 100,
                discount_total: null,
                payable_total: 950,
                same_purchase_of: null,
              },
              error: null,
            };
          }
          if (tablo === "stores") {
            return { data: { id: "store-1", edit_token: "et-1", name: "Test Mağaza" }, error: null };
          }
          return { data: null, error: null };
        };
        z.then = (basari: never, alici: never) => {
          if (tablo === "invoice_job_lines") {
            return Promise.resolve({
              data: [
                {
                  id: "satir-1",
                  line_index: 0,
                  raw_line: "MAVI JEAN",
                  model: "004222",
                  product_name: "Mavi Jake Jean",
                  barcode: "8691234567890",
                  variant_name: "SYH",
                  size_text: "M",
                  brand: "Mavi",
                  qty: 2,
                  qty_unit: "adet",
                  unit_price: 500,
                  line_total: 1000,
                  confidence: 0.98,
                  outcome: "kanitli",
                  catalog_snapshot: {},
                  owner_state: {
                    satisFiyati: "900",
                    stok: "2",
                    stokOnaylandi: true,
                    kategoriId: "",
                    onayli: false,
                    esnafGorselleri: [],
                  },
                  product_id: "urun-1",
                },
              ],
              error: null,
            }).then(basari, alici);
          }
          if (tablo === "products") {
            return Promise.resolve({ data: [{ id: "urun-1", is_visible: false, fatura_kanit: {}, image_urls: [] }], error: null }).then(basari, alici);
          }
          return Promise.resolve({ data: [], error: null }).then(basari, alici);
        };
        return z;
      },
    } as unknown as SupabaseClient;

    await arkaPlanFaturaSonucunuAl(admin, "store-1", "test-magaza", ISLEM_ID);

    expect(mocks.islemKaydet).toHaveBeenCalledTimes(1);
    const kaydedilen = mocks.islemKaydet.mock.calls[0][0];
    expect(kaydedilen.tedarikci).toBe("");
    expect(kaydedilen.tedarikciVergiNo).toBe("");
    expect(kaydedilen.tedarikciAdres).toBe("");
    expect(kaydedilen.belgeNo).toBe("");
    expect(kaydedilen.belgeTarihi).toBe("");
    expect(kaydedilen.indirimTutari).toBeNull();
    expect(kaydedilen.aramaDurumu.presetCevabi.belgeEkleri).toEqual({});
    expect(kaydedilen.satirlar[0].alisBirimFiyat).toBe(500);
    expect(kaydedilen.satirlar[0].katalog.firma).toBe("");
  });

  it("islemiYukle ve islemYaniti eski DB kaydındaki ticari sırları sıfırlar, alisBirimFiyat değerini korur", async () => {
    const admin = {
      from: (tablo: string) => {
        const z: Record<string, unknown> = {};
        z.select = () => z;
        z.eq = () => z;
        z.in = () => z;
        z.order = () => z;
        z.maybeSingle = async () =>
          tablo === "invoice_jobs"
            ? {
                data: {
                  id: ISLEM_ID,
                  status: "inceleme",
                  supplier_name: "Gizli Toptancı A.Ş.",
                  supplier_tax_id: "9988776655",
                  supplier_address: "Merter Sokak No 5",
                  supplier_site: "https://mavi.com",
                  supplier_trace: { ip: "1.2.3.4" },
                  document_adet: 2,
                  document_total: 1000,
                  document_warning: null,
                  document_type: "e-arsiv",
                  document_no: "GIB20269999",
                  document_date: "2026-11-18",
                  goods_total: 1000,
                  vat_total: 100,
                  discount_total: 150,
                  payable_total: 950,
                  discovery_state: {
                    sinirDoldu: false,
                    presetCevabi: {
                      belgeEkleri: { iban: "TR330006100519786457841326", vade: "60 gün" },
                      gruplar: [],
                      uyarilar: [],
                    },
                  },
                },
                error: null,
              }
            : { data: null, error: null };
        z.then = (basari: never, alici: never) =>
          Promise.resolve({
            data:
              tablo === "invoice_job_lines"
                ? [
                    {
                      id: "satir-1",
                      line_index: 0,
                      raw_line: "MAVI JEAN",
                      model: "004222",
                      product_name: "Mavi Jake Jean",
                      barcode: "8691234567890",
                      variant_name: "SYH",
                      size_text: "M",
                      brand: "Mavi",
                      qty: 2,
                      qty_unit: "adet",
                      unit_price: 425.75,
                      line_total: 851.5,
                      confidence: 0.95,
                      outcome: "kanitli",
                      catalog_snapshot: null,
                      conflict_snapshot: null,
                      owner_state: null,
                      product_id: null,
                    },
                  ]
                : [],
            error: null,
          }).then(basari, alici);
        return z;
      },
    } as unknown as SupabaseClient;

    const yuklenen = await islemiYukle(admin, "store-1", ISLEM_ID);
    expect(yuklenen).not.toBeNull();
    expect(yuklenen?.tedarikci).toBe("");
    expect(yuklenen?.tedarikciVergiNo).toBe("");
    expect(yuklenen?.tedarikciAdres).toBe("");
    expect(yuklenen?.tedarikciDijitalIz).toBeNull();
    expect(yuklenen?.belge.belgeNo).toBe("");
    expect(yuklenen?.belge.belgeTarihi).toBeNull();
    expect(yuklenen?.belge.indirimTutari).toBeNull();
    expect(yuklenen?.satirlar[0].alisBirimFiyat).toBe(425.75);

    const yanit = islemYaniti(yuklenen!);
    expect(yanit.tedarikci).toBe("");
    expect(yanit.tedarikciVergiNo).toBe("");
    expect(yanit.tedarikciAdres).toBe("");
    expect(yanit.tedarikciDijitalIz).toBeNull();
    expect(yanit.belgeEkleri).toEqual({});
    expect(yanit.belge).toMatchObject({
      belgeNo: "",
      belgeTarihi: null,
      indirimTutari: null,
    });
    expect((yanit.satirlar as Array<{ alisBirimFiyat: number }>)[0].alisBirimFiyat).toBe(425.75);
  });

  it("InvoiceToProducts urunler ekranında toptancı VKN/adres/unvan bilgisini göstermez", () => {
    mocks.stateIndex = 0;
    const satir = {
      satirId: "satir-1",
      hamSatir: "MAVI JEAN",
      model: "004222",
      ad: "Mavi Jean",
      barkod: "8691234567890",
      varyant: "SYH",
      beden: "M",
      marka: "Mavi",
      adet: 2,
      birim: "adet",
      alisBirimFiyat: 425,
      satirToplam: 850,
      guven: 0.95,
      katalog: null,
      sonuc: "kanitli" as const,
      satisFiyati: "699",
      stok: "2",
      stokOnaylandi: true,
      kategoriId: "",
      onayli: false,
      seciliGorseller: [],
      yeniGorselUrl: "",
      esnafGorselleri: [],
      acik: false,
      urunId: null,
      birlestirmeAdayi: null,
      birlestirmeKarari: null,
    };
    mocks.stateValues = {
      0: "urunler",
      2: {
        satirlar: [satir],
        belgeAdedi: 2,
        belgeToplami: 850,
        tedarikci: "GİZLİ TOPTANCI LİMİTED",
        tedarikciVergiNo: "9876543210",
        tedarikciAdres: "GİZLİ ADRES CADDESİ NO:99",
      },
      3: [satir],
    };

    const html = renderToStaticMarkup(
      createElement(InvoiceToProducts, {
        storeSlug: "test-vitrin",
        onUploaded: async () => {},
      }),
    );

    expect(html).not.toContain("9876543210");
    expect(html).not.toContain("GİZLİ ADRES CADDESİ NO:99");
    expect(html).not.toContain("Vergi no:");
    expect(html).not.toContain("Adres:");
    expect(html).not.toContain("Firma: GİZLİ TOPTANCI LİMİTED");
    expect(html).toContain("Belgede toplam miktar: 2");
  });
});

describe("fatura-oku PDF sayfa sınırı (B1)", () => {
  beforeEach(() => {
    vi.stubEnv("GEMINI_API_KEY", "AIzaSyPdfTestKey");
    mocks.cookies.mockResolvedValue({ get: () => ({ value: "session-cookie" }) });
    mocks.verifyOwnerSession.mockReturnValue({ slug: "ornek-vitrin" });
    mocks.ownerSessionStillActive.mockResolvedValue(true);
    mocks.faturayiArkaPlanaGonder.mockResolvedValue(ISLEM_ID);
    mocks.rpc.mockResolvedValue({ data: [{ allowed: true, retry_after_seconds: 0 }], error: null });
    mocks.admin.mockReturnValue({
      rpc: mocks.rpc,
      from: (tablo: string) => {
        const z: Record<string, unknown> = {};
        z.select = () => z;
        z.eq = () => z;
        z.maybeSingle = async () =>
          tablo === "stores" ? { data: { id: "store-1" }, error: null } : { data: null, error: null };
        return z;
      },
    });
  });

  function pdfIstegi(dosyalar: Uint8Array[]): NextRequest {
    const form = new FormData();
    form.set("slug", "ornek-vitrin");
    dosyalar.forEach((bayt, idx) => {
      form.append("dosya", new File([Buffer.from(bayt)], `fatura-${idx + 1}.pdf`, { type: "application/pdf" }));
    });
    return new NextRequest("http://localhost/api/fatura-oku", {
      method: "POST",
      body: form,
    });
  }

  it("normal 1-3 sayfalık PDF yüklemesini kabul eder", async () => {
    const cevap = await faturaOkuPost(pdfIstegi([sahtePdf(3)]));
    expect(cevap.status).toBe(202);
    expect(mocks.faturayiArkaPlanaGonder).toHaveBeenCalledTimes(1);
  });

  it("aşırı çok sayfalı PDF veya sıkıştırılmış ObjStm PDF saldırısını 400 ile reddeder", async () => {
    const cokSayfali = await faturaOkuPost(pdfIstegi([sahtePdf(15)]));
    expect(cokSayfali.status).toBe(400);

    const sikistirilmisCokSayfali = await faturaOkuPost(pdfIstegi([sahtePdf(12, true)]));
    expect(sikistirilmisCokSayfali.status).toBe(400);

    const ikiCokSayfali = await faturaOkuPost(pdfIstegi([sahtePdf(2), sahtePdf(2)]));
    expect(ikiCokSayfali.status).toBe(400);

    expect(mocks.faturayiArkaPlanaGonder).not.toHaveBeenCalled();
  });
});
