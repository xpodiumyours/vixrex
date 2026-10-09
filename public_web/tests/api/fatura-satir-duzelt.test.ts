import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

const ISLEM = "11111111-1111-4111-8111-111111111111";
const m = vi.hoisted(() => ({
  yetki: vi.fn(),
  rpc: vi.fn(),
  is: vi.fn(),
  satir: vi.fn(),
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
});
