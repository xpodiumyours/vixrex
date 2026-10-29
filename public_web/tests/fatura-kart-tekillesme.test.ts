import { expect, it } from "vitest";
import { tekrarGruplari } from "@/lib/faturaKartPreset";

const kayit = (grup: string, kanonik = "1") => new Map([["1", { duplicate_group: grup, canonical_row_id: kanonik }],
  ["2", { duplicate_group: grup, canonical_row_id: kanonik }],
  ["3", { duplicate_group: grup, canonical_row_id: kanonik }]]) as never;

it("aynı barkodlu üç satır tek karta indirilir, kanonik satır modelin dediğidir", () => {
  const satirlar = [
    { barkod: "8690123456789", ad: "Ülker Gofret", marka: "Ülker" },
    { barkod: "8690123456789", ad: "Ülker Gofret", marka: "Ülker" },
    { barkod: "8690123456789", ad: "Ülker Gofret", marka: "Ülker" },
  ];
  const sonuc = tekrarGruplari(satirlar, kayit("ulker-8690123456789"));
  expect([...sonuc.entries()]).toEqual([["2", 1], ["3", 1]]);
});

it("barkodsuz satırda ad 6 karakterden kısaysa birleştirme yapılmaz", () => {
  const satirlar = [
    { barkod: "", ad: "Çay", marka: "Torku" },
    { barkod: "", ad: "Çay", marka: "Torku" },
  ];
  expect(tekrarGruplari(satirlar, kayit("cay")).size).toBe(0);
});

it("barkodsuz satırda marka ve ad aynıysa birleştirme yapılır", () => {
  const satirlar = [
    { barkod: "", ad: "Pınar Süzme Peynir 500 g", marka: "Pınar" },
    { barkod: "", ad: "pınar  süzme peynir 500 g", marka: "Pınar" },
  ];
  expect([...tekrarGruplari(satirlar, kayit("pinar-peynir")).keys()]).toEqual(["2"]);
});

it("barkodsuz satırda marka farklıysa birleştirme yapılmaz", () => {
  const satirlar = [
    { barkod: "", ad: "Süzme Peynir 500 g", marka: "Pınar" },
    { barkod: "", ad: "Süzme Peynir 500 g", marka: "Sütaş" },
  ];
  expect(tekrarGruplari(satirlar, kayit("peynir")).size).toBe(0);
});

it("farklı barkodlar aynı gruba konsa da birleştirilmez", () => {
  const satirlar = [
    { barkod: "8690123456789", ad: "Ürün", marka: "Marka" },
    { barkod: "8690123456790", ad: "Ürün", marka: "Marka" },
  ];
  expect(tekrarGruplari(satirlar, kayit("karisik")).size).toBe(0);
});

it("grup etiketi olmayan satırlar tekilleştirilmez", () => {
  const satirlar = [
    { barkod: "8690123456789", ad: "Ürün A", marka: "Marka" },
    { barkod: "8690123456789", ad: "Ürün A", marka: "Marka" },
  ];
  expect(tekrarGruplari(satirlar, new Map() as never).size).toBe(0);
});
