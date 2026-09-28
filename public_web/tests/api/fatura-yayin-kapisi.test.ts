import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

// Faturadan gelen satırın yayın kapısı.
//
// Kural: fotoğrafı ve zorunlu alanları tam olsa bile, esnaf satış fiyatını
// girip kartı açıkça onaylamadan ürün vitrinde görünmez. Alış fiyatı da
// satış fiyatı yerine geçmez ve ürün kartına sızmaz.

const mocks = vi.hoisted(() => ({
  get: vi.fn(() => "owner-cookie"),
  admin: vi.fn(),
  verifyOwner: vi.fn(() => ({ storeId: "store-1" })),
  createProduct: vi.fn(),
  update: vi.fn(),
  upsert: vi.fn(),
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
        eq: vi.fn(() => ({ eq: vi.fn(async () => ({ error: null })) })),
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

/** Fotoğrafı ve zorunlu alanları tam, yani kapıyı yalnız onay/fiyat tutar. */
function faturaSatiri(fazla: Record<string, unknown> = {}) {
  return {
    name: "Elit Erkek Elastan Sıfır Yaka Uzun Kol",
    priceText: "199 TL",
    categoryId: "kategori-1",
    barcode: "8681128321677",
    imageUrls: FOTOGRAFLAR,
    stockQuantity: 2,
    sourceType: "invoice",
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
  return new NextRequest("http://localhost/api/products/batch", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ slug: "deneme-vitrin", products }),
  });
}

describe("faturadan gelen ürünün yayın kapısı", () => {
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

  it("esnaf onayı yoksa ürün taslak kalır", async () => {
    const cevap = await topluUrunEkle(istek([faturaSatiri({ ownerApproved: false })]));
    const govde = await cevap.json();

    expect(mocks.createProduct.mock.calls[0][0].isVisible).toBe(false);
    expect(govde.yayinda).toBe(0);
    expect(govde.taslak).toBe(1);
    expect(govde.satirlar[0].sebep).toContain("onaylanmadı");
  });

  it("onay alanı hiç gönderilmezse de ürün taslak kalır", async () => {
    await topluUrunEkle(istek([faturaSatiri()]));
    expect(mocks.createProduct.mock.calls[0][0].isVisible).toBe(false);
  });

  it("satış fiyatı girilmemişse onaylı olsa bile taslak kalır", async () => {
    const cevap = await topluUrunEkle(
      istek([faturaSatiri({ ownerApproved: true, priceText: "" })]),
    );
    const govde = await cevap.json();

    expect(mocks.createProduct.mock.calls[0][0].isVisible).toBe(false);
    expect(govde.satirlar[0].sebep).toContain("Satış fiyatı");
  });

  it("onay ve satış fiyatı birlikte varsa ürün yayına çıkar", async () => {
    const cevap = await topluUrunEkle(istek([faturaSatiri({ ownerApproved: true })]));
    const govde = await cevap.json();

    expect(mocks.createProduct.mock.calls[0][0].isVisible).toBe(true);
    expect(govde.yayinda).toBe(1);
  });

  it("fotoğrafı eksik ürün, onaylı ve fiyatlı olsa bile taslak kalır", async () => {
    const cevap = await topluUrunEkle(
      istek([faturaSatiri({ ownerApproved: true, imageUrls: [FOTOGRAFLAR[0]] })]),
    );
    const govde = await cevap.json();

    expect(mocks.createProduct.mock.calls[0][0].isVisible).toBe(false);
    expect(govde.satirlar[0].sebep).toContain("fotoğraf");
  });

  it("alış fiyatı ürün kartına hiçbir alandan sızmaz", async () => {
    await topluUrunEkle(
      istek([faturaSatiri({ ownerApproved: true, purchasePriceAmount: 137 })]),
    );

    const yazilan = mocks.createProduct.mock.calls[0][0];
    expect(JSON.stringify(yazilan)).not.toContain("137");
    expect(yazilan.priceText).toBe("199 TL");
    expect(yazilan.priceAmount).toBe(199);
  });

  it("alış fiyatı karta değil, kilitli tabloya yazılır", async () => {
    // products tablosunda anon'un tablo düzeyinde okuma yetkisi var; oraya
    // yazılan her alan müşteriye de açılırdı. Bu yüzden ayrı tablo.
    await topluUrunEkle(
      istek([faturaSatiri({ ownerApproved: true, purchasePriceAmount: 137 })]),
    );

    expect(mocks.upsert).toHaveBeenCalledTimes(1);
    const [kayit, secenek] = mocks.upsert.mock.calls[0];
    expect(kayit).toMatchObject({ product_id: "urun-1", store_id: "store-1", amount: 137 });
    expect(secenek).toMatchObject({ onConflict: "product_id" });
    // Ürün kartına hiçbir şekilde yazılmadı.
    expect(mocks.update).not.toHaveBeenCalled();
  });

  it("izinsiz üretici fotoğrafı gönderilirse ürün taslak kalır", async () => {
    // Tarayıcı kapıyı atlayıp doğrudan üretici adresini gönderse bile sunucu
    // tanır: Seher'in izni "bekliyor", fotoğrafı yayına çıkamaz.
    const cevap = await topluUrunEkle(
      istek([
        faturaSatiri({ ownerApproved: true, imageUrls: IZINSIZ_URETICI_FOTOGRAFLARI }),
      ]),
    );
    const govde = await cevap.json();

    expect(mocks.createProduct.mock.calls[0][0].isVisible).toBe(false);
    expect(govde.yayinda).toBe(0);
    expect(govde.satirlar[0].sebep).toContain("izni yok");
  });

  it("izinsiz üretici fotoğrafı ürün kartına hiç yazılmaz", async () => {
    await topluUrunEkle(
      istek([
        faturaSatiri({ ownerApproved: true, imageUrls: IZINSIZ_URETICI_FOTOGRAFLARI }),
      ]),
    );

    const yazilan: string[] = mocks.createProduct.mock.calls[0][0].imageUrls;
    for (const adres of IZINSIZ_URETICI_FOTOGRAFLARI) {
      expect(yazilan).not.toContain(adres);
    }
  });

  it("esnaf kendi fotoğrafını koyarsa aynı ürün yayına çıkar", async () => {
    // İzin kuralı esnafı kilitlemez: kendi çektiği fotoğrafla sistem uçtan
    // uca çalışır. Kilitlenen yalnız izinsiz ÜRETİCİ fotoğrafıdır.
    const cevap = await topluUrunEkle(
      istek([faturaSatiri({ ownerApproved: true, imageUrls: FOTOGRAFLAR })]),
    );
    const govde = await cevap.json();

    expect(mocks.createProduct.mock.calls[0][0].isVisible).toBe(true);
    expect(govde.yayinda).toBe(1);
  });

  it("Excel/XML gibi fatura dışı kaynaklar eski davranışını korur", async () => {
    await topluUrunEkle(
      istek([faturaSatiri({ sourceType: "bulk_import", ownerApproved: undefined })]),
    );

    expect(mocks.createProduct.mock.calls[0][0].isVisible).toBe(true);
  });
});
