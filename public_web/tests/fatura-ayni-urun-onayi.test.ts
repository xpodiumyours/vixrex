import { beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({ update: vi.fn(), upsert: vi.fn(), rpc: vi.fn() }));

vi.mock("@/lib/productCoreServer", () => ({ updateRichCoreProduct: mocks.update }));

import { ayniUrunOlabilirMi, faturaUrununuKaydet } from "@/lib/faturaUrunBaglantisi";

const MEVCUT = {
  id: "urun-seker",
  slug: "torku-toz-seker-1-kg",
  name: "Torku Toz Şeker 1 kg",
  description: "",
  price_text: "39,90 TL",
  price_amount: 39.9,
  image_urls: ["seker.jpg"],
  category_id: "kat-1",
  stock_status: "Mevcut",
  stock_quantity: 10,
  old_price_amount: null,
  badge_tag: null,
  fulfillment_region: null,
  brand: "Torku",
  barcode: "",
  metadata: {},
  variants: [],
  is_visible: true,
  is_active: true,
};

interface SatirDurumu {
  product_id: string | null;
  merge_candidate_product_id: string | null;
  merge_decision: string | null;
}

function adminKur(args: { satir: SatirDurumu; urunler: Record<string, unknown>[] }) {
  const satir = { ...args.satir };
  const from = vi.fn((tablo: string) => {
    const filtre = new Map<string, unknown>();
    let guncelleme: Record<string, unknown> | null = null;
    const q: Record<string, unknown> = {};
    q.select = vi.fn(() => q);
    q.eq = vi.fn((kolon: string, deger: unknown) => {
      filtre.set(kolon, deger);
      return q;
    });
    q.update = vi.fn((yeni: Record<string, unknown>) => {
      guncelleme = yeni;
      return q;
    });
    q.upsert = mocks.upsert;
    q.maybeSingle = vi.fn(async () => {
      if (tablo === "invoice_job_lines") {
        return { data: { id: "satir-1", ...satir }, error: null };
      }
      if (filtre.has("id")) {
        return { data: args.urunler.find((urun) => urun.id === filtre.get("id")) ?? null, error: null };
      }
      return { data: null, error: null };
    });
    q.then = (tamam: (deger: unknown) => unknown) =>
      Promise.resolve({ data: tablo === "products" ? args.urunler : [], error: null }).then(tamam);
    // `.eq("id", ...)` sonrası update zinciri: eq -> then
    const eskiEq = q.eq as unknown as (kolon: string, deger: unknown) => unknown;
    q.eq = vi.fn((kolon: string, deger: unknown) => {
      eskiEq(kolon, deger);
      if (guncelleme) {
        satir.merge_candidate_product_id =
          (guncelleme.merge_candidate_product_id as string | null) ?? satir.merge_candidate_product_id;
        satir.merge_decision = (guncelleme.merge_decision as string | null) ?? satir.merge_decision;
        guncelleme = null;
      }
      return q;
    });
    return q;
  });
  return { admin: { from, rpc: mocks.rpc } as never, satir };
}

function girdi(fazla: Record<string, unknown> = {}) {
  return {
    name: "Torku Kristal Şeker 1 kg",
    brand: "Torku",
    barcode: "",
    stockQuantity: 12,
    imageUrls: [],
    priceAmount: 44,
    priceText: "44 TL",
    variants: [],
    ...fazla,
  };
}

beforeEach(() => {
  vi.clearAllMocks();
  mocks.update.mockResolvedValue(undefined);
  mocks.upsert.mockResolvedValue({ error: null });
  mocks.rpc.mockResolvedValue({
    data: { success: true, id: "yeni-1", slug: "yeni-1", created: true, kayit: "yeni" },
    error: null,
  });
});

describe("aynı ürün olabilir kuralı", () => {
  it("aynı marka, aynı miktar, farklı ad yazımı aday üretir", () => {
    expect(ayniUrunOlabilirMi(MEVCUT, girdi())).toBe(true);
  });

  it("miktar farklıysa aday olmaz", () => {
    expect(ayniUrunOlabilirMi(MEVCUT, girdi({ name: "Torku Kristal Şeker 500 g" }))).toBe(false);
  });

  it("marka farklıysa aday olmaz", () => {
    expect(ayniUrunOlabilirMi(MEVCUT, girdi({ brand: "Başakşehir" }))).toBe(false);
  });

  it("barkod varsa tahmin sorulmaz", () => {
    expect(ayniUrunOlabilirMi(MEVCUT, girdi({ barcode: "8690000000005" }))).toBe(false);
  });

  it("ad birebir aynıysa bu kural değil, kesin eşleşme çalışır", () => {
    expect(ayniUrunOlabilirMi(MEVCUT, girdi({ name: "Torku Toz Şeker 1 kg" }))).toBe(false);
  });

  it("ortak kelime yoksa aday olmaz", () => {
    expect(
      ayniUrunOlabilirMi({ ...MEVCUT, name: "Torku Ayçiçek Yağı 1 L" }, girdi({ name: "Torku Kristal Şeker 1 L" })),
    ).toBe(false);
  });
});

describe("kart sessizce ikinci kez açılmaz", () => {
  it("barkodsuz şüpheli satırda kart açmaz, adayı satıra yazar", async () => {
    const c = adminKur({
      satir: { product_id: null, merge_candidate_product_id: null, merge_decision: null },
      urunler: [MEVCUT],
    });
    const sonuc = await faturaUrununuKaydet(c.admin, {
      storeId: "store-1",
      editToken: "token-1",
      satirId: "satir-1",
      girdi: girdi(),
      kanit: {},
      alisFiyati: 30,
    });

    expect(sonuc).toEqual({ durum: "onay-bekliyor", aday: { id: "urun-seker", ad: "Torku Toz Şeker 1 kg" } });
    expect(mocks.rpc).not.toHaveBeenCalled();
    expect(mocks.update).not.toHaveBeenCalled();
    expect(c.satir.merge_candidate_product_id).toBe("urun-seker");
  });

  it("\"ayrı ürün\" cevabından sonra kart normal yoldan açılır", async () => {
    const c = adminKur({
      satir: { product_id: null, merge_candidate_product_id: "urun-seker", merge_decision: "ayri" },
      urunler: [MEVCUT],
    });
    const sonuc = await faturaUrununuKaydet(c.admin, {
      storeId: "store-1",
      editToken: "token-1",
      satirId: "satir-1",
      girdi: girdi(),
      kanit: {},
      alisFiyati: 30,
    });

    expect(mocks.rpc).toHaveBeenCalledWith("save_invoice_product", expect.objectContaining({ p_line_id: "satir-1" }));
    expect(sonuc).toEqual({ durum: "kaydedildi", id: "yeni-1", slug: "yeni-1", created: true, kayit: "yeni" });
  });

  it("\"aynı ürün\" cevabı var olan kartın stoğunu toplar, yeni kart açmaz", async () => {
    const c = adminKur({
      satir: { product_id: null, merge_candidate_product_id: "urun-seker", merge_decision: "birlestir" },
      urunler: [MEVCUT],
    });
    const sonuc = await faturaUrununuKaydet(c.admin, {
      storeId: "store-1",
      editToken: "token-1",
      satirId: "satir-1",
      girdi: girdi(),
      kanit: {},
      alisFiyati: 30,
    });

    expect(mocks.rpc).not.toHaveBeenCalled();
    expect(mocks.update).toHaveBeenCalledWith(
      expect.objectContaining({ productId: "urun-seker", stockQuantity: 22, priceAmount: 39.9 }),
    );
    expect(sonuc).toEqual({
      durum: "kaydedildi",
      id: "urun-seker",
      slug: "torku-toz-seker-1-kg",
      created: false,
      kayit: "guncellendi",
    });
  });

  it("kapanmış (birleştirilmiş) karta stok eklenmez; aday da olmaz", async () => {
    const kapali = { ...MEVCUT, is_active: false, is_visible: false };
    const c = adminKur({
      satir: { product_id: null, merge_candidate_product_id: null, merge_decision: null },
      urunler: [kapali],
    });
    const sonuc = await faturaUrununuKaydet(c.admin, {
      storeId: "store-1",
      editToken: "token-1",
      satirId: "satir-1",
      girdi: girdi(),
      kanit: {},
      alisFiyati: 30,
    });

    expect(sonuc.durum).toBe("kaydedildi");
    expect(mocks.rpc).toHaveBeenCalledOnce();
    expect(mocks.update).not.toHaveBeenCalled();
  });
});
