import { beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  update: vi.fn(),
  rpc: vi.fn(),
  baglamalar: [] as Record<string, unknown>[],
}));

vi.mock("@/lib/productCoreServer", () => ({ updateRichCoreProduct: mocks.update }));

import { faturaUrununuKaydet } from "@/lib/faturaUrunBaglantisi";

interface Durum {
  satirUrunId?: string | null;
  barkodlu?: Record<string, unknown> | null;
  urunler?: Record<string, unknown>[];
}

const MEVCUT = {
  id: "urun-9",
  slug: "popkek",
  name: "Popkek",
  description: "Kakaolu kek",
  price_text: "",
  price_amount: null,
  image_urls: ["a.jpg"],
  category_id: "kat-1",
  stock_status: "Mevcut",
  stock_quantity: 2,
  old_price_amount: null,
  badge_tag: null,
  fulfillment_region: null,
  brand: "Eti",
  barcode: "8690000000005",
  metadata: {},
  variants: [],
  is_visible: false,
};

function adminKur(durum: Durum) {
  return vi.fn((tablo: string) => {
    const sorgu: { barkod: boolean; kimlik: boolean } = { barkod: false, kimlik: false };
    const q: Record<string, unknown> = {};
    q.select = vi.fn(() => q);
    q.eq = vi.fn((kolon: string) => {
      if (kolon === "barcode") sorgu.barkod = true;
      if (kolon === "id") sorgu.kimlik = true;
      return q;
    });
    q.update = vi.fn((yeni: Record<string, unknown>) => {
      if (tablo === "invoice_job_lines") mocks.baglamalar.push(yeni);
      return { eq: vi.fn(async () => ({ error: null })) };
    });
    q.upsert = vi.fn(async () => ({ error: null }));
    q.maybeSingle = vi.fn(async () => {
      if (tablo === "invoice_job_lines") {
        return { data: { product_id: durum.satirUrunId ?? null }, error: null };
      }
      return { data: sorgu.barkod ? (durum.barkodlu ?? null) : null, error: null };
    });
    q.then = (tamam: (deger: unknown) => unknown) =>
      Promise.resolve({
        data: tablo === "products" && !sorgu.barkod ? (durum.urunler ?? []) : [],
        error: null,
      }).then(tamam);
    return q;
  });
}

beforeEach(() => {
  vi.clearAllMocks();
  mocks.baglamalar.length = 0;
  mocks.update.mockResolvedValue(undefined);
  mocks.rpc.mockResolvedValue({
    data: { success: true, id: "yeni-1", slug: "yeni-1", created: true, kayit: "yeni" },
    error: null,
  });
});

describe("fatura ürün tekrar kilidi", () => {
  it("aynı barkodlu ürün ikinci kez kart açmaz; mevcut kartın stoğu artar", async () => {
    const admin = { from: adminKur({ satirUrunId: null, barkodlu: MEVCUT }), rpc: mocks.rpc } as never;
    const sonuc = await faturaUrununuKaydet(admin, {
      storeId: "store-1",
      editToken: "token-1",
      satirId: "satir-1",
      girdi: {
        name: "Popkek",
        brand: "Eti",
        barcode: "8690000000005",
        stockQuantity: 3,
        imageUrls: ["b.jpg"],
        priceAmount: 12,
        priceText: "12 TL",
        variants: [],
      },
      kanit: {},
      alisFiyati: 7,
    });

    expect(mocks.rpc).not.toHaveBeenCalled();
    expect(mocks.update).toHaveBeenCalledWith(
      expect.objectContaining({
        productId: "urun-9",
        stockQuantity: 5,
        imageUrls: ["a.jpg", "b.jpg"],
      }),
    );
    expect(mocks.baglamalar).toContainEqual(expect.objectContaining({ product_id: "urun-9" }));
    expect(sonuc).toEqual({ id: "urun-9", slug: "popkek", created: false, kayit: "guncellendi" });
  });

  it("eksik fiyat tamamlanır, dolu fiyat değiştirilmez", async () => {
    const admin = { from: adminKur({ satirUrunId: null, barkodlu: MEVCUT }), rpc: mocks.rpc } as never;
    await faturaUrununuKaydet(admin, {
      storeId: "store-1",
      editToken: "token-1",
      satirId: "satir-1",
      girdi: { name: "Popkek", brand: "Eti", barcode: "8690000000005", stockQuantity: 1, priceAmount: 12, variants: [] },
      kanit: {},
      alisFiyati: null,
    });
    expect(mocks.update).toHaveBeenCalledWith(expect.objectContaining({ priceAmount: 12 }));

    mocks.update.mockClear();
    const doluFiyatli = { from: adminKur({ satirUrunId: null, barkodlu: { ...MEVCUT, price_amount: 10 } }), rpc: mocks.rpc } as never;
    await faturaUrununuKaydet(doluFiyatli, {
      storeId: "store-1",
      editToken: "token-1",
      satirId: "satir-2",
      girdi: { name: "Popkek", brand: "Eti", barcode: "8690000000005", stockQuantity: 1, priceAmount: 99, variants: [] },
      kanit: {},
      alisFiyati: null,
    });
    expect(mocks.update).toHaveBeenCalledWith(expect.objectContaining({ priceAmount: 10 }));
  });

  it("barkodsuz üründe ad + marka eşleşmesi kartı birleştirir", async () => {
    const admin = { from: adminKur({
      satirUrunId: null,
      urunler: [{ ...MEVCUT, barcode: "", image_urls: ["a.jpg"] }],
    }), rpc: mocks.rpc } as never;
    const sonuc = await faturaUrununuKaydet(admin, {
      storeId: "store-1",
      editToken: "token-1",
      satirId: "satir-1",
      girdi: { name: " Popkek ", brand: "ETİ", stockQuantity: 4, imageUrls: [], variants: [] },
      kanit: {},
      alisFiyati: null,
    });
    expect(mocks.rpc).not.toHaveBeenCalled();
    expect(sonuc.kayit).toBe("guncellendi");
    expect(mocks.update).toHaveBeenCalledWith(expect.objectContaining({ stockQuantity: 6 }));
  });

  it("farklı varyant aynı kart sayılmaz; yeni kart açılır", async () => {
    const admin = { from: adminKur({
      satirUrunId: null,
      urunler: [{ ...MEVCUT, barcode: "", variants: [{ id: "v-1", options: { size: "L" } }] }],
    }), rpc: mocks.rpc } as never;
    const sonuc = await faturaUrununuKaydet(admin, {
      storeId: "store-1",
      editToken: "token-1",
      satirId: "satir-1",
      girdi: {
        name: "Popkek",
        brand: "Eti",
        stockQuantity: 2,
        variants: [{ id: "v-2", options: { size: "XL" } }],
      },
      kanit: {},
      alisFiyati: null,
    });
    expect(mocks.update).not.toHaveBeenCalled();
    expect(mocks.rpc).toHaveBeenCalledWith(
      "save_invoice_product",
      expect.objectContaining({ p_line_id: "satir-1" }),
    );
    expect(sonuc).toEqual({ id: "yeni-1", slug: "yeni-1", created: true, kayit: "yeni" });
  });

  it("satır zaten bir ürüne bağlıysa ön kontrole girilmez", async () => {
    const admin = { from: adminKur({ satirUrunId: "urun-9", barkodlu: MEVCUT }), rpc: mocks.rpc } as never;
    await faturaUrununuKaydet(admin, {
      storeId: "store-1",
      editToken: "token-1",
      satirId: "satir-1",
      girdi: { name: "Popkek", brand: "Eti", barcode: "8690000000005", stockQuantity: 3, variants: [] },
      kanit: {},
      alisFiyati: null,
    });
    expect(mocks.update).not.toHaveBeenCalled();
    expect(mocks.baglamalar).toHaveLength(0);
    expect(mocks.rpc).toHaveBeenCalledOnce();
  });
});
