import { describe, expect, it } from "vitest";
import { faturaSahipGuncellemesi } from "@/lib/faturaYayinKilidi";

// publish_invoice_product koşulları (20261107120000 migration):
// - owner_state.satisFiyati sayısal olarak products.price_amount ile eşit olmalı
// - owner_state.stok >= 0, onayli=true, fatura_kanit.esnafOnayladi=true
describe("faturaSahipGuncellemesi", () => {
  it("geçerli 499 fiyat / 5 stok girdisini RPC koşullarına uyan çıktıya çevirir", () => {
    const sonuc = faturaSahipGuncellemesi({
      priceAmount: 499,
      stockQuantity: 5,
      mevcutOwnerState: { satisFiyati: "0", stok: 0, onayli: false },
      mevcutFaturaKanit: { satirId: "abc", kaynak: "https://ornek.com/urun" },
    });
    expect(sonuc).not.toBeNull();
    expect(sonuc?.ownerState).toEqual({
      satisFiyati: "499",
      stok: 5,
      onayli: true,
    });
    expect(sonuc?.faturaKanitGuncellemesi).toEqual({
      satirId: "abc",
      kaynak: "https://ornek.com/urun",
      esnafOnayladi: true,
    });
  });

  it("mevcut owner_state içindeki esnafGorselleri gibi alanları korur", () => {
    const sonuc = faturaSahipGuncellemesi({
      priceAmount: 499,
      stockQuantity: 5,
      mevcutOwnerState: {
        satisFiyati: "0",
        stok: 0,
        onayli: false,
        esnafGorselleri: ["https://cdn.vixrex.com/storage/v1/object/public/shelf-images/d1/products/f1.jpg"],
      },
      mevcutFaturaKanit: null,
    });
    expect(sonuc?.ownerState.esnafGorselleri).toEqual([
      "https://cdn.vixrex.com/storage/v1/object/public/shelf-images/d1/products/f1.jpg",
    ]);
    expect(sonuc?.faturaKanitGuncellemesi).toEqual({ esnafOnayladi: true });
  });

  it("satisFiyati metni, products.price_amount sayısal değerine RPC parse kuralıyla eşit olmalı", () => {
    const durumlar: Array<[number, number]> = [
      [499, 499],
      [499.5, 499.5],
      [1200, 1200],
    ];
    for (const [priceAmount, beklenenAmount] of durumlar) {
      const sonuc = faturaSahipGuncellemesi({
        priceAmount,
        stockQuantity: 3,
        mevcutOwnerState: null,
        mevcutFaturaKanit: null,
      });
      const satisFiyati = sonuc?.ownerState.satisFiyati;
      expect(typeof satisFiyati).toBe("string");
      // RPC: strpos(satisFiyati, ',')>0 ? TR formatı düzelt : direkt parse
      const parsed =
        (satisFiyati as string).indexOf(",") > 0
          ? Number((satisFiyati as string).replace(/\./g, "").replace(",", "."))
          : Number(satisFiyati);
      expect(parsed).toBe(beklenenAmount);
      expect(parsed <= 0).toBe(false);
    }
  });

  it("fiyat 0 iken null döner (senkron yok)", () => {
    const sonuc = faturaSahipGuncellemesi({
      priceAmount: 0,
      stockQuantity: 5,
      mevcutOwnerState: { onayli: false },
      mevcutFaturaKanit: {},
    });
    expect(sonuc).toBeNull();
  });

  it("fiyat null iken null döner", () => {
    const sonuc = faturaSahipGuncellemesi({
      priceAmount: null,
      stockQuantity: 5,
      mevcutOwnerState: null,
      mevcutFaturaKanit: null,
    });
    expect(sonuc).toBeNull();
  });

  it("negatif fiyat null döner", () => {
    const sonuc = faturaSahipGuncellemesi({
      priceAmount: -1,
      stockQuantity: 5,
      mevcutOwnerState: null,
      mevcutFaturaKanit: null,
    });
    expect(sonuc).toBeNull();
  });

  it("stok null (hizmet) iken null döner — RPC stok toplamı kuralı", () => {
    const sonuc = faturaSahipGuncellemesi({
      priceAmount: 499,
      stockQuantity: null,
      mevcutOwnerState: { satisFiyati: "0", stok: 0 },
      mevcutFaturaKanit: {},
    });
    expect(sonuc).toBeNull();
  });

  it("negatif stok null döner", () => {
    const sonuc = faturaSahipGuncellemesi({
      priceAmount: 499,
      stockQuantity: -2,
      mevcutOwnerState: null,
      mevcutFaturaKanit: null,
    });
    expect(sonuc).toBeNull();
  });
});
