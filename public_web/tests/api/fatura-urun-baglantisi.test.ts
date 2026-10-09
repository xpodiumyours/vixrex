import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  get: vi.fn(() => "owner-cookie"),
  admin: vi.fn(),
  verifyOwner: vi.fn(() => ({ storeId: "store-1" })),
  save: vi.fn(),
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
  faturaUrununuKaydet: mocks.save,
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
    alisBirimFiyati: 450,
    katalog: { resmiAd: "Işılay İnterlok Penye Erkek Takım", aciklama: "Resmî açıklama", marka: "Işılay", kaynak: "https://firma.example/16747" },
    ...fazla,
  };
}

beforeEach(() => {
  vi.clearAllMocks();
  mocks.get.mockReturnValue("owner-cookie");
  mocks.verifyOwner.mockReturnValue({ storeId: "store-1" });
  mocks.admin.mockImplementation(() => ({ from: adminMock() }));
  mocks.save.mockResolvedValue({ id: "urun-1", slug: "urun-1", created: true, kayit: "yeni" });
  mocks.createProduct.mockResolvedValue({ id: "urun-1", slug: "urun-1", created: true });
  mocks.publishProduct.mockResolvedValue({ success: true, id: "urun-1" });
  mocks.dogrula.mockResolvedValue(dogrulanmis());
  mocks.bagla.mockResolvedValue(true);
  mocks.mevcutOku.mockResolvedValue(null);
});

describe("fatura satırı → atomik ürün kaydı", () => {
  it("tarayıcının kanıtlı etiketi sunucudaki eksik sonucu yayımlatamaz", async () => {
    mocks.dogrula.mockResolvedValue(dogrulanmis({ sonuc: "eksik" }));
    const body = await (await topluUrunEkle(istek([satir()]))).json();
    expect(mocks.publishProduct).not.toHaveBeenCalled();
    expect(body.yayinda).toBe(0);
    expect(body.taslak).toBe(1);
  });
  it("sahipliği doğrulanamayan satır kaydedilemez", async () => {
    mocks.dogrula.mockResolvedValue(null);
    const body = await (await topluUrunEkle(istek([satir({ islemKimligi: undefined })]))).json();
    expect(body.hatali).toBe(1);
    expect(mocks.save).not.toHaveBeenCalled();
    expect(mocks.publishProduct).not.toHaveBeenCalled();
  });
  it("satırın kayıtlı kaynak ve alış bilgisi tek kayıt kapısına taşınır", async () => {
    await topluUrunEkle(istek([satir({ name: "Yanlış ad", purchasePriceAmount: 1 })]));
    expect(mocks.save).toHaveBeenCalledOnce();
    expect(mocks.save.mock.calls[0][1]).toMatchObject({
      satirId: "satir-1", alisFiyati: 450,
      girdi: { name: "Işılay İnterlok Penye Erkek Takım", brand: "Işılay" },
    });
    expect(mocks.createProduct).not.toHaveBeenCalled();
    expect(mocks.bagla).not.toHaveBeenCalled();
  });
  it("ayri yayin istegi olmadan gercek urun ID'si taslak kalir", async () => {
    const body = await (await topluUrunEkle(istek([satir({
      yayinIstegi: false, ownerApproved: true,
    })]))).json();
    expect(body.taslak).toBe(1);
    expect(body.yayinda).toBe(0);
    expect(body.kayitBasarili).toBe(true);
    expect(body.kayitliUrunIdleri).toEqual(["urun-1"]);
    expect(mocks.save).toHaveBeenCalledOnce();
    expect(mocks.publishProduct).not.toHaveBeenCalled();
  });
  it("sahip onayi olmadan dogru gorselli kart dahi yayina cikmaz", async () => {
    const body = await (await topluUrunEkle(istek([satir({
      yayinIstegi: true, ownerApproved: false,
    })]))).json();
    expect(body.yayinda).toBe(0);
    expect(mocks.publishProduct).not.toHaveBeenCalled();
  });
  it("aynı satırın mevcut kimliği atomik kayıttan geri gelir", async () => {
    mocks.dogrula.mockResolvedValue(dogrulanmis({ urunId: "urun-9" }));
    mocks.save.mockResolvedValue({ id: "urun-9", slug: "urun-9", created: false, kayit: "guncellendi" });
    const body = await (await topluUrunEkle(istek([satir()]))).json();
    expect(body.satirlar[0]).toMatchObject({ id: "urun-9", kayit: "guncellendi" });
    expect(mocks.createProduct).not.toHaveBeenCalled();
    expect(mocks.updateProduct).not.toHaveBeenCalled();
  });
  it("transaction hatası başarı veya yayın üretmez; mevcut ürün silinmez", async () => {
    mocks.save.mockRejectedValue(new Error("FATURA_KANIT_YAZILAMADI"));
    const body = await (await topluUrunEkle(istek([satir()]))).json();
    expect(body.hatali).toBe(1);
    expect(body.eklenen).toBe(0);
    expect(body.kayitBasarili).toBe(false);
    expect(body.kayitliUrunIdleri).toEqual([]);
    expect(mocks.publishProduct).not.toHaveBeenCalled();
    expect(mocks.geriAl).not.toHaveBeenCalled();
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
