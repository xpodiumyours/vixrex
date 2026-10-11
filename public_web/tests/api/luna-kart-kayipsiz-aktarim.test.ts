import { describe, expect, it, vi } from "vitest";
import sharp from "sharp";
vi.mock("@/lib/supabaseAdmin", () => ({ getSupabaseAdmin: vi.fn() }));
import { satirKanitKayitlari } from "@/lib/faturaIslemKaydi";
import { satiriDogrula } from "@/lib/faturaUrunBaglantisi";
import { kaynakGorselleriniHazirla } from "@/lib/faturaGorsel";
import { urunGirdisiniHazirla } from "@/lib/productIntake";
import { normalizeProductVariants } from "@/lib/productRichData";
import { buildProductDetailFacts, buildVariantOptionGroups, findMatchingVariant } from "@/lib/productCardPresentation";

import { getProductImages, isPublicCatalogProduct, resolveCatalogImage } from "@/lib/products";

const gorseller = Array.from({ length: 12 }, (_, i) => `https://cdn.example/${i}.jpg`);
const varyantlar = Array.from({ length: 101 }, (_, i) => ({ id: `v${i}`, options: { voltage: String(i) }, imageUrls: gorseller }));

describe("Luna kartı kayıt ve görünüm aktarımı", () => {
  it("fatura kartının görselleri ve yayınlanmış adı eski OCR filtreleriyle gizlenmez", () => {
    const product = { name: "X", source: "invoice", imageUrls: ["https://cdn.example/screenshot-urun.jpg", ...gorseller], isVisible: true };
    expect(getProductImages(product)).toHaveLength(13);
    expect(resolveCatalogImage(product, "https://cdn.example/logo.jpg")).toBe(product.imageUrls[0]);
    expect(isPublicCatalogProduct(product)).toBe(true);
    expect(isPublicCatalogProduct({ ...product, isVisible: false })).toBe(false);
    expect(getProductImages({ ...product, source: "manual" })).toHaveLength(11);
    expect(isPublicCatalogProduct({ ...product, source: "manual" })).toBe(false);
  });
  it("uzun kaynak adresi kayıttan sonra aynı adresle doğrulanır", async () => {
    const adres = `https://cdn.example/photo.jpg?token=${"a".repeat(600)}`;
    const satir = { model: "M1", ad: "Ürün", barkod: "", varyant: "", beden: "", adet: 1, alisBirimFiyat: 2, satirToplam: 2, guven: 1, sonuc: "kanitli" as const,
      katalog: { firma: "Firma", kaynakFirma: "Firma", dayanak: "ad" as const, izinDurumu: "yok" as const, resmiAd: "Ürün", marka: "Firma", aciklama: "", gorseller: [adres], gorselAdaylari: [adres], kaynak: "https://firma.example/urun" } };
    const kayit = satirKanitKayitlari("line", satir, "");
    const admin = { from: (table: string) => {
      const query = { select: () => query, eq: () => query,
        maybeSingle: async () => ({ data: table === "invoice_jobs" ? { id: "job" } : { id: "line", outcome: "kanitli", catalog_snapshot: satir.katalog } }),
        then: (resolve: (value: unknown) => unknown) => Promise.resolve({ data: kayit.gorsel, error: null }).then(resolve),
      }; return query;
    } };
    const dogrulama = await satiriDogrula(admin as never, "store", { islemKimligi: "11111111-1111-4111-8111-111111111111", satirSirasi: 0 }, "kanitli");
    expect(dogrulama?.izinliGorseller.has(adres)).toBe(true);
  });

  it("12 gerçek görsel taslağı reddetmez ve hepsi depoya aktarılır", async () => {
    const sonuc = await urunGirdisiniHazirla({ admin: {} as never, storeId: "store", storeName: "Store", govde: { name: "Ürün", imageUrls: gorseller }, gorselPolitikasi: "toplu", lunaVaryantlariniKoru: true, enAzGorsel: 1 });
    expect(sonuc.durum).not.toBe("reddedildi");
    const bayt = await sharp({ create: { width: 100, height: 100, channels: 3, background: "blue" } }).jpeg().toBuffer();
    const upload = vi.fn(async () => ({ error: null }));
    const hazir = await kaynakGorselleriniHazirla({ slug: "store", kaynakSayfa: "https://firma.example/urun", adaylar: gorseller,
      bagimliliklar: { resolveHost: async () => ["8.8.8.8"], fetcher: async () => new Response(new Uint8Array(bayt)) },
      admin: { storage: { from: () => ({ upload, getPublicUrl: () => ({ data: { publicUrl: "https://depo.example/foto.jpg" } }) }) } },
    });
    expect(upload).toHaveBeenCalledTimes(12);
    expect(hazir.gorseller).toHaveLength(12);
  });

  it("fatura dışı girdinin mevcut görsel sınırı korunur", async () => {
    const sonuc = await urunGirdisiniHazirla({ admin: {} as never, storeId: "store", storeName: "Store", govde: { name: "Ürün", imageUrls: gorseller }, gorselPolitikasi: "toplu" });
    expect(sonuc.durum).toBe("reddedildi");
  });

  it("Luna'nın 101. varyantı ve şablon dışı seçeneği kayıtta ve görünümde korunur", () => {
    expect(normalizeProductVariants(varyantlar, true)).toHaveLength(101);
    expect(normalizeProductVariants(varyantlar)).toHaveLength(100);
    expect(normalizeProductVariants(varyantlar, true)[100].imageUrls).toHaveLength(12);
    expect(buildVariantOptionGroups(varyantlar, "fashion", true)[0].values).toHaveLength(101);
    expect(findMatchingVariant(varyantlar, { voltage: "100" }, "fashion", true)?.id).toBe("v100");
    expect(buildVariantOptionGroups(varyantlar, "fashion")).toEqual([]);
  });

  it("Luna'nın şablon dışı özelliği ürün detayında gösterilir", () => {
    const metadata = { templateKey: "generic", lunaInvoice: true, attributes: [{ key: "voltage", label: "Gerilim", value: "220 V" }] };
    expect(buildProductDetailFacts({ metadata })).toContainEqual({ key: "voltage", label: "Gerilim", value: "220 V" });
    expect(buildProductDetailFacts({ metadata: { ...metadata, lunaInvoice: false } })).not.toContainEqual({ key: "voltage", label: "Gerilim", value: "220 V" });
  });
});
