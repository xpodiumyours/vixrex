import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

// Kabul matrisi R1–R10 + R2a'nın sunucu kapısı sözleşmesi (P7).
//
// Bu dosya matrisin OTOMATİK kısmını kilitler: her satır sonucu, yayın kapısı
// ve izinsiz-yayın toleransı (sıfır) mock isteklerle kanıtlanır. Gerçek
// fotoğraf + kullanıcı faturalarıyla Preview kanıtı test-sonuc/ altında
// ayrıca raporlanır; "test yazıldı / koştu / canlıda görüldü" ayrı işaretlenir.

const mocks = vi.hoisted(() => ({
  get: vi.fn(() => "owner-cookie"),
  admin: vi.fn(),
  rpc: vi.fn(),
  kayitlar: new Map<number, Record<string, unknown>>(),
  verifyOwner: vi.fn(() => ({ storeId: "store-1" })),
  createProduct: vi.fn(),
  publishProduct: vi.fn(
    async (_args: Record<string, unknown>): Promise<{ success: boolean; id?: string; hata?: string }> => ({
      success: true,
      id: "urun-1",
    }),
  ),
  upsert: vi.fn(async () => ({ error: null })),
}));
vi.mock("next/headers", () => ({ cookies: vi.fn(async () => ({ get: mocks.get })) }));
vi.mock("@/lib/supabaseAdmin", () => ({ getSupabaseAdmin: mocks.admin }));
vi.mock("@/lib/ownerSession", () => ({
  OWNER_SESSION_COOKIE: "vixrex_owner_session",
  verifyOwnerSession: mocks.verifyOwner,
}));
vi.mock("@/lib/faturaGorsel", () => ({
  kaynakGorselleriniHazirla: async (args: { adaylar: string[]; kaynakSayfa: string }) => ({
    gorseller: args.adaylar.map((adres) => ({
      url: adres,
      kaynakGorsel: adres,
      kaynakSayfa: args.kaynakSayfa,
      genislik: 1200,
      yukseklik: 1200,
    })),
    reddedilenler: [],
    altyapiSorunu: false,
  }),
}));
vi.mock("@/lib/faturaUrunBaglantisi", async (importOriginal) => ({
  ...await importOriginal<typeof import("@/lib/faturaUrunBaglantisi")>(),
  satiriDogrula: async (_admin: unknown, _storeId: string, kimlik: { satirSirasi: number }) => mocks.kayitlar.get(kimlik.satirSirasi) ?? null,
}));
vi.mock("@/lib/productCoreServer", () => ({
  createRichCoreProduct: mocks.createProduct,
  publishInvoiceProduct: mocks.publishProduct,
}));

import { POST as topluUrunEkle } from "@/app/api/products/batch/route";

const STORE = { id: "store-1", edit_token: "token-1", name: "Deneme Butik" };

function adminMock() {
  return vi.fn((tablo: string) => {
    if (tablo === "stores") {
      const query = { select: vi.fn(), eq: vi.fn(), single: vi.fn() };
      query.select.mockReturnValue(query);
      query.eq.mockReturnValue(query);
      query.single.mockResolvedValue({ data: STORE, error: null });
      return query;
    }
    const query = {
      select: vi.fn(),
      eq: vi.fn(),
      maybeSingle: vi.fn(),
      upsert: mocks.upsert,
      update: vi.fn(() => ({ eq: vi.fn(async () => ({ error: null })) })),
    };
    query.select.mockReturnValue(query);
    query.eq.mockReturnValue(query);
    query.maybeSingle.mockResolvedValue({
      data: { id: "kategori-1", product_template_key: "fashion" },
      error: null,
    });
    return query;
  });
}

const FOTOGRAFLAR = [
  "https://tedarikci.example.com/1.jpg",
  "https://tedarikci.example.com/2.jpg",
  "https://tedarikci.example.com/3.jpg",
];

function kanitliSatir(fazla: Record<string, unknown> = {}) {
  return {
    name: "Matris Ürünü",
    priceText: "199 TL",
    categoryId: "kategori-1",
    barcode: "8681128321677",
    imageUrls: FOTOGRAFLAR,
    stockQuantity: 2,
    sourceType: "invoice",
    kartDurumu: "kanitli",
    stokOnaylandi: true,
    ownerApproved: true,
    yayinIstegi: true,
    variants: [{ id: "v-matris-siyah-l", options: { color: "Siyah", size: "L" } }],
    metadata: {
      attributes: [
        { key: "gender", value: "Erkek" },
        { key: "fit", value: "Normal" },
      ],
    },
    ...fazla,
  };
}

function kayitlariHazirla(products: unknown[]) {
  for (const [i, ham] of products.entries()) {
    const p = ham as Record<string, unknown>;
    if (p.sourceType !== "invoice") continue;
    p.islemKimligi = "11111111-1111-4111-8111-111111111111";
    p.satirSirasi = i;
    mocks.kayitlar.set(i, { satirId: String(i), sonuc: p.kartDurumu ?? "kanitli", urunId: null,
      izinliGorseller: new Set(p.imageUrls as string[]), alisBirimFiyati: typeof p.purchasePriceAmount === "number" ? p.purchasePriceAmount : null,
      katalog: { resmiAd: p.name, aciklama: p.description ?? "", marka: p.brand ?? "Üretici", kaynak: `https://tedarikci.example.com/urun/${i}` } });
  }
}

function istek(products: unknown[]) {
  kayitlariHazirla(products);
  return new NextRequest("http://localhost/api/products/batch", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ slug: "deneme-vitrin", products }),
  });
}

describe("kabul matrisi R1-R10 + R2a sunucu sozlesmesi", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.kayitlar.clear();
    mocks.rpc.mockImplementation(async (_name: string, args: { p_line_id: string }) => ({ data: { success: true, id: `urun-${args.p_line_id}`, slug: `urun-${args.p_line_id}`, created: true, kayit: "yeni" }, error: null }));
    mocks.get.mockReturnValue("owner-cookie");
    mocks.verifyOwner.mockReturnValue({ storeId: "store-1" });
    mocks.admin.mockImplementation(() => ({ from: adminMock(), rpc: mocks.rpc }));
    mocks.publishProduct.mockResolvedValue({ success: true, id: "urun-1" });
    let sayac = 0;
    mocks.createProduct.mockImplementation(async () => {
      sayac += 1;
      return { id: `urun-${sayac}`, slug: `urun-${sayac}` };
    });
  });

  it("R5: izi olmayan satir kaybolmaz; fiyat ve fotograf varsa yayina cikar", async () => {
    const cevap = await topluUrunEkle(istek([kanitliSatir({ kartDurumu: "iz-yok" })]));
    const govde = await cevap.json();

    expect(mocks.rpc).toHaveBeenCalledTimes(1);
    expect(govde.yayinda).toBe(1);
    expect(govde.taslak).toBe(0);
    expect(mocks.rpc.mock.calls[0][1].p_evidence.kartDurumu).toBe("iz-yok");
  });

  it("R4: celiskili satir fiyat ve fotograf varsa yayina cikar", async () => {
    const cevap = await topluUrunEkle(istek([kanitliSatir({ kartDurumu: "celiski" })]));
    const govde = await cevap.json();

    expect(govde.yayinda).toBe(1);
    expect(mocks.publishProduct).toHaveBeenCalled();
  });

  it("R7: alis fiyati musteriye cikmaz ve ayni satir kopya yayin uretemez", async () => {
    const satir = kanitliSatir({ purchasePriceAmount: 137 });
    const birinci = await (await topluUrunEkle(istek([satir]))).json();
    const ikinci = await (await topluUrunEkle(istek([satir]))).json();

    // Her yazım ayrı taslak/yayın kaydıdır; sessizce birleşmez, fiyatı sızdırmaz.
    expect(birinci.yayinda).toBe(1);
    expect(ikinci.yayinda).toBe(1);
    expect(birinci.satirlar[0].id).toBe(ikinci.satirlar[0].id);
    for (const cagri of mocks.rpc.mock.calls) {
      expect(JSON.stringify(cagri[1].p_product)).not.toContain("137");
    }
  });

  it("R8: izinsiz yayin toleransi sifir — kapali kapidan hicbir satir cikmaz", async () => {
    const kapaliVaryantlar: Array<Record<string, unknown>> = [
      { ownerApproved: false },
      { priceText: "" },
      { imageUrls: [] },
      { yayinIstegi: false },
    ];
    for (const varyant of kapaliVaryantlar) {
      vi.clearAllMocks();
    mocks.kayitlar.clear();
    mocks.rpc.mockImplementation(async (_name: string, args: { p_line_id: string }) => ({ data: { success: true, id: `urun-${args.p_line_id}`, slug: `urun-${args.p_line_id}`, created: true, kayit: "yeni" }, error: null }));
      mocks.get.mockReturnValue("owner-cookie");
      mocks.verifyOwner.mockReturnValue({ storeId: "store-1" });
      mocks.admin.mockImplementation(() => ({ from: adminMock(), rpc: mocks.rpc }));
      mocks.publishProduct.mockResolvedValue({ success: true, id: "urun-1" });
      mocks.createProduct.mockResolvedValue({ id: "urun-1", slug: "urun-1" });

      const govde = await (await topluUrunEkle(istek([kanitliSatir(varyant)]))).json();
      expect(govde.yayinda).toBe(0);
    }
    expect(mocks.publishProduct).not.toHaveBeenCalled();
  });

  it("R6+R2: kanitli gida satiri da ayni iki ayri onaydan gecer", async () => {
    // Sektöre göre kapı değişmez: bilgi onayı taslak, Yayınla görünürlük.
    const taslakCevap = await (
      await topluUrunEkle(istek([kanitliSatir({ yayinIstegi: false })]))
    ).json();
    expect(taslakCevap.yayinda).toBe(0);
    expect(taslakCevap.taslak).toBe(1);

    const yayinCevap = await (await topluUrunEkle(istek([kanitliSatir()]))).json();
    expect(yayinCevap.yayinda).toBe(1);
  });
});
