import { afterEach, beforeEach, expect, it, vi } from "vitest";
import { kartPresetYanitiniOku, tekillesmeKarari, tekrarGruplari } from "@/lib/faturaKartPreset";
import type { GoruSonucu } from "@/lib/faturaGoru";

beforeEach(() => vi.stubEnv("PRESET_AKIS", "yeni"));
afterEach(() => vi.unstubAllEnvs());

const kart = (grup: string, kanonik = "1", durum = "verified") => ({
  duplicate_group: grup, canonical_row_id: kanonik,
  validation: { status: durum, official_product_url: "https://uretici.example/urun" },
  media: {},
});
const kayit = (grup: string, kanonik = "1", durum = "verified") => new Map([
  ["1", kart(grup, kanonik, durum)], ["2", kart(grup, kanonik, durum)], ["3", kart(grup, kanonik, durum)],
]) as never;

it("OpenRouter kanonik satır 2 dediyse Vixrex ürün özelliklerinden ikinci karar çıkarmaz", () => {
  const satirlar = [
    { barkod: "111", ad: "Peynir 250 g", marka: "A", beden: "S", varyant: "Kırmızı", gramaj: "250 g" },
    { barkod: "222", ad: "Peynir 500 g", marka: "B", beden: "M", varyant: "Mavi", gramaj: "500 g" },
    { barkod: "", ad: "Çay", marka: "C", beden: "L", varyant: "Yeşil", gramaj: "1 kg" },
  ];
  expect([...tekrarGruplari(satirlar, kayit("preset-grup", "2")).entries()])
    .toEqual([["1", 2], ["3", 2]]);
});

it("aynı barkod ve beden, OpenRouter grubu yoksa Vixrex tarafından birleştirilmez", () => {
  const satirlar = [{ barkod: "111", ad: "A", beden: "4" }, { barkod: "111", ad: "A", beden: "4" }];
  expect(tekrarGruplari(satirlar, new Map() as never).size).toBe(0);
});

it("OpenRouter ayrı gruplar verdiyse aynı ürün adı tekilleştirme sebebi değildir", () => {
  const satirlar = [{ ad: "Çay" }, { ad: "Çay" }, { ad: "Çay" }];
  const items = new Map([
    ["1", kart("grup-a", "1")], ["2", kart("grup-b", "2")], ["3", kart("grup-b", "2")],
  ]) as never;
  expect([...tekrarGruplari(satirlar, items).entries()]).toEqual([["3", 2]]);
});

it("doğrulama belirsizliği OpenRouter'ın kanonik seçimini değiştirmez", () => {
  const satirlar = [{ ad: "A" }, { ad: "B" }, { ad: "C" }];
  expect([...tekrarGruplari(satirlar, kayit("grup", "1", "not_researched")).entries()])
    .toEqual([["2", 1], ["3", 1]]);
});

it("resmî kaynak bulunmaması tekilleştirme kararını Vixrex'e taşımaz", () => {
  const satirlar = [{ ad: "A" }, { ad: "B" }];
  const items = new Map([
    ["1", { ...kart("grup"), validation: { status: "verified", official_product_url: "" } }],
    ["2", { ...kart("grup"), validation: { status: "verified", official_product_url: "" } }],
  ]) as never;
  expect([...tekrarGruplari(satirlar, items).entries()]).toEqual([["2", 1]]);
});

it("fatura dışındaki kanonik row_id işaret edilirse bağlantı kabul edilmez", () => {
  expect(tekrarGruplari([{}, {}], new Map([
    ["1", kart("grup", "9")], ["2", kart("grup", "9")],
  ]) as never).size).toBe(0);
});

it("geçersiz kanonik row_id için Vixrex yeni bir kanonik seçmez", () => {
  expect(tekrarGruplari([{}, {}], new Map([
    ["1", kart("grup", "1.5")], ["2", kart("grup", "1.5")],
  ]) as never).size).toBe(0);
});

it("aynı grup içinde çelişkili canonical_row_id varsa kısmi birleştirme yapılmaz", () => {
  expect(tekrarGruplari([{}, {}, {}], new Map([
    ["1", kart("grup", "1")], ["2", kart("grup", "1")], ["3", kart("grup", "2")],
  ]) as never).size).toBe(0);
});

it("kanonik satırın kendine işaret etmediği çelişkili bağlantı kabul edilmez", () => {
  expect(tekrarGruplari([{}, {}], new Map([
    ["1", kart("grup", "2")], ["2", kart("grup", "1")],
  ]) as never).size).toBe(0);
});

it("boş canonical_row_id'li grup için satırlar korunur", () => {
  expect(tekrarGruplari([{}, {}], new Map([
    ["1", kart("grup", "")], ["2", kart("grup", "")],
  ]) as never).size).toBe(0);
});

it("mevcut geri dönüş yolu barkod veya bedenle yeniden ürün kararı vermez", () => {
  vi.stubEnv("PRESET_AKIS", "mevcut");
  const satirlar = [
    { barkod: "8680508918971", ad: "Tutku Fanila", marka: "Tutku", beden: "4" },
    { barkod: "8680508918971", ad: "Tutku Fanila", marka: "Tutku", beden: "5" },
  ];
  const karar = tekillesmeKarari(satirlar, new Map([
    ["1", kart("tutku", "1")], ["2", kart("tutku", "1")],
  ]) as never);
  expect(karar.indirgenen.size).toBe(0);
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
  barcode: "8680508918971", code: "TER0105",
  invoice_data: { quantity: 6, unit: "adet", unit_price: null, total_amount: null },
  duplicate_group: "tutku-8680508918971", canonical_row_id: "1",
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

it("yeni yolda Vixrex beden başlığı üretmez; kanonik kararı olduğu gibi taşır", async () => {
  const sonuc = await kartPresetYanitiniOku(yanit([
    kartKaydi("1", "Tutku Elit Sıfıryaka", "4"), kartKaydi("2", "", "5"),
  ]), okuma([
    { hamSatir: "1", model: "TER0105", ad: "Tutku Elit Sıfıryaka", barkod: "8680508918971", beden: "4", marka: "Tutku", adet: 6 },
    { hamSatir: "2", model: "TER0105", ad: "Tutku Elit Sıfıryaka", barkod: "8680508918971", beden: "5", marka: "Tutku", adet: 6 },
  ]));
  expect(sonuc.sonuc.satirlar.map((satir) => satir.ad))
    .toEqual(["Tutku Elit Sıfıryaka", "Tutku Elit Sıfıryaka"]);
  expect(sonuc.sonuc.satirlar[1].eksikler).toContain("OpenRouter aynı ürünü 1. satıra bağladı.");
  expect(sonuc.sonuc.satirlar.map((satir) => satir.adet)).toEqual([6, 6]);
  expect(sonuc.sonuc.satirlar.map((satir) => [satir.duplicateGroup, satir.canonicalRowId]))
    .toEqual([["tutku-8680508918971", "1"], ["tutku-8680508918971", "1"]]);
});

it("preset ayrı satır verdiyse Vixrex doğrulanmamış ürünleri kendisi tekilleştirmez", async () => {
  const ayriKart = (id: string) => ({
    ...kartKaydi(id, "Tutku Elit Sıfıryaka", "4", "not_found"),
    duplicate_group: null, canonical_row_id: null,
  });
  const sonuc = await kartPresetYanitiniOku(yanit([ayriKart("1"), ayriKart("2")]), okuma([
    { hamSatir: "1", model: "TER0105", ad: "Tutku Elit Sıfıryaka", barkod: "8680508918971", beden: "4", marka: "Tutku", adet: 6 },
    { hamSatir: "2", model: "TER0105", ad: "Tutku Elit Sıfıryaka", barkod: "8680508918971", beden: "4", marka: "Tutku", adet: 6 },
  ]));
  expect(sonuc.sonuc.satirlar.map((satir) => satir.dogrulamaDurumu)).toEqual(["Bulunamadı", "Bulunamadı"]);
  for (const satir of sonuc.sonuc.satirlar) {
    expect(satir.eksikler).not.toContain("OpenRouter aynı ürünü 1. satıra bağladı.");
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
  expect(sonuc.sonuc.satirlar[0].adet).toBe(6);
  expect(sonuc.sonuc.satirlar[1].adet).toBe(6);
  expect(sonuc.sonuc.satirlar[1].eksikler).toContain("OpenRouter aynı ürünü 1. satıra bağladı.");
});

const metinYanit = (icerik: string) => new Response(JSON.stringify({
  choices: [{ message: { content: icerik }, finish_reason: "stop" }],
}), { status: 200, headers: { "content-type": "application/json" } });
const gorselliKart = (id: string, baslik: string, beden: string) => ({
  ...kartKaydi(id, baslik, beden),
  duplicate_group: null, canonical_row_id: null,
  media: {
    image_url: "https://cdn.example/urun.webp", source_url: "https://uretici.example/urun",
    verification_status: "verified", rights_status: "unknown",
  },
});
const ikiSatir = [
  { hamSatir: "1", model: "TER0105", ad: "Tutku Elit Sıfıryaka", barkod: "8680508918971", beden: "4", marka: "Tutku", adet: 6 },
  { hamSatir: "2", model: "TER0105", ad: "Tutku Elit Sıfıryaka", barkod: "8680508918988", beden: "5", marka: "Tutku", adet: 6 },
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
    { hamSatir: "1", model: "TER0105", ad: "Tutku Elit Sıfıryaka", barkod: "8680508918971", beden: "4", marka: "Tutku", adet: 6 },
    { hamSatir: "2", model: "TER0105", ad: "Tutku Elit Sıfıryaka", barkod: "8680508918971", beden: "4", marka: "Tutku", adet: null },
  ]));
  expect(sonuc.sonuc.satirlar[0].adet).toBe(6);
});
