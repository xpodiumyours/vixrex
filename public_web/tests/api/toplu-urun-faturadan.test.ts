import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  get: vi.fn(() => "owner-cookie"),
  admin: vi.fn(),
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

const FATURA_SATIRLARI = [
  {
    name: "Elit Erkek Elastan Sıfır Yaka Uzun Kol",
    priceText: "199 TL",
    categoryId: "kategori-1",
    barcode: "8681128321677",
    imageUrls: FOTOGRAFLAR,
    stockQuantity: 2,
    variants: [{ id: "v-elt1302-siyah-l", options: { color: "Siyah", size: "L" } }],
    metadata: {
      attributes: [
        { key: "gender", value: "Erkek" },
        { key: "fit", value: "Normal" },
      ],
    },
  },
  {
    name: "Elit Erkek Termal Alt",
    priceText: "289 TL",
    categoryId: "kategori-1",
    barcode: "8681128332550",
    imageUrls: [FOTOGRAFLAR[0]],
    stockQuantity: 6,
    variants: [{ id: "v-elt1306-siyah-m", options: { color: "Siyah", size: "M" } }],
    metadata: {
      attributes: [
        { key: "gender", value: "Erkek" },
        { key: "fit", value: "Normal" },
      ],
    },
  },
  {
    name: "Tutku Çocuk Termal Alt",
    priceText: "149 TL",
    categoryId: "kategori-1",
    barcode: "8680508957796",
    imageUrls: FOTOGRAFLAR,
    stockQuantity: 18,
    variants: [{ id: "v-tec0135-siyah-4", options: { color: "Siyah", size: "4" } }],
    metadata: { attributes: [] },
  },
];

function istek(products: unknown[]) {
  return new NextRequest("http://localhost/api/products/batch", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ slug: "deneme-vitrin", products }),
  });
}

describe("faturadan gelen satırlar toplu kapıdan ürün kartına dönüşür", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.get.mockReturnValue("owner-cookie");
    mocks.verifyOwner.mockReturnValue({ storeId: "store-1" });
    mocks.admin.mockImplementation(() => ({ from: adminMock() }));
    let sayac = 0;
    mocks.createProduct.mockImplementation(async () => {
      sayac += 1;
      return { id: `urun-${sayac}`, slug: `urun-${sayac}` };
    });
  });

  it("üç satır: eksiksiz olan yayına, eksik olanlar taslağa düşer", async () => {
    const cevap = await topluUrunEkle(istek(FATURA_SATIRLARI));
    const govde = await cevap.json();

    expect(cevap.status).toBe(200);
    expect(govde.toplam).toBe(3);
    expect(govde.yayinda).toBe(1);
    expect(govde.taslak).toBe(2);
    expect(govde.hatali).toBe(0);

    const fotografEksigi = govde.satirlar.find((satir: { sira: number }) => satir.sira === 1);
    expect(fotografEksigi.durum).toBe("taslak");
    expect(fotografEksigi.sebep).toContain("fotoğraf");

    const alanEksigi = govde.satirlar.find((satir: { sira: number }) => satir.sira === 2);
    expect(alanEksigi.durum).toBe("taslak");
    expect(alanEksigi.sebep).toContain("zorunlu");
  });

  it("beden, renk ve barkod karta gerçekten yazılır", async () => {
    await topluUrunEkle(istek([FATURA_SATIRLARI[0]]));

    const yazilan = mocks.createProduct.mock.calls[0][0];
    expect(yazilan.variants).toHaveLength(1);
    expect(yazilan.variants[0].options).toMatchObject({ color: "Siyah", size: "L" });
    expect(yazilan.barcode).toBe("8681128321677");
    expect(yazilan.metadata.templateKey).toBe("fashion");
    expect(yazilan.metadata.attributes).toEqual(
      expect.arrayContaining([expect.objectContaining({ key: "gender", value: "Erkek" })]),
    );
    expect(yazilan.isVisible).toBe(true);
  });

  it("alış fiyatı karta hiçbir alandan sızmaz", async () => {
    await topluUrunEkle(
      istek([{ ...FATURA_SATIRLARI[0], alisFiyati: 137, purchasePrice: 137, priceText: "199 TL" }]),
    );

    const yazilan = mocks.createProduct.mock.calls[0][0];
    const kartYazisi = JSON.stringify(yazilan);
    expect(kartYazisi).not.toContain("137");
    expect(yazilan.priceText).toBe("199 TL");
    expect(yazilan.priceAmount).toBe(199);
  });

  it("eksik satır silinmez, taslak olarak yine de kurulur", async () => {
    await topluUrunEkle(istek([FATURA_SATIRLARI[1]]));

    const yazilan = mocks.createProduct.mock.calls[0][0];
    expect(mocks.createProduct).toHaveBeenCalledTimes(1);
    expect(yazilan.isVisible).toBe(false);
    expect(yazilan.imageUrls).toHaveLength(1);
  });
});

// Faturadan gelen satırın yayına çıkması için dört kapı birden geçmelidir:
// kanıtlı kart durumu, esnafın satış fiyatı, onayladığı stok ve kart onayı.
// Bu testler tek tek kapıyı kapatıp ürünün taslakta kaldığını kanıtlar.
describe("faturadan gelen satirin yayin kapisi", () => {
  const FATURA_URUNU = {
    name: "Elit Erkek Elastan Sıfır Yaka",
    description: "Pamuklu, nefes alan kumaş.",
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
  };

  beforeEach(() => {
    vi.clearAllMocks();
    mocks.get.mockReturnValue("owner-cookie");
    mocks.verifyOwner.mockReturnValue({ storeId: "store-1" });
    mocks.admin.mockImplementation(() => ({ from: adminMock() }));
    mocks.createProduct.mockResolvedValue({ id: "urun-1", slug: "urun-1" });
  });

  it("dört kapı + ayrı Yayınla birlikte açılınca ürün vitrine çıkar", async () => {
    const cevap = await topluUrunEkle(istek([FATURA_URUNU]));
    const govde = await cevap.json();

    expect(govde.yayinda).toBe(1);
    expect(govde.taslak).toBe(0);
    // Satır önce taslak kurulur, sonra publish RPC'si görünür yapar.
    expect(mocks.createProduct.mock.calls[0][0].isVisible).toBe(false);
    expect(mocks.publishProduct).toHaveBeenCalledTimes(1);
    expect(mocks.publishProduct.mock.calls[0][0]).toMatchObject({
      productId: "urun-1",
      editToken: "token-1",
    });
  });

  it("kapılar tam ama Yayınla denmemişse ürün taslak kaydedilir", async () => {
    const cevap = await topluUrunEkle(istek([{ ...FATURA_URUNU, yayinIstegi: false }]));
    const govde = await cevap.json();

    expect(govde.yayinda).toBe(0);
    expect(govde.taslak).toBe(1);
    expect(govde.satirlar[0].sebep).toContain("Yayın onayı");
    expect(mocks.publishProduct).not.toHaveBeenCalled();
    expect(mocks.createProduct.mock.calls[0][0].isVisible).toBe(false);
  });

  it("yayın isteği hiç gönderilmezse de ürün taslak kaydedilir", async () => {
    const { yayinIstegi: _atilan, ...isteksiz } = FATURA_URUNU;
    void _atilan;
    const cevap = await topluUrunEkle(istek([isteksiz]));
    const govde = await cevap.json();

    expect(govde.yayinda).toBe(0);
    expect(govde.taslak).toBe(1);
    expect(mocks.publishProduct).not.toHaveBeenCalled();
  });

  it("publish RPC kapıyı kapatırsa ürün taslak kalır ve sebep yazar", async () => {
    mocks.publishProduct.mockResolvedValueOnce({ success: false, hata: "Satış fiyatı girilmedi." });
    const cevap = await topluUrunEkle(istek([FATURA_URUNU]));
    const govde = await cevap.json();

    expect(govde.yayinda).toBe(0);
    expect(govde.taslak).toBe(1);
    expect(govde.satirlar[0].sebep).toContain("Satış fiyatı");
  });

  it("kanıtlı olmayan satır yayına çıkmaz", async () => {
    const cevap = await topluUrunEkle(
      istek([{ ...FATURA_URUNU, kartDurumu: "iz-yok" }]),
    );
    const govde = await cevap.json();

    expect(govde.yayinda).toBe(0);
    expect(govde.taslak).toBe(1);
    expect(govde.satirlar[0].sebep).toContain("kanıtlı değil");
    expect(mocks.createProduct.mock.calls[0][0].isVisible).toBe(false);
  });

  it("stok onaylanmadan satır yayına çıkmaz", async () => {
    const cevap = await topluUrunEkle(
      istek([{ ...FATURA_URUNU, stokOnaylandi: false }]),
    );
    const govde = await cevap.json();

    expect(govde.yayinda).toBe(0);
    expect(govde.satirlar[0].sebep).toContain("Stok onaylanmadı");
  });

  it("esnaf kartı onaylamadan satır yayına çıkmaz", async () => {
    const cevap = await topluUrunEkle(
      istek([{ ...FATURA_URUNU, ownerApproved: false }]),
    );
    const govde = await cevap.json();

    expect(govde.yayinda).toBe(0);
    expect(govde.satirlar[0].sebep).toContain("onaylanmadı");
  });

  it("alış fiyatı kartta görünmez, yalnız kilitli tabloya yazılır", async () => {
    const cevap = await topluUrunEkle(
      istek([{ ...FATURA_URUNU, purchasePriceAmount: 137 }]),
    );
    const govde = await cevap.json();

    // Ürün kartı hiçbir alanında alış fiyatını taşımaz.
    const yazilan = mocks.createProduct.mock.calls[0][0];
    expect(JSON.stringify(yazilan)).not.toContain("137");
    expect(yazilan.priceAmount).toBe(199);

    // Alış fiyatı ayrı, kilitli tabloya yazılır ve ürün taslakta kalmaz.
    expect(mocks.upsert).toHaveBeenCalledWith(
      expect.objectContaining({ amount: 137, store_id: "store-1" }),
      { onConflict: "product_id" },
    );
    expect(govde.yayinda).toBe(1);
  });

  it("aynı islemKimligi+satirIndex iki kez gönderilince ikinci çağrı yeni ürün oluşturmuyor", async () => {
    const depo = new Map<string, string>();
    const baglantiliFrom = (tablo: string) => {
      if (tablo === "invoice_product_links") {
        let jobId: string | null = null;
        let lineIndex: number | null = null;
        const zincir: Record<string, unknown> = {};
        (zincir as { select: unknown }).select = vi.fn(() => zincir);
        (zincir as { eq: unknown }).eq = vi.fn((kolon: string, deger: unknown) => {
          if (kolon === "job_id") jobId = deger as string;
          if (kolon === "line_index") lineIndex = deger as number;
          return zincir;
        });
        (zincir as { maybeSingle: unknown }).maybeSingle = vi.fn(async () => {
          const anahtar = `${jobId}:${lineIndex}`;
          if (jobId !== null && lineIndex !== null && depo.has(anahtar)) {
            return { data: { product_id: depo.get(anahtar) }, error: null };
          }
          return { data: null, error: null };
        });
        (zincir as { insert: unknown }).insert = vi.fn(
          async (satir: Record<string, unknown>) => {
            depo.set(`${satir.job_id}:${satir.line_index}`, satir.product_id as string);
            return { error: null };
          },
        );
        return zincir;
      }
      return adminMock()(tablo);
    };
    mocks.admin.mockImplementation(() => ({ from: baglantiliFrom }));

    const satir = { ...FATURA_URUNU, islemKimligi: "job-1", satirIndex: 0 };
    const ilk = await topluUrunEkle(istek([satir]));
    expect((await ilk.json()).satirlar[0].durum).toBe("yayinda");

    const ikinci = await topluUrunEkle(istek([satir]));
    const ikinciGovde = await ikinci.json();

    expect(mocks.createProduct).toHaveBeenCalledTimes(1);
    expect(ikinciGovde.satirlar[0].durum).toBe("atlandi");
    expect(ikinciGovde.satirlar[0].sebep).toContain("zaten yazılmış");
    expect(ikinciGovde.satirlar[0].id).toBe("urun-1");
  });
});
