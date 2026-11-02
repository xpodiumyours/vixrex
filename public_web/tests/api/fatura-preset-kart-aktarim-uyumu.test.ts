import { describe, expect, it } from "vitest";
import type { SupabaseClient } from "@supabase/supabase-js";
import { faturaSatiriniAktar } from "@/lib/faturaPresetAktarimi";
import { kayitliFaturaKatalogunuUygula } from "@/lib/faturaUrunHazirlama";
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
    // Bu çalışmada stok birleştirme davranışı değişmesin.
    expect(girdi.variants).toEqual([]);
    expect(girdi.metadata.attributes).toEqual(expect.arrayContaining([
      expect.objectContaining({ key: "size", value: "4" }),
      expect.objectContaining({ key: "variant", value: "Siyah" }),
    ]));
  });
});
