import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  get: vi.fn(() => "owner-cookie"),
  admin: vi.fn(),
  verifyOwner: vi.fn(() => ({ storeId: "store-1" })),
  createProduct: vi.fn(),
  upsert: vi.fn(async () => ({ error: null })),
}));
vi.mock("next/headers", () => ({ cookies: vi.fn(async () => ({ get: mocks.get })) }));
vi.mock("@/lib/supabaseAdmin", () => ({ getSupabaseAdmin: mocks.admin }));
vi.mock("@/lib/ownerSession", () => ({
  OWNER_SESSION_COOKIE: "vixrex_owner_session",
  verifyOwnerSession: mocks.verifyOwner,
}));
vi.mock("@/lib/productCoreServer", () => ({ createRichCoreProduct: mocks.createProduct }));

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
    const query = { select: vi.fn(), eq: vi.fn(), maybeSingle: vi.fn(), upsert: mocks.upsert };
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

  it("dört kapı birlikte açılınca ürün vitrine çıkar", async () => {
    const cevap = await topluUrunEkle(istek([FATURA_URUNU]));
    const govde = await cevap.json();

    expect(govde.yayinda).toBe(1);
    expect(govde.taslak).toBe(0);
    expect(mocks.createProduct.mock.calls[0][0].isVisible).toBe(true);
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
});
