import { describe, expect, it } from "vitest";
import { katalogJsonunuOku } from "@/lib/faturaGoru";
import { kartPresetIstekGovdesi, kartPresetYanitiniOku } from "@/lib/faturaKartPreset";

const okuma = () => katalogJsonunuOku(JSON.stringify({
  tedarikci: "Toptancı", belge_no: "TEST-1", toplam_tutar: 36,
  belge_ekleri: { alici: "İkinci aşamaya gönderilmez" },
  satirlar: [
    { satir_no: 7, ham_satir: "001 ÜRÜN 175 G", ad: "Ürün", marka: "Marka", model: "001",
      barkod: "0012345678901", adet: 2, birim: "AD", birim_fiyat: 0, tutar: 0, okuma_guveni: 0.9, varyant: "175 G" },
    { satir_no: 7, ham_satir: "001 ÜRÜN 450 G", ad: "Ürün", marka: "Marka", model: "001",
      adet: null, birim: "KG", birim_fiyat: 36, tutar: 36, varyant: "450 G" },
  ],
}));
const item = (row_id: string, status = "verified") => ({
  row_id, invoice_data: { quantity: 999, unit_price: 999 },
  vixrex_product_json: { title: `Resmî ürün ${row_id}`, variant: "Yanlış yeni varyant",
    short_description: "Kaynak açıklaması", consumer_sale_price: 999, stock_quantity: 999 },
  validation: { status, official_product_url: "https://manufacturer.example/urun",
    matched_attributes: ["title"], unmatched_attributes: ["gramaj"] },
  media: { image_url: "https://manufacturer.example/urun.jpg", rights_status: "unknown" },
  card_status: "draft",
});
const response = (items: unknown[], extra = {}) => new Response(JSON.stringify({
  choices: [{ message: { content: JSON.stringify({ items }) }, finish_reason: "stop" }],
  usage: { cost: 0.02, prompt_tokens: 100, completion_tokens: 50 }, ...extra,
}), { headers: { "content-type": "application/json" } });

describe("ikinci presetin mevcut ürün kartlarına aktarılması", () => {
  it("yalnız satır verisini gönderir; kimlikler koddan ve belge satır numarasından bağımsızdır", () => {
    const body = kartPresetIstekGovdesi(okuma());
    expect(body.model).toBe("@preset/urun-kart-olusturucu");
    expect(body).not.toHaveProperty("tools"); expect(body).not.toHaveProperty("temperature");
    const content = (body.messages as Array<{ content: string }>)[0].content;
    const input = JSON.parse(content.split("\n").at(-1)!);
    expect(input.groups[0].rows.map((s: { row_id: string }) => s.row_id)).toEqual(["1", "2"]);
    expect(input.groups[0].rows[0].barcode).toBe("0012345678901");
    expect(content).not.toContain("İkinci aşamaya gönderilmez"); expect(content).not.toContain("data:image");
  });
  it("farklı çıktı sırasını kimlikle eşler; fatura değerlerini ikinci model değiştiremez", async () => {
    const ilk = okuma();
    const { sonuc, kartCevabi, kullanim } = await kartPresetYanitiniOku(response([item("2"), item("1")]), ilk);
    expect(sonuc.satirlar.map((s) => s.ad)).toEqual(["Resmî ürün 1", "Resmî ürün 2"]);
    expect(sonuc.satirlar[0]).toMatchObject({ hamSatir: "001 ÜRÜN 175 G", model: "001", barkod: "0012345678901",
      adet: 2, birimFiyat: 0, tutar: 0, varyant: "175 G", siteAciklama: "Kaynak açıklaması", dogrulamaDurumu: "Doğrulandı" });
    expect(sonuc.satirlar[1].adet).toBeNull();
    expect(sonuc.belgeNo).toBe("TEST-1");
    expect(sonuc.satirlar[0]).not.toHaveProperty("satisFiyati");
    expect(sonuc.satirlar[0]).not.toHaveProperty("ownerApproved");
    expect(sonuc.satirlar[0].gorselDogrulamaDurumu).toBe("");
    expect(ilk.satirlar[0].ad).toBe("Ürün");
    expect(kartCevabi.items).toHaveLength(2); expect(kullanim.gercekMaliyet).toBe(0.02);
  });
  it.each([["verified", "Doğrulandı"], ["ambiguous", "Belirsiz"], ["not_found", "Bulunamadı"], ["not_researched", "Araştırılamadı"]])
    ("%s kararı değiştirilmeden taşınır", async (status, sonuc) => {
      const data = await kartPresetYanitiniOku(response([item("1", status), item("2", status)]), okuma());
      expect(data.sonuc.satirlar.every((s) => s.dogrulamaDurumu === sonuc)).toBe(true);
    });
  it.each([
    [item("1")], [item("1"), item("1")], [item("1"), item("3")], [item("1"), item("2"), item("3")],
    [{ ...item("1"), row_id: 1 }, item("2")],
  ])("eksik, yinelenen veya yabancı satırlar sessizce kaybolmaz", async (...items) => {
    await expect(kartPresetYanitiniOku(response(items), okuma())).rejects.toThrow("KART_SATIRLARI_ESLESMEDI");
  });
  it("görsel yoksa satır ve modelin taslak kararı korunur", async () => {
    const data = await kartPresetYanitiniOku(response([
      { ...item("1", "not_found"), media: { image_url: null, rights_status: "unknown" } }, item("2"),
    ]), okuma());
    expect(data.sonuc.satirlar[0].siteGorseller).toEqual([]);
    expect(data.sonuc.satirlar[0].dogrulamaDurumu).toBe("Bulunamadı");
    expect(data.sonuc.satirlar).toHaveLength(2);
  });
  it("preset talimatındaki source_url da taşınır; kimlik bilgili URL kartta gösterilmez", async () => {
    const data = await kartPresetYanitiniOku(response([
      { ...item("1"), media: { source_url: "https://manufacturer.example/source.jpg" } },
      { ...item("2"), media: { image_url: "https://secret:pass@manufacturer.example/image.jpg" } },
    ]), okuma());
    expect(data.sonuc.satirlar[0].siteGorseller).toEqual(["https://manufacturer.example/source.jpg"]);
    expect(data.sonuc.satirlar[1].siteGorseller).toEqual([]);
  });
  it.each(["maybe", "toString", "constructor", "__proto__"])("tanımsız %s durumu başarılı karta çevrilmez", async (status) => {
    await expect(kartPresetYanitiniOku(response([item("1", status), item("2")]), okuma()))
      .rejects.toThrow("KART_YANITI_COZULEMEDI");
  });
  it("kesilmiş ikinci yanıt tamamlandı sayılmaz", async () => {
    await expect(kartPresetYanitiniOku(response([], {
      choices: [{ finish_reason: "length", message: { content: '{"items":[]}' } }],
    }), okuma())).rejects.toThrow("OKUYUCU_EKSIK_CEVAP");
  });
});
