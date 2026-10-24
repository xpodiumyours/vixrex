import { afterEach, describe, expect, it, vi } from "vitest";
import { faturaIstekGovdesi, faturaPresetReferansi, faturayiOku, katalogJsonunuOku } from "@/lib/faturaGoru";
import { FATURA_JSON_ISTEGI } from "@/lib/faturaPresetSozlesmesi";
import { faturaSatiriniAktar, presetDurumunuAktar } from "@/lib/faturaPresetAktarimi";
import { satirdanFaturaTaslagi } from "@/lib/faturaTaslagi";
import { islemYaniti, type KayitliIslem } from "@/lib/faturaIslemOku";

const satir = {
  satir_no: 7, ham_satir: "ÜLKER PÖTİBÖR 175 G 2 ADET", ad: "ÜLKER PÖTİBÖR", model: "", barkod: "0012345678901",
  marka: "ÜLKER", uretici: "Ülker Sanayi A.Ş.", gramaj: "175 g", varyant: "Sade", beden: "",
  adet: 2, birim: "adet", birim_fiyat: 20, tutar: 40, okuma_guveni: 0.9,
  site_sayfa: "https://www.ulker.com.tr/tr/markalar/potibor", site_gorseller: ["https://resmi.example/175.jpg"],
  site_aciklama: "Kaynakta okunan açıklama", ozellikler: [{ key: "netQuantity", label: "Net miktar", value: "175 g" }],
  dogrulama_durumu: "? Belirsiz", eslesen_bilgiler: ["Ürün adı eşleşti"],
  eksikler: ["Gramaj resmî sayfada yok"], gorsel_dogrulama_durumu: "incelenmedi",
  kaynaklar: [{ url: "https://www.ulker.com.tr/tr/markalar/potibor", kanit: "Marka sayfası" }],
};
const parse = (s: unknown = satir, ek: Record<string, unknown> = {}) => katalogJsonunuOku(JSON.stringify({ satirlar: [s], ...ek }));

afterEach(() => { vi.unstubAllEnvs(); vi.unstubAllGlobals(); });

describe("Vixrex preset taşıma sözleşmesi", () => {
  it("boş ayarda mevcut çalışan preset seçilir", () => {
    vi.stubEnv("OPENROUTER_PRESET", ""); vi.stubEnv("OPENROUTER_FATURA_PRESET", "");
    expect(faturaPresetReferansi()).toBe("@preset/vixrex-qwen-fatura-okuma-suzme");
  });
  it("açık preset seçimi korunur ve ön ek tekrarlanmaz", () => {
    vi.stubEnv("OPENROUTER_PRESET", "@preset/ozel"); expect(faturaPresetReferansi()).toBe("@preset/ozel");
  });
  it("legacy preset ortam adı korunur", () => {
    vi.stubEnv("OPENROUTER_PRESET", ""); vi.stubEnv("OPENROUTER_FATURA_PRESET", "eski");
    expect(faturaPresetReferansi()).toBe("@preset/eski");
  });
  it("model, sistem istemi ve araçlar istemci tarafından değiştirilmez", () => {
    const body = faturaIstekGovdesi("data:image/png;base64,TEST");
    expect(body).not.toHaveProperty("tools"); expect(body).not.toHaveProperty("temperature");
    expect(body.response_format).toEqual({ type: "json_object" });
    expect(body.provider).toEqual({ require_parameters: true });
    expect(JSON.stringify(body)).toContain(FATURA_JSON_ISTEGI.replace(/\n/g, "\\n").slice(0, 10));
  });
  it("birinci preset yalnız fatura okur; araştırmayı ve satış kararını ikinci aşamaya bırakır", () => {
    expect(FATURA_JSON_ISTEGI).toContain("yalnız fatura okuma aşamasıdır");
    expect(FATURA_JSON_ISTEGI).toContain("web araştırması yapma");
    expect(FATURA_JSON_ISTEGI).toContain("Vixrex her satıra kendi değişmez row_id değerini atayacaktır");
    expect(FATURA_JSON_ISTEGI).toContain("Satış fiyatı");
    expect(FATURA_JSON_ISTEGI).toContain("vixrex.invoice-read/1.0");
    const body = faturaIstekGovdesi("data:image/png;base64,TEST");
    expect(body.model).toContain("@preset/");
    expect(body).not.toHaveProperty("tools");
  });
  it("invoice-read/1.0 bütün satırları korur ve row_id değerlerini Vixrex atar", () => {
    const result = katalogJsonunuOku(JSON.stringify({
      contract_version: "vixrex.invoice-read/1.0",
      document: {
        document_type: "e-arsiv", document_number: "F-001", document_date: null,
        supplier: { name: "Toptancı", tax_id: null, address: null, website_printed_on_invoice: null },
        buyer: { name: "Esnaf", tax_id: null }, currency: "TRY",
        totals: { goods: 40, vat: 4, discount: null, payable: 44 },
      },
      items: [
        { invoice_row_number: "07", raw_text: "ÜLKER PÖTİBÖR 175 G", product_name: "PÖTİBÖR", brand: "ÜLKER", manufacturer_printed: null, model_or_code: "A-7", gtin: "0012345678901", variant_text: "175 G", quantity: 2, unit: "AD", purchase_unit_price: 20, line_total: 40, read_confidence: 0.9 },
        { invoice_row_number: null, raw_text: "Başka ürün", product_name: null, brand: null, manufacturer_printed: null, model_or_code: null, gtin: null, variant_text: null, quantity: 1, unit: "AD", purchase_unit_price: null, line_total: null, read_confidence: null },
      ],
      warnings: ["Bir satırın adı okunamadı"],
    }));
    expect(result.satirlar.map((s) => s.rowId)).toEqual(["row-0001", "row-0002"]);
    expect(result.satirlar[0]).toMatchObject({ satirNo: 7, barkod: "0012345678901", marka: "ÜLKER", adet: 2, birimFiyat: 20, tutar: 40 });
    expect(result.satirlar[1].ad).toBe("Başka ürün");
    expect(result.tedarikci).toBe("Toptancı");
    expect(result.belgeTuru).toBe("e-arsiv");
    expect(result.uyarilar).toEqual(["Bir satırın adı okunamadı"]);
  });
  it("invoice-read/1.0 eksik zorunlu alanı veya sözleşme dışı alanı sessizce kabul etmez", () => {
    const valid = {
      contract_version: "vixrex.invoice-read/1.0",
      document: { document_type: null, document_number: null, document_date: null,
        supplier: { name: null, tax_id: null, address: null, website_printed_on_invoice: null },
        buyer: { name: null, tax_id: null }, currency: null,
        totals: { goods: null, vat: null, discount: null, payable: null } },
      items: [{ invoice_row_number: null, raw_text: "Ürün", product_name: null, brand: null,
        manufacturer_printed: null, model_or_code: null, gtin: null, variant_text: null,
        quantity: null, unit: null, purchase_unit_price: null, line_total: null, read_confidence: null }],
      warnings: [],
    };
    expect(() => katalogJsonunuOku(JSON.stringify({...valid, extra:"unexpected"}))).toThrow("OKUMA_COZULEMEDI");
    expect(() => katalogJsonunuOku(JSON.stringify({...valid, items:[{...valid.items[0], gtin:undefined}]}))).toThrow("OKUMA_COZULEMEDI");
  });
  it("PDF file, fotoğraf image_url olarak gönderilir", () => {
    const body = faturaIstekGovdesi(["data:application/pdf;base64,TEST", "data:image/jpeg;base64,TEST"]);
    const messages = body.messages as Array<{ content: Array<Record<string, unknown>> }>;
    expect(messages[0].content[1]).toEqual({ type: "file", file: { filename: "fatura.pdf", file_data: "data:application/pdf;base64,TEST" } });
    expect(messages[0].content[2].type).toBe("image_url");
  });
  it("98 kelimelik ekin ürün/kaynak/eksik alanları kayıpsız taşınır", () => {
    const sonuc = parse(); const kart = faturaSatiriniAktar(sonuc.satirlar[0], "Toptancı");
    expect(kart.katalog).toMatchObject({ uretici: satir.uretici, gramaj: "175 g", satirNo: 7,
      ozellikler: satir.ozellikler, dogrulamaDurumu: "? Belirsiz", eksikler: satir.eksikler,
      kaynaklar: satir.kaynaklar, eslesenBilgiler: satir.eslesen_bilgiler });
    expect(kart.barkod).toBe("0012345678901"); expect(kart.sonuc).toBe("eksik");
    expect(kart.katalog?.izinDurumu).toBe("yok"); expect(kart.katalog?.dayanak).toBe("ad");
    const taslak = satirdanFaturaTaslagi(kart, "test-islem");
    expect(taslak).toMatchObject({ uretici: satir.uretici, gramaj: "175 g", satisFiyati: null,
      ownerApproved: false, isVisible: false, kaynaklar: satir.kaynaklar, dogrulamaDurumu: "? Belirsiz" });
  });
  it.each([
    ["✓ Doğrulandı", "kanitli"], ["? Belirsiz", "eksik"], ["✗ Bulunamadı", "iz-yok"],
    ["⚠ Araştırılamadı", "eksik"], ["", "eksik"], ["başka değer", "eksik"],
  ])("OpenRouter %s kararı yeni araştırma olmadan %s etiketine taşınır", (durum, hedef) => {
    expect(presetDurumunuAktar(durum)).toBe(hedef);
  });
  it("bilinmeyen güven ve doğrulama tam güven veya kanıtlı sayılmaz", () => {
    const raw = { ...satir, okuma_guveni: null, dogrulama_durumu: "", eksikler: [] };
    const kart = faturaSatiriniAktar(parse(raw).satirlar[0], "Toptancı");
    expect(kart.guven).toBe(0); expect(kart.sonuc).toBe("eksik");
    expect(kart.uyari).toContain("okuma güveni bildirmedi");
  });
  it("null, sıfır ve Türkçe ondalık doğru taşınır; boolean sayı olmaz", () => {
    const s = parse({ ...satir, adet: null, birim_fiyat: 0, tutar: "1.234,50", okuma_guveni: true }).satirlar[0];
    expect(s.adet).toBeNull(); expect(s.birimFiyat).toBe(0); expect(s.tutar).toBe(1234.5); expect(s.okumaGuveni).toBeNull();
  });
  it("marka grupları ve belge ekleri/uyarılar korunur", () => {
    const ek = { gruplar: [{ marka: "ÜLKER", satirlar: [7] }], belge_ekleri: { not: "TEST" }, uyarilar: ["KDV belirsiz"] };
    const sonuc = parse(satir, ek);
    expect(sonuc.gruplar).toEqual(ek.gruplar); expect(sonuc.belgeEkleri).toEqual(ek.belge_ekleri); expect(sonuc.uyarilar).toEqual(ek.uyarilar);
  });
  it("eski site_ozellikler alan adı kaybolmaz", () => {
    expect(parse({ ...satir, ozellikler: undefined, site_ozellikler: satir.ozellikler }).satirlar[0].ozellikler).toEqual(satir.ozellikler);
  });
  it("iki satır ve varyantlar birleştirilmez", () => {
    const sonuc = katalogJsonunuOku(JSON.stringify({ satirlar: [satir, { ...satir, satir_no: 8, gramaj: "450 g" }] }));
    expect(sonuc.satirlar).toHaveLength(2); expect(sonuc.satirlar[1].gramaj).toBe("450 g");
  });
  it("geçersiz/kimlik bilgili görsel URL karta taşınmaz", () => {
    expect(parse({ ...satir, site_gorseller: ["javascript:alert(1)", "https://name:pass@example.com/a.jpg", "https://resmi.example/a.jpg"] }).satirlar[0].siteGorseller)
      .toEqual(["https://resmi.example/a.jpg"]);
  });
  it.each(["bozuk cevap", '{"satirlar":[null]}', '{"products":[]}', 'Önsöz {"satirlar":[]}'])
    ("bozuk veya sözleşmesiz JSON reddedilir: %s", (text) => { expect(() => katalogJsonunuOku(text)).toThrow("OKUMA_COZULEMEDI"); });
  it("tek fenced JSON okunabilir", () => { expect(katalogJsonunuOku('```json\n{"satirlar":[]}\n```').satirlar).toEqual([]); });
  it("yeniden açılan faturada gruplar/uyarılar korunur", () => {
    const data = islemYaniti({ satirlar: [], belge: {}, aramaDurumu: { presetCevabi: { gruplar: ["ÜLKER"], uyarilar: ["Eksik"], belgeEkleri: { test: true } } } } as unknown as KayitliIslem);
    expect(data.gruplar).toEqual(["ÜLKER"]); expect(data.uyarilar).toEqual(["Eksik"]);
  });
  it.each(["length", "tool_calls"])("yarım API yanıtı yayın verisine çevrilmez: %s", async (finish) => {
    vi.stubEnv("OPENROUTER_API_KEY", "test-key");
    vi.stubGlobal("fetch", vi.fn(async () => ({ ok: true, json: async () => ({ choices: [{ finish_reason: finish,
      message: { content: JSON.stringify({ satirlar: [satir] }), ...(finish === "tool_calls" ? { tool_calls: [{ id: "pending" }] } : {}) } }] }) })));
    await expect(faturayiOku("data:image/png;base64,TEST")).rejects.toThrow(finish === "length" ? "OKUYUCU_EKSIK_CEVAP" : "OKUYUCU_TAMAMLANMADI");
  });
});
