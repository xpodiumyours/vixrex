import { describe, expect, it } from "vitest";
import { kartPresetIstekGovdeleri, URUN_KART_PRESET_YENI } from "@/lib/faturaKartPreset";
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

const govdeSatirlari = (govde: Record<string, unknown>) => {
  const mesaj = (govde.messages as Array<{ content: string }>)[0].content;
  const veri = JSON.parse(mesaj.slice(mesaj.lastIndexOf("\n") + 1)) as {
    groups: Array<{ rows: Array<{ row_id: string }> }>;
  };
  return veri.groups.flatMap((g) => g.rows.map((r) => r.row_id));
};

describe("kart isteği parçalama", () => {
  it("20 satırı küresel row_id korunarak 5'erli parçalara böler", () => {
    const govdeler = kartPresetIstekGovdeleri(okuma(20), "yeni");
    expect(govdeler).toHaveLength(4);
    expect(govdeler.map(govdeSatirlari)).toEqual([
      ["1", "2", "3", "4", "5"],
      ["6", "7", "8", "9", "10"],
      ["11", "12", "13", "14", "15"],
      ["16", "17", "18", "19", "20"],
    ]);
    for (const govde of govdeler) expect(govde.model).toBe(URUN_KART_PRESET_YENI);
  });

  it("5 ve altı satırda tek gövde üretir", () => {
    expect(kartPresetIstekGovdeleri(okuma(5), "yeni")).toHaveLength(1);
    expect(kartPresetIstekGovdeleri(okuma(1), "yeni")).toHaveLength(1);
  });
});
