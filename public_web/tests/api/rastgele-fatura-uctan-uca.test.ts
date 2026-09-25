import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";
import seherHam from "@/data/uretici-katalog-seher.json";
import type { UreticiUrunu } from "@/lib/ureticiKatalog";

// Rastgele faturaların GERÇEK /api/products/batch uç noktasından geçtiğinde
// ne olduğunu kanıtlar — yalnız eşleştirme fonksiyonunu değil, tüm HTTP
// isteği/yanıtı döngüsünü. Katalogdan gerçekten var olan ürünler tohumlu
// rastgelelikle seçilir; hiçbir satır elle uydurulmaz.

const mocks = vi.hoisted(() => ({
  get: vi.fn(() => "owner-cookie"),
  admin: vi.fn(),
  verifyOwner: vi.fn(() => ({ storeId: "store-1" })),
  createProduct: vi.fn(),
  update: vi.fn(),
}));
vi.mock("next/headers", () => ({ cookies: vi.fn(async () => ({ get: mocks.get })) }));
vi.mock("@/lib/supabaseAdmin", () => ({ getSupabaseAdmin: mocks.admin }));
vi.mock("@/lib/ownerSession", () => ({
  OWNER_SESSION_COOKIE: "vixrex_owner_session",
  verifyOwnerSession: mocks.verifyOwner,
}));
vi.mock("@/lib/productCoreServer", () => ({ createRichCoreProduct: mocks.createProduct }));

import { POST as topluUrunEkle } from "@/app/api/products/batch/route";
import { ureticiUrunuBul } from "@/lib/ureticiKatalog";

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
    if (tablo === "products") {
      const query = { select: vi.fn(), eq: vi.fn(), maybeSingle: vi.fn(), update: mocks.update };
      query.select.mockReturnValue(query);
      query.eq.mockReturnValue(query);
      query.maybeSingle.mockResolvedValue({
        data: { id: "kategori-1", product_template_key: "fashion" },
        error: null,
      });
      mocks.update.mockReturnValue({ eq: vi.fn(() => ({ eq: vi.fn(async () => ({ error: null })) })) });
      return query;
    }
    const query = { select: vi.fn(), eq: vi.fn(), maybeSingle: vi.fn() };
    query.select.mockReturnValue(query);
    query.eq.mockReturnValue(query);
    query.maybeSingle.mockResolvedValue({ data: { id: "kategori-1", product_template_key: "fashion" }, error: null });
    return query;
  });
}

function tohumluRastgele(tohum: number) {
  let durum = tohum >>> 0;
  return () => {
    durum |= 0;
    durum = (durum + 0x6d2b79f5) | 0;
    let t = Math.imul(durum ^ (durum >>> 15), 1 | durum);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/** Katalogdan tohumla rastgele N ürün seçip esnaf panelinin göndereceği
 * gerçek istek gövdesini (InvoiceToProducts.tsx'teki vitrineYaz() ile aynı
 * biçim) üretir — esnaf her satırı onaylamış ve satış fiyatı girmiş kabul
 * edilir, çünkü kapı testi bu şartı ayrı dosyada zaten kanıtlıyor. */
function rastgeleFaturaIstegi(tohum: number, satirSayisi: number) {
  const rastgele = tohumluRastgele(tohum);
  const havuz = [...(seherHam as UreticiUrunu[])];
  const secilenKodlar = new Set<string>();
  const urunler: unknown[] = [];

  while (secilenKodlar.size < satirSayisi) {
    const kod = havuz[Math.floor(rastgele() * havuz.length)].kod;
    if (secilenKodlar.has(kod)) continue;
    secilenKodlar.add(kod);

    const eslesme = ureticiUrunuBul({ model: kod });
    if (!eslesme) continue; // katalogda gerçekten bulunmayan satır faturaya girmez

    const alisFiyati = Math.round((60 + rastgele() * 200) * 100) / 100;
    const satisFiyati = Math.round(alisFiyati * 1.4 * 100) / 100;

    urunler.push({
      name: eslesme.urun.ad,
      description: `${eslesme.urun.ad}. Faturadaki miktar: ${1 + Math.floor(rastgele() * 20)} adet.`,
      priceText: `${satisFiyati} TL`,
      categoryId: "kategori-1",
      imageUrls: eslesme.urun.gorseller,
      barcode: eslesme.urun.barkod || undefined,
      sourceType: "invoice",
      externalProductId: eslesme.urun.barkod || kod,
      ownerApproved: true,
      purchasePriceAmount: alisFiyati,
    });
  }

  return new NextRequest("http://localhost/api/products/batch", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ slug: "deneme-vitrin", products: urunler }),
  });
}

describe("rastgele faturalar gerçek /api/products/batch uç noktasından geçer", () => {
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

  it.each([
    { tohum: 5005, satir: 7 },
    { tohum: 6006, satir: 9 },
    { tohum: 7007, satir: 5 },
  ])("tohum=$tohum: $satir satırlık gerçek istek — hiçbir alış fiyatı karta sızmaz", async ({ tohum, satir }) => {
    const istek = rastgeleFaturaIstegi(tohum, satir);
    const cevap = await topluUrunEkle(istek);
    const govde = await cevap.json();

    expect(cevap.status).toBe(200);
    expect(govde.toplam).toBeGreaterThan(0);
    expect(govde.hatali).toBe(0);

    for (const cagri of mocks.createProduct.mock.calls) {
      const yazilan = cagri[0];
      // Seher katalogundaki alış fiyatları 60-260 TL bandında; bu aralıktaki
      // hiçbir sayı satış metnine/açıklamaya karışmamalı.
      expect(yazilan.priceText).not.toMatch(/\b(6\d|1\d\d|2[0-5]\d)\.\d\d TL\b.*alış/i);
      expect(JSON.stringify(yazilan)).not.toMatch(/alışFiyat|purchasePrice/);
    }
  });

  it("fotoğrafı 3'ten az olan katalog ürünü rastgele faturaya düşerse taslak kalır", async () => {
    // Katalogda bilerek az fotoğraflı bir ürün arıyoruz (gerçek veri).
    const azFotografli = (seherHam as UreticiUrunu[]).find((u) => u.gorseller.length > 0 && u.gorseller.length < 3);
    expect(azFotografli, "test verisi için az fotoğraflı ürün bulunamadı").toBeTruthy();

    const eslesme = ureticiUrunuBul({ model: azFotografli!.kod });
    const istek = new NextRequest("http://localhost/api/products/batch", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        slug: "deneme-vitrin",
        products: [
          {
            name: eslesme!.urun.ad,
            description: "test",
            priceText: "199 TL",
            categoryId: "kategori-1",
            imageUrls: eslesme!.urun.gorseller,
            sourceType: "invoice",
            ownerApproved: true,
          },
        ],
      }),
    });

    const cevap = await topluUrunEkle(istek);
    const govde = await cevap.json();
    expect(govde.taslak).toBe(1);
    expect(govde.yayinda).toBe(0);
  });
});
