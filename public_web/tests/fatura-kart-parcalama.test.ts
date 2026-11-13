import { describe, expect, it } from "vitest";
import { kartPresetIstekGovdeleri, kartPresetIstekGovdesi, kartPresetIstekGovdesiSatirlar, URUN_KART_PRESET_YENI } from "@/lib/faturaKartPreset";
import type { GoruSonucu } from "@/lib/faturaGoru";

const okuma = (adet: number): GoruSonucu =>
  ({
    tedarikci: "Tedarikçi",
    satirlar: Array.from({ length: adet }, (_, i) => ({
      satirNo: i + 1, hamSatir: `Satır ${i + 1}`, ad: `Ürün ${i + 1}`, model: `M-${i + 1}`,
      marka: i % 2 ? "B" : "A", barkod: `869${i}`, varyant: "", beden: "", gramaj: "",
      adet: 1, birim: "adet", birimFiyat: 10, tutar: 10,
    })),
  }) as unknown as GoruSonucu;

const satir = (sira: number, marka: string, barkod: string, model = `M-${sira}`) => ({
  satirNo: sira, hamSatir: `Satır ${sira}`, ad: `Ürün ${sira}`, model,
  marka, barkod, varyant: "", beden: "", gramaj: "",
  adet: 1, birim: "adet", birimFiyat: 10, tutar: 10,
});

const govdeVerisi = (govde: Record<string, unknown>) => {
  const mesaj = (govde.messages as Array<{ content: string }>)[0].content;
  return JSON.parse(mesaj.slice(mesaj.lastIndexOf("\n") + 1)) as {
    supplier: { name: string; role?: string };
    groups: Array<{ brand: string; rows: Array<{ row_id: string; brand: string }> }>;
  };
};

const govdeSatirlari = (govde: Record<string, unknown>) =>
  govdeVerisi(govde).groups.flatMap((g) => g.rows.map((r) => r.row_id));

describe("kart isteği parçalama", () => {
  it("20 satırı üretici kümesine göre böler; aynı marka farklı paketlere dağılmaz", () => {
    const govdeler = kartPresetIstekGovdeleri(okuma(20), "yeni");
    expect(govdeler).toHaveLength(4);
    const kumeler = govdeler.map((g) => govdeSatirlari(g).sort((a, b) => Number(a) - Number(b)));
    expect(kumeler).toEqual([
      ["1", "3", "5", "7", "9"],
      ["11", "13", "15", "17", "19"],
      ["2", "4", "6", "8", "10"],
      ["12", "14", "16", "18", "20"],
    ]);
    for (const govde of govdeler) {
      expect(govde.model).toBe(URUN_KART_PRESET_YENI);
      expect(new Set(govdeVerisi(govde).groups.flatMap((g) => g.rows.map((r) => r.brand))).size).toBe(1);
    }
  });

  it("küçük üretici kümelerini bölmeden, parça sınırını aşmadan paketler", () => {
    const satirlar = Array.from({ length: 10 }, (_, i) =>
      satir(i + 1, ["A", "B", "C", "D", "E"][i % 5] ?? "", ""));
    const govdeler = kartPresetIstekGovdeleri({ tedarikci: "Tedarikçi", satirlar } as unknown as GoruSonucu, "yeni", 5);
    expect(govdeler.map((g) => govdeSatirlari(g))).toEqual([
      ["1", "6", "2", "7"],
      ["3", "8", "4", "9"],
      ["5", "10"],
    ]);
    for (const govde of govdeler) expect(govdeSatirlari(govde).length).toBeLessThanOrEqual(5);
  });

  it("parça sınırını tek başına aşan kümeyi kendi içinde dilimler", () => {
    const satirlar = Array.from({ length: 7 }, (_, i) => satir(i + 1, "A", ""));
    const govdeler = kartPresetIstekGovdeleri({ tedarikci: "Tedarikçi", satirlar } as unknown as GoruSonucu, "yeni", 5);
    expect(govdeler.map((g) => govdeSatirlari(g))).toEqual([["1", "2", "3", "4", "5"], ["6", "7"]]);
  });

  it("markası boş satırları GS1 üretici önekiyle aynı kümeye toplar", () => {
    const satirlar = [satir(1, "", "8691234000010"), satir(2, "", "8691234000029")];
    const gruplar = govdeVerisi(kartPresetIstekGovdesi({ tedarikci: "Tedarikçi", satirlar } as unknown as GoruSonucu)).groups;
    expect(gruplar).toHaveLength(1);
    expect(gruplar[0].rows.map((r) => r.row_id)).toEqual(["1", "2"]);
  });

  it("markasız satırı tek markalı faturada markanın kümesine katar", () => {
    const satirlar = [satir(1, "Tutku", ""), satir(2, "", "")];
    const gruplar = govdeVerisi(kartPresetIstekGovdesi({ tedarikci: "Tedarikçi", satirlar } as unknown as GoruSonucu)).groups;
    expect(gruplar).toHaveLength(1);
    expect(gruplar[0].rows.map((r) => r.row_id)).toEqual(["1", "2"]);
  });

  it("araştırmadan önce tekrar satırları süzer; yalnız kanonik satır gönderilir", () => {
    const satirlar = [satir(1, "A", "8691234567890"), satir(2, "A", "8691234567890"), satir(3, "B", "")];
    const tek = kartPresetIstekGovdesi({ tedarikci: "Tedarikçi", satirlar } as unknown as GoruSonucu, "yeni");
    expect(govdeSatirlari(tek).sort()).toEqual(["1", "3"]);
    const parcalar = kartPresetIstekGovdeleri({ tedarikci: "Tedarikçi", satirlar } as unknown as GoruSonucu, "yeni");
    expect(parcalar.flatMap((g) => govdeSatirlari(g)).sort()).toEqual(["1", "3"]);
  });

  it("geri dönüş yolunda tekrar satırlar gönderilmeye devam eder", () => {
    const satirlar = [satir(1, "A", "8691234567890"), satir(2, "A", "8691234567890")];
    const tek = kartPresetIstekGovdesi({ tedarikci: "Tedarikçi", satirlar } as unknown as GoruSonucu, "mevcut");
    expect(govdeSatirlari(tek).sort()).toEqual(["1", "2"]);
  });

  it("karantina tamamlamada yalnız seçili satırları küresel kimliğiyle taşır", () => {
    const govde = kartPresetIstekGovdesiSatirlar(okuma(20), [20, 3, 3, 99], "yeni");
    expect(govdeSatirlari(govde).sort((a, b) => Number(a) - Number(b))).toEqual(["3", "20"]);
  });

  it("5 ve altı satırda tek gövde üretir", () => {
    expect(kartPresetIstekGovdeleri(okuma(5), "yeni")).toHaveLength(1);
    expect(kartPresetIstekGovdeleri(okuma(1), "yeni")).toHaveLength(1);
  });
});
