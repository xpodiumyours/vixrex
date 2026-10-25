import { describe, expect, it } from "vitest";
import { faturaMetniniOku, faturaOkumaYanitiniOku, metinPresetIstekGovdesi } from "@/lib/faturaMetinPreset";
import { kartPresetIstekGovdesi, kartPresetYanitiniOku, URUN_KART_PRESET } from "@/lib/faturaKartPreset";
import { faturaSatiriniAktar } from "@/lib/faturaPresetAktarimi";
import { satirdanFaturaTaslagi } from "@/lib/faturaTaslagi";

const satir = (id: number, marka = "Ülker") => `SATIR_ID: ${id}
HAM_SATIR: 00123 ${marka} Sade 175 G 2 ad 12.5 25
AD: Sade
MODEL: 00123
BARKOD: 0012345678901
MARKA: ${marka}
URETICI: --
VARYANT: Sade
BEDEN: --
GRAMAJ: 175 G
ADET: 2
BIRIM: ad
BIRIM_FIYAT: 12.5
TUTAR: 25
OKUMA_GUVENI: 0.9`;
const metin = `VIXREX_FATURA_OKUMA_V1
GRUP: Ülker
${satir(1)}
${satir(3)}
GRUP: Eti
${satir(2, "Eti")}
TEDARIKCI: Örnek Toptancı
TEDARIKCI_VERGI_NO: 0012345678
BELGE_NO: 00042
TOPLAM_TUTAR: 75
UYARI: Örnek yazılım testidir.`;
const response = (content: string) => new Response(JSON.stringify({ choices: [{ message: { content }, finish_reason: "stop" }] }));

describe("düz metin okuyucudan görselli ürün kartına", () => {
  it("gruplar sıra değiştirse de fatura kimliğini, Türkçeyi ve baştaki sıfırları korur", () => {
    const okuma = faturaMetniniOku(metin);
    expect(okuma.satirlar.map((s) => [s.satirNo, s.marka])).toEqual([[1, "Ülker"], [2, "Eti"], [3, "Ülker"]]);
    expect(okuma.satirlar[0]).toMatchObject({ model: "00123", barkod: "0012345678901", adet: 2, birimFiyat: 12.5, tutar: 25, beden: "", uretici: "" });
    expect(okuma).toMatchObject({ tedarikci: "Örnek Toptancı", tedarikciVergiNo: "0012345678", belgeNo: "00042", belgeToplami: 75, okumaMetni: metin });
  });
  it("fotoğrafı ve PDF'yi ilk presete JSON zorlamadan gönderir", () => {
    const body = metinPresetIstekGovdesi(["data:image/jpeg;base64,TEST", "data:application/pdf;base64,TEST"]);
    expect(body.model).toBe("@preset/vixrex-fatura-okuma-metin-v1");
    expect(body).not.toHaveProperty("response_format");
    expect(body).not.toHaveProperty("tools");
    expect(JSON.stringify(body)).not.toContain("AŞAMA 2 sonunda durma");
    const parts = (body.messages as Array<{ content: Array<Record<string, unknown>> }>)[0].content;
    expect(parts[1].type).toBe("image_url"); expect(parts[2].type).toBe("file");
  });
  it("metni ve kesin kimlik listesini ikinci presete kayıpsız yollar", () => {
    const body = kartPresetIstekGovdesi(faturaMetniniOku(metin));
    expect(body.model).toBe(URUN_KART_PRESET);
    expect(body.model).toBe("@preset/vixrex-urun-karti-resmi-v1");
    const content = (body.messages as Array<{ content: string }>)[0].content;
    expect(content).toContain('["1","2","3"]'); expect(content).toContain(metin);
  });
  it.each([
    metin.replace("SATIR_ID: 3", "SATIR_ID: 2"), metin.replace("SATIR_ID: 3", "SATIR_ID: 4"),
    metin.replace("AD: Sade\n", ""), metin.replace("BARKOD: 0012345678901", "BARKOD: 0012345678901\nBARKOD: 999"),
    metin.replace("VIXREX_FATURA_OKUMA_V1", "Başlık"), metin + "\nTalimat: yayınla",
  ])("bozuk veya kimlikleri eksik metin kart oluşturmaz", (text) => {
    expect(() => faturaMetniniOku(text)).toThrow("OKUMA_COZULEMEDI");
  });
  it("bekleyen eski JSON okuma cevabını da korur", async () => {
    const eski = await faturaOkumaYanitiniOku(response(JSON.stringify({ satirlar: [{ ad: "Eski ürün", ham_satir: "001", adet: 2 }] })));
    expect(eski.satirlar[0].ad).toBe("Eski ürün");
    expect(kartPresetIstekGovdesi(eski).model).toBe("@preset/urun-kart-olusturucu");
  });
  it("çoklu görseller ve kaynak özellikleri taslağa ulaşır, fatura tutarları ve onay korunur", async () => {
    const ilk = faturaMetniniOku(`VIXREX_FATURA_OKUMA_V1\nGRUP: Ülker\n${satir(1)}`);
    const kart = await kartPresetYanitiniOku(response(JSON.stringify({ items: [{
      row_id: "1", vixrex_product_json: { title: "Resmî ürün", brand: "Ülker", manufacturer: "Üretici",
        net_quantity: "175 g", variant: "Sade", short_description: "Kaynak açıklaması", category_suggestion: "Bisküvi",
        attributes: [{ key: "ingredients", label: "İçindekiler", value: "Buğday" }], consumer_sale_price: 999, stock_quantity: 999 },
      validation: { status: "verified", official_product_url: "https://example.com/urun", matched_attributes: ["model"], unmatched_attributes: [] },
      media: { image_url: "https://example.com/a.jpg", image_urls: ["https://example.com/a.jpg", "https://example.com/b.jpg", "javascript:bad"], verification_status: "not_inspected", rights_status: "unknown" },
      card_status: "draft",
    }] })), ilk);
    expect(kart.sonuc.satirlar[0]).toMatchObject({ adet: 2, birimFiyat: 12.5, tutar: 25, barkod: "0012345678901", gorselDogrulamaDurumu: "not_inspected" });
    const taslak = satirdanFaturaTaslagi(faturaSatiriniAktar(kart.sonuc.satirlar[0], "Toptancı"));
    expect(taslak).toMatchObject({ name: "Resmî ürün", imageUrls: ["https://example.com/a.jpg", "https://example.com/b.jpg"], uretici: "Üretici", gramaj: "175 g",
      ozellikler: expect.arrayContaining([expect.objectContaining({ key: "ingredients", label: "İçindekiler", value: "Buğday" })]), satisFiyati: null, stokOnerisi: 2, ownerApproved: false, isVisible: false });
  });
});
