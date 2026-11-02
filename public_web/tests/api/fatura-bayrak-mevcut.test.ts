import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { kartPresetIstekGovdesi } from "@/lib/faturaKartPreset";
import type { GoruSonucu } from "@/lib/faturaGoru";

const okuma = {
  tedarikci: "Tedarikçi",
  satirlar: [{
    satirNo: 1, hamSatir: "X", model: "A", ad: "Ürün", marka: "M", barkod: "111",
    varyant: "", beden: "", gramaj: "", adet: 1, birim: "adet", birimFiyat: 10, tutar: 10,
    okumaGuveni: 1,
    siteAciklama: "eski açıklama", siteSayfa: "https://x/1", siteGorseller: ["https://x/1.jpg"],
    siteKategori: "Kat", uretici: "Uretici", ozellikler: [{ key: "k", value: "v" }],
    dogrulamaDurumu: "Belirsiz", eslesenBilgiler: ["M"], eksikler: [], gorselDogrulamaDurumu: "Araştırılamadı",
    kaynaklar: [{ url: "https://x/1", type: "manufacturer" }],
  }],
} as GoruSonucu;

describe("PRESET_AKIS=mevcut (üretim varsayılanı — geri alınabilirlik)", () => {
  beforeAll(() => { process.env.PRESET_AKIS = "mevcut"; });
  afterAll(() => { delete process.env.PRESET_AKIS; });

  it("eski preset adını kullanır", () => {
    const govde = kartPresetIstekGovdesi(okuma);
    expect(govde.model).toBe("@preset/urun-kart-olusturucu");
  });

  it("önceki araştırma alanını gönderir (eski davranış)", () => {
    const govde = kartPresetIstekGovdesi(okuma);
    const icerik = (govde.messages as Array<{ content: string }>)[0].content;
    const veri = JSON.parse(icerik.slice(icerik.lastIndexOf("\n") + 1));
    expect(veri.groups[0].rows[0].previous_product_research).toMatchObject({
      description: "eski açıklama", product_url: "https://x/1",
    });
  });
});
