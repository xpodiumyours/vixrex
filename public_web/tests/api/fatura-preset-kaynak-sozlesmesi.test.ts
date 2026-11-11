import { readFileSync } from "node:fs";
import path from "node:path";
import { describe, expect, it } from "vitest";
import { faturaIstekGovdesi } from "@/lib/faturaGoru";
import { kartPresetIstekGovdesi, URUN_KART_PRESET_YENI } from "@/lib/faturaKartPreset";
import type { GoruSonucu } from "@/lib/faturaGoru";

type Json = Record<string, unknown>;
const preset = (ad: string): Json =>
  JSON.parse(readFileSync(path.resolve(__dirname, "../../../openrouter", ad), "utf8")) as Json;
const okuma = preset("preset-okuma.json");
const kart = preset("preset-kart.json");
const sistem = (p: Json): string =>
  (p.messages as Array<{ role: string; content: string }>).find((m) => m.role === "system")?.content ?? "";

const ilkSonuc = {
  tedarikci: "Tedarikçi",
  satirlar: [
    { satirNo: 1, hamSatir: "Birinci ürün", model: "A-1", ad: "Birinci", marka: "Marka", barkod: "111", varyant: "Siyah", beden: "4", gramaj: "", adet: 2, birim: "adet", birimFiyat: 15, tutar: 30, okumaGuveni: 0.8 },
    { satirNo: 2, hamSatir: "İkinci ürün", model: "A-2", ad: "İkinci", marka: "Marka", barkod: "222", varyant: "", beden: "", gramaj: "400 g", adet: 3, birim: "adet", birimFiyat: 12, tutar: 36, okumaGuveni: null },
  ],
} as GoruSonucu;

describe("depodaki OpenRouter preset tanımı ↔ Vixrex taşıma sözleşmesi", () => {
  it("ilk preset ve üretim isteği aynı JSON modunu kullanır, web aracı çağırmaz", () => {
    const istek = faturaIstekGovdesi("data:image/jpeg;base64,AAAA");
    expect(okuma.response_format).toEqual({ type: "json_object" });
    expect(istek).not.toHaveProperty("response_format");
    expect(istek).not.toHaveProperty("provider");
    expect(istek.stream).toBe(true);
    expect(okuma).not.toHaveProperty("tools");
    expect(istek).not.toHaveProperty("tools");
    expect(sistem(okuma)).toContain("ARAŞTIRMA YOK");
  });

  it("ikinci preset gerçek 11 giriş alanını bilir; eski araştırma çıktısı istemez", () => {
    const govde = kartPresetIstekGovdesi(ilkSonuc);
    expect(govde.model).toBe(URUN_KART_PRESET_YENI);
    expect(govde.stream).toBe(true);
    expect(govde).not.toHaveProperty("tools");
    const metin = (govde.messages as Array<{content: string}>)[0].content;
    const veri = JSON.parse(metin.slice(metin.lastIndexOf("\n") + 1)) as {
      groups: Array<{brand: string; rows: Array<Record<string, unknown>>}>;
    };
    const ilk = veri.groups[0].rows[0];
    expect(Object.keys(ilk).sort()).toEqual([
      "row_id", "satir_no", "raw_invoice_line", "brand", "name", "code",
      "barcode", "variant", "size", "net_quantity", "invoice_data",
    ].sort());
    for (const alan of Object.keys(ilk)) expect(sistem(kart)).toContain(alan);
    expect(metin).not.toContain("previous_product_research");
    expect(sistem(kart)).not.toContain("previous_product_research");
    expect(veri.groups[0].rows.map((s) => s.row_id)).toEqual(["1", "2"]);
  });

  it("ikinci presetin zorunlu kart şemasında satır, kanıt ve fotoğraf ayrı alanlardır", () => {
    const format = kart.response_format as { type: string; json_schema: { strict: boolean; schema: {
      properties: {items: { items: {required: string[]; properties: Record<string, {required?: string[]; properties?: Record<string, unknown>}>}}}
    }}};
    expect(format.type).toBe("json_schema");
    expect(format.json_schema.strict).toBe(true);
    const kalem = format.json_schema.schema.properties.items.items;
    expect(kalem.required).toEqual([
      "row_id", "vixrex_product_json", "validation", "media",
      "duplicate_group", "canonical_row_id", "sources",
    ]);
    expect(kalem.properties).not.toHaveProperty("invoice_data");
    expect(kalem.properties).not.toHaveProperty("card_status");
    expect(kalem.properties.vixrex_product_json.properties).not.toHaveProperty("consumer_sale_price");
    expect(kalem.properties.vixrex_product_json.properties).not.toHaveProperty("stock_quantity");
    expect(kalem.properties.media.required).toEqual([
      "image_url", "source_url", "verification_status",
    ]);
    expect(kalem.properties.media.properties).not.toHaveProperty("rights_status");
    expect(kalem.properties.validation.required).toContain("official_product_url");
  });

  it("kopya satır talimatı strict şemanın zorunlu alanlarıyla çelişmez", () => {
    const metin=sistem(kart);
    expect(metin).toContain("title ve brand boş dize");
    expect(metin).toContain("validation ve media yine şemaya uygun döner");
    expect(metin).toContain("summary, card_status, invoice_data");
    expect(metin).toContain("rights_status alanlarını üretme");
    type StrictItem = { properties: Record<string, { required?: string[] }> };
    type StrictFormat = { json_schema: { schema: { properties: { items: { items: StrictItem } } } } };
    const item = (kart.response_format as StrictFormat).json_schema.schema.properties.items.items;
    expect(item.properties.vixrex_product_json.required).toContain("title");
    expect(item.properties.validation.required).toContain("official_product_url");
    expect(item.properties.media.required).toContain("image_url");
  });

  it("ürün araştırması yalnız ikinci presetindir ve üretim isteği preset ayarlarına dokunmaz", () => {
    const istek = kartPresetIstekGovdesi(ilkSonuc);
    const araclar = kart.tools as Array<{type: string}>;
    expect(araclar.map((arac) => arac.type)).toEqual([
      "openrouter:web_search", "openrouter:web_fetch",
    ]);
    expect(istek).not.toHaveProperty("response_format");
    expect(istek).not.toHaveProperty("provider");
    expect(istek).not.toHaveProperty("system");
    expect(istek).not.toHaveProperty("tools");
    expect(sistem(kart)).toContain("image_url");
    expect(sistem(kart)).toContain("source_url");
    expect(sistem(kart)).toContain("web_fetch");
  });

  it("faturanın fiyatı, miktarı, barkodu ve satır sırası ikinci presete kayıpsız geçer", () => {
    const istek = kartPresetIstekGovdesi(ilkSonuc);
    const content = (istek.messages as Array<{content:string}>)[0].content;
    const veri = JSON.parse(content.slice(content.lastIndexOf("\n") + 1)) as { groups: Array<{rows: Json[]}> };
    const satirlar = veri.groups.flatMap((g) => g.rows);
    expect(satirlar[0]).toMatchObject({
      row_id: "1", barcode: "111", variant: "Siyah", size: "4",
      invoice_data: { quantity: 2, unit: "adet", unit_price: 15, total_amount: 30 },
    });
    expect(satirlar[1]).toMatchObject({
      row_id: "2", barcode: "222", net_quantity: "400 g",
      invoice_data: { quantity: 3, unit: "adet", unit_price: 12, total_amount: 36 },
    });
    expect(content).not.toContain("Satış fiyatı: 15");
  });
});
