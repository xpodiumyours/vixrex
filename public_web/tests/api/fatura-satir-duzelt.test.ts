import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

const ISLEM = "11111111-1111-4111-8111-111111111111";
const m = vi.hoisted(() => ({
  yetki: vi.fn(),
  rpc: vi.fn(),
  is: vi.fn(),
  satir: vi.fn(),
  siteSearch: vi.fn(),
  brandSearch: vi.fn(),
  imageCheck: vi.fn(),
  cost: vi.fn(),
  record: vi.fn(),
  imgFetch: vi.fn(),
  pageProof: vi.fn(),
}));

vi.mock("@/lib/supabaseAdmin", () => ({
  getSupabaseAdmin: () => ({
    rpc: m.rpc,
    from: (tablo: string) => ({
      select: () => ({
        eq: () => ({
          eq: () => ({
            maybeSingle: async () => (tablo === "invoice_jobs" ? m.is() : m.satir()),
          }),
        }),
      }),
    }),
  }),
}));
vi.mock("@/lib/faturaYetki", () => ({ sahipYetkisi: m.yetki }));
vi.mock("@/lib/faturaGoru", () => ({
  satirSitesindeAra: m.siteSearch,
  markaSitesiniBul: m.brandSearch,
  lunaGorseliniDogrula: m.imageCheck,
}));
vi.mock("@/lib/faturaGorsel", () => ({
  kaynakGorseliniDogrula: m.imgFetch,
  urunSayfasindaGorselKaniti: m.pageProof,
}));
vi.mock("@/lib/faturaMaliyet", () => ({
  ARAMA_UCETI_USD: 0.01,
  aramaCagrisiSigarMi: () => true,
  bugunkuMaliyetUsd: m.cost,
  kullanimKaydet: m.record,
}));

import { POST } from "@/app/api/fatura-satir-duzelt/route";

const istek = (ek: Record<string, unknown> = {}) =>
  new NextRequest("http://localhost/api/fatura-satir-duzelt", {
    method: "POST",
    body: JSON.stringify({ slug: "dukkan", islemKimligi: ISLEM, satirSirasi: 0, ...ek }),
  });

describe("satır düzeltme kartı site kaydından kurar", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    m.yetki.mockResolvedValue({ tamam: true, slug: "dukkan", storeId: "store" });
    m.cost.mockResolvedValue(0);
    m.record.mockResolvedValue(undefined);
    m.siteSearch.mockResolvedValue({
      ad: "ELT1002 Üretici Fanila", dayanak: "kod",
      gorsel: "https://cdn.example/elt1002.jpg",
      sayfa: "https://sehermensucat.com/urun/elt1002",
      aciklama: "ELT1002 pamuklu fanila",
      maliyet: 0.01,
    });
    m.imgFetch.mockResolvedValue({
      tamam: true, bayt: new Uint8Array([1, 2, 3]), tur: "image/jpeg",
    });
    m.pageProof.mockResolvedValue({
      kaynakAlintisi: '<img alt="ELT1002 Fanila" src="https://cdn.example/elt1002.jpg">',
    });
    m.imageCheck.mockResolvedValue({ uyumlu: true, gerekce: "Doğru fanila", maliyet: 0.001 });
    m.rpc.mockImplementation(async (ad: string) => {
      if (ad === "consume_assistant_request") return { data: [{ allowed: true }], error: null };
      return { data: { success: true, sahipDurumu: null, onaySifirlandi: false }, error: null };
    });
    m.is.mockResolvedValue({ data: { id: ISLEM, discovery_state: {} }, error: null });
    m.satir.mockResolvedValue({
      data: {
        id: "satir-1",
        raw_line: "ELT1001",
        model: "ELT1001",
        product_name: "Faturadaki fanila",
        barcode: "",
        variant_name: "",
        size_text: "",
        brand: "",
        qty: 1,
        unit_price: 10,
        line_total: 10,
        confidence: 1,
        product_id: null,
        catalog_snapshot: {
          aciklama: "Sitede yazan açıklama",
          gorseller: ["https://firma.example/urun.jpg"],
          kaynak: "https://firma.example/urun",
          fotografKaniti: {
            kaynakSayfa: "https://firma.example/urun",
            kaynakGorsel: "https://firma.example/urun.jpg",
            kaynakAlintisi: '<img src="https://firma.example/urun.jpg">',
            lunaGerekcesi: "Fotoğrafta fanila görünüyor.",
          },
        },
      },
      error: null,
    });
  });

  it("aday seçimi kayıtlı site fotoğrafının üstüne yazmaz", async () => {
    const cevap = await POST(istek({ secilenKaynak: "https://katalog.example/baska" }));
    const govde = await cevap.json();
    expect(cevap.status).toBe(200);
    expect(govde.satir.katalog.gorseller).toEqual(["https://firma.example/urun.jpg"]);
    expect(govde.satir.katalog.kaynak).toBe("https://firma.example/urun");
    expect(govde.satir.katalog.aciklama).toBe("Sitede yazan açıklama");
    expect(govde.satir.katalog.resmiAd).toBe("Faturadaki fanila");
  });


  it("ürün kodu veya marka değişince eski fotoğraf ve eşleşme kanıtı geçersiz olur", async () => {
    const cevap = await POST(istek({ model: "BASKA-MODEL", marka: "Baska Marka" }));
    const govde = await cevap.json();
    expect(cevap.status).toBe(200);
    expect(govde.satir.sonuc).toBe("eksik");
    expect(govde.satir.katalog).toBeNull();
    const islem = m.rpc.mock.calls.find((c) => c[0] === "replace_invoice_line");
    expect(islem?.[1].p_line.outcome).toBe("eksik");
  });

  it("açıklaması olmayan kayıtlı fotoğraftan kart kurmaz", async () => {
    m.satir.mockResolvedValue({
      data: {
        id: "satir-1",
        raw_line: "ELT1001",
        model: "ELT1001",
        product_name: "Faturadaki fanila",
        barcode: "",
        variant_name: "",
        size_text: "",
        brand: "",
        qty: 1,
        unit_price: 10,
        line_total: 10,
        confidence: 1,
        product_id: null,
        catalog_snapshot: {
          aciklama: "",
          gorseller: ["https://cdn.myikas.com/images/liste.webp"],
          kaynak: "https://sehermensucat.com/elt1001-elit-erkek-penye-atlet",
        },
      },
      error: null,
    });
    const cevap = await POST(istek({ model: "ELT1001" }));
    const govde = await cevap.json();
    expect(cevap.status).toBe(200);
    expect(govde.satir.katalog).toBeNull();
    expect(govde.satir.sonuc).toBe("eksik");
  });
  it("kimlik düzeltmesinde sadece bu satırı yeniden araştırıp yeni kanıtla kart kurar", async () => {
    m.is.mockResolvedValue({
      data: { id: ISLEM, discovery_state: {}, supplier_name: "Seher Mensucat",
        supplier_site: "sehermensucat.com" },
      error: null,
    });
    const cevap = await POST(istek({ model: "ELT1002" }));
    const govde = await cevap.json();

    expect(cevap.status).toBe(200);
    expect(m.siteSearch).toHaveBeenCalledOnce();
    expect(m.siteSearch).toHaveBeenCalledWith(expect.objectContaining({
      alan: "sehermensucat.com", model: "ELT1002",
    }));
    expect(m.pageProof).toHaveBeenCalledOnce();
    expect(m.imageCheck).toHaveBeenCalledOnce();
    expect(govde.satir.sonuc).toBe("kanitli");
    expect(govde.satir.katalog.kaynak).toBe("https://sehermensucat.com/urun/elt1002");
    expect(govde.satir.katalog.fotografKaniti.kaynakGorsel).toBe("https://cdn.example/elt1002.jpg");
    expect(m.rpc.mock.calls.find((c) => c[0] === "replace_invoice_line")?.[1].p_line.outcome)
      .toBe("kanitli");
  });

  it("yeniden araştırma başarısızsa eski kanıtı kabul etmez ve satırı taslak tutar", async () => {
    m.is.mockResolvedValue({
      data: { id: ISLEM, discovery_state: {}, supplier_name: "Seher Mensucat",
        supplier_site: "sehermensucat.com" },
      error: null,
    });
    m.siteSearch.mockRejectedValue(new Error("OKUYUCU_CEVAP_VERMEDI"));
    const cevap = await POST(istek({ model: "ELT1002" }));
    const govde = await cevap.json();

    expect(cevap.status).toBe(200);
    expect(m.siteSearch).toHaveBeenCalledOnce();
    expect(m.imageCheck).not.toHaveBeenCalled();
    expect(govde.satir.sonuc).toBe("eksik");
    expect(govde.satir.katalog).toBeNull();
    expect(govde.satir.uyari).toContain("başarısız");
  });

  it("ürün kimliği değişmediyse ücretli araştırmayı tekrar başlatmaz", async () => {
    const cevap = await POST(istek());
    expect(cevap.status).toBe(200);
    expect(m.siteSearch).not.toHaveBeenCalled();
    expect(m.imageCheck).not.toHaveBeenCalled();
  });

});
