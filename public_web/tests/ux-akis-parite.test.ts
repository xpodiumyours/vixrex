import { describe, expect, it } from "vitest";
import {
  KESFET_LIMIT,
  kategoriVitrinleriniGetir,
  type KesfetVitrini,
} from "@/lib/explore";
import { kesfetVitrinleriniFiltrele } from "@/lib/kesfetFiltreleme";
import type { BusinessTemplateGroup } from "@/lib/businessCategories";

const kategoriGruplari = new Map<string, BusinessTemplateGroup>([
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
  grup: undefined as BusinessTemplateGroup | undefined,
  kategoriKimligi: null,
  sadeceFavoriler: false,
  favoriAdlari: [] as string[],
  sadeceKiralik: false,
};

describe("UX akışı — gerçek Keşfet filtreleme ve veri yardımcıları", () => {
  it("global arama vitrin, açıklama, kategori, konum ve ürün adını gerçekten tarar", () => {
    for (const sorgu of ["teknofix", "CİHAZ", "servis", "kadıköy", "ekran"]) {
      expect(
        kesfetVitrinleriniFiltrele(
          vitrinler,
          { ...temelFiltre, sorgu },
          kategoriGruplari,
        ),
      ).toEqual([vitrinler[0]]);
    }
  });

  it("grup + kategori + favori + yalnız kiralık filtrelerini birlikte uygular", () => {
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
        kategoriGruplari,
      ),
    ).toEqual([vitrinler[1]]);
  });

  it("kategori akışı yükleyicinin gerçek sonucunu süzer ve hata kurtarmasını çalıştırır", async () => {
    const liste: KesfetVitrini[] = [
      {
        slug: "a",
        ad: "A",
        aciklama: "",
        kategoriEtiketi: "Giyim",
        kategoriKimligi: "giyim",
        kapakUrl: null,
        konum: "Ankara",
        kiralikMi: false,
        acikMi: true,
        urunSayisi: 0,
        urunAdlari: [],
        whatsapp: null,
        guncellemeZamani: null,
      },
      {
        slug: "b",
        ad: "B",
        aciklama: "",
        kategoriEtiketi: "Teknik Servis",
        kategoriKimligi: "teknik_servis",
        kapakUrl: null,
        konum: "İstanbul",
        kiralikMi: false,
        acikMi: true,
        urunSayisi: 0,
        urunAdlari: [],
        whatsapp: null,
        guncellemeZamani: null,
      },
    ];

    await expect(
      kategoriVitrinleriniGetir("giyim", async () => liste),
    ).resolves.toEqual([liste[0]]);
    await expect(
      kategoriVitrinleriniGetir("giyim", async () => {
        throw new Error("geçici kesinti");
      }),
    ).resolves.toEqual([]);
  });

  it("Keşfet veri katmanının gerçek kayıt sınırını dışa aktarır", () => {
    expect(KESFET_LIMIT).toBe(50);
  });
});
