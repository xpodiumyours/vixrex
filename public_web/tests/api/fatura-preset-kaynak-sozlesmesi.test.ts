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
const govdeVerisi = (govde: Record<string, unknown>) => {
  const content = (govde.messages as Array<{ content: string }>)[0].content;
  return JSON.parse(content.slice(content.lastIndexOf("\n") + 1)) as {
    supplier: { name: string; website: string; role?: string };
    groups: Array<{ brand: string; rows: Array<Record<string, unknown>> }>;
  };
};

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
    const govde = kartPresetIstekGovdesi(ilkSonuc, "yeni");
    expect(govde.model).toBe(URUN_KART_PRESET_YENI);
    expect(govde.stream).toBe(true);
    expect(govde).not.toHaveProperty("tools");
    const metin = (govde.messages as Array<{content: string}>)[0].content;
    const veri = JSON.parse(metin.slice(metin.lastIndexOf("\n") + 1)) as {
      groups: Array<{brand: string; rows: Array<Record<string, unknown>>}>;
    };
    const ilk = veri.groups[0].rows[0];
    expect(Object.keys(ilk).sort()).toEqual([
      "row_id", "satir_no", "brand", "name", "code",
      "barcode", "variant", "size", "net_quantity", "invoice_data",
    ].sort());
    expect(ilk).not.toHaveProperty("raw_invoice_line");
    expect(ilk.invoice_data).toEqual({ quantity: 2, unit: "adet" });
    for (const alan of Object.keys(ilk)) expect(sistem(kart)).toContain(alan);
    expect(sistem(kart)).toContain("invoice_data yalnız quantity ve unit içerir");
    expect(sistem(kart)).not.toContain("row_id, satir_no, raw_invoice_line");
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
      "row_id", "vixrex_product_json", "validation", "media", "sources",
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

  it("preset talimatı strict şemanın zorunlu alanlarıyla çelişmez", () => {
    const metin=sistem(kart);
    expect(metin).toContain("summary, card_status, invoice_data");
    expect(metin).toContain("rights_status alanlarını üretme");
    expect(metin).not.toContain("duplicate_group");
    expect(metin).not.toContain("canonical_row_id");
    type StrictItem = { required: string[]; properties: Record<string, { required?: string[] }> };
    type StrictFormat = { json_schema: { schema: { properties: { items: { items: StrictItem } } } } };
    const item = (kart.response_format as StrictFormat).json_schema.schema.properties.items.items;
    expect(item.required).toEqual(["row_id", "vixrex_product_json", "validation", "media", "sources"]);
    expect(item.properties.vixrex_product_json.required).toContain("title");
    expect(item.properties.validation.required).toContain("official_product_url");
    expect(item.properties.media.required).toContain("image_url");
  });

  it("ürün araştırması yalnız ikinci presetindir ve üretim isteği preset ayarlarına dokunmaz", () => {
    const istek = kartPresetIstekGovdesi(ilkSonuc, "yeni");
    const araclar = kart.tools as Array<{type: string}>;
    expect(araclar.map((arac) => arac.type)).toEqual([
      "openrouter:web_search", "openrouter:web_fetch",
    ]);
    expect(istek.response_format).toEqual(kart.response_format);
    expect(istek).not.toHaveProperty("provider");
    expect(istek).not.toHaveProperty("system");
    expect(istek).not.toHaveProperty("tools");
    expect(sistem(kart)).toContain("image_url");
    expect(sistem(kart)).toContain("source_url");
    expect(sistem(kart)).toContain("web_fetch");
  });

  it("faturadaki alış fiyatı ve tutar dışarı çıkmaz; miktar, barkod ve satır sırası korunur", () => {
    const istek = kartPresetIstekGovdesi(ilkSonuc, "yeni");
    const content = (istek.messages as Array<{content:string}>)[0].content;
    const veri = JSON.parse(content.slice(content.lastIndexOf("\n") + 1)) as { groups: Array<{rows: Json[]}> };
    const satirlar = veri.groups.flatMap((g) => g.rows);
    expect(satirlar[0]).toMatchObject({
      row_id: "1", barcode: "111", variant: "Siyah", size: "4",
      invoice_data: { quantity: 2, unit: "adet" },
    });
    expect(satirlar[1]).toMatchObject({
      row_id: "2", barcode: "222", net_quantity: "400 g",
      invoice_data: { quantity: 3, unit: "adet" },
    });
    for (const satir of satirlar) {
      expect(satir).not.toHaveProperty("raw_invoice_line");
      expect(satir.invoice_data).not.toHaveProperty("unit_price");
      expect(satir.invoice_data).not.toHaveProperty("total_amount");
    }
    expect(content).not.toContain("Satış fiyatı: 15");
    expect(content).not.toContain("unit_price");
    expect(content).not.toContain("total_amount");
  });

  it("geri dönüş yolunda ham satır ve alış fiyatı gövdede kalır", () => {
    const istek = kartPresetIstekGovdesi(ilkSonuc, "mevcut");
    const veri = govdeVerisi(istek);
    const ilk = veri.groups[0].rows[0];
    expect(ilk).toMatchObject({
      raw_invoice_line: "Birinci ürün",
      invoice_data: { quantity: 2, unit: "adet", unit_price: 15, total_amount: 30 },
    });
    expect(veri.supplier).not.toHaveProperty("role");
  });

  it("çok markalı toptancı üretici sanılmasın diye tedarikçi rolü gövdeye yazılır", () => {
    const cokMarkali = {
      ...ilkSonuc,
      satirlar: [ilkSonuc.satirlar[0], { ...ilkSonuc.satirlar[1], marka: "Başka Marka" }],
    };
    expect(govdeVerisi(kartPresetIstekGovdesi(cokMarkali, "yeni")).supplier.role).toBe("cok_markali_toptanci");
    expect(govdeVerisi(kartPresetIstekGovdesi({ ...ilkSonuc, tedarikci: "Marka Tekstil" }, "yeni")).supplier.role).toBe("uretici");
    expect(govdeVerisi(kartPresetIstekGovdesi(ilkSonuc, "yeni")).supplier.role).toBe("bilinmiyor");
  });
});
