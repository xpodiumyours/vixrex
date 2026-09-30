import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  get: vi.fn(() => "owner-cookie"),
  admin: vi.fn(),
  verifyOwner: vi.fn(() => ({ storeId: "store-1" })),
  createProduct: vi.fn(),
  updateProduct: vi.fn(),
  publishProduct: vi.fn(async () => ({ success: true, id: "urun-1" })),
  dogrula: vi.fn(),
  bagla: vi.fn(),
  geriAl: vi.fn(),
  mevcutOku: vi.fn(),
  update: vi.fn(),
  jeton: vi.fn(),
}));
vi.mock("next/headers", () => ({ cookies: vi.fn(async () => ({ get: mocks.get })) }));
vi.mock("@/lib/supabaseAdmin", () => ({ getSupabaseAdmin: mocks.admin }));
vi.mock("@/lib/ownerSession", () => ({
  OWNER_SESSION_COOKIE: "vixrex_owner_session",
  verifyOwnerSession: mocks.verifyOwner,
}));
vi.mock("@/lib/instagramServer", () => ({ verifyStoreEditToken: mocks.jeton }));
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
vi.mock("@/lib/productCoreServer", () => ({
  createRichCoreProduct: mocks.createProduct,
  updateRichCoreProduct: mocks.updateProduct,
  publishInvoiceProduct: mocks.publishProduct,
}));
vi.mock("@/lib/faturaUrunBaglantisi", () => ({
  satiriDogrula: mocks.dogrula,
  satiriUrunleBagla: mocks.bagla,
  urunuGeriAl: mocks.geriAl,
  mevcutUrunuOku: mocks.mevcutOku,
}));

import { POST as topluUrunEkle } from "@/app/api/products/batch/route";

const STORE = { id: "store-1", edit_token: "token-1", name: "Deneme Butik" };
const ISLEM = "11111111-1111-4111-8111-111111111111";
const GORSEL = "https://firma.example/urun-1.jpg";

function adminMock() {
  return vi.fn((tablo: string) => {
    if (tablo === "stores") {
      const query = { select: vi.fn(), eq: vi.fn(), single: vi.fn() };
      query.select.mockReturnValue(query);
      query.eq.mockReturnValue(query);
      query.single.mockResolvedValue({ data: STORE, error: null });
      return query;
    }
    if (tablo === "products") {
      const query = { select: vi.fn(), eq: vi.fn(), maybeSingle: vi.fn(), update: mocks.update };
      query.select.mockReturnValue(query);
      query.eq.mockReturnValue(query);
      query.maybeSingle.mockResolvedValue({
        data: { id: "kategori-1", product_template_key: "fashion" },
        error: null,
      });
      mocks.update.mockReturnValue({ eq: vi.fn(async () => ({ error: null })) });
      return query;
    }
    const query = { select: vi.fn(), eq: vi.fn(), maybeSingle: vi.fn(), upsert: vi.fn() };
    query.select.mockReturnValue(query);
    query.eq.mockReturnValue(query);
    query.upsert.mockResolvedValue({ error: null });
    query.maybeSingle.mockResolvedValue({
      data: { id: "kategori-1", product_template_key: "fashion" },
      error: null,
    });
    return query;
  });
}

function satir(fazla: Record<string, unknown> = {}) {
  return {
    name: "Işılay İnterlok Penye Erkek Takım",
    priceText: "499 TL",
    categoryId: "kategori-1",
    barcode: "8681128321677",
    imageUrls: [GORSEL],
    stockQuantity: 8,
    sourceType: "invoice",
    kartDurumu: "kanitli",
    stokOnaylandi: true,
    ownerApproved: true,
    yayinIstegi: true,
    islemKimligi: ISLEM,
    satirSirasi: 0,
    variants: [{ id: "v-16747", options: { color: "Siyah", size: "L" } }],
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
  return new NextRequest("http://localhost/api/products/batch", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ slug: "deneme-vitrin", products }),
  });
}

function dogrulanmis(fazla: Record<string, unknown> = {}) {
  return {
    satirId: "satir-1",
    sonuc: "kanitli",
    urunId: null,
    izinliGorseller: new Set([GORSEL]),
    ...fazla,
  };
}

beforeEach(() => {
  vi.clearAllMocks();
  mocks.get.mockReturnValue("owner-cookie");
  mocks.verifyOwner.mockReturnValue({ storeId: "store-1" });
  mocks.admin.mockImplementation(() => ({ from: adminMock() }));
  mocks.createProduct.mockResolvedValue({ id: "urun-1", slug: "urun-1", created: true });
  mocks.publishProduct.mockResolvedValue({ success: true, id: "urun-1" });
  mocks.dogrula.mockResolvedValue(dogrulanmis());
  mocks.bagla.mockResolvedValue(true);
  mocks.mevcutOku.mockResolvedValue(null);
});

describe("fatura satırı → ürün bağlantısı", () => {
  it("tarayıcının 'kanıtlı' etiketi tek başına yetmez: sunucudaki sonuç eksikse yayın olmaz", async () => {
    mocks.dogrula.mockResolvedValue(dogrulanmis({ sonuc: "eksik" }));

    const govde = await (await topluUrunEkle(istek([satir()]))).json();

    expect(mocks.publishProduct).not.toHaveBeenCalled();
    expect(govde.yayinda).toBe(0);
    expect(govde.taslak).toBe(1);
  });

  it("işlem ve satır kimliği doğrulanamayan satır yayına çıkamaz", async () => {
    mocks.dogrula.mockResolvedValue(null);

    const govde = await (await topluUrunEkle(istek([satir({ islemKimligi: undefined })]))).json();

    expect(mocks.publishProduct).not.toHaveBeenCalled();
    expect(govde.yayinda).toBe(0);
  });

  it("satırla kayıtlı olmayan dış görsel karta girmez", async () => {
    mocks.dogrula.mockResolvedValue(dogrulanmis({ izinliGorseller: new Set<string>() }));

    await topluUrunEkle(istek([satir({ imageUrls: [GORSEL, "https://baska.example/sizan.jpg"] })]));

    expect(mocks.createProduct.mock.calls[0][0].imageUrls).toEqual([]);
  });

  it("yeni ürün satıra bağlanır", async () => {
    const govde = await (await topluUrunEkle(istek([satir()]))).json();

    expect(mocks.bagla).toHaveBeenCalledWith(expect.anything(), "satir-1", "urun-1");
    expect(govde.satirlar[0].kayit).toBe("yeni");
  });

  it("aynı satır yeniden kaydedilince ikinci ürün oluşmaz, aynı ürün güncellenir ve stok korunur", async () => {
    mocks.dogrula.mockResolvedValue(dogrulanmis({ urunId: "urun-9" }));
    mocks.mevcutOku.mockResolvedValue({
      id: "urun-9",
      stockQuantity: 5,
      stockStatus: "Mevcut",
      gorunur: false,
    });

    const govde = await (await topluUrunEkle(istek([satir({ stockQuantity: 8 })]))).json();

    expect(mocks.createProduct).not.toHaveBeenCalled();
    expect(mocks.updateProduct).toHaveBeenCalledTimes(1);
    expect(mocks.updateProduct.mock.calls[0][0]).toMatchObject({
      productId: "urun-9",
      stockQuantity: 5,
      priceText: "499 TL",
    });
    expect(govde.satirlar[0].kayit).toBe("guncellendi");
  });

  it("aynı ürün başka alışverişten gelirse mevcut kayıt korunur, üzerine yazılmaz", async () => {
    mocks.createProduct.mockResolvedValue({ id: "urun-3", slug: "urun-3", created: false });

    const govde = await (await topluUrunEkle(istek([satir()]))).json();

    expect(govde.satirlar[0].kayit).toBe("mevcut");
    expect(mocks.update).not.toHaveBeenCalled();
    expect(mocks.geriAl).not.toHaveBeenCalled();
  });

  it("ürün yazıldı ama satır bağlantısı yazılamadıysa yarım kayıt bırakılmaz", async () => {
    mocks.bagla.mockResolvedValue(false);

    const govde = await (await topluUrunEkle(istek([satir()]))).json();

    expect(mocks.geriAl).toHaveBeenCalledWith(expect.anything(), "store-1", "urun-1");
    expect(govde.hatali).toBe(1);
    expect(govde.yayinda).toBe(0);
    expect(mocks.publishProduct).not.toHaveBeenCalled();
  });
});

describe("telefon: çerez yerine edit_token ile aynı kapı", () => {
  it("çerezi olmayan istek geçerli jetonla aynı sunucu doğrulamasından geçer", async () => {
    mocks.verifyOwner.mockReturnValue(null as never);
    mocks.jeton.mockResolvedValue({ id: "store-1", slug: "deneme-vitrin" });

    const cevap = await topluUrunEkle(
      new NextRequest("http://localhost/api/products/batch", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ slug: "deneme-vitrin", editToken: "token-1", products: [satir()] }),
      }),
    );

    expect(cevap.status).toBe(200);
    expect(mocks.jeton).toHaveBeenCalledWith("deneme-vitrin", "token-1");
    expect(mocks.dogrula).toHaveBeenCalledTimes(1);
  });

  it("geçersiz jeton reddedilir ve hiçbir ürün yazılmaz", async () => {
    mocks.verifyOwner.mockReturnValue(null as never);
    mocks.jeton.mockRejectedValue(new Error("STORE_AUTH_FAILED"));

    const cevap = await topluUrunEkle(
      new NextRequest("http://localhost/api/products/batch", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ slug: "deneme-vitrin", editToken: "kotu", products: [satir()] }),
      }),
    );

    expect(cevap.status).toBe(401);
    expect(mocks.createProduct).not.toHaveBeenCalled();
  });
});
