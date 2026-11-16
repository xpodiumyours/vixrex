import { describe, expect, it, vi } from "vitest";
import sharp from "sharp";
import type { SupabaseClient } from "@supabase/supabase-js";
import { faturaSatiriniAktar } from "@/lib/faturaPresetAktarimi";
import { faturaUrunGorselleriniAktar, kayitliFaturaKatalogunuUygula } from "@/lib/faturaUrunHazirlama";
import { tekKartSozlesmesi } from "@/lib/faturaKartSozlesmesi";
import { buildProductCardFacts } from "@/lib/productCardPresentation";
import type { GoruSatiri } from "@/lib/faturaGoru";
import type { HazirUrunGirdisi } from "@/lib/productIntake";
import type { DogrulanmisSatir } from "@/lib/faturaUrunBaglantisi";

const resmiGorsel = "https://uretici.example/urun.webp";
const esnafGorseli = "https://depo.example/esnaf.jpg";

function okunanSatir(ek: Partial<GoruSatiri> = {}): GoruSatiri {
  return {
    satirNo: 1, hamSatir: "TER0105 Siyah Beden 4",
    model: "TER0105", ad: "Tutku Fanila", barkod: "8680508918971",
    varyant: "Siyah", beden: "4", marka: "Tutku",
    adet: 2, birim: "adet", birimFiyat: 100, tutar: 200,
    okumaGuveni: 0.9, siteVaryant: "Siyah",
    siteSayfa: "https://uretici.example/urun", siteGorseller: [resmiGorsel],
    dogrulamaDurumu: "Doğrulandı", ...ek,
  };
}

describe("OpenRouter → Vixrex kayıt sınırı (stok eşleştirmesi sabit)", () => {
  it("faturadaki kimlik, beden ve varyant metinleri kaybolmaz", () => {
    const satir = faturaSatiriniAktar(okunanSatir(), "Tedarikçi");
    expect(satir).toMatchObject({
      barkod: "8680508918971", adet: 2, alisBirimFiyat: 100,
      beden: "4", varyant: "Siyah",
      katalog: { beden: "4", varyant: "Siyah", gorseller: [resmiGorsel] },
    });
    expect(satir.katalog?.urunVaryantlari).toBeUndefined();
  });

  it("ikinci preset varyantı katalogda kalır; yeni stok/ürün eşleştirmesi yaratılmaz", () => {
    const satir = faturaSatiriniAktar(
      okunanSatir({ varyant: "Siyah", siteVaryant: "Lacivert", dogrulamaDurumu: "Belirsiz" }),
      "Tedarikçi",
    );
    expect(satir.varyant).toBe("Siyah");
    expect(satir.katalog?.varyant).toBe("Lacivert");
    expect(satir.katalog?.urunVaryantlari).toBeUndefined();
  });

  it("Vixrex tekilleştirme kararı katalog snapshot'a aynen taşınır", () => {
    const satir=faturaSatiriniAktar(okunanSatir({
      duplicateGroup:"üretici-ürün-grubu",canonicalRowId:"2",
    }),"Tedarikçi");
    expect(satir.katalog).toMatchObject({
      duplicateGroup:"üretici-ürün-grubu",canonicalRowId:"2",
    });
  });

  it("üretici görseli uygulanırken esnaf görseli ve mevcut stok-varyant kuralı korunur", async () => {
    const sonuc = faturaSatiriniAktar(okunanSatir(), "Tedarikçi");
    const girdi = {
      name: "Tutku Fanila", imageUrls: [resmiGorsel, esnafGorseli],
      variants: [], metadata: {}, categoryId: "",
    } as unknown as HazirUrunGirdisi;
    const hata = await kayitliFaturaKatalogunuUygula({
      admin: {} as SupabaseClient,
      storeId: "store", editToken: "token", girdi,
      satir: { sonuc: "kanitli", katalog: sonuc.katalog } as DogrulanmisSatir,
      kategoriOnbellegi: new Map(),
    });
    expect(hata).toBeNull();
    expect(girdi.imageUrls).toEqual([resmiGorsel, esnafGorseli]);
    expect(girdi.variants).toEqual([]);
    expect(girdi.metadata.attributes).toEqual(expect.arrayContaining([
      expect.objectContaining({ key: "size", value: "4" }),
      expect.objectContaining({ key: "variant", value: "Siyah" }),
    ]));
  });

  it("image_candidates içindeki resmî katalog görseli ve kaynağı düşürülmez", () => {
    const sozlesme = tekKartSozlesmesi({
      row_id: "1",
      title: "Tutku Erkek Thermal Fanila",
      brand: "Tutku",
      image_url: null,
      official_product_url: null,
      image_candidates: [
        {
          url: "https://cdn.myikas.com/images/74e89546/image_1080.webp",
          source_url: "https://sehermensucat.com/products.xml",
        },
      ],
      validation: { status: "ambiguous" },
    });
    expect(sozlesme.gorselAdresi).toBe("https://cdn.myikas.com/images/74e89546/image_1080.webp");
    expect(sozlesme.resmiSayfa).toBe("https://sehermensucat.com/products.xml");
    expect(sozlesme.dogrulanmis).toBe(false);
  });

  it("tüketici vitrin kartında aktarılan iç varyant etiketi tekrarlanmaz", () => {
    const satir = faturaSatiriniAktar(
      okunanSatir({ varyant: "Y.Haki", beden: "S / 2", siteVaryant: "Y.Haki / S / 2" }),
      "Tedarikçi",
    );
    const girdi = {
      name: "Tutku Fanila", imageUrls: [resmiGorsel],
      variants: [], metadata: {}, categoryId: "",
    } as unknown as HazirUrunGirdisi;
    void kayitliFaturaKatalogunuUygula({
      admin: {} as SupabaseClient,
      storeId: "store", editToken: "token", girdi,
      satir: { sonuc: "kanitli", katalog: satir.katalog } as DogrulanmisSatir,
      kategoriOnbellegi: new Map(),
    });
    const kart = buildProductCardFacts({ brand: "Tutku", metadata: girdi.metadata });
    expect(kart.ozellikler.map((o) => o.value)).toContain("Y.Haki");
    expect(kart.ozellikler.map((o) => o.value)).toContain("S / 2");
    expect(kart.ozellikler.map((o) => o.value)).not.toContain("Y.Haki / S / 2");
  });

  it("faturaUrunGorselleriniAktar üretici sayfasını tekrar kazımadan CDN görselini karta yerleştirir", async () => {
    const cdnGorsel = "https://cdn.myikas.com/images/74e89546/urun.jpg";
    const piksel = await sharp({
      create: { width: 1200, height: 1200, channels: 3, background: { r: 220, g: 220, b: 220 } },
    }).jpeg().toBuffer();
    const fetchSpy = vi.spyOn(globalThis, "fetch").mockImplementation(async (input) => {
      const url = String(input);
      if (url === cdnGorsel) return new Response(new Uint8Array(piksel), { status: 200 });
      return new Response("yok", { status: 404 });
    });
    const admin = {
      storage: {
        from: () => ({
          upload: async () => ({ error: null }),
          getPublicUrl: (yol: string) => ({
            data: { publicUrl: `https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/shelf-images/${yol}` },
          }),
        }),
      },
    } as unknown as SupabaseClient;
    const sonuc = await faturaUrunGorselleriniAktar({
      admin,
      slug: "deneme-vitrin",
      girdi: { imageUrls: [cdnGorsel], variants: [] } as unknown as HazirUrunGirdisi,
      satir: {
        satirId: "satir-1",
        sonuc: "kanitli",
        urunId: null,
        izinliGorseller: new Set([cdnGorsel]),
        katalog: { kaynak: "https://sehermensucat.com/products.xml", resmiAd: "Tutku Fanila" },
        alisBirimFiyati: 100,
        varyant: "Beyaz",
        beden: "M",
      },
    });
    expect(sonuc.gorselDurumu).toBe("depoda");
    expect(sonuc.urunGorselleri).toHaveLength(1);
    expect(sonuc.urunGorselleri[0]).toContain("/storage/v1/object/public/shelf-images/deneme-vitrin/products/fatura/");
    expect(fetchSpy).toHaveBeenCalledTimes(1);
    fetchSpy.mockRestore();
  });
});
