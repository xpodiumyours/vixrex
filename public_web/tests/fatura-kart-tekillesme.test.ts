import { afterEach, beforeEach, expect, it, vi } from "vitest";
import { kartPresetYanitiniOku, tekillesmeKarari, tekrarGruplari } from "@/lib/faturaKartPreset";
import type { GoruSonucu } from "@/lib/faturaGoru";

beforeEach(() => vi.stubEnv("PRESET_AKIS", "yeni"));
afterEach(() => vi.unstubAllEnvs());

it("aynı geçerli barkod Vixrex tarafından tek karta indirgenir", () => {
  const satirlar = [
    { barkod: "8691234567890", model: "P1", ad: "Peynir 250 g", marka: "A", adet: 2 },
    { barkod: "8691234567890", model: "P1", ad: "Peynir 250 g", marka: "A", adet: 3 },
  ];
  expect([...tekrarGruplari(satirlar).entries()]).toEqual([["2", 1]]);
});

it("farklı geçerli barkodlar aynı kod ve ad olsa da birleştirilmez", () => {
  const satirlar = [
    { barkod: "8691234567890", model: "TER0105", ad: "Fanila", marka: "Tutku", adet: 6 },
    { barkod: "8691234567891", model: "TER0105", ad: "Fanila", marka: "Tutku", adet: 6 },
  ];
  expect(tekrarGruplari(satirlar).size).toBe(0);
});

it("barkodsuz satırlarda kod, ad, marka ve miktar birlikte eşleşirse tekilleşir", () => {
  const satirlar = [
    { barkod: "", model: "TER0105", ad: "Fanila", marka: "Tutku", adet: 6 },
    { barkod: "", model: "TER0105", ad: "Fanila", marka: "Tutku", adet: 6 },
    { barkod: "", model: "TER0105", ad: "Fanila", marka: "Tutku", adet: 4 },
  ];
  expect([...tekrarGruplari(satirlar).entries()]).toEqual([["2", 1]]);
});

it("barkodsuz satırda yalnız ad aynıysa Vixrex ürün kararı vermez", () => {
  const satirlar = [{ barkod: "", ad: "Çay" }, { barkod: "", ad: "Çay" }];
  expect(tekrarGruplari(satirlar).size).toBe(0);
});

it("kontrol hanesi tutmayan barkod kimlik sayılmaz; kod varsa kodla eşleşir", () => {
  const gecersiz = [
    { barkod: "8691234567891", model: "", ad: "Fanila", marka: "Tutku", adet: 6 },
    { barkod: "8691234567891", model: "", ad: "Fanila", marka: "Tutku", adet: 6 },
  ];
  expect(tekrarGruplari(gecersiz).size).toBe(0);
  const kodlu = [
    { barkod: "8691234567891", model: "TER0105", ad: "Fanila", marka: "Tutku", adet: 6 },
    { barkod: "8691234567891", model: "TER0105", ad: "Fanila", marka: "Tutku", adet: 6 },
  ];
  expect([...tekrarGruplari(kodlu).entries()]).toEqual([["2", 1]]);
});

it("tekilleştirme kararı model cevabından bağımsız olarak yalnız fatura satırlarından çıkar", () => {
  const satirlar = [{ barkod: "8691234567890" }, { barkod: "8691234567890" }, { barkod: "8691234567890" }];
  expect([...tekillesmeKarari(satirlar).indirgenen.entries()]).toEqual([["2", 1], ["3", 1]]);
});

it("OpenRouter grup alanı göndermese de Vixrex kendi kimliğiyle karar verir", async () => {
  const sonuc = await kartPresetYanitiniOku(yanit([
    kartKaydi("1", "Tutku Elit Sıfıryaka", "4"),
    kartKaydi("2", "Tutku Elit Sıfıryaka", "4"),
  ]), okuma([
    { hamSatir: "1", model: "TER0105", ad: "Tutku Elit Sıfıryaka", barkod: "8691234567890", beden: "4", marka: "Tutku", adet: 6 },
    { hamSatir: "2", model: "TER0105", ad: "Tutku Elit Sıfıryaka", barkod: "8691234567890", beden: "4", marka: "Tutku", adet: 6 },
  ]));
  expect(sonuc.sonuc.satirlar[0].ad).toBe("Tutku Elit Sıfıryaka");
  expect(sonuc.sonuc.satirlar[1].eksikler).toContain("Aynı ürün belgede 1. satırda da geçiyor; tek kart açılır.");
  expect(sonuc.sonuc.satirlar.map((satir) => [satir.duplicateGroup, satir.canonicalRowId]))
    .toEqual([["barkod:8691234567890", "1"], ["barkod:8691234567890", "1"]]);
});

it("modelin verdiği grup farklı barkodlu satırları birleştirmez", async () => {
  const ayniGrup = (id: string, baslik: string) => ({
    ...kartKaydi(id, baslik, "4"),
    duplicate_group: "model-grubu", canonical_row_id: "1",
  });
  const sonuc = await kartPresetYanitiniOku(yanit([
    ayniGrup("1", "Tutku Elit Sıfıryaka"),
    ayniGrup("2", "Tutku Elit Sıfıryaka"),
  ]), okuma([
    { hamSatir: "1", model: "TER0105", ad: "Tutku Elit Sıfıryaka", barkod: "8691234567890", beden: "4", marka: "Tutku", adet: 6 },
    { hamSatir: "2", model: "TER0105", ad: "Tutku Elit Sıfıryaka", barkod: "8691234567891", beden: "5", marka: "Tutku", adet: 6 },
  ]));
  for (const satir of sonuc.sonuc.satirlar) {
    expect(satir.eksikler).not.toContain("Aynı ürün belgede 1. satırda da geçiyor; tek kart açılır.");
    expect(satir.duplicateGroup).toBeNull();
    expect(satir.canonicalRowId).toBeNull();
  }
});

it("mevcut geri dönüş yolu da tekilleştirmeyi Vixrex kimliğinden alır", async () => {
  vi.stubEnv("PRESET_AKIS", "mevcut");
  const satirlar = [
    { model: "TER0105", barkod: "8691234567890", ad: "Tutku Fanila", marka: "Tutku", adet: 6 },
    { model: "TER0105", barkod: "8691234567890", ad: "Tutku Fanila", marka: "Tutku", adet: 6 },
  ];
  expect([...tekillesmeKarari(satirlar).indirgenen.entries()]).toEqual([["2", 1]]);
});

const okuma = (satirlar: Array<Record<string, unknown>>) => ({ tedarikci: "Tedarikçi", satirlar }) as unknown as GoruSonucu;
const yanit = (items: unknown[]) => new Response(JSON.stringify({
  choices: [{ message: { content: JSON.stringify({
    summary: { total_rows: items.length, verified_count: items.length, draft_count: items.length, not_found_count: 0 },
    items,
  }) }, finish_reason: "stop" }],
}), { status: 200, headers: { "content-type": "application/json" } });
const kartKaydi = (id: string, title: string, beden: string, durum = "verified") => ({
  row_id: id, raw_invoice_line: "Beden " + beden, brand: "Tutku",
  barcode: "8691234567890", code: "TER0105",
  invoice_data: { quantity: 6, unit: "adet", unit_price: null, total_amount: null },
  vixrex_product_json: {
    title, brand: "Tutku", category_suggestion: null, variant: null,
    short_description: null, consumer_sale_price: null, stock_quantity: null,
  },
  validation: {
    status: durum, official_domain: "uretici.example", official_product_url: "https://uretici.example/urun",
    matched_attributes: [], unmatched_attributes: [],
  },
  media: { image_url: null, source_url: null, verification_status: null, rights_status: "unknown" },
  card_status: "draft",
  sources: [{ url: "https://uretici.example/urun", fetched_at: "2026-11-02T00:00:00Z", snippet: "Tutku Elit" }],
});

const metinYanit = (icerik: string) => new Response(JSON.stringify({
  choices: [{ message: { content: icerik }, finish_reason: "stop" }],
}), { status: 200, headers: { "content-type": "application/json" } });
const gorselliKart = (id: string, baslik: string, beden: string) => ({
  ...kartKaydi(id, baslik, beden),
  media: {
    image_url: "https://cdn.example/urun.webp", source_url: "https://uretici.example/urun",
    verification_status: "verified", rights_status: "unknown",
  },
});
const ikiSatir = [
  { hamSatir: "1", model: "TER0105", ad: "Tutku Elit Sıfıryaka", barkod: "8691234567890", beden: "4", marka: "Tutku", adet: 6 },
  { hamSatir: "2", model: "TER0105", ad: "Tutku Elit Sıfıryaka", barkod: "8691234567891", beden: "5", marka: "Tutku", adet: 6 },
];

it("kart yanıtı başında cümle ve JSON çitiyle gelse de çözülür", async () => {
  const kartlar = [gorselliKart("1", "Tutku Elit Sıfıryaka", "4"), gorselliKart("2", "Tutku Elit Sıfıryaka", "5")];
  const icerik = "I'll research each brand's official website.\n\n```json\n" +
    JSON.stringify({ summary: { total_rows: 2, verified_count: 2, draft_count: 2, not_found_count: 0 }, items: kartlar }, null, 2) +
    "\n```\n";
  const sonuc = await kartPresetYanitiniOku(metinYanit(icerik), okuma(ikiSatir));
  expect(sonuc.sonuc.satirlar.map((satir) => satir.dogrulamaDurumu))
    .toEqual(["Doğrulandı", "Doğrulandı"]);
  expect(sonuc.sonuc.satirlar.map((satir) => satir.siteGorseller))
    .toEqual([["https://cdn.example/urun.webp"], ["https://cdn.example/urun.webp"]]);
  expect(sonuc.sonuc.satirlar[0].siteSayfa).toBe("https://uretici.example/urun");
});

it("yalnız JSON çitiyle gelen kart yanıtı da çözülür", async () => {
  const icerik = "```json\n" + JSON.stringify({
    summary: { total_rows: 1, verified_count: 1, draft_count: 1, not_found_count: 0 },
    items: [gorselliKart("1", "Tutku Elit Sıfıryaka", "4")],
  }) + "\n```";
  const sonuc = await kartPresetYanitiniOku(metinYanit(icerik), okuma([ikiSatir[0]]));
  expect(sonuc.sonuc.satirlar[0].ad).toBe("Tutku Elit Sıfıryaka");
});

it("JSON içermeyen kart yanıtı hâlâ reddedilir", async () => {
  await expect(kartPresetYanitiniOku(metinYanit("Ürün bulunamadı."), okuma([ikiSatir[0]])))
    .rejects.toThrow("KART_YANITI_COZULEMEDI");
});

it("eski akış düz kart yanıtından ürün adresini okumaya devam eder", async () => {
  vi.stubEnv("PRESET_AKIS", "mevcut");
  const duzKart = {
    row_id: "1", title: "Tutku Elit Sıfıryaka", brand: "Tutku", variant: "100 BEYAZ",
    short_description: "Pamuklu fanila", category_suggestion: "Erkek İç Giyim",
    verification_status: "verified", product_url: "https://uretici.example/urun",
    image_url: "https://cdn.example/urun.webp", source_url: "https://uretici.example/urun",
    matched_attributes: ["beden: 4"], unmatched_attributes: [], sources: [{ url: "https://uretici.example/urun", fetched_at: "2026-11-02T00:00:00Z", snippet: "Tutku Elit" }],
  };
  const sonuc = await kartPresetYanitiniOku(metinYanit(JSON.stringify({ items: [duzKart] })), okuma([ikiSatir[0]]));
  const satir = sonuc.sonuc.satirlar[0];
  expect(satir.dogrulamaDurumu).toBe("Doğrulandı");
  expect(satir.siteSayfa).toBe("https://uretici.example/urun");
  expect(satir.siteGorseller).toEqual(["https://cdn.example/urun.webp"]);
  expect(satir.ad).toBe("Tutku Elit Sıfıryaka");
});

it("adet sayı değilse birleşen kartta toplama yapılmaz", async () => {
  const sonuc = await kartPresetYanitiniOku(yanit([
    kartKaydi("1", "Tutku Elit Sıfıryaka", "4"), kartKaydi("2", "Tutku Elit Sıfıryaka", "4"),
  ]), okuma([
    { hamSatir: "1", model: "TER0105", ad: "Tutku Elit Sıfıryaka", barkod: "8691234567890", beden: "4", marka: "Tutku", adet: 6 },
    { hamSatir: "2", model: "TER0105", ad: "Tutku Elit Sıfıryaka", barkod: "8691234567890", beden: "4", marka: "Tutku", adet: null },
  ]));
  expect(sonuc.sonuc.satirlar[0].adet).toBe(6);
});
