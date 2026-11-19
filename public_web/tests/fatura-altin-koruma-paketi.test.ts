import { describe, expect, it } from "vitest";
import { faturaYanitiniOku, type GoruSatiri } from "@/lib/faturaGoru";
import { FATURA_JSON_ISTEGI } from "@/lib/faturaPresetSozlesmesi";
import {
  gorselAdaylariniSuz,
  kural32NesneTemizle,
  resmiAlanAdiUygunMu,
} from "@/lib/faturaUrunHazirlama";
import { faturaSatiriniAktar } from "@/lib/faturaPresetAktarimi";
import { kartDegerlendir } from "@/lib/faturaKartDurumu";
import {
  DOGRULANMIS_HAK_DURUMLARI,
  gorselHakKaydiniRaporla,
  gorselHakKayitlariniDerle,
  gorselIzinBekliyorMu,
} from "@/lib/faturaGorselHakDenetimi";
import { belgeParmakIzi } from "@/lib/faturaIslemKaydi";
import { kartPresetIstekGovdesi } from "@/lib/faturaKartPreset";

describe("Aşama 1 — Fatura Altın Koruma Paketi", () => {
  it("Kilit 1: faturaYanitiniOku model, barkod, adet, birimFiyat, tutar ve tedarikciSite alanlarını korur; model kodu sözleşmede zorunludur", async () => {
    const yanit = new Response(
      JSON.stringify({
        choices: [
          {
            finish_reason: "stop",
            message: {
              content: JSON.stringify({
                tedarikci: "Güler Bebe Tekstil",
                tedarikci_site: "www.gulerbebe.com",
                satirlar: [
                  {
                    satir_no: 1,
                    ham_satir: "GB-1042 Yenidoğan Hastane Çıkışı 5 ADET 240,00 1.200,00",
                    model: "GB-1042",
                    ad: "Yenidoğan Hastane Çıkışı",
                    barkod: "8691234567890",
                    marka: "Güler Bebe",
                    adet: 5,
                    birim: "adet",
                    birim_fiyat: 240,
                    tutar: 1200,
                    okuma_guveni: 0.96,
                  },
                ],
              }),
            },
          },
        ],
      }),
      { status: 200, headers: { "content-type": "application/json" } },
    );

    const sonuc = await faturaYanitiniOku(yanit);
    expect(sonuc.tedarikciSite).toBe("www.gulerbebe.com");
    expect(sonuc.satirlar).toHaveLength(1);
    expect(sonuc.satirlar[0]).toMatchObject({
      model: "GB-1042",
      barkod: "8691234567890",
      adet: 5,
      birimFiyat: 240,
      tutar: 1200,
    });
    expect(FATURA_JSON_ISTEGI).toContain("Model Kodu");
    expect(FATURA_JSON_ISTEGI).toContain("Stok Kodu");
    expect(FATURA_JSON_ISTEGI).toContain("model alanına aynen yaz");
  });

  it("Kilit 2: pazaryeri ve aracı URL'leri reddedilir, onaylı e-ticaret CDN adresleri kabul edilir", () => {
    const yasakliUrller = [
      "https://www.trendyol.com/marka/urun-p-123",
      "https://cdn.dsmcdn.com/mnresize/1200/1800/urun.jpg",
      "https://www.hepsiburada.com/urun-p-HBV00001",
      "https://productimages.hepsiburada.net/s/100/500/1.jpg",
      "https://www.n11.com/urun/test-urun-1",
      "https://www.amazon.com.tr/dp/B00TEST123",
      "https://www.instagram.com/p/test123/",
    ];
    const onayliCdnUrlleri = [
      "https://gulerbebe.sercdn.com/products/gb-1042.jpg",
      "https://static.ticimax.cloud/550/uploads/urun.jpg",
      "https://cdn.akinoncdn.com/products/2026/01/urun.webp",
    ];

    for (const url of yasakliUrller) {
      expect(resmiAlanAdiUygunMu(url, "gulerbebe.com", { gorsel: true })).toBe(false);
    }
    for (const url of onayliCdnUrlleri) {
      expect(resmiAlanAdiUygunMu(url, "gulerbebe.com", { gorsel: true })).toBe(true);
    }

    const suzulen = gorselAdaylariniSuz({
      adaylar: [...yasakliUrller, ...onayliCdnUrlleri],
      tespitEdilenAlan: "gulerbebe.com",
    });
    expect(suzulen).toEqual(onayliCdnUrlleri);
  });

  it("Kilit 3: web sitesi, barkodu ve görseli olmayan yerel ürün sahte URL/görsel üretmez", () => {
    const yerelSatir = {
      satirNo: 1,
      hamSatir: "EL YAPIMI BEBEK PATİĞİ 3 ADET 75",
      model: "PATIK-01",
      ad: "El Yapımı Bebek Patiği",
      barkod: "",
      varyant: "Ekru",
      beden: "0-3 Ay",
      marka: "Yerel Atölye",
      adet: 3,
      birim: "adet",
      birimFiyat: 75,
      tutar: 225,
      okumaGuveni: 0.9,
      siteSayfa: "",
      siteGorsel: "",
      siteGorseller: [],
      siteAciklama: "",
      siteKategori: "",
      dogrulamaDurumu: "✗ Bulunamadı",
      eksikler: ["Resmî üretici sitesi yok"],
    } as unknown as GoruSatiri;

    const aktarilan = faturaSatiriniAktar(yerelSatir, "Yerel Toptancı");
    expect(aktarilan.sonuc).toBe("iz-yok");
    expect(aktarilan.siteSayfa).toBe("");
    expect(aktarilan.siteGorsel).toBe("");
    expect(aktarilan.siteGorseller).toEqual([]);
    expect(aktarilan.katalog?.kaynak).toBe("");
    expect(aktarilan.katalog?.izinDurumu).toBe("yok");
    expect(aktarilan.katalog?.gorseller).toEqual([]);

    const degerlendirme = kartDegerlendir({ satir: aktarilan });
    expect(degerlendirme.durum).toBe("iz-yok");
    expect(degerlendirme.gorseller).toEqual([]);
    expect(degerlendirme.yayinaHazir).toBe(false);
  });

  it("Kilit 4: kural32NesneTemizle ticari sırları siler ve telif kalkanı fail-closed kalır", () => {
    const temiz = kural32NesneTemizle({
      name: "Bebek Zıbın",
      vkn: "1234567890",
      tckn: "12345678901",
      ettn: "11111111-2222-3333-4444-555555555555",
      iban: "TR330006100519786457841326",
      alisFiyati: 120,
      unit_price: 120,
      purchase_price: 120,
      iskonto: 15,
      discount: 15,
      nested: { faturaNo: "FTR2026001", model: "GB-1042" },
      attributes: [
        { key: "vkn", value: "1234567890" },
        { key: "fabric", label: "Kumaş", value: "%100 Pamuk" },
      ],
    });

    expect(temiz.name).toBe("Bebek Zıbın");
    expect(temiz).not.toHaveProperty("vkn");
    expect(temiz).not.toHaveProperty("tckn");
    expect(temiz).not.toHaveProperty("ettn");
    expect(temiz).not.toHaveProperty("iban");
    expect(temiz).not.toHaveProperty("alisFiyati");
    expect(temiz).not.toHaveProperty("unit_price");
    expect(temiz).not.toHaveProperty("purchase_price");
    expect(temiz).not.toHaveProperty("iskonto");
    expect(temiz).not.toHaveProperty("discount");
    expect(temiz.nested).toEqual({ model: "GB-1042" });
    expect(temiz.attributes).toEqual([{ key: "fabric", label: "Kumaş", value: "%100 Pamuk" }]);

    const durumHaritasi = gorselHakKayitlariniDerle([
      { image_url: "https://cdn.example.com/unknown.jpg", usage_status: "unknown" },
      { image_url: "https://cdn.example.com/denied.jpg", usage_status: "verified_supplier_permission" },
      { image_url: "https://cdn.example.com/denied.jpg", usage_status: "denied" },
      { image_url: "https://cdn.example.com/izinli-supplier.jpg", usage_status: "verified_supplier_permission" },
      { image_url: "https://cdn.example.com/izinli-feed.jpg", usage_status: "verified_feed_terms" },
      { image_url: "https://cdn.example.com/izinli-merchant.jpg", usage_status: "merchant_owned_media" },
    ]);

    expect(gorselHakKaydiniRaporla("https://cdn.example.com/unknown.jpg", durumHaritasi)).toEqual({
      hakKayitDurumu: "unknown",
      hakIncelemeGerekiyor: true,
    });
    expect(gorselHakKaydiniRaporla("https://cdn.example.com/denied.jpg", durumHaritasi)).toEqual({
      hakKayitDurumu: "denied",
      hakIncelemeGerekiyor: true,
    });
    expect(gorselHakKaydiniRaporla("https://cdn.example.com/eksik.jpg", durumHaritasi)).toEqual({
      hakKayitDurumu: "kayit_yok",
      hakIncelemeGerekiyor: true,
    });

    for (const url of [
      "https://cdn.example.com/izinli-supplier.jpg",
      "https://cdn.example.com/izinli-feed.jpg",
      "https://cdn.example.com/izinli-merchant.jpg",
    ]) {
      const rapor = gorselHakKaydiniRaporla(url, durumHaritasi);
      expect(DOGRULANMIS_HAK_DURUMLARI).toContain(rapor.hakKayitDurumu);
      expect(rapor.hakIncelemeGerekiyor).toBe(false);
    }

    expect(
      gorselIzinBekliyorMu({
        gorselKaynaklari: [{ hakKayitDurumu: "unknown" }],
      }),
    ).toBe(true);
    expect(
      gorselIzinBekliyorMu({
        gorselKaynaklari: [{ hakKayitDurumu: "denied" }],
      }),
    ).toBe(true);
    expect(
      gorselIzinBekliyorMu({
        gorselKaynaklari: [{ hakKayitDurumu: "kayit_yok" }],
      }),
    ).toBe(true);
    expect(
      gorselIzinBekliyorMu({
        gorselKaynaklari: [
          { hakKayitDurumu: "verified_supplier_permission" },
          { hakKayitDurumu: "verified_feed_terms" },
          { hakKayitDurumu: "merchant_owned_media" },
        ],
      }),
    ).toBe(false);
  });

  it("Kilit 5: belgeParmakIzi deterministiktir ve kartPresetIstekGovdesi 20 satırı eksiksiz ve tam tool limitleriyle taşır", () => {
    const baytA = new TextEncoder().encode("fatura-belge-a");
    const baytB = new TextEncoder().encode("fatura-belge-b");
    const hashA1 = belgeParmakIzi(baytA);
    const hashA2 = belgeParmakIzi(baytA);
    const hashB = belgeParmakIzi(baytB);

    expect(hashA1).toMatch(/^[0-9a-f]{64}$/);
    expect(hashA1).toBe(hashA2);
    expect(hashA1).not.toBe(hashB);

    const markalar = ["Güler Bebe", "Tutku", "Mavi", "Koton"];
    const satirlar = Array.from({ length: 20 }, (_, i) => ({
      satirNo: i + 1,
      hamSatir: `MDL-${i + 1} Ürün ${i + 1}`,
      model: `MDL-${i + 1}`,
      ad: `Ürün ${i + 1}`,
      barkod: "",
      varyant: "Standart",
      beden: "M",
      gramaj: "",
      marka: markalar[i % markalar.length],
      adet: i + 1,
      birim: "adet",
      birimFiyat: 50,
      tutar: (i + 1) * 50,
      okumaGuveni: 0.95,
    }));

    const govde = kartPresetIstekGovdesi(
      {
        tedarikci: "Çok Markalı Toptancı",
        tedarikciSite: "www.toptanci.example",
        satirlar,
      } as Parameters<typeof kartPresetIstekGovdesi>[0],
      "yeni",
    );

    const tools = govde.tools as Array<{
      type: string;
      parameters: { max_results?: number; max_uses?: number; max_total_results?: number };
    }>;
    const webSearch = tools.find((t) => t.type === "openrouter:web_search");
    const webFetch = tools.find((t) => t.type === "openrouter:web_fetch");
    expect(webSearch?.parameters.max_results).toBeGreaterThanOrEqual(8);
    expect(webSearch?.parameters.max_uses).toBeGreaterThanOrEqual(35);
    expect(webFetch?.parameters.max_uses).toBeGreaterThanOrEqual(35);

    const content = (govde.messages as Array<{ content: string }>)[0].content;
    const payload = JSON.parse(content.slice(content.lastIndexOf("\n") + 1)) as {
      groups: Array<{ brand: string; rows: Array<{ row_id: string }> }>;
    };
    const rowIds = payload.groups
      .flatMap((g) => g.rows.map((r) => r.row_id))
      .sort((a, b) => Number(a) - Number(b));
    expect(rowIds).toEqual(Array.from({ length: 20 }, (_, i) => String(i + 1)));
  });
});
