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

function akisEkrani(adim: string, satirlar: unknown[], sonuc?: unknown) {
  state.index = 0;
  state.values = {
    0: adim,
    2: { satirlar, belgeAdedi: null, belgeToplami: null, tedarikci: "Test toptancı" },
    3: satirlar,
    ...(sonuc ? { 7: sonuc } : {}),
  };
  return renderToStaticMarkup(createElement(InvoiceToProducts, {
    storeSlug: "offline-test", onUploaded: async () => {},
  }));
}

function ornekKart() {
  const parsed = katalogJsonunuOku(JSON.stringify({ satirlar: [cases[0].product] }));
  return faturaSatiriDurumunuHazirla(faturaSatiriniAktar(parsed.satirlar[0], "Test toptancı"), "");
}

it("fiyatı yazılmış kart açık onay verilmeden hazır sayılmaz", () => {
  const kart = { ...ornekKart(), satisFiyati: "149,90" };
  const bekleyen = akisEkrani("urunler", [kart]);
  expect(bekleyen).toContain("0 / 1 hazır");
  expect(bekleyen).toContain('aria-pressed="false"');
  const onayli = akisEkrani("urunler", [{ ...kart, onayli: true }]);
  expect(onayli).toContain("1 / 1 hazır");
  expect(onayli).toContain('aria-pressed="true"');
  expect(onayli).toContain("1 onaylı kartla devam et");
});

it("resmî kaynak gelmeyen kartın taslakta korunduğunu açıklar", () => {
  const html = akisEkrani("urunler", [{ ...ornekKart(), katalog: null }]);
  expect(html).toContain("Kart faturadaki bilgilerle taslak olarak korunur.");
  expect(html).not.toContain("kart üretilmez");
});

it.each([false, true])("yayın sonucunu tüketici doğrulamasına göre gösterir: %s", (dogrulandi) => {
  const kart = { ...ornekKart(), satisFiyati: "149.90", onayli: true };
  const html = akisEkrani("bitti", [kart], {
    tuketiciDogrulandi: dogrulandi, toplam: 1, yayinda: 1, taslak: 0, hatali: 0,
    satirlar: [{ sira: 0, ad: kart.ad, durum: "yayinda", id: "test-product" }],
  });
  expect(html).toContain(dogrulandi ? "Vitrin hazır" : "Yayın kaydı alındı");
  if (!dogrulandi) expect(html).not.toContain("Vitrin hazır");
  expect(html).toContain('href="/v/offline-test"');
  expect(html).toContain("Kartları düzenle");
});

it("taslak kaydından sonra yayınlama ve kartlara dönüş ayrı kalır", () => {
  const kart = { ...ornekKart(), satisFiyati: "149.90", onayli: true };
  const html = akisEkrani("bitti", [kart], {
    toplam: 1, yayinda: 0, taslak: 1, hatali: 0,
    satirlar: [{ sira: 0, ad: kart.ad, durum: "taslak", id: "test-product" }],
  });
  expect(html).toContain("1 ürünü yayınla");
  expect(html).toContain("Kartları düzenle");
  expect(html).not.toContain("Vitrin hazır");
  expect(html).not.toContain('href="/v/offline-test"');
});

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
