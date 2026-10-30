import { expect, it } from "vitest";
import { kartPresetYanitiniOku, tekillesmeKarari, tekrarGruplari } from "@/lib/faturaKartPreset";
import type { GoruSonucu } from "@/lib/faturaGoru";

const kart = (grup: string, kanonik = "1", durum = "verified") => ({
  duplicate_group: grup, canonical_row_id: kanonik,
  validation: { status: durum, official_product_url: "https://uretici.example/urun" },
  media: {},
});
const kayit = (grup: string, kanonik = "1", durum = "verified") => new Map([
  ["1", kart(grup, kanonik, durum)], ["2", kart(grup, kanonik, durum)], ["3", kart(grup, kanonik, durum)],
]) as never;

it("aynı barkod + aynı beden tek karta indirilir", () => {
  const satirlar = [
    { barkod: "8680508918971", model: "TER0105", ad: "Tutku Elit Sıfıryaka", marka: "Tutku", beden: "4" },
    { barkod: "8680508918971", model: "TER0105", ad: "Tutku Elit Sıfıryaka", marka: "Tutku", beden: "4" },
    { barkod: "8680508918971", model: "TER0105", ad: "Tutku Elit Sıfıryaka", marka: "Tutku", beden: "4" },
  ];
  const sonuc = tekrarGruplari(satirlar, kayit("tutku-8680508918971"));
  expect([...sonuc.entries()]).toEqual([["2", 1], ["3", 1]]);
});

it("aynı barkod farklı bedende birleştirilmez ve beden ayrışması işaretlenir", () => {
  const satirlar = [
    { barkod: "8680508918971", model: "TER0105", ad: "Tutku Elit Sıfıryaka", marka: "Tutku", beden: "4" },
    { barkod: "8680508918971", model: "TER0105", ad: "Tutku Elit Sıfıryaka", marka: "Tutku", beden: "5" },
  ];
  const karar = tekillesmeKarari(satirlar, kayit("tutku-8680508918971"));
  expect(karar.indirgenen.size).toBe(0);
  expect([...karar.bedenAyrisan].sort()).toEqual(["1", "2"]);
});

it("aynı barkod farklı varyantta birleştirilmez", () => {
  const satirlar = [
    { barkod: "8680508918971", model: "TER0105", ad: "Tutku Elit Sıfıryaka", marka: "Tutku", varyant: "Beyaz" },
    { barkod: "8680508918971", model: "TER0105", ad: "Tutku Elit Sıfıryaka", marka: "Tutku", varyant: "Siyah" },
  ];
  expect(tekrarGruplari(satirlar, kayit("tutku-renk")).size).toBe(0);
});

it("barkodsuz satırda marka, ad ve beden aynıysa birleştirilir", () => {
  const satirlar = [
    { barkod: "", model: "", ad: "Pınar Süzme Peynir 500 g", marka: "Pınar", beden: "500 g" },
    { barkod: "", model: "", ad: "pınar  süzme peynir 500 g", marka: "Pınar", beden: "500 g" },
  ];
  expect([...tekrarGruplari(satirlar, kayit("pinar-peynir")).keys()]).toEqual(["2"]);
});

it("barkodsuz satırda ad 6 karakterden kısaysa birleştirme yapılmaz", () => {
  const satirlar = [
    { barkod: "", model: "", ad: "Çay", marka: "Torku" },
    { barkod: "", model: "", ad: "Çay", marka: "Torku" },
  ];
  expect(tekrarGruplari(satirlar, kayit("cay")).size).toBe(0);
});

it("barkodsuz satırda marka farklıysa birleştirme yapılmaz", () => {
  const satirlar = [
    { barkod: "", model: "", ad: "Süzme Peynir 500 g", marka: "Pınar" },
    { barkod: "", model: "", ad: "Süzme Peynir 500 g", marka: "Sütaş" },
  ];
  expect(tekrarGruplari(satirlar, kayit("peynir")).size).toBe(0);
});

it("doğrulanmamış satırlar birleştirilmez ve kimlik kurulamadı diye işaretlenir", () => {
  const satirlar = [
    { barkod: "8680508918971", model: "TER0105", ad: "Tutku Elit Sıfıryaka", marka: "Tutku", beden: "4" },
    { barkod: "8680508918971", model: "TER0105", ad: "Tutku Elit Sıfıryaka", marka: "Tutku", beden: "4" },
  ];
  const karar = tekillesmeKarari(satirlar, kayit("tutku-belirsiz", "1", "ambiguous"));
  expect(karar.indirgenen.size).toBe(0);
  expect([...karar.kimlikKurulamayan].sort()).toEqual(["1", "2"]);
});

it("resmî kaynak adresi olmayan doğrulanmış satır birleştirilmez", () => {
  const satirlar = [
    { barkod: "8680508918971", model: "TER0105", ad: "Tutku Elit Sıfıryaka", marka: "Tutku", beden: "4" },
    { barkod: "8680508918971", model: "TER0105", ad: "Tutku Elit Sıfıryaka", marka: "Tutku", beden: "4" },
  ];
  const items = new Map([["1", { ...kart("tutku-kaynaksiz"), validation: { status: "verified", official_product_url: "" } }],
    ["2", { ...kart("tutku-kaynaksiz"), validation: { status: "verified", official_product_url: "" } }]]) as never;
  expect(tekrarGruplari(satirlar, items).size).toBe(0);
});

it("canonical_row_id geçersizse ilk satır kanonik olur", () => {
  const satirlar = [
    { barkod: "8690123456789", model: "A1", ad: "Ülker Gofret", marka: "Ülker", beden: "40 g" },
    { barkod: "8690123456789", model: "A1", ad: "Ülker Gofret", marka: "Ülker", beden: "40 g" },
  ];
  const items = new Map([["1", kart("ulker", "9")], ["2", kart("ulker", "9.5")]]) as never;
  expect([...tekrarGruplari(satirlar, items).entries()]).toEqual([["2", 1]]);
});

it("farklı barkodlar aynı gruba konsa da birleştirilmez", () => {
  const satirlar = [
    { barkod: "8690123456789", model: "A1", ad: "Ürün", marka: "Marka" },
    { barkod: "8690123456790", model: "A2", ad: "Ürün", marka: "Marka" },
  ];
  expect(tekrarGruplari(satirlar, kayit("karisik")).size).toBe(0);
});

it("grup etiketi olmayan satırlar tekilleştirilmez", () => {
  const satirlar = [
    { barkod: "8690123456789", model: "A1", ad: "Ürün A", marka: "Marka" },
    { barkod: "8690123456789", model: "A1", ad: "Ürün A", marka: "Marka" },
  ];
  expect(tekrarGruplari(satirlar, new Map() as never).size).toBe(0);
});

const okuma = (satirlar: Array<Record<string, unknown>>) => ({ tedarikci: "Tedarikçi", satirlar }) as unknown as GoruSonucu;
const yanit = (items: unknown[]) => new Response(JSON.stringify({
  choices: [{ message: { content: JSON.stringify({ items }) }, finish_reason: "stop" }],
}), { status: 200, headers: { "content-type": "application/json" } });
const kartKaydi = (id: string, title: string, beden: string, durum = "verified") => ({
  row_id: id, duplicate_group: "tutku-8680508918971", canonical_row_id: "1",
  vixrex_product_json: { title }, validation: { status: durum, official_product_url: "https://uretici.example/urun" },
  media: {}, beden,
});

it("bedenle ayrışan satırların kart başlığında beden görünür", async () => {
  const sonuc = await kartPresetYanitiniOku(yanit([
    kartKaydi("1", "Tutku Elit Sıfıryaka", "4"), kartKaydi("2", "Tutku Elit Sıfıryaka", "5"),
  ]), okuma([
    { hamSatir: "1", model: "TER0105", ad: "Tutku Elit Sıfıryaka", barkod: "8680508918971", beden: "4", marka: "Tutku", adet: 6 },
    { hamSatir: "2", model: "TER0105", ad: "Tutku Elit Sıfıryaka", barkod: "8680508918971", beden: "5", marka: "Tutku", adet: 6 },
  ]));
  expect(sonuc.sonuc.satirlar.map((satir) => satir.ad))
    .toEqual(["Tutku Elit Sıfıryaka (Beden 4)", "Tutku Elit Sıfıryaka (Beden 5)"]);
  expect(sonuc.sonuc.satirlar.map((satir) => satir.adet)).toEqual([6, 6]);
});

it("doğrulanmamış iki satır ayrı kart alır ve ikisi de işaretlenir", async () => {
  const sonuc = await kartPresetYanitiniOku(yanit([
    kartKaydi("1", "Tutku Elit Sıfıryaka", "4", "not_found"),
    kartKaydi("2", "Tutku Elit Sıfıryaka", "4", "not_found"),
  ]), okuma([
    { hamSatir: "1", model: "TER0105", ad: "Tutku Elit Sıfıryaka", barkod: "8680508918971", beden: "4", marka: "Tutku", adet: 6 },
    { hamSatir: "2", model: "TER0105", ad: "Tutku Elit Sıfıryaka", barkod: "8680508918971", beden: "4", marka: "Tutku", adet: 6 },
  ]));
  expect(sonuc.sonuc.satirlar.map((satir) => satir.dogrulamaDurumu)).toEqual(["Bulunamadı", "Bulunamadı"]);
  for (const satir of sonuc.sonuc.satirlar) {
    expect(satir.eksikler).toContain("Aynı ürün doğrulanamadı; ayrı kart açıldı.");
  }
});

it("doğrulanmış aynı ürün iki satırı tek karta indirir", async () => {
  const sonuc = await kartPresetYanitiniOku(yanit([
    kartKaydi("1", "Tutku Elit Sıfıryaka", "4"), kartKaydi("2", "Tutku Elit Sıfıryaka", "4"),
  ]), okuma([
    { hamSatir: "1", model: "TER0105", ad: "Tutku Elit Sıfıryaka", barkod: "8680508918971", beden: "4", marka: "Tutku", adet: 6 },
    { hamSatir: "2", model: "TER0105", ad: "Tutku Elit Sıfıryaka", barkod: "8680508918971", beden: "4", marka: "Tutku", adet: 6 },
  ]));
  expect(sonuc.sonuc.satirlar[0].ad).toBe("Tutku Elit Sıfıryaka");
  expect(sonuc.sonuc.satirlar[0].adet).toBe(12);
  expect(sonuc.sonuc.satirlar[1].adet).toBe(6);
  expect(sonuc.sonuc.satirlar[1].eksikler).toContain("Aynı ürün belgede 1. satırda da geçiyor; tek kart açılır.");
});

const metinYanit = (icerik: string) => new Response(JSON.stringify({
  choices: [{ message: { content: icerik }, finish_reason: "stop" }],
}), { status: 200, headers: { "content-type": "application/json" } });
const gorselliKart = (id: string, baslik: string, beden: string) => ({
  ...kartKaydi(id, baslik, beden),
  media: { image_url: "https://cdn.example/urun.webp" },
});
const ikiSatir = [
  { hamSatir: "1", model: "TER0105", ad: "Tutku Elit Sıfıryaka", barkod: "8680508918971", beden: "4", marka: "Tutku", adet: 6 },
  { hamSatir: "2", model: "TER0105", ad: "Tutku Elit Sıfıryaka", barkod: "8680508918988", beden: "5", marka: "Tutku", adet: 6 },
];

it("kart yanıtı başında cümle ve JSON çitiyle gelse de çözülür", async () => {
  const icerik = "I'll research each brand's official website.\n\n```json\n" +
    JSON.stringify({ items: [gorselliKart("1", "Tutku Elit Sıfıryaka", "4"), gorselliKart("2", "Tutku Elit Sıfıryaka", "5")] }, null, 2) +
    "\n```\n";
  const sonuc = await kartPresetYanitiniOku(metinYanit(icerik), okuma(ikiSatir));
  expect(sonuc.sonuc.satirlar.map((satir) => satir.dogrulamaDurumu))
    .toEqual(["Doğrulandı", "Doğrulandı"]);
  expect(sonuc.sonuc.satirlar.map((satir) => satir.siteGorseller))
    .toEqual([["https://cdn.example/urun.webp"], ["https://cdn.example/urun.webp"]]);
  expect(sonuc.sonuc.satirlar[0].siteSayfa).toBe("https://uretici.example/urun");
});

it("yalnız JSON çitiyle gelen kart yanıtı da çözülür", async () => {
  const icerik = "```json\n" + JSON.stringify({ items: [gorselliKart("1", "Tutku Elit Sıfıryaka", "4")] }) + "\n```";
  const sonuc = await kartPresetYanitiniOku(metinYanit(icerik), okuma([ikiSatir[0]]));
  expect(sonuc.sonuc.satirlar[0].ad).toBe("Tutku Elit Sıfıryaka");
});

it("JSON içermeyen kart yanıtı hâlâ reddedilir", async () => {
  await expect(kartPresetYanitiniOku(metinYanit("Ürün bulunamadı."), okuma([ikiSatir[0]])))
    .rejects.toThrow("KART_YANITI_COZULEMEDI");
});

it("adet sayı değilse birleşen kartta toplama yapılmaz", async () => {
  const sonuc = await kartPresetYanitiniOku(yanit([
    kartKaydi("1", "Tutku Elit Sıfıryaka", "4"), kartKaydi("2", "Tutku Elit Sıfıryaka", "4"),
  ]), okuma([
    { hamSatir: "1", model: "TER0105", ad: "Tutku Elit Sıfıryaka", barkod: "8680508918971", beden: "4", marka: "Tutku", adet: 6 },
    { hamSatir: "2", model: "TER0105", ad: "Tutku Elit Sıfıryaka", barkod: "8680508918971", beden: "4", marka: "Tutku", adet: null },
  ]));
  expect(sonuc.sonuc.satirlar[0].adet).toBe(6);
});
