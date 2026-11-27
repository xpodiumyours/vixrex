import { describe, expect, it } from "vitest";
import { resmiMarkaRafiniAyir } from "../src/lib/resmiMarkaRafi";
import type { RichProductItem } from "../src/lib/richProductItem";

function urunYap(ek: Partial<RichProductItem>): RichProductItem {
  return {
    id: "u-1",
    name: "Örnek Ürün",
    price: "250 TL",
    source: "manual",
    metadata: {},
    ...ek,
  };
}

describe("resmiMarkaRafiniAyir", () => {
  it("dogrulanmis fatura urunu yoksa null doner ve tum urunleri korur", () => {
    const liste = [
      urunYap({ id: "1", name: "Klasik Gömlek", source: "manual" }),
      urunYap({ id: "2", name: "Keten Pantolon", source: "manual" }),
    ];
    const sonuc = resmiMarkaRafiniAyir(liste);
    expect(sonuc.resmiMarkaAdi).toBeNull();
    expect(sonuc.resmiUrunler).toHaveLength(0);
    expect(sonuc.digerUrunler).toHaveLength(2);
  });

  it("telif onayi bekleyen fatura urunlerini resmi rafa almaz", () => {
    const kilitli = Object.assign(
      urunYap({
        id: "1",
        name: "Tutku Atlet",
        source: "invoice",
        metadata: { brand: "Tutku" },
      }),
      { _telif_onayi_bekliyor: true },
    );
    const sonuc = resmiMarkaRafiniAyir([kilitli]);
    expect(sonuc.resmiMarkaAdi).toBeNull();
    expect(sonuc.resmiUrunler).toHaveLength(0);
    expect(sonuc.digerUrunler).toHaveLength(1);
  });

  it("baskin dogrulanmis markayi ayirir ve toplam urun sayisini korur", () => {
    const liste = [
      urunYap({ id: "1", name: "Tutku 0101", source: "invoice", metadata: { brand: "Tutku" } }),
      urunYap({ id: "2", name: "Tutku 0102", source: "invoice", metadata: { brand: "Tutku" } }),
      urunYap({ id: "3", name: "Alize İp", source: "invoice", metadata: { brand: "Alize" } }),
      urunYap({ id: "4", name: "Esnaf Özel", source: "manual" }),
    ];
    const sonuc = resmiMarkaRafiniAyir(liste);
    expect(sonuc.resmiMarkaAdi).toBe("Tutku");
    expect(sonuc.resmiUrunler.map((u) => u.id)).toEqual(["1", "2"]);
    expect(sonuc.digerUrunler.map((u) => u.id)).toEqual(["3", "4"]);
    expect(sonuc.resmiUrunler.length + sonuc.digerUrunler.length).toBe(liste.length);
  });
});
