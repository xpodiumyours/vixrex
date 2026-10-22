import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";
import { afterAll, expect, it, vi } from "vitest";

const state = vi.hoisted(() => ({ index: 0, values: {} as Record<number, unknown> }));
vi.mock("react", async (importOriginal) => {
  const actual = await importOriginal<typeof import("react")>();
  return {
    ...actual,
    useState(initial: unknown) {
      const index = state.index++;
      return actual.useState(Object.hasOwn(state.values, index) ? state.values[index] : initial);
    },
  };
});

import InvoiceToProducts, { faturaSatiriDurumunuHazirla } from "@/components/owner/InvoiceToProducts";
import { katalogJsonunuOku } from "@/lib/faturaGoru";
import { faturaSatiriniAktar } from "@/lib/faturaPresetAktarimi";
import { satirdanFaturaTaslagi } from "@/lib/faturaTaslagi";
import { faturaKatalogMetadatasi } from "@/lib/faturaUrunIcerigi";
import { buildProductDetailFacts } from "@/lib/productCardPresentation";

const cases = [
  {
    sector: "Gıda",
    product: {
      ad: "Örnek gıda ürünü", uretici: "Test Gıda Üreticisi", gramaj: "175 g",
      adet: 2, birim: "adet", dogrulama_durumu: "? Belirsiz",
      site_sayfa: "https://manufacturer.example/food",
      ozellikler: [
        { key: "ingredients", label: "İçindekiler", value: "Örnek içerik" },
        { key: "energy", label: "Enerji", value: 125, unit: "kcal" },
        { key: "allergens", label: "Alerjenler", value: ["Buğday", "Süt"] },
      ],
    },
    visible: ["175 g", "Test Gıda Üreticisi", "Örnek içerik", "125 kcal", "Buğday, Süt"],
  },
  {
    sector: "Tekstil",
    product: {
      ad: "Örnek tekstil ürünü", uretici: "Test Tekstil Üreticisi", beden: "L", varyant: "Lacivert",
      adet: 2, birim: "adet", dogrulama_durumu: "? Belirsiz",
      site_sayfa: "https://manufacturer.example/textile",
      ozellikler: [
        { key: "fabric", label: "Kumaş içeriği", value: "%100 pamuk (örnek)" },
        { key: "care", label: "Yıkama / bakım", value: "Örnek kaynak bakım bilgisi" },
        { key: "fit", label: "Kesim", value: "Regular (örnek)" },
      ],
    },
    visible: ["Test Tekstil Üreticisi", "%100 pamuk (örnek)", "Örnek kaynak bakım bilgisi", "Lacivert", "Beden"],
  },
];
const results: unknown[] = [];

it.each(cases)("$sector: gelen alanlar esnaf ve tüketici kartına taşınır", ({ sector, product, visible }) => {
  const input = { satirlar: [product] };
  const parsed = katalogJsonunuOku(JSON.stringify(input));
  const row = faturaSatiriniAktar(parsed.satirlar[0], "Test toptancı");
  const ownerRow = faturaSatiriDurumunuHazirla(row, "");
  state.index = 0;
  state.values = {
    0: "urunler",
    2: { satirlar: [row], belgeAdedi: 2, belgeToplami: null, tedarikci: "Test toptancı" },
    3: [ownerRow],
  };
  const html = renderToStaticMarkup(createElement(InvoiceToProducts, {
    storeSlug: "offline-test", onUploaded: async () => {},
  }));
  expect(html).toContain("Ürün bilgileri");
  for (const value of visible) expect(html).toContain(value);
  expect(html).toContain("? Belirsiz");
  expect(ownerRow.satisFiyati).toBe("");
  expect(ownerRow.onayli).toBe(false);
  const metadata = faturaKatalogMetadatasi(row.katalog ?? {});
  const facts = buildProductDetailFacts({ metadata });
  if (sector === "Tekstil") {
    expect(facts).toEqual(expect.arrayContaining([
      { key: "size", label: "Beden", value: "L" },
      { key: "variant", label: "Varyant", value: "Lacivert" },
    ]));
    expect(facts.some((fact) => fact.key === "netQuantity")).toBe(false);
  }
  results.push({
    sektor: sector, ornekJson: input, vixrexTaslagi: satirdanFaturaTaslagi(row),
    tuketiciMetadatasi: metadata, tuketiciOzellikleri: facts,
    esnafEkraninda: visible.map((value) => ({ deger: value, gercekHtmlIcindeGorunuyor: html.includes(value) })),
    satisFiyati: ownerRow.satisFiyati, esnafOnayi: ownerRow.onayli,
  });
});

afterAll(() => {
  const output = process.env.VIXREX_KART_TEST_LOG;
  if (!output) return;
  let lastRealCall: Record<string, unknown> = {};
  try {
    const raw = JSON.parse(readFileSync("/tmp/vixrex-minimax-taslak-aktarim-test.json", "utf8"));
    for (const key of ["started", "finished", "success", "apiStatus", "generationId", "error"]) {
      lastRealCall[key] = raw[key];
    }
  } catch { lastRealCall = { durum: "Gerçek çağrı kaydı bu test ortamında mevcut değil." }; }
  mkdirSync(dirname(output), { recursive: true });
  writeFileSync(output, JSON.stringify({
    kapsam: "Gerçek Vixrex dönüştürme ve esnaf render koduyla çevrimdışı sözleşme testi",
    uyari: "Aşağıdaki gıda/tekstil JSON'ları sınama örnekleridir; gerçek OpenRouter fatura yanıtı veya resmî üretici verisi değildir. .example adresleri örnektir.",
    gercekOpenRouterSonKayit: lastRealCall,
    gercekFaturadanTamamlanmisKartAlindi: false,
    buKontroldeModelCagrisi: 0, buKontroldeCanliUrunKaydi: 0,
    ornekler: results,
  }, null, 2) + "\n");
});
