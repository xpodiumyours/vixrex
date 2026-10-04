import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

// Faturadan gelen satırın yayın kapısı.
//
// Kural: fotoğrafı ve zorunlu alanları tam olsa bile, satır KANITLI değilse,
// esnaf satış fiyatını girip stoğu ve kartı açıkça onaylamadan ürün vitrinde
// görünmez. Alış fiyatı satış fiyatı yerine geçmez ve ürün kartına sızmaz;
// faturadaki adet de tek başına stok sayılmaz.

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
  update: vi.fn(),
  upsert: vi.fn(),
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

import seherKatalog from "../../data/katalog/uretici-katalog-seher-mensucat.json";

/**
 * Gerçek katalogdan alınmış, izni OLMAYAN bir üretici fotoğrafı.
 * Seher'in izni "bekliyor" — yani bu adres yayına çıkamamalı.
 */
const IZINSIZ_URETICI_FOTOGRAFLARI = (seherKatalog as Array<{ gorseller: string[] }>)
  .find((urun) => urun.gorseller.length >= 3)!
  .gorseller.slice(0, 3);

const FOTOGRAFLAR = [
  "https://tedarikci.example.com/1.jpg",
  "https://tedarikci.example.com/2.jpg",
  "https://tedarikci.example.com/3.jpg",
];

function adminMock() {
  return vi.fn((tablo: string) => {
    if (tablo === "stores") {
      const query = { select: vi.fn(), eq: vi.fn(), single: vi.fn() };
      query.select.mockReturnValue(query);
      query.eq.mockReturnValue(query);
      query.single.mockResolvedValue({ data: STORE, error: null });
      return query;
    }
    if (tablo === "product_purchase_prices") {
      mocks.upsert.mockResolvedValue({ error: null });
      return { upsert: mocks.upsert };
    }
    if (tablo === "products") {
      const query = {
        select: vi.fn(),
        eq: vi.fn(),
        maybeSingle: vi.fn(),
        update: mocks.update,
      };
      query.select.mockReturnValue(query);
      query.eq.mockReturnValue(query);
      query.maybeSingle.mockResolvedValue({
        data: { id: "kategori-1", product_template_key: "fashion" },
        error: null,
      });
      mocks.update.mockReturnValue({
        eq: vi.fn(async () => ({ error: null })),
      });
      return query;
    }
    const query = { select: vi.fn(), eq: vi.fn(), maybeSingle: vi.fn() };
    query.select.mockReturnValue(query);
    query.eq.mockReturnValue(query);
    query.maybeSingle.mockResolvedValue({
      data: { id: "kategori-1", product_template_key: "fashion" },
      error: null,
    });
    return query;
  });
}

/**
 * Fotoğrafı, zorunlu alanları ve kanıt durumu tam satır. Kapıyı yalnız
 * testin kapatmak istediği tek şart tutar.
 */
function faturaSatiri(fazla: Record<string, unknown> = {}) {
  return {
    name: "Elit Erkek Elastan Sıfır Yaka Uzun Kol",
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
    variants: [{ id: "v-elt1302-siyah-l", options: { color: "Siyah", size: "L" } }],
    metadata: {
      attributes: [
        { key: "gender", value: "Erkek" },
        { key: "fit", value: "Normal" },
      ],
    },
    ...fazla,
  };
}

function istek(products: unknown[]) {
  for (const [i, ham] of products.entries()) {
    const p = ham as Record<string, unknown>;
    if (p.sourceType !== "invoice") continue;
    p.islemKimligi = "11111111-1111-4111-8111-111111111111";
    p.satirSirasi = i;
    mocks.kayitlar.set(i, { satirId: String(i), sonuc: p.kartDurumu ?? "eksik", urunId: null,
      izinliGorseller: new Set(p.imageUrls as string[]), alisBirimFiyati: typeof p.purchasePriceAmount === "number" ? p.purchasePriceAmount : null,
      katalog: { resmiAd: p.name, aciklama: p.description ?? "", marka: p.brand ?? "Üretici", kaynak: `https://tedarikci.example.com/urun/${i}` } });
  }
  return new NextRequest("http://localhost/api/products/batch", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ slug: "deneme-vitrin", products }),
  });
}

describe("faturadan gelen ürünün yayın kapısı", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.kayitlar.clear();
    mocks.rpc.mockImplementation(async () => ({ data: { success: true, id: "urun-1", slug: "urun-1", created: true, kayit: "yeni" }, error: null }));
    mocks.get.mockReturnValue("owner-cookie");
    mocks.verifyOwner.mockReturnValue({ storeId: "store-1" });
    mocks.admin.mockImplementation(() => ({ from: adminMock(), rpc: mocks.rpc }));
    let sayac = 0;
    mocks.createProduct.mockImplementation(async () => {
      sayac += 1;
      return { id: `urun-${sayac}`, slug: `urun-${sayac}` };
    });
  });

  it("esnaf onayı yoksa ürün taslak kalır", async () => {
    const cevap = await topluUrunEkle(istek([faturaSatiri({ ownerApproved: false })]));
    const govde = await cevap.json();

    expect(mocks.rpc.mock.calls[0][0]).toBe("save_invoice_product");
    expect(mocks.createProduct).not.toHaveBeenCalled();
    expect(govde.yayinda).toBe(0);
    expect(govde.taslak).toBe(1);
    expect(govde.satirlar[0].sebep).toContain("onaylanmadı");
  });

  it("onay alanı hiç gönderilmezse de ürün taslak kalır", async () => {
    await topluUrunEkle(istek([faturaSatiri({ ownerApproved: undefined })]));
    expect(mocks.rpc.mock.calls[0][0]).toBe("save_invoice_product");
    expect(mocks.createProduct).not.toHaveBeenCalled();
  });

  it("kanıtlı olmayan satır, onay ve fiyat olsa bile taslak kalır", async () => {
    const cevap = await topluUrunEkle(
      istek([faturaSatiri({ kartDurumu: "celiski" })]),
    );
    const govde = await cevap.json();

    expect(mocks.rpc.mock.calls[0][0]).toBe("save_invoice_product");
    expect(mocks.createProduct).not.toHaveBeenCalled();
    expect(govde.yayinda).toBe(0);
    expect(govde.satirlar[0].sebep).toContain("kanıtlı değil");
  });

  it("kart durumu hiç gönderilmezse satır taslak kalır — eksik bilgi uydurulmaz", async () => {
    const cevap = await topluUrunEkle(istek([faturaSatiri({ kartDurumu: undefined })]));
    const govde = await cevap.json();

    expect(mocks.rpc.mock.calls[0][0]).toBe("save_invoice_product");
    expect(mocks.createProduct).not.toHaveBeenCalled();
    expect(govde.satirlar[0].sebep).toContain("kanıtlı değil");
  });

  it("faturadaki adet stok yerine geçmez: stok onayı olmadan satır yayına çıkmaz", async () => {
    const cevap = await topluUrunEkle(istek([faturaSatiri({ stokOnaylandi: false })]));
    const govde = await cevap.json();

    expect(mocks.rpc.mock.calls[0][0]).toBe("save_invoice_product");
    expect(mocks.createProduct).not.toHaveBeenCalled();
    expect(govde.yayinda).toBe(0);
    expect(govde.satirlar[0].sebep).toContain("Stok onaylanmadı");
  });

  it("satış fiyatı girilmemişse onaylı olsa bile taslak kalır", async () => {
    const cevap = await topluUrunEkle(istek([faturaSatiri({ priceText: "" })]));
    const govde = await cevap.json();

    expect(mocks.rpc.mock.calls[0][0]).toBe("save_invoice_product");
    expect(mocks.createProduct).not.toHaveBeenCalled();
    expect(govde.satirlar[0].sebep).toContain("Satış fiyatı");
  });

  it("dört kapı + ayrı Yayınla birlikte açılınca ürün yayına çıkar", async () => {
    const cevap = await topluUrunEkle(istek([faturaSatiri()]));
    const govde = await cevap.json();

    // Satır önce taslak kurulur, sonra publish RPC'si görünür yapar.
    expect(mocks.rpc.mock.calls[0][0]).toBe("save_invoice_product");
    expect(mocks.createProduct).not.toHaveBeenCalled();
    expect(mocks.publishProduct).toHaveBeenCalledTimes(1);
    expect(govde.yayinda).toBe(1);
  });

  it("kapılar tam ama Yayınla denmemişse ürün taslak kaydedilir", async () => {
    const cevap = await topluUrunEkle(istek([faturaSatiri({ yayinIstegi: false })]));
    const govde = await cevap.json();

    expect(mocks.rpc.mock.calls[0][0]).toBe("save_invoice_product");
    expect(mocks.createProduct).not.toHaveBeenCalled();
    expect(mocks.publishProduct).not.toHaveBeenCalled();
    expect(govde.yayinda).toBe(0);
    expect(govde.taslak).toBe(1);
    expect(govde.satirlar[0].sebep).toContain("Yayın onayı");
  });

  it("fatura kanıt özeti satıra yazılır — ayrı Yayınla buradan okur", async () => {
    await topluUrunEkle(istek([faturaSatiri()]));

    expect(mocks.rpc).toHaveBeenCalledOnce();
    expect(mocks.rpc.mock.calls[0][1].p_evidence).toMatchObject({ kartDurumu: "kanitli", stokOnaylandi: true });
  });

  it("fotoğrafsız ürün, onaylı ve fiyatlı olsa bile taslak kalır", async () => {
    const cevap = await topluUrunEkle(istek([faturaSatiri({ imageUrls: [] })]));
    const govde = await cevap.json();

    expect(mocks.rpc.mock.calls[0][0]).toBe("save_invoice_product");
    expect(mocks.createProduct).not.toHaveBeenCalled();
    expect(mocks.publishProduct).not.toHaveBeenCalled();
    expect(govde.satirlar[0].sebep).toContain("fotoğraf");
  });

  it("tek doğrulanmış ürün fotoğrafı olan kanıtlı satır yayına çıkabilir", async () => {
    const cevap = await topluUrunEkle(
      istek([faturaSatiri({ imageUrls: [FOTOGRAFLAR[0]] })]),
    );
    const govde = await cevap.json();

    expect(mocks.rpc.mock.calls[0][0]).toBe("save_invoice_product");
    expect(mocks.createProduct).not.toHaveBeenCalled();
    expect(mocks.publishProduct).toHaveBeenCalledTimes(1);
    expect(govde.yayinda).toBe(1);
  });

  it("alış fiyatı ürün kartına hiçbir alandan sızmaz", async () => {
    await topluUrunEkle(istek([faturaSatiri({ purchasePriceAmount: 137 })]));

    const yazilan = mocks.rpc.mock.calls[0][1].p_product;
    expect(JSON.stringify(yazilan)).not.toContain("137");
    expect(yazilan.priceText).toBe("199 TL");
    expect(yazilan.priceAmount).toBe(199);
  });

  it("alış fiyatı karta değil, kilitli tabloya yazılır", async () => {
    // products tablosunda anon'un tablo düzeyinde okuma yetkisi var; oraya
    // yazılan her alan müşteriye de açılırdı. Bu yüzden ayrı tablo.
    await topluUrunEkle(istek([faturaSatiri({ purchasePriceAmount: 137 })]));

    expect(mocks.rpc).toHaveBeenCalledOnce();
    expect(mocks.rpc.mock.calls[0][1]).toMatchObject({ p_store_id: "store-1", p_purchase_price: 137 });
    expect(JSON.stringify(mocks.rpc.mock.calls[0][1].p_product)).not.toContain("137");
    // Ürün satırına yazılan tek şey fatura kanıt özetidir; alış fiyatı yok.
    for (const cagri of mocks.update.mock.calls) {
      expect(JSON.stringify(cagri[0])).not.toContain("137");
    }
  });

  it("üretici fotoğrafı karta girer ve yayınlanır; izni sonra istenir", async () => {
    // Kilitli kapsam: önce çalışan sistem. Seher'in izni "bekliyor" ama
    // fotoğrafı yayına girer; kullanım izni sonra bu kayıtlardan istenir.
    const cevap = await topluUrunEkle(
      istek([faturaSatiri({ imageUrls: IZINSIZ_URETICI_FOTOGRAFLARI })]),
    );
    const govde = await cevap.json();

    expect(mocks.publishProduct).toHaveBeenCalledTimes(1);
    expect(govde.yayinda).toBe(1);
    const yazilan: string[] = mocks.rpc.mock.calls[0][1].p_product.imageUrls;
    for (const adres of IZINSIZ_URETICI_FOTOGRAFLARI) {
      expect(yazilan).toContain(adres);
    }
  });

  it("üretici görseli fatura kanıtına işaretlenir — izin turu bu listeden yürür", async () => {
    await topluUrunEkle(
      istek([faturaSatiri({ imageUrls: IZINSIZ_URETICI_FOTOGRAFLARI })]),
    );

    const yazilan = { fatura_kanit: mocks.rpc.mock.calls[0][1].p_evidence };
    expect(yazilan).toMatchObject({
      fatura_kanit: { kartDurumu: "kanitli", stokOnaylandi: true, ureticiGorsel: true },
    });
  });

  it("esnafın kendi fotoğrafında üretici işareti konmaz", async () => {
    await topluUrunEkle(istek([faturaSatiri({ imageUrls: FOTOGRAFLAR })]));

    const yazilan = { fatura_kanit: mocks.rpc.mock.calls[0][1].p_evidence };
    expect(yazilan).toMatchObject({
      fatura_kanit: { kartDurumu: "kanitli", stokOnaylandi: true, ureticiGorsel: false },
    });
  });

  it("esnaf kendi fotoğrafını koyarsa aynı ürün yayına çıkar", async () => {
    // İzin kuralı esnafı kilitlemez: kendi çektiği fotoğrafla sistem uçtan
    // uca çalışır. Kilitlenen yalnız izinsiz ÜRETİCİ fotoğrafıdır.
    const cevap = await topluUrunEkle(istek([faturaSatiri({ imageUrls: FOTOGRAFLAR })]));
    const govde = await cevap.json();

    expect(mocks.rpc.mock.calls[0][0]).toBe("save_invoice_product");
    expect(mocks.createProduct).not.toHaveBeenCalled();
    expect(mocks.publishProduct).toHaveBeenCalledTimes(1);
    expect(govde.yayinda).toBe(1);
  });

  it("Excel/XML gibi fatura dışı kaynaklar eski davranışını korur", async () => {
    await topluUrunEkle(
      istek([
        faturaSatiri({
          sourceType: "bulk_import",
          ownerApproved: undefined,
          kartDurumu: undefined,
          stokOnaylandi: undefined,
        }),
      ]),
    );

    expect(mocks.createProduct.mock.calls[0][0].isVisible).toBe(true);
  });
});
