import { describe, expect, it } from "vitest";
import {
  barkodDenetimi,
  belgeAritmetigiDenetimi,
  gtinBicimindeMi,
  kaynakDenetimi,
  satirAritmetigiDenetimi,
} from "@/lib/faturaKapiDenetimi";
import { katalogJsonunuOku } from "@/lib/faturaGoru";
import { kartPresetIstekGovdesi } from "@/lib/faturaKartPreset";
import { tekKartSozlesmesi } from "@/lib/faturaKartSozlesmesi";
import type { GoruSonucu } from "@/lib/faturaGoru";

describe("barkod kontrol hanesi", () => {
  it("son hanesi yanlış GTIN yakalanır", () => {
    expect(gtinBicimindeMi("8691234567891")).toBe(true);
    expect(barkodDenetimi("8691234567891")?.kod).toBe("BARKOD_KONTROL_HANESI");
  });
  it("doğru GTIN ve yerel kod serbest geçer", () => {
    expect(barkodDenetimi("8691234567890")).toBeNull();
    expect(barkodDenetimi("TER0105")).toBeNull();
    expect(barkodDenetimi("")).toBeNull();
  });
});

describe("fatura aritmetiği", () => {
  it("satır: adet × birim fiyat tutmazsa yakalanır", () => {
    expect(satirAritmetigiDenetimi({ adet: 2, birimFiyat: 50, tutar: 100 })).toBeNull();
    expect(satirAritmetigiDenetimi({ adet: 2, birimFiyat: 50, tutar: 90 })?.kod).toBe("SATIR_ARITMETIGI");
    expect(satirAritmetigiDenetimi({ adet: null, birimFiyat: 50, tutar: 90 })).toBeNull();
  });
  it("belge: satır toplamı basılı toplamı tutmazsa yakalanır", () => {
    expect(belgeAritmetigiDenetimi([100, 200], 300)).toBeNull();
    expect(belgeAritmetigiDenetimi([100, 200], 350)?.kod).toBe("BELGE_ARITMETIGI");
    expect(belgeAritmetigiDenetimi([100, null], 350)).toBeNull();
  });
});

describe("okuma aşaması uyarıları", () => {
  const json = (ek: Record<string, unknown>) => JSON.stringify({
    tedarikci: "TUTKU", mal_bedeli: 300, odenecek_toplam: 300,
    satirlar: [{ satir_no: 1, ham_satir: "ÜRÜN A 2X50", ad: "Ürün A", barkod: "8691234567891",
      adet: 2, birim: "adet", birim_fiyat: 50, tutar: 100 }],
    ...ek,
  });

  it("yanlış barkod ve tutmayan toplam sessiz geçmez", () => {
    const sonuc = katalogJsonunuOku(json({}));
    const uyarilar = sonuc.uyarilar ?? [];
    expect(uyarilar.some((u) => u.includes("kontrol hanesi"))).toBe(true);
    expect(uyarilar.some((u) => u.includes("basılı toplam"))).toBe(true);
  });

  it("doğru belgede uyarı üretilmez", () => {
    const sonuc = katalogJsonunuOku(JSON.stringify({
      mal_bedeli: 100,
      satirlar: [{ satir_no: 1, ad: "Ürün A", barkod: "8691234567890", adet: 2, birim_fiyat: 50, tutar: 100 }],
    }));
    expect(sonuc.uyarilar ?? []).toEqual([]);
  });
});

describe("ürün kartı isteğinde kimlik", () => {
  const okuma = {
    tedarikci: "TUTKU",
    satirlar: [
      { hamSatir: "A", ad: "Ürün A", marka: "TUTKU", barkod: "8691234567891", varyant: "", beden: "", model: "", adet: 2, birim: "adet", birimFiyat: 50, tutar: 100, okumaGuveni: 1 },
      { hamSatir: "B", ad: "Ürün B", marka: "TUTKU", barkod: "8691234567890", varyant: "", beden: "", model: "", adet: 1, birim: "adet", birimFiyat: 10, tutar: 10, okumaGuveni: 1 },
    ],
  } as unknown as GoruSonucu;

  it("kontrol hanesi tutmayan barkod kimlik olarak gönderilmez", () => {
    const govde = kartPresetIstekGovdesi(okuma);
    const metin = (govde.messages as Array<{ content: string }>)[0].content;
    const satirlar = (JSON.parse(metin.slice(metin.indexOf("{"))) as { groups: Array<{ rows: Array<Record<string, unknown>> }> }).groups[0].rows;
    expect(satirlar[0].barcode).toBeNull();
    expect(satirlar[1].barcode).toBe("8691234567890");
  });
});

describe("kartın kaynak kaydı", () => {
  const kart = (ek: Record<string, unknown> = {}) => ({
    row_id: "1", raw_invoice_line: "A", brand: "TUTKU", barcode: "8691234567890", code: null,
    invoice_data: { quantity: 1, unit: "adet", unit_price: 10, total_amount: 10 },
    vixrex_product_json: { title: "Ürün", brand: "TUTKU", category_suggestion: null, variant: null,
      short_description: null, consumer_sale_price: null, stock_quantity: null },
    validation: { status: "verified", official_domain: "sehermensucat.com",
      official_product_url: "https://sehermensucat.com/urun", matched_attributes: [], unmatched_attributes: [] },
    media: { image_url: null, source_url: null, verification_status: null, rights_status: "unknown" },
    card_status: "draft", duplicate_group: null, canonical_row_id: null,
    ...ek,
  });

  it("kaynak kaydı yoksa kart doğrulanmış sayılmaz", () => {
    expect(kaynakDenetimi({ resmiSayfa: "https://sehermensucat.com/urun", kaynaklar: [] })?.kod).toBe("KAYNAK_KAYDI_YOK");
    expect(tekKartSozlesmesi(kart()).dogrulanmis).toBe(false);
  });

  it("başka sayfayı gösteren kaynak kanıt sayılmaz", () => {
    const yanlis = [{ url: "https://sehermensucat.com/baska-urun" }];
    expect(kaynakDenetimi({ resmiSayfa: "https://sehermensucat.com/urun", kaynaklar: yanlis })?.kod).toBe("KAYNAK_UYUSMUYOR");
    expect(tekKartSozlesmesi(kart({ sources: yanlis })).dogrulanmis).toBe(false);
  });

  it("açılan sayfanın kaydı varsa doğrulanmış sayılır", () => {
    const dogru = [{ url: "https://sehermensucat.com/urun" }];
    expect(tekKartSozlesmesi(kart({ sources: dogru })).dogrulanmis).toBe(true);
  });

  it("resmî ürün sayfasının alan adı official_domain ile uyuşmazsa doğrulanmış sayılmaz", () => {
    const dogru = [{ url: "https://baskaalan.com/urun" }];
    expect(kaynakDenetimi({
      resmiSayfa: "https://baskaalan.com/urun", kaynaklar: dogru, officialDomain: "sehermensucat.com",
    })?.kod).toBe("ALAN_ADI_UYUSMUYOR");
    const baska = kart({
      validation: { status: "verified", official_domain: "sehermensucat.com",
        official_product_url: "https://baskaalan.com/urun", matched_attributes: [], unmatched_attributes: [] },
      sources: dogru,
    });
    expect(tekKartSozlesmesi(baska).dogrulanmis).toBe(false);
    expect(tekKartSozlesmesi(baska).kanitEksigi?.kod).toBe("ALAN_ADI_UYUSMUYOR");
  });

  it("alt alan adı ve www farkı alan adı uyuşmazlığı sayılmaz", () => {
    expect(kaynakDenetimi({
      resmiSayfa: "https://www.sehermensucat.com/urun",
      kaynaklar: [{ url: "https://www.sehermensucat.com/urun" }],
      officialDomain: "sehermensucat.com",
    })).toBeNull();
    expect(kaynakDenetimi({
      resmiSayfa: "https://shop.sehermensucat.com/urun",
      kaynaklar: [{ url: "https://shop.sehermensucat.com/urun" }],
      officialDomain: "sehermensucat.com",
    })).toBeNull();
  });
});
