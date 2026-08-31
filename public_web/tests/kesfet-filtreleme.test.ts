import { describe, expect, it } from "vitest";
import { kesfetVitrinleriniFiltrele } from "@/lib/kesfetFiltreleme";
import type { BusinessTemplateGroup } from "@/lib/businessCategories";

const gruplar = new Map<string, BusinessTemplateGroup>([
  ["teknik_servis", "hizmet"],
  ["giyim", "perakende"],
]);

const vitrinler = [
  {
    ad: "Teknofix",
    aciklama: "Aynı gün cihaz onarımı",
    kategoriEtiketi: "Teknik Servis",
    kategoriKimligi: "teknik_servis",
    konum: "Kadıköy, İstanbul",
    urunAdlari: ["OLED ekran değişimi", "Batarya"],
    kiralikMi: false,
  },
  {
    ad: "Aymira",
    aciklama: "Yeni sezon kadın giyim",
    kategoriEtiketi: "Giyim",
    kategoriKimligi: "giyim",
    konum: "Çankaya, Ankara",
    urunAdlari: ["Keten gömlek"],
    kiralikMi: true,
  },
];

const temelFiltre = {
  sorgu: "",
  grup: "tumu" as const,
  kategoriKimligi: null,
  sadeceFavoriler: false,
  favoriAdlari: [] as string[],
  sadeceKiralik: false,
};

describe("Keşfet filtreleme sözleşmesi", () => {
  it("vitrin, açıklama, kategori, konum ve ürün adında arar", () => {
    for (const sorgu of ["Teknofix", "cihaz", "Servis", "Kadıköy", "ekran"]) {
      expect(
        kesfetVitrinleriniFiltrele(
          vitrinler,
          { ...temelFiltre, sorgu },
          gruplar
        )
      ).toEqual([vitrinler[0]]);
    }
  });

  it("grup, kategori, favori ve yalnız kiralık filtrelerini birlikte uygular", () => {
    expect(
      kesfetVitrinleriniFiltrele(
        vitrinler,
        {
          ...temelFiltre,
          grup: "perakende",
          kategoriKimligi: "giyim",
          sadeceFavoriler: true,
          favoriAdlari: ["Aymira"],
          sadeceKiralik: true,
        },
        gruplar
      )
    ).toEqual([vitrinler[1]]);
  });
});
